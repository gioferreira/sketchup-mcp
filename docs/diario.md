# Diário — SketchUp MCP

## Sessão 1 — 2026-03-18

**Foco:** Pesquisa de viabilidade + setup inicial

### O que foi feito
- Pesquisa de MCPs existentes: mhyrr/sketchup-mcp (194★), darwin/supex (15★, SU2026 only), tarkiin (1★)
- Comparação com Blender MCP (10.475★) — muito mais maduro
- Auditoria de segurança do mhyrr/sketchup-mcp: LIMPO
- Decisão: repo próprio (não fork) com crédito ao mhyrr — `gioferreira/sketchup-mcp`
- Ruby TCP skeleton reescrito: ~280 linhas limpas (vs ~1860 originais)
  - Adicionado undo support (start_operation/commit_operation)
  - Removidas tools de woodworking quebradas
- Extensão instalada no SketchUp 2024 Mac
- Testes: ping OK, get_scene_info OK, eval_ruby OK
- Demo: living room criado remotamente (sofá, mesa, poltrona, estante, luminária, quadro)
- Bug encontrado: pushpull vai pro subsolo quando normal aponta pra baixo — corrigido via translate
- NotebookLM: notebook "SketchUp Ruby API" criado com ~30 fontes da documentação oficial
- Lista de sources salva em ~/Desktop/sketchup-ruby-api-sources.md

### Decisões
- Python MCP server será FastMCP (mesmo padrão do CFO server), não o Python do mhyrr
- Workflow: AutoCAD (PC) → DWG → SketchUp (Mac) → Claude via MCP
- 3D Warehouse: download manual + import via Ruby API (sem API pública)

### Próximos passos
- Fase 1: construir Python MCP server com FastMCP
