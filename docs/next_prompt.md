# Next Prompt — SketchUp MCP

## Contexto
Repo: `~/repos/sketchup-mcp/` (gioferreira/sketchup-mcp)
Extensão Ruby já instalada e testada no SketchUp 2024 Mac.
NotebookLM "SketchUp Ruby API" disponível pra consulta.
Memória: `project_sketchup_mcp.md`

## Tarefa: Fase 1 — Python MCP Server

Construir o MCP server Python com FastMCP. Referência de arquitetura: `~/repos/pts/cfo-mcp-server/` (mesmo padrão).

### Estrutura alvo

```
sketchup-mcp/
  su_mcp/              # Extensão Ruby (DONE)
  src/
    sketchup_mcp/
      __init__.py
      __main__.py      # mcp.run()
      server.py        # FastMCP init + tools
      connection.py    # SketchUpConnection (TCP socket localhost:9876)
  pyproject.toml
  docs/
```

### Checklist
1. Scaffold Python (pyproject.toml, src/, __main__.py)
2. connection.py — TCP client com reconnect, send_command, receive_response
3. server.py — FastMCP + tools (get_scene_info, get_selection, eval_ruby, create/delete/transform_component, set_material, export_scene)
4. Registrar: `claude mcp add sketchup -- uv run --directory ~/repos/sketchup-mcp python -m sketchup_mcp`
5. Testar end-to-end

### Referências de arquitetura
- CFO MCP server: `~/repos/pts/cfo-mcp-server/` — FastMCP, lifespan, tools modulares, docstrings ricas
- CFO PRD: `~/repos/pts/cfo-mcp-server/docs/prd-v3.md` — padrões de design adotados
- InDesign MCP: experiência prévia com MCP para app desktop (memória do projeto TFG)
- NotebookLM "SketchUp Ruby API": consultar antes de gerar código Ruby

### Decisões já tomadas
- Consultar NotebookLM "SketchUp Ruby API" antes de gerar código Ruby
- eval_ruby é a tool mais poderosa — as outras são conveniência
- Docstrings ricas em português (consumidor é LLM + Danilo)
