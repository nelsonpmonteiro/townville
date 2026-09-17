# Townville — Godot 4 POC com PixelLab

## Estado atual

- Mundo **32×24 tiles** (48px/tile) = 1536×1152px
- Mapa e colisão de uma única fonte
- **8 NPCs** com sprites PixelLab: Mae, Chester, Joe, Vera, Lily, Rose, Billy, Old Mac
- **6 prédios** com sprites PixelLab: Galinheiros, Estábulo, Celeiro, Clínica, Jardim
- **Tilesets Wang** PixelLab importados (grama↔terra 16px)
- Câmera suave com limites do mundo
- HUD com FPS, instruções e prompts de interação
- Movimento WASD/setas, interação com E/Espaço
- 22 testes passando, screenshot gerado

## Assets PixelLab

| Tipo | Origem |
|------|--------|
| NPCs idle | `artifacts/pixellab-world1-idle/*.png` |
| Prédios | `artifacts/pixellab-world1-buildings-idle/*.png` |
| Terreno | `artifacts/pixellab-terrain-v2-grass-dirt/tileset.png` |
| Água | `artifacts/pixellab-terrain-v2-water-grass/tileset.png` |
| Mapa completo | `artifacts/pixellab-world1-map-v2/` |

## Executar

```bash
GODOT="/Users/nelsonmonteiro/Applications/Godot.app/Contents/MacOS/Godot"
cd /Users/nelsonmonteiro/Documents/Townville-Godot-POC/godot
"$GODOT" --editor --path "$PWD"   # importa os PNGs na primeira execução
"$GODOT" --path "$PWD"
```

Controles: setas ou WASD para andar; `E` ou `Espaço` perto da Dra. Vera para conversar.

## Testes e verificação

```bash
"$GODOT" --headless --path "$PWD" --script res://tests/test_runner.gd
"$GODOT" --headless --path "$PWD" --quit-after 10
"$GODOT" --path "$PWD" -- --capture
```

O runner valida dimensões, matriz única, spawn e caminho, bordas, tile bloqueado, limites da câmera, ocupação/interação do NPC, movimento e instanciação da cena. Evidência TDD fica em `tests/red*.log` e `tests/green*.log`. A captura é salva em `artifacts/townville-godot-poc.png`.

## Estrutura

- `scripts/world_data.gd`: única fonte 32×24 para desenho navegável e colisão.
- `scripts/map_renderer.gd`: faz o fundo compacto a partir dessa matriz.
- `scripts/player.gd`: `AnimatedSprite2D` persistente com os sprites atuais e câmera limitada.
- `scripts/player_movement.gd`: movimento testável e bloqueio por tile.
- `scripts/game.gd`: cena, NPC, prompt, diálogo, HUD e captura.
- `scenes/main.tscn`: cena principal.
- `tests/test_runner.gd`: testes headless sem add-ons.
