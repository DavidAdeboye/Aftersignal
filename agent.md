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

### 2.1 Setup & Logline
Two salvagers sent to strip a dead research station for parts uncover a twelve-year-old cover-up, a crew that didn't just disappear — they were *replaced*, one by one — and a thing under the ice that has been quietly rehearsing how to be human. By the time they realize the moon isn't the anomaly, it's the *containment*, they have to decide whether to finish what the crew started, undo it, or become the next entry in the log.

### 2.2 Narrative Structure (Act Breakdown)
The game's story is told through divergent environmental storytelling (audio logs, text files, and physical evidence) split asymmetrically between the two players.

* **Act 1 — Arrival (Landing Bay & Habitation Wing):** Players land and get separated by a shuttle system glitch. 
  * *Twist Seed:* Player A finds a crew roster listing twelve names and photos. Player B, exploring mess quarters, finds personal quarters/effects for only eleven people. One scientist's presence was completely erased or never existed.
* **Act 2 — Research Labs:** Introduces early anomaly testing.
  * *Story Beats:* Audio logs reveal the anomaly responds to human stimuli. Dr. Osei Farrow becomes obsessed. A whistleblower, Callum Bray, tries to warn corporate and vanishes.
  * *Twist Seed:* The glyph code players use to communicate sketch messages was found already carved into ice core samples predating the station.
* **Act 3 — Reactor & Power Wing:** Power rerouting issues.
  * *Story Beats:* Logs show the station automatically restored power to the excavation site whenever the crew tried to cut it. Black-box flight recorder fragments suggest a deliberate power surge was fired from the command deck the night of the blackout. First threat encountered: a corrupted maintenance drone patrolling the corridors.
* **Act 4 — Deep Excavation Site:** Signal static-heavy crystal tunnels.
  * *Major Reveal:* The twelfth crew member was never a real human, but a construct created by the anomaly modeled from the other crew members' behavior to walk among them.
  * *The Big Twist:* The reconstructed black-box log reveals Dr. Farrow initiated the power surge as a mercy-kill attempt to destroy the construct, Stranding the crew.
* **Act 5 — The Core (Finale):** Players physically reunite.
  * *The Construct:* Encounter the entity directly, speaking in a stitched composite of the crew's voices.
  * *Final Climactic Battle:* Wave-based co-op defense against corrupted drones while executing the dialog/puzzle to choose the ending (Awaken / Seal / Communicate).
* **Epilogue Wing — Aftersignal (New):** A short post-credits sequence showing the consequences of the ending selected in Act 5.

### 2.3 Key Characters
* **Dr. Osei Farrow:** Lead researcher, obsessive, sympathetic; initiator of the black-box blackout.
* **Callum Bray:** Whistleblower researcher, first to be absorbed by the anomaly.
* **The Construct ("Twelve"):** The composite entity born from the anomaly, speaking with combined crew voices.

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

The station is divided into **wings**, each a self-contained puzzle sequence with its own aesthetic and story chapter.

1. **Landing Bay & Habitation Wing** (Act 1 Tutorial) — Learn movement, controller inputs, radio communication, and basic puzzle-sharing. Sets up the eleven-vs-twelve crew discrepancy.
2. **Research Labs** (Act 2) — Introduces the core glyph/symbol system and first simultaneous-action puzzles. Logs detail initial anomaly response.
3. **Reactor & Power Wing** (Act 3) — Cross-wing environmental sync puzzles. Introduces the first corrupted maintenance drone patrol (utility-based combat).
4. **Deep Excavation Site** (Act 4) — Dense crystal growths; radio signal degradation is central. Reconstruct the flight black-box showing Dr. Farrow's blackout trigger.
5. **The Core** (Act 5 Finale) — Players physically reunite to face the entity. Features a co-op puzzle-under-pressure boss climax defending the Core from drone waves while deciding the ending.
6. **Aftersignal** (Epilogue) — A short epilogue showing the distinct consequences of the chosen Act 5 ending.

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
- **6 wings total (Acts 1-5 + Epilogue).**
- **Utility-based combat systems only.** No traditional gunplay or power-fantasy weapons. Players defend themselves using repurposed salvager tools (welding torch, signal disruptor) and coordinate via scanner information.
- **No character customization** — players are simple, functional character models.
- **Reuse assets aggressively.** A consistent, smaller asset library beats a huge, inconsistent one.

---

## 10. Milestone Roadmap (Loose)

| Phase | Goal |
|---|---|
| 0 | Project setup, networking & radio/proximity chat basics (Completed) |
| 1 | Wing 1 (Landing Bay) fully playable with keypad, pressure plates, locked doors, and consoles (Completed) |
| 2 | Drone AI pathfinding & welding torch/disruptor combat tools prototype |
| 3 | Wing 2 (Research Labs) puzzles, terminals, and glyph pad drawings |
| 4 | Wing 3 (Reactor Wing) sync mechanics and drone combat integration |
| 5 | Wing 4 (Excavation) signal jammer zones and flight recorder puzzle |
| 6 | Wing 5 (The Core) physical reunion, waves climax, and ending dialogs |
| 7 | Epilogue Wing (Aftersignal) & final polish pass |

---

## 11. Open Questions / Things to Decide Later

- Final title (Aftersignal is a placeholder)
- Whether the "sketch tool" for glyph puzzles is worth the dev time, or whether a simpler symbol-matching UI achieves the same goal for less effort
- Whether voice chat is built-in or the game just assumes players use Discord/a call alongside it (building your own voice chat is a real technical undertaking — worth deciding early whether that's in scope)
- Exact ending branches — revisit once the middle of the game has a defined tone
