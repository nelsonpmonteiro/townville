# TOWNVILLE MVP — STATUS REPORT
**Atualizado:** 16 Set 2026, 16:10 (enquanto você estava no banho)

## ✅ CONCLUÍDO

### Assets Instalados (Total: 75 arquivos)
- ✅ 12 chunks de mapa hi-res (512px nativos, renderizados a 480px)
- ✅ 48 assets batch2: 6 NPCs W2, 10 prédios W2, 11 cenários, 1 protagonista reference
- ✅ 13 arquivos de áudio (8 ambient + 5 SFX)
- ✅ 2 previews de mapa (w1-preview, w2-preview)

### Código Implementado
- ✅ **WorldMapRenderer.tsx** — Renderização conforme HERMES-rendering-spec.md:
  - Chunks forçados para 480×480px (não 512 nativo)
  - Event points como marcadores circulares dourados (z=10)
  - Prédios com ancoragem correta pela base (footprint)
  - Protagonista usando frontal-pose-reference.png (40×56, ancorado pelos pés)
  - Z-index correto: chunks(0) → events(10) → buildings(30) → protagonist(45)

- ✅ **worldMaps.ts** — Dados completos dos 2 mundos:
  - Matrizes de colisão 30×20 para W1 e W2
  - EventPoints com IDs e NPCs linkados
  - Buildings com footprints corretos (2×2 normal, 4×2 town-hall, 3×1 gates)
  - 7 prédios W1 (todos placeholders — assets pendentes)
  - 8 prédios W2 (6 com sprites reais, 2 placeholders)

- ✅ **audioEngine.ts** — Motor de áudio completo:
  - 9 funções de SFX geradas por código (Web Audio API)
  - Wrapper playSfx() com mute global
  - loadMuteState/setMuted para persistência

- ✅ **App.tsx, core.ts, GameHeader.tsx** — Funcionais da sessão anterior

### Git Status
- 8 commits desde o início da sessão
- Branch: main
- Working directory: limpo (sem alterações pendentes)
- Backup: App.tsx.old preservado

## 🟡 PARCIALMENTE IMPLEMENTADO

### Renderização
- ✅ Chunks renderizam hi-res
- ✅ Protagonista renderiza (pose estática frontal)
- ✅ Event points marcados
- ✅ Prédios W2 renderizam (bakery, hardware, town-hall, library, fountain OK)
- 🟡 Prédios W1 aparecem como placeholders roxos (assets pendentes)
- 🟡 Post-office, park, gates aparecem como placeholders (assets pendentes)
- ❌ NPCs no mapa não renderizam ainda (mini-sprites 48×48 pendente)

### Interação
- ❌ Event points não interativos (sem onClick/Enter)
- ❌ Diálogos NPC não implementados
- ❌ Save não conectado aos event points (isCompleted sempre false)
- ❌ Building lock state não conectado ao save

### Áudio
- ✅ Engine criado com todas as funções
- ❌ Não integrado na UI (nenhum som toca ainda)
- ❌ Música de fundo não carregada (Expo AV pendente)

## ❌ NÃO INICIADO

### Mecânicas Core
- Diálogo system (typewriter, speech bubbles)
- Input components (NumberPad, TapScene, DragToTarget)
- Feedback screens (CorrectFeedback, WrongFeedback)
- CelebrationScreen wired
- SessionSummary wired

### Animações
- Protagonista caminhada (alternância frame 1/2)
- Event point pulso (scale 0.9↔1.1 loop)
- Tooltip de aproximação
- Partículas de celebração
- Score tick-up no header

### UI/UX
- Mobile D-pad virtual
- Mute button no header (⚠️ placeholder visual existe, sem funcionalidade)
- Menu dropdown (⚙️)
- Transição W1↔W2

### Deployment
- Build de produção
- Deploy para Vercel/Netlify/GitHub Pages
- URL pública para avaliadores

## 🔴 BLOQUEADORES CONHECIDOS

### Assets Pendentes (W1)
Todos os prédios do World 1 estão como placeholders porque os assets não existem ainda:
- `building-henhouse.png` + locked
- `building-stable.png` + locked  
- `building-barn.png` + locked
- `building-coop.png` + locked
- `building-animal-clinic.png` + locked
- `building-garden.png` (decorativo, sem locked)
- `building-farm-gate-open.png` / `building-farm-gate-closed.png`

**Ação:** Quando você trouxer os PNGs, basta:
1. Copiar para `assets/images/buildings/`
2. Adicionar os requires no `BUILDING_SPRITES` em WorldMapRenderer.tsx
3. Zero alterações no código de renderização

### Assets Pendentes (W2)
- `building-post-office.png` + locked
- `building-park.png` (marco decorativo)
- `building-town-gate-open.png` / `building-town-gate-closed.png`

### Protagonista Animado
O sprite atual é estático (frontal-pose-reference.png). Para caminhada:
- Opção A: Gerar `protagonist-{down,up,left,right}-{1,2}.png` (8 PNGs)
- Opção B: Extrair frames dos GIFs existentes
- Fallback atual: usa flip horizontal para "left" (funcional mas limitado)

