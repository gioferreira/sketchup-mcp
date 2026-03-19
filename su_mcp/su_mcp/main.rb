# SketchUp MCP Extension — TCP bridge for AI agents
# Based on mhyrr/sketchup-mcp (MIT). Rewritten for clarity and correctness.

require 'sketchup'
require 'json'
require 'socket'

module SU_MCP
  class Server
    def initialize
      @port = 9876
      @server = nil
      @running = false
      @timer_id = nil
    end

    def log(msg)
      begin
        SKETCHUP_CONSOLE.write("MCP: #{msg}\n")
      rescue
        puts "MCP: #{msg}"
      end
      STDOUT.flush
    end

    def start
      return if @running

      begin
        log "Starting server on localhost:#{@port}..."

        @server = TCPServer.new('127.0.0.1', @port)
        @running = true

        @timer_id = UI.start_timer(0.1, true) {
          begin
            if @running
              ready = IO.select([@server], nil, nil, 0)
              if ready
                client = @server.accept_nonblock
                data = client.gets

                if data
                  begin
                    request = JSON.parse(data)
                    response = handle_request(request)
                    client.write(response.to_json + "\n")
                    client.flush
                  rescue JSON::ParserError => e
                    log "JSON parse error: #{e.message}"
                    error_response = {
                      jsonrpc: "2.0",
                      error: { code: -32700, message: "Parse error" },
                      id: nil
                    }.to_json + "\n"
                    client.write(error_response)
                    client.flush
                  rescue StandardError => e
                    log "Request error: #{e.message}"
                    error_response = {
                      jsonrpc: "2.0",
                      error: { code: -32603, message: e.message },
                      id: request ? request["id"] : nil
                    }.to_json + "\n"
                    client.write(error_response)
                    client.flush
                  end
                end

                client.close
              end
            end
          rescue IO::WaitReadable
            # Normal for accept_nonblock
          rescue StandardError => e
            log "Timer error: #{e.message}"
          end
        }

        log "Server started and listening on port #{@port}"

      rescue StandardError => e
        log "Error: #{e.message}"
        stop
      end
    end

    def stop
      log "Stopping server..."
      @running = false

      if @timer_id
        UI.stop_timer(@timer_id)
        @timer_id = nil
      end

      @server.close if @server
      @server = nil
      log "Server stopped"
    end

    private

    def handle_request(request)
      method = request["method"]
      id = request["id"]

      case method
      when "tools/call"
        handle_tool_call(request)
      when "ping"
        { jsonrpc: "2.0", result: { status: "ok" }, id: id }
      else
        { jsonrpc: "2.0", error: { code: -32601, message: "Method not found" }, id: id }
      end
    end

    def handle_tool_call(request)
      tool_name = request.dig("params", "name")
      args = request.dig("params", "arguments") || {}
      id = request["id"]

      begin
        result = case tool_name
        when "get_scene_info"
          get_scene_info
        when "get_selection"
          get_selection
        when "create_component"
          create_component(args)
        when "delete_component"
          delete_component(args)
        when "transform_component"
          transform_component(args)
        when "set_material"
          set_material(args)
        when "export_scene"
          export_scene(args)
        when "eval_ruby"
          eval_ruby(args)
        else
          raise "Unknown tool: #{tool_name}"
        end

        {
          jsonrpc: "2.0",
          result: {
            content: [{ type: "text", text: (result[:result] || "Success").to_s }],
            isError: false,
            success: true
          },
          id: id
        }
      rescue StandardError => e
        log "Tool error (#{tool_name}): #{e.message}"
        {
          jsonrpc: "2.0",
          error: { code: -32603, message: e.message },
          id: id
        }
      end
    end

    # --- Tools ---

    def get_scene_info
      model = Sketchup.active_model
      raise "No active model" unless model

      entities = model.active_entities
      info = {
        name: model.name,
        path: model.path,
        entity_count: entities.length,
        entities: entities.first(50).map { |e|
          { id: e.entityID, type: e.typename }
        }
      }
      { success: true, result: info.to_json }
    end

    def get_selection
      model = Sketchup.active_model
      selection = model.selection

      selected = selection.map { |e|
        { id: e.entityID, type: e.typename }
      }
      { success: true, result: selected.to_json }
    end

    def create_component(params)
      model = Sketchup.active_model
      entities = model.active_entities
      pos = params["position"] || [0, 0, 0]
      dims = params["dimensions"] || [1, 1, 1]

      model.start_operation("MCP Create", true)
      begin
        group = entities.add_group
        face = group.entities.add_face(
          [pos[0], pos[1], pos[2]],
          [pos[0] + dims[0], pos[1], pos[2]],
          [pos[0] + dims[0], pos[1] + dims[1], pos[2]],
          [pos[0], pos[1] + dims[1], pos[2]]
        )
        face.pushpull(dims[2])
        model.commit_operation
        { success: true, result: "Created component #{group.entityID}" }
      rescue => e
        model.abort_operation
        raise e
      end
    end

    def delete_component(params)
      model = Sketchup.active_model
      entity = model.find_entity_by_id(params["id"].to_i)
      raise "Entity not found: #{params["id"]}" unless entity

      model.start_operation("MCP Delete", true)
      entity.erase!
      model.commit_operation
      { success: true, result: "Deleted" }
    end

    def transform_component(params)
      model = Sketchup.active_model
      entity = model.find_entity_by_id(params["id"].to_i)
      raise "Entity not found: #{params["id"]}" unless entity

      model.start_operation("MCP Transform", true)
      begin
        if params["position"]
          p = params["position"]
          entity.transform!(Geom::Transformation.translation(Geom::Point3d.new(p[0], p[1], p[2])))
        end

        if params["rotation"]
          r = params["rotation"]
          center = entity.bounds.center
          if r[0] != 0
            entity.transform!(Geom::Transformation.rotation(center, Geom::Vector3d.new(1,0,0), r[0] * Math::PI / 180))
          end
          if r[1] != 0
            entity.transform!(Geom::Transformation.rotation(center, Geom::Vector3d.new(0,1,0), r[1] * Math::PI / 180))
          end
          if r[2] != 0
            entity.transform!(Geom::Transformation.rotation(center, Geom::Vector3d.new(0,0,1), r[2] * Math::PI / 180))
          end
        end

        if params["scale"]
          s = params["scale"]
          entity.transform!(Geom::Transformation.scaling(entity.bounds.center, s[0], s[1], s[2]))
        end

        model.commit_operation
        { success: true, result: "Transformed #{entity.entityID}" }
      rescue => e
        model.abort_operation
        raise e
      end
    end

    def set_material(params)
      model = Sketchup.active_model
      entity = model.find_entity_by_id(params["id"].to_i)
      raise "Entity not found: #{params["id"]}" unless entity

      material_name = params["material"]
      material = model.materials[material_name]
      unless material
        material = model.materials.add(material_name)
        if material_name.start_with?("#") && material_name.length == 7
          r = material_name[1..2].to_i(16)
          g = material_name[3..4].to_i(16)
          b = material_name[5..6].to_i(16)
          material.color = Sketchup::Color.new(r, g, b)
        end
      end

      model.start_operation("MCP Material", true)
      if entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
        ents = entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities
        ents.grep(Sketchup::Face).each { |face| face.material = material }
      elsif entity.respond_to?(:material=)
        entity.material = material
      end
      model.commit_operation
      { success: true, result: "Material '#{material_name}' applied to #{entity.entityID}" }
    end

    def export_scene(params)
      model = Sketchup.active_model
      format = params["format"] || "png"
      timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
      temp_dir = File.join(Dir.tmpdir, "sketchup_mcp")
      Dir.mkdir(temp_dir) unless Dir.exist?(temp_dir)

      case format.downcase
      when "png", "jpg", "jpeg"
        ext = format.downcase == "jpg" ? "jpeg" : format.downcase
        path = File.join(temp_dir, "export_#{timestamp}.#{ext}")
        model.active_view.write_image({
          filename: path,
          width: params["width"] || 1920,
          height: params["height"] || 1080,
          antialias: true,
          transparent: (ext == "png")
        })
        { success: true, result: path }
      when "skp"
        path = File.join(temp_dir, "export_#{timestamp}.skp")
        model.save(path)
        { success: true, result: path }
      else
        raise "Unsupported format: #{format}. Use png, jpg, or skp."
      end
    end

    def eval_ruby(params)
      code = params["code"]
      raise "No code provided" unless code && !code.empty?
      result = eval(code)
      { success: true, result: result.to_s }
    end
  end

  unless file_loaded?(__FILE__)
    @server = Server.new

    menu = UI.menu("Plugins").add_submenu("MCP Server")
    menu.add_item("Start Server") { @server.start }
    menu.add_item("Stop Server") { @server.stop }

    file_loaded(__FILE__)
  end
end
