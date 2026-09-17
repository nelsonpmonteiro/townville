# Townville — Godot 4 POC

POC jogável isolada do app Expo. O World 1 usa uma alternativa visual coerente e compacta construída diretamente da mesma matriz 32×24 usada pela colisão: 48 px por tile, total exato de **1536×1152 px**. Isso elimina o antigo desacordo com os 12 chunks de 480 px (1920×1440).

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