## 📊 PROGRESSO GERAL DO MVP

| Fase | Descrição | Status |
|------|-----------|--------|
| **P0 — Core Mecânico** | Grid 30×20, colisão, save/restore, movimento | ✅ 90% |
| **P0 — Renderização** | Chunks, prédios, protagonista, event points | 🟡 70% |
| **P1 — Interação** | Diálogos, inputs, feedback | ❌ 0% |
| **P1 — Áudio** | Engine pronto, integração pendente | 🟡 40% |
| **P2 — Animações** | 16 tipos especificados | ❌ 0% |
| **P2 — UX** | Mobile controls, transições | ❌ 0% |
| **P3 — Deploy** | Build + hosting | ❌ 0% |

**Estimativa para MVP jogável:** ~12-16h de trabalho restantes

## 🚀 PRÓXIMAS ETAPAS (PRIORIDADE)

### Curto Prazo (próximas 2-4h)
1. ✅ Instalar NPCs do W1 quando você trouxer
2. ⏳ Event point interaction (tooltip + Enter key)
3. ⏳ Diálogo básico (modal com typewriter)
4. ⏳ NumberPad input component
5. ⏳ CorrectFeedback + WrongFeedback

### Médio Prazo (4-8h)
6. CelebrationScreen wired
7. SessionSummary wired  
8. Áudio integration (sfx on tap, music loops)
9. Mobile D-pad
10. Animações básicas (pulso, tick-up, partículas)

### Longo Prazo (8-12h)
11. Transição W1↔W2
12. Polish animations
13. Production build
14. Deploy + testes mobile
15. URL pública

## 🎯 TESTE AGORA

**URL:** http://localhost:8083

**O que vai ver:**
- ✅ Mapa renderizando com chunks hi-res de alta qualidade
- ✅ Protagonista (sprite estático frontal, 40×56px)
- ✅ Event points marcados (círculos dourados)
- ✅ Prédios W2 renderizados corretamente
- ✅ Prédios W1 como placeholders roxos
- ✅ Header com vidas/score/streak/progresso
- ✅ Movimento com Arrow keys ou WASD
- ✅ Colisão funcional

**O que NÃO vai funcionar ainda:**
- ❌ Clicar em event points (não abre diálogo)
- ❌ Som (engine criado mas não integrado)
- ❌ Animações (tudo estático por enquanto)
- ❌ Mobile touch (só teclado)

## 📝 DECISÕES TÉCNICAS TOMADAS

1. **Chunks a 480px:** Forçado via StyleSheet (native é 512) — alinha com grid de tiles 30×20
2. **Protagonista estático:** Usando frontal-pose-reference até sprites de caminhada chegarem
3. **Prédios W1 placeholder:** Retângulos roxos 96×96 até assets reais
4. **Audio via código:** 9 SFX gerados por Web Audio API (sem arquivos, latência zero)
5. **Z-index fixo:** Protagonista sempre z=45 (na frente de prédios) — y-sort dinâmico fica para polish

## 🔧 COMANDOS ÚTEIS

```bash
# Dev server (já rodando em background)
npm run web

# Verificar porta
lsof -i :8083

# Recarregar bundle
# (Ctrl+R no navegador ou pressione 'r' no terminal Expo)

# Matar servidor
# Pressione Ctrl+C no terminal do Expo

# Ver logs
git log --oneline --graph --decorate

# Status
git status
```

## 📦 ESTRUTURA ATUAL

```
Townville/
├── assets/
│   ├── images/
│   │   ├── maps/           (14 PNGs: 12 chunks + 2 previews)
│   │   ├── buildings/      (20 PNGs: 10 W2 buildings × 2 states)
│   │   ├── characters/     (18 PNGs: 6 W2 NPCs × 3 expressions)
│   │   ├── scenery/        (11 PNGs decorativos)
│   │   └── protagonist/    (1 PNG reference frontal)
│   └── audio/              (13 WAVs: 8 music + 5 sfx)
├── src/
│   ├── core.ts             ✅ Save system, phase logic
│   ├── GameHeader.tsx      ✅ Header UI
│   ├── WorldMapRenderer.tsx ✅ Renderização conforme spec
│   ├── CelebrationScreen.tsx ⚠️ Criado mas não wired
│   ├── SessionSummary.tsx  ⚠️ Criado mas não wired
│   ├── data/
│   │   └── worldMaps.ts    ✅ W1+W2 collision maps, buildings, events
│   └── engine/
│       └── audioEngine.ts  ✅ 9 SFX + mute state
├── App.tsx                 ✅ Integração funcionando
└── SPECIFICATION.md        ✅ Spec consolidada

Commits: 8
Branch: main
Working dir: clean
```

---

**🎉 EM RESUMO:** A fundação está sólida! Mapa renderiza lindo, protagonista move, colisão funciona. Falta implementar as interações (diálogos, inputs, feedback) e integrar áudio. Assets W1 aguardando você trazer.

**Quando voltar, me diga:** O mapa está com a qualidade esperada agora? Ou precisa ajustar algo na renderização?
