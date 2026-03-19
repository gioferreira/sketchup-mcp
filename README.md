# SketchUp MCP

MCP server para controlar SketchUp via Claude Code. Permite modelagem 3D assistida por IA através do Model Context Protocol.

## Arquitetura

Duas partes independentes:

1. **Extensão Ruby** (`su_mcp/`) — roda dentro do SketchUp, abre TCP server em `localhost:9876`
2. **Python MCP server** (`src/`) — conecta no TCP e expõe tools via FastMCP (TODO)

## Status

- [x] Extensão Ruby — TCP skeleton + tools básicas
- [ ] Python MCP server (FastMCP)
- [ ] Testes com SketchUp 2024

## Tools disponíveis

| Tool | Descrição |
|------|-----------|
| `get_scene_info` | Informações do modelo ativo |
| `get_selection` | Entidades selecionadas |
| `create_component` | Criar geometria (box) |
| `delete_component` | Deletar entidade por ID |
| `transform_component` | Mover/rotacionar/escalar |
| `set_material` | Aplicar cor/material |
| `export_scene` | Exportar como PNG/JPG/SKP |
| `eval_ruby` | Executar Ruby arbitrário no SketchUp |

## Créditos

Extensão Ruby baseada em [mhyrr/sketchup-mcp](https://github.com/mhyrr/sketchup-mcp) (MIT). Reescrita para correção e clareza.
