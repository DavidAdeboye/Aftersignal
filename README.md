# Aftersignal

*Working title — subject to change*

A small-scale, atmospheric 3D co-op puzzle-exploration game built in Godot 4. Two players are dropped into a derelict research outpost on a distant moon, separated across different sections of the station. They explore, share information over radio, and solve environmental puzzles together to uncover what happened to the crew — and to something buried deep beneath the facility.

Built as part of [Hack Club's Stardance](https://stardance.hackclub.com).

---

## Overview

| | |
|---|---|
| **Genre** | Co-op puzzle / exploration / mystery |
| **Perspective** | First-person |
| **Players** | 2 (asymmetric cooperation) |
| **Tone** | Quiet, mysterious, melancholic — curiosity over fear |
| **Engine** | Godot 4 (GDScript) |
| **Inspiration** | *We Were Here* series, *Subnautica*, *Firewatch* |

## Premise

Two salvagers sent to strip a dead research station for parts uncover a twelve-year-old cover-up, a crew that didn't just disappear — they were *replaced*, one by one — and a thing under the ice that has been quietly rehearsing how to be human. By the time they realize the moon isn't the anomaly, it's the *containment*, they have to decide whether to finish what the crew started, undo it, or become the next entry in the log.

The story is told entirely through divergent environmental storytelling — audio logs, terminal entries, physical evidence, and environmental change — with no cutscenes or forced dialogue. Each player usually finds different fragments of the same story, reinforcing that the timeline can only be pieced together by players comparing notes.

## Core Loop

1. Explore your section of the station alone.
2. Discover a fragment of information (a code, a symbol, a story beat, an item).
3. Communicate with your partner via proximity or radio to compare notes.
4. Solve a puzzle that requires both players' information or actions.
5. Unlock progress — new areas open for both players.

## Communication System

The mechanic everything else is built around:

- **Proximity chat** — normal voice/text when players are near each other in-world.
- **Radio relay** — limited-range, interference-prone comms used when separated (most of the game). Certain rooms are built to jam signal, forcing players to relocate.
- **Shared glyphs** — a simple sketch tool lets one player draw a shape that appears on the other's handheld device, for puzzles too complex to describe verbally.

## World Structure

The station is divided into six self-contained wings, each with its own aesthetic, story chapter, and puzzle mechanics:

1. **Landing Bay & Habitation Wing** *(tutorial)* — movement, radio, basic puzzle-sharing, setup of the eleven-vs-twelve crew roster anomaly.
2. **Research Labs** — glyph/symbol system, early testing logs, first simultaneous-action puzzles.
3. **Reactor & Power Wing** — cross-wing environmental sync puzzles, introduction of corrupted drone hazard.
4. **Deep Excavation Site** — radio interference mechanic, black-box flight recorder reconstruction puzzle.
5. **The Core** *(finale)* — players physically reunite, concluding with a wave-based defense climax and choice of ending.
6. **Aftersignal** *(epilogue)* — a brief post-credits epilogue scene playing out the consequences of the ending.

## Tech Stack

- **Engine:** Godot 4
- **Networking:** Godot's built-in `MultiplayerAPI` / `ENetMultiplayerPeer` (peer-to-peer / simple relay, 2 players only)
- **Scripting:** GDScript

## Project Structure

```
Aftersignal/
  scenes/
    wings/
      01_landing_bay/
      02_research_labs/
      03_reactor/
      04_excavation/
      05_core/
    shared/       # player controller, UI, radio system
  scripts/
  assets/
    models/
    materials/
    audio/
  addons/
```

## Scope Guardrails

- Exactly 2 players, always — no matchmaking or lobbies beyond a room code/invite link
- 6 wings total (Acts 1-5 + Epilogue)
- Utility-based combat only — no traditional guns; players use repurposed tools (welding torch, disruptor) and coordinate weak-point scanning
- No character customization
- Reuse a small, consistent asset library rather than a large inconsistent one

## Status

🚧 Early development — networking, proximity/radio chat, and Wing 1's first code-sharing puzzle are playable end to end. Persistence and further wing content next.

## License

TBD

