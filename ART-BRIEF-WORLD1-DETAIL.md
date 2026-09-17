# Townville World 1 — Roteiro de Arte Pixel-a-Pixel (32×24 tiles, 48px/tile)

Referência: Stardew Valley farm interior — grama variada, terra batida com
gradiente de desgaste, clutter orgânico, sombras suaves ancoradas, cercas com
postes de canto, sinalização em cruzamentos.

## 1. Base física

- Grid lógico: 32 colunas × 24 linhas = 1536×1152px em jogo (tile 48px).
- Arte nativa: tiles 16px (upscale ×3 sem filtro, nearest-neighbor).
- Vértices de terreno: (33×25) — cada tile lê 4 cantos (NW/NE/SW/SE), Wang
  autotiling. Já implementado (`path_mask` → grid de vértices).

## 2. Terreno — o que falta (Fase 2)

Tileset atual (`tileset-grass-dirt-v3.png`) tem só 1 variante de grama e 1 de
terra. Falta variedade de sub-textura dentro de cada material:

- **Grama**: 2 variantes extras de tile "grama pura" (upper-only) com manchas
  mais escuras/claras intercaladas aleatoriamente nas áreas grandes (cols
  0-3, 29-31 nas linhas 0-23; e bolsões internos entre prédios) — evita
  repetição óptica visível a partir de ~6 tiles adjacentes iguais.
- **Terra**: 1 variante "terra pisada" com marcas de trilha mais claras no
  centro do caminho principal (linha 8-9, colunas 4-27) vs. terra "crua" nas
  bordas do caminho (transição de 1 tile).
- **Decalques de solo** (map objects, não tileset): poças de lama pequenas
  perto do poço (col 8, row 9-10) e da fonte (col 16, row 9-10); terra
  revolvida/pegadas perto do jardim (col 25-27, row 12-14).

## 3. Clutter de grama (map objects, ~48-64px cada, alinhados ao tile)

Distribuição alvo: ~1 elemento a cada 3-4 tiles de grama aberta, nunca sobre
caminho/colisão. Variedade de 6 tipos rotacionados/species-mixed:

| Tipo | Contagem alvo | Zona |
|---|---|---|
| Tufo de grama alta (2 variantes) | 14 | espalhado nas bordas verdes (cols 0-3, 29-31, rows 0-4, 20-23) |
| Pedrinha solta (1-2px sombra) | 8 | perto de `stone` existente e cantos do mapa |
| Flor silvestre pequena (branca/roxa, distinta das já existentes vermelha/amarela) | 10 | dispersa nas 4 quadrantes de grama |
| Toco de árvore | 3 | perto das árvores existentes (col 30 rows 18-22) |
| Cogumelo pequeno (2-3 em cluster) | 4 | sombra das árvores |
| Graveto/folhas secas no chão | 6 | aleatório em grama |

## 4. Clutter de caminho (sobre terra, non-blocking, z acima do tilemap)

| Tipo | Contagem | Zona |
|---|---|---|
| Rodada de carroça (2 trilhas paralelas, decal) | 1 par | caminho principal linha 8 |
| Pegadas de bota (decal, 3-4 por trilho) | 2 grupos | aproximação da clínica e do celeiro |
| Poça de lama pequena | 2 | perto do poço e da fonte |
| Monte de feno / fardo | 2 | perto do celeiro (Joe) e do estábulo (Chester) |
| Caixote de madeira empilhado | 2 | perto do galinheiro e do celeiro |
| Barril | 1 | perto do celeiro |
| Placa de sinalização (madeira, seta) | 1 | cruzamento central (col 15-16, row 12) |
| Cerca — postes de canto/complemento | 4 postes extras | fechar visualmente o curral do Billy (já tem 2 painéis) |

## 5. Sombras ancoradas (crítico para "grounding")

Todo elemento vertical (prédio, NPC, árvore, poste, fonte) precisa de uma
sombra elíptica semi-transparente (~35% opacidade, preto/azul-escuro),
deslocada 4-6px para sudeste, desenhada ANTES do sprite (z-index abaixo).
Sem isso os elementos "flutuam" sobre o terreno — esse é o maior gap visual
atual comparado a Stardew Valley. Implementação: blob elíptico gerado 1x via
PixelLab (32×16px, transparente) e reutilizado com escala por elemento
(prédios 2x maior, NPCs 1x, props pequenos 0.6x).

## 6. Bordas do mapa

Atualmente grama lisa até a borda do viewport. Adicionar uma faixa de
"moldura" com 1-2 tiles de arbustos/vegetação densa (já existe `bush`, faltam
mais 6-8 unidades) ao longo das 4 bordas para evitar sensação de "mapa
cortado no vazio" — reforça a ideia de fazenda cercada por mata.

## 7. Execução (ordem de aplicação)

1. Gerar clutter set via PixelLab `/map-objects` com `background_image` =
   crop do terreno atual (style matching automático).
2. Gerar shadow-blob via `/create-image-pixflux` (transparente, radial).
3. Definir posições fixas determinísticas em `world_data.gd` (nunca random)
   — cada item tem tile exato, sem overlap com colisão existente.
4. Renderizar em `map_renderer.gd`: camada de sombras (z=2) → tilemap terreno
   (z=-10, já existe) → clutter de grama/caminho (z=4) → prédios/NPCs/props
   (z=5-16, já existe).
5. Rodar os 22 testes headless (colisão não muda).
6. Recapturar screenshot completo + zoom de jogo para validação visual.
