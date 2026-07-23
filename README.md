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

Twelve years ago, the Halcyon Institute built a research outpost on Kessler-9, drawn there by an anomalous signature buried beneath the ice. Six years in, all contact was lost — no distress call, no wreckage. You and your partner are contracted salvagers sent to recover data and equipment before a rival crew arrives. You didn't sign up for a mystery. That changes fast.

The story is told entirely through environmental storytelling — audio logs, terminal entries, physical evidence, and environmental change — with no cutscenes or forced dialogue. Each player usually finds different fragments of the same story, mirroring the game's core communication mechanic at a narrative level.

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

The station is divided into five self-contained wings, each with its own aesthetic, story chapter, and puzzle mechanics:

1. **Landing Bay & Habitation Wing** *(tutorial)* — movement, radio, basic puzzle-sharing
2. **Research Labs** — glyph/symbol system, first simultaneous-action puzzle
3. **Reactor & Power Wing** — cross-wing environmental sync puzzles
4. **Deep Excavation Site** — radio interference mechanic, story accelerates
5. **The Core** *(finale)* — players reunite in person for the ending choice

Wings 4–5 are stretch goals; the game is considered complete and shippable even if it ends after Wing 3.

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
- 5 wings max, unless earlier ones finish ahead of schedule
- No combat, ever
- No character customization
- Reuse a small, consistent asset library rather than a large inconsistent one

## Status

🚧 Early development — project scaffolded, tutorial/basics in progress.

## License

TBD
