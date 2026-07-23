# Aftersignal
### Game Design Document (Working Title)

---

## 1. High Concept

**Aftersignal** is a small-scale, atmospheric 3D co-op puzzle-exploration game. Two players are dropped into a derelict research outpost on a distant moon, separated across different sections of the station. They must explore, share information through proximity/radio communication, and solve environmental puzzles together to uncover what happened to the crew — and to something buried deep beneath the facility.

**Genre:** Co-op puzzle / exploration / mystery
**Perspective:** First-person
**Players:** 2 (asymmetric cooperation — you rarely stand in the same room)
**Tone:** Quiet, mysterious, melancholic — not horror. Curiosity over fear.
**Inspiration:** *We Were Here* series (communication-driven puzzle structure), *Subnautica* (isolation and environmental storytelling), *Firewatch* (tone and pacing)

---

## 2. Premise / Story

### 2.1 Setup

Twelve years ago, the *Halcyon Institute* established a remote research outpost on Moon designation **Kessler-9**, drawn there by an anomalous energy signature buried beneath the ice. The station studied the signature for six years before all contact was lost. No distress call. No wreckage. The station simply went silent mid-transmission.

You and your partner are contracted salvagers — not scientists, not soldiers — sent to recover data and equipment before a rival company's crew arrives. You didn't sign up for a mystery. You signed up for a paycheck. That changes fast.

### 2.2 The Hook

Within minutes of landing, your shuttle's systems glitch and the two of you are separated — different airlocks, different wings of the station. Communication is spotty at best. As you explore, you start finding personal logs, terminal entries, and physical evidence left behind by the twelve-person research crew, painting a picture of a team that made an incredible discovery... and then made increasingly disturbing choices in response to it.

The "signature" the station was built to study isn't a mineral or an energy source. It's the moon reacting to something ancient buried at its core — and the deeper the crew dug, the more the moon began to respond back.

### 2.3 Structure

