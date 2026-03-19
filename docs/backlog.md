# Backlog — SketchUp MCP

## Fase 0 — Extensão Ruby (DONE)

- [x] TCP server skeleton (localhost:9876, JSON-RPC)
- [x] Tools básicas: get_scene_info, get_selection, create/delete/transform_component, set_material, export_scene, eval_ruby
- [x] Instalado no SketchUp 2024 Mac
- [x] Testado via netcat — ping, get_scene_info, eval_ruby funcionando
- [x] Demo: living room criado remotamente (identificado bug de pushpull/normals, corrigido via translate)

## Fase 1 — Python MCP Server (PRÓXIMA)

- [ ] Scaffold com FastMCP (mesmo padrão do CFO MCP server)
- [ ] SketchUpConnection class (TCP socket → localhost:9876)
- [ ] Lifespan (connect on startup, disconnect on shutdown)
- [ ] Tools com docstrings ricas e annotations
- [ ] Registrar no Claude Code: `claude mcp add sketchup ...`
- [ ] Testar end-to-end: Claude Code → MCP → TCP → SketchUp

### Tools Fase 1

| Tool | Descrição | Prioridade |
|------|-----------|-----------|
| `get_scene_info` | Modelo ativo, entidades, bounds | P0 |
| `get_selection` | Entidades selecionadas | P0 |
| `eval_ruby` | Executar Ruby arbitrário | P0 |
| `create_component` | Criar geometria básica | P0 |
| `delete_component` | Deletar por ID | P0 |
| `transform_component` | Mover/rotacionar/escalar | P0 |
| `set_material` | Aplicar cor/material | P0 |
| `export_scene` | Exportar PNG/JPG/SKP | P0 |
| `import_file` | Importar DWG/DXF/SKP | P1 |
| `get_entity_info` | Detalhes de uma entidade (bounds, material, faces) | P1 |
| `screenshot` | Captura da viewport atual | P1 |

## Fase 2 — Tools especializadas para interiores

- [ ] `import_dwg` — importar planta baixa do AutoCAD com opções (flatten, merge faces, scale)
- [ ] `create_walls_from_plan` — levantar paredes a partir de linhas importadas
- [ ] `apply_material_by_name` — buscar material na biblioteca do SketchUp por nome
- [ ] `place_component` — posicionar componente .skp baixado do 3D Warehouse
- [ ] `set_camera` — posicionar câmera para perspectiva específica
- [ ] `create_section_cut` — corte de seção para plantas/cortes

## Fase 3 — Workflow de via dupla

- [ ] Claude lê o modelo atual, entende o que existe, sugere mudanças
- [ ] Danilo modela manualmente, Claude inspeciona e continua de onde parou
- [ ] Export de renders pra QA visual (Claude lê screenshot)

## Nice-to-have / Ideias futuras

- [ ] Auth por shared secret (env var nos dois lados do TCP)
- [ ] Tool de undo/redo (model.undo / model.redo)
- [ ] Batch operations (múltiplos comandos numa request)
- [ ] Watch mode (observer no SketchUp notifica mudanças)
- [ ] Suporte ao SketchUp 2025 no PC (quando tiver Claude Code lá)

## Conhecimento adquirido

- **pushpull e normals**: `face.pushpull(d)` extrude na direção da normal. Se vértices foram criados em sentido horário (visto de cima), normal aponta pra baixo → pushpull vai pro subsolo. Fix: checar `face.normal.z` e reverter face ou usar valor negativo.
- **Unidades**: SketchUp Ruby API usa inches internamente. Converter cm→inches ou usar `"100cm".to_l`.
- **start_operation**: SEMPRE wrappear modificações em `model.start_operation("Nome", true)` / `model.commit_operation` pra undo funcionar.
- **NotebookLM**: notebook "SketchUp Ruby API" com ~30 fontes — consultar antes de gerar código Ruby.
