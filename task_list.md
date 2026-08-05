# Aftersignal - Complete Development Roadmap & Task List

This document outlines all remaining steps, scenes, and mechanics needed to build the full scope of the game (Acts 1–5, Epilogue, and utility-based combat).

---

## 1. Core Systems & Combat Prototyping
- [x] **Basic Drone AI & State Machine (`drone.gd`):**
  - [x] Patrol path following (using Path3D / NavMesh).
  - [x] Raycast-based player detection (360-degree vision checks).
  - [x] Chase mode: moves toward the detected player.
  - [x] Disabling logic: turns off, resets, and restarts patrol upon stun.
- [x] **Salvager Combat Tools:**
  - [x] **Welding Torch:** Short-range interaction that disables drones on contact.
  - [x] **Signal Disruptor:** Ranged stun weapon with limited battery charges.
  - [x] **Scanner Attachment:** Scanner device allowing Player A to view drone routes/weaknesses and call them out to Player B.
- [x] **Player KO Fail-State:**
  - [x] Add damage/hit detection to player.
  - [x] Knockout sequence: screen fades black, player is teleported back to the wing's checkpoint, and patrolling drones reset.

---

## 2. Act 1: Landing Bay & Habitation Wing (Polish & Story Placement)
- [x] **Plant Act 1 Twist Seeds:**
  - [x] **Player A quarters:** Add a physical crew roster showing photos and names of all 12 crew members.
  - [x] **Player B quarters (Mess Hall):** Modify the layout so only 11 personal quarters exist, leaving a blank gap where the 12th room should be.
- [x] Wire up the initial dialog and environmental logs introducing Dr. Farrow's early research.

---

## 3. Act 2: Research Labs (Scene & Puzzles)
- [ ] **Scene Setup (`02_research_labs`):**
  - [ ] Lay out Lab rooms, separation walls, and windows.
- [ ] **Glyph Puzzle Mechanics:**
  - [ ] Create glyph matching console locks where players must paint matching symbols onto the drawing pad to unlock research vaults.
- [ ] **Story Logs:**
  - [ ] Add Dr. Farrow's early personal logs expressing her obsession with the anomaly.
  - [ ] Add Callum Bray's logs warning corporate before his sudden disappearance.
  - [ ] Add a terminal log detailing the discovery of pre-existing carved glyphs in the ice.

---

## 4. Act 3: Reactor & Power Wing (Combat Introduction)
- [ ] **Scene Setup (`03_reactor`):**
  - [ ] Build reactor core chambers, battery rooms, and maintenance corridors.
- [ ] **Environmental Sync Puzzles:**
  - [ ] Implement power router sync: Player A flips switches to route voltage, which opens vents or powers elevator platforms for Player B.
- [ ] **Drone Patrols Deployment:**
  - [ ] Place basic maintenance drones patrolling reactor loops.
  - [ ] Place the Welding Torch pickup near the entry lock.
- [ ] **Story Logs:**
  - [ ] Add logs documenting unexplained power feedback loops from the excavation site.
  - [ ] Plant flight recorder black-box fragment A (Player A) and fragment B (Player B).

---

## 5. Act 4: Deep Excavation Site (Interference & Twist Climax)
- [ ] **Scene Setup (`04_excavation`):**
  - [ ] Build ice-cave tunnels overgrown with glowing amber crystal clusters.
- [ ] **Signal Static Mechanics:**
  - [ ] Deploy dense signal jammers forcing severe radio static, requiring players to visually match signs or navigate back to relay antennas to communicate.
- [ ] **Flight Recorder Puzzle:**
  - [ ] Create a terminal where both players must insert their black-box fragments simultaneously, prompting a joint audio decoding puzzle to reveal Dr. Farrow's mercy-kill blackout attempt.
- [ ] **Fused Drone Patrols:**
  - [ ] Deploy fast, crystal-fused drones requiring coordination (Player A scans path, Player B uses signal disruptor to stun).

---

## 6. Act 5: The Core (Reunion & Dialogue Boss Climax)
- [ ] **Scene Setup (`05_core`):**
  - [ ] Build the crystal heart chamber at the moon's core.
- [ ] **Dialogue Construct Interaction:**
  - [ ] Set up the meeting with "Twelve" (the construct).
  - [ ] Implement the branching conversation utilizing a stitched voice composite of all crew members.
- [ ] **Climax Wave Defense Climax:**
  - [ ] Co-op puzzle-under-pressure: Player A works terminal overrides/dialogue paths to finalize the ending choice, while Player B uses disruptors to fight off converging waves of drones.
- [ ] **Ending Choices:**
  - [ ] Implement the branching paths: **Awaken** (power up core), **Seal** (trigger self-destruct/collapse), or **Communicate** (integrate with the entity).

---

## 7. Epilogue Wing: Aftersignal (Outcomes)
- [ ] **Scene Setup (`06_aftersignal`):**
  - [ ] Create a short, atmospheric ending sequence (rescue shuttle arriving, static feedback broadcast, or silent separation scene) matching each of the three ending outcomes.
- [ ] Create end-credits roll and return-to-menu triggers.
