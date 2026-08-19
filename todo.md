# Act 1 / Wing 1 Completion Checklist

This checklist defines the work required before Act 1 can be considered complete and player-ready.

## 1. Authoritative Wing 1 Scene

- [x] Choose `landing_bay.scn` as the authoritative Wing 1 scene.
- [x] Update the menu to load `landing_bay.scn` for Host, Join, and direct game entry.
- [ ] Remove duplicate, obsolete, and temporary Wing 1 scene files after the merge.
- [ ] Confirm the scene launched from the main menu contains all intended Act 1 content.

## 2. Act 1 Progression

Implement and test a clear, stateful sequence:

- [ ] Player A reads the 12-person crew roster.
- [ ] Player B inspects the missing Quarters 12 gap.
- [ ] Players investigate the habitation and Dr. Farrow logs.
- [ ] Players solve the storage keypad puzzle.
- [ ] Players solve the pressure-plate puzzle.
- [ ] Players investigate the lab evidence required for the Act 1 reveal.
- [ ] Players reach the Research Labs airlock.
- [ ] Objectives advance only after the required interaction or puzzle is completed.
- [ ] Objective state remains consistent for both players.

## 3. Act 1 Ending

- [ ] Keep the Research Labs airlock locked until Act 1 requirements are complete.
- [ ] Add a clear Act 1 completion state before changing scenes.
- [ ] Create the Research Labs target scene before enabling the transition, or use a temporary Act 1 completion screen.
- [ ] Verify the transition works for both connected players.
- [ ] Handle a missing target scene with a visible, player-facing error rather than a silent failure.

## 4. Two-Player Asymmetry

- [ ] Restrict the roster clue to Player A's intended access.
- [ ] Restrict the missing-room clue to Player B's intended access.
- [ ] Ensure each player has information the other needs.
- [ ] Ensure the important clues cannot all be collected by one player.
- [ ] Verify the role restrictions in a two-client session.

## 5. Chat and Radio

- [ ] Allow radio messages when players are separated beyond proximity-chat range.
- [ ] Degrade or garble radio messages based on distance and jammer zones instead of preventing chat entirely.
- [ ] Show clear signal states: strong, weak, and static.
- [ ] Add visible and/or audio feedback when entering a jammer zone.
- [ ] Confirm messages are delivered to the correct partner on both clients.
- [ ] Verify code-sharing remains possible under intended signal conditions.

## 6. Multiplayer Verification

Run a complete two-client test for every shared mechanic:

- [ ] Player spawning and role assignment.
- [ ] Roster interaction.
- [ ] Missing Quarters 12 interaction.
- [ ] Log and evidence interactions.
- [ ] Code relay and keypad entry.
- [ ] Door opening on both peers.
- [ ] Pressure plates and door re-locking.
- [ ] Signal jammer behavior.
- [ ] Glyph drawing relay and clear action.
- [ ] Player disconnect and rejoin.
- [ ] Save/load behavior for permanent puzzle progress.
- [ ] Airlock completion and scene transition.

## 7. Persistence

- [ ] Confirm a solved keypad door remains open after restarting the game.
- [ ] Confirm pressure-plate doors do not persist open.
- [ ] Add a clear Continue/New Game flow, or make reset behavior explicit and reliable.
- [ ] Test stale and partially completed save data.
- [ ] Verify saved state does not break after scene changes.

## 8. Set and Presentation Pass

- [ ] Align room pieces, doors, props, and collision.
- [ ] Make the landing bay, habitation area, storage area, lab approach, and airlock read as one coherent wing.
- [ ] Add clear visual cues around the roster, Quarters 12 gap, keypad, pressure plates, and airlock.
- [ ] Remove distracting placeholder or out-of-scope content from Act 1.
- [ ] Add ambient station audio.
- [ ] Add radio static and interaction feedback audio.
- [ ] Add visual feedback for puzzle state changes.

## 9. Act 1 Scope Review

- [ ] Decide whether drones and salvager tools belong in Act 1 or should move to Act 3.
- [ ] If retained, give them a clear tutorial purpose.
- [ ] Ensure combat/tool systems do not distract from the Act 1 mystery and communication loop.
- [ ] Keep Research Labs and Reactor implementation work tracked separately from this checklist.

## 10. Verified Milestone

- [ ] Remove temporary files and resolve duplicate scene ownership.
- [ ] Review and commit all Act 1 changes as one coherent milestone.
- [ ] Run the full two-player walkthrough from the main menu to the Act 1 ending.
- [ ] Record the exact successful route and any remaining known issues.

## Definition of Complete

Act 1 is complete when two players can start from the main menu, receive different necessary information, communicate, solve the required puzzles in order, unlock and use the airlock, receive an Act 1 completion state, and restart without the flow breaking.