The story is told entirely through **environmental storytelling** — no cutscenes, no forced dialogue. Players piece together the timeline from:
- Audio logs (personal recordings from crew members)
- Terminal text logs and emails
- Physical evidence (arranged rooms, abandoned personal effects, handwritten notes)
- Environmental changes (crystal growth patterns that map to the station's timeline — areas closer to "the end" are more overgrown)

Each player often finds *different* fragments of the same story, meaning neither player has the full picture alone — mirroring the game's core communication mechanic at a narrative level.

### 2.4 Ending (subject to change during development)

There is no combat, no "villain." The ending is a choice: players can choose to fully awaken the signature (opening the way for the moon's process to continue, for better or worse), seal it permanently, or attempt to communicate with it. Each ending recontextualizes what players read throughout the game — an intentionally ambiguous, "what did we actually just do" note to end on.

*(This is a placeholder ending structure — refine once the middle of the game is built and you know what tone actually landed.)*

---

## 3. Core Gameplay Loop

1. **Explore** your section of the station alone.
2. **Discover** a fragment of information (a code, a symbol, a story beat, an item).
3. **Communicate** with your partner via proximity/radio to compare notes.
4. **Solve** a puzzle that requires both players' information or actions.
5. **Unlock** progress — new areas open for both players.
6. Repeat, with escalating complexity and story stakes.

Sessions are designed to run **20–45 minutes** per "wing" of the station, so players can play in digestible chunks rather than committing to a long unbroken sitting (unlike a fixed 2–3 hour session structure like *We Were Here*).

---

## 4. Communication System

This is the heart of the game — the mechanic everything else is built around.

- **Proximity voice/text chat:** When players are physically near each other in-world, they can talk normally.
- **Radio relay:** When separated (which is most of the game), players communicate through handheld radios with limited range and occasional interference — static, dropouts, or garbled audio near crystal-heavy areas. This is a **gameplay mechanic**, not just flavor: certain puzzle rooms are built to interfere with radio signal, forcing players to physically relocate to find a clear signal, adding tension and pacing.
- **Shared symbols/glyphs:** Some puzzles use an in-game "language" of symbols found on terminals and walls. Since verbally describing a complex symbol is hard, later puzzles introduce a simple **sketch tool** — one player can draw a rough shape that appears on the other player's handheld device.

---

## 5. Puzzle Design Philosophy

- **Asymmetric information, not asymmetric difficulty.** Both players do meaningful things — neither is ever just "the helper."
- **No combat, no fail-states that punish harshly.** Puzzles can be retried; the game is about atmosphere and cooperation, not tension from failure.
- **Escalation, not repetition.** Early puzzles are simple code-sharing (Player A has a number, Player B has a lock). Later puzzles introduce timing (both players must act simultaneously), spatial reasoning (describing a 3D layout to someone who can't see it), and multi-step logic that spans multiple rooms.

### Example puzzle types
| Type | Example |
|---|---|
| Code-sharing | Player A finds a date on a photograph; Player B needs it to open a keypad-locked door |
| Simultaneous action | Two pressure plates in different rooms must be held down at the same time to open a shared door |
| Spatial description | Player A sees a control panel with unlabeled switches; Player B has the instruction manual and must describe switch positions verbally |
| Environmental sync | Player A redirects power in the reactor wing; this changes what's visible/accessible in Player B's wing (a hidden door lights up, a vent opens) |
| Late-game glyph puzzle | Players sketch symbols to each other to reconstruct a research team's discovery log |

---

## 6. World / Level Structure

The station is divided into **wings**, each a self-contained puzzle sequence with its own aesthetic and story chapter. This structure keeps development scoped — you build and polish one wing at a time rather than one sprawling open space.

1. **Landing Bay & Habitation Wing** (Tutorial) — learn movement, radio communication, and basic puzzle-sharing. Introduces the crew through personal quarters.
2. **Research Labs** — the crew's early discoveries. Introduces the glyph/symbol system. First simultaneous-action puzzle.
3. **Reactor & Power Wing** — introduces cross-wing environmental sync puzzles (what one player does changes the other's space).
4. **Deep Excavation Site** — the crystal growth is dense here; radio interference mechanic is central. Story reveals accelerate.
5. **The Core** (Finale) — smaller, more intimate space where both players are finally reunited in person for the ending choice.

Each wing should be buildable and playable **independently**, which is ideal for solo development — you can finish and polish Wing 1 completely before starting Wing 2, giving you constant shippable milestones.

---

## 7. Art Direction

**Palette:** Cold blues and grays (station interiors, ice, metal) contrasted with warm amber/gold crystal glow — the crystal light is the game's signature visual motif and gets more prominent as players progress deeper into the story.

**Style:** Stylized low-poly / mid-poly, not photorealistic. Lighting and atmosphere carry the visual quality far more than geometric detail.

**Key visual techniques (all solo-dev friendly):**
- Volumetric fog / light shafts through cracked windows and vents
- Emissive materials on crystal growths (cheap to implement, huge atmospheric payoff)
- Limited, reused texture/material set applied consistently (a handful of metal, concrete, ice, and crystal materials reused across all wings)
- Sound design carrying as much weight as visuals — ambient station hum, distant groaning ice, radio static

**Asset strategy:** Build the game around free/CC0 sci-fi station and ice-cave asset packs (Kenney.nl, Quaternius, itch.io marketplaces) as a base, then hand-modify key story-critical objects (terminals, photographs, specific puzzle objects) yourself for uniqueness.

---

## 8. Technical Plan

**Engine:** Godot 4 (free, strong 3D support, built-in high-level multiplayer API, GDScript is beginner-friendly)

**Core systems to build, roughly in order of implementation:**
1. First-person character controller
2. Single-player scene loading / level structure
3. Basic interaction system (pick up items, read logs, press buttons)
4. Networking — player position/rotation sync between two clients
5. Radio/proximity voice or text chat system
6. Shared puzzle state sync (a switch one player flips must update for both)
7. Save/persistence system (so progress isn't lost between sessions)
8. Polish pass: lighting, sound, UI

**Multiplayer approach:** Peer-to-peer or simple relay server for 2 players is sufficient — this is not a game that needs dedicated game servers or matchmaking infrastructure at this scale. Godot's built-in `MultiplayerAPI` and `ENetMultiplayerPeer` can handle a 2-player session without external services to start.

---

## 9. Scope Guardrails

Since this project is meant to run all summer without becoming unmanageable, some explicit limits:

- **Exactly 2 players, always.** No matchmaking, no lobbies beyond a simple room code/invite link.
- **5 wings, not more**, unless the first few are finished early and you genuinely want to expand.
- **No combat systems, ever.** Keeps scope and animation needs low.
- **No character customization** — players are simple, functional character models (or even just a floating radio/light with a nametag, if modeling humans proves too time-consuming).
- **Reuse assets aggressively.** A consistent, smaller asset library beats a huge, inconsistent one.

---

## 10. Milestone Roadmap (Loose)

| Phase | Goal | Rough Timeframe |
|---|---|---|
| 0 | Learn Godot basics (official tutorial) | Week 1 |
| 1 | Single room, walking character, basic lighting | Week 1–2 |
| 2 | Two players connected, see each other move | Week 2–3 |
| 3 | Radio/proximity chat working | Week 3–4 |
| 4 | Wing 1 (tutorial wing) fully playable start to finish | Week 4–5 |
| 5 | Persistence system (save progress between sessions) | Week 5–6 |
| 6 | Wing 2 puzzles (glyph system introduced) | Week 6–7 |
| 7 | Wing 3 (cross-wing environmental sync puzzles) | Week 7–8 |
| 8 | Polish, sound design, playtesting with a friend | Week 8–9 |

Wings 4–5 (Deep Excavation, The Core) are stretch goals — great to have if the pacing above goes smoothly, but the game is genuinely "complete and shippable" even if it ends after Wing 3, since each wing is a self-contained chapter.

---

## 11. Open Questions / Things to Decide Later

- Final title (Aftersignal is a placeholder)
- Whether the "sketch tool" for glyph puzzles is worth the dev time, or whether a simpler symbol-matching UI achieves the same goal for less effort
- Whether voice chat is built-in or the game just assumes players use Discord/a call alongside it (building your own voice chat is a real technical undertaking — worth deciding early whether that's in scope)
- Exact ending branches — revisit once the middle of the game has a defined tone
