# Aftersignal — Devlog #4

**Date:** August 4, 2026
**Focus:** Phase 4 — turning the gray-box test room into a real, playable Wing 1 with the first genuine co-op puzzle

---

## Summary

The last three sessions built the *systems* — movement, networking, proximity/radio chat. This session was about finally using them to build actual **content**: a first version of Wing 1 (the Landing Bay & Habitation Wing) that a pair of players can walk into, explore, and solve together. The headline change is that interactions are no longer console `print()` calls that only the developer can see — every log, terminal, and access panel now surfaces real text on the player's in-game HUD. That single change is what turns "a networked walking sim with a keypad" into "a co-op puzzle you can actually play," because the whole game loop depends on one player *reading* information and relaying it to the other over the radio.

---

## 1. The Core Problem: Interactions Were Invisible

Going back through the interaction code from Day 1, every interactable ended in a `print()`:

```gdscript
func interact() -> void:
    print("You found a log: 'Day 47...'")
```

That's fine for a solo dev testing in the editor with the output panel open — but a player in a running build sees *nothing*. For a game whose entire premise is "read a code, tell your partner," having no way to show that code on screen is a hard blocker for calling Wing 1 "playable."

**Fix — a proper HUD message system.** Added a `MessagePanel` (a `PanelContainer` with a centered `Label`) to the player scene's `CanvasLayer`, and a `show_message(text, duration)` method on the player controller. It displays the text, starts a `SceneTreeTimer`, and hides the panel when the timer expires — with a guard so that a newer message replacing an older one doesn't get prematurely hidden by the old message's timer:

```gdscript
_message_timer = get_tree().create_timer(duration)
var timer_ref := _message_timer
await timer_ref.timeout
if _message_timer == timer_ref:   # only hide if not superseded
    message_panel.visible = false
```

It also early-returns on non-authoritative player instances, so — exactly like the Day 3 chat bug taught us — the message only ever shows on the local player's own HUD, never the remote copy.

## 2. Rewiring the Interactables

Refactored the `Interactable` base class so `interact()` now takes the interacting player as an argument, and added a `_notify(player, text)` helper that routes text to `player.show_message()` (falling back to a print if there's no player, so editor testing still works):

```gdscript
func interact(player: Node = null) -> void:
    if message != "":
        _notify(player, message)

func _notify(player: Node, text: String) -> void:
    if player != null and player.has_method("show_message"):
        player.show_message(text)
    else:
        print(text)
```

The player controller now calls `current_interactable.interact(self)`, passing itself in. Updated all four subclasses to match:

- **`test_log.gd`** — reads a crew audio log onto the HUD (text is editable per-instance via an exported `message`)
- **`code_display.gd`** — shows a labeled access code (`STORAGE DOOR ACCESS CODE: 4471`)
- **`pickup_item.gd`** — reports what was collected, then removes itself
- **`keypad.gd`** — cleaned up, made the door lookup null-safe, and it now shows "Access granted. Door unlocked." on success

## 3. The First Real Puzzle (Code-Sharing)

This is puzzle type #1 straight from the design doc's table: *"Player A finds a code; Player B needs it to open a keypad-locked door."* All the pieces already half-existed from earlier prototyping — this session connected them into an actual designed loop:

1. One player finds the **CodeDisplay** access panel (`4471`) near the landing area.
2. A nearby **CrewLog** (Dr. Vance, Day 47) gives narrative context *and* reinforces the code diegetically — the log mentions the storage wing was locked "after the incident."
3. The other player stands at the **Keypad** by the sealed double doors, out of sight of the panel.
4. They radio the code across (using the Day 3 proximity/signal-degradation chat — stand too far apart and the digits come through as static, which is a *feature* here).
5. Correct code → `NetworkManager.unlock_door.rpc(...)` fires → the door tweens open **for both peers**, since it goes through the shared autoload RPC established on Day 3.

The unlock going through the `NetworkManager` singleton (not the local keypad node) is the same architectural lesson from the chat bug: shared state has to be driven from something that exists identically on every peer.

## 4. First Environment Pass

Dropped in a `WorldEnvironment` with:

- A dark blue-gray background and low ambient light, matching the "cold blues and grays" from the art direction doc
- Volumetric-friendly **fog** (`fog_enabled`, low density) for the atmospheric, slightly-obscured station feel the design doc keeps calling for

It's not a final art pass — still mostly kit-bashed modular pieces — but it reads as a real place now instead of a CSG gray box, and the fog does a surprising amount of atmospheric heavy lifting for basically zero effort, exactly as predicted.

**Gotcha — half the asset pack is still Godot 3.** First attempt at this pass added the pack's Science Lab room. On launch it exploded with a wall of `Can't create sub resource of type 'OccluderShapePolygon'` errors: that room (and the pack's wall/window/single-door pieces it depends on) are `format=2` Godot-3-era scenes using `OccluderShapePolygon`, `Occluder`, and `StaticBody` — none of which exist in Godot 4 — so they fail to load entirely, taking the room with them. The three rooms already in use (hall, hall-end, storage) happen to only use `format=3`-compatible pieces, which is why they were fine. Pulled the Science Lab back out rather than hand-porting dozens of third-party files mid-session; noting it here so future room additions get spot-checked for the same trap before committing to a layout.

## 5. Small Polish

- Fixed the main menu's join button still reading "JoinButton" (leftover placeholder text) → now "Join Game"
- Moved player spawn points to sit inside the actual landing area geometry (`z ≈ 13`) instead of the old test-room origin

## 6. Verification

Actually ran it — hosted a session and walked the loop. After pulling the Godot-3 Science Lab room (see §4), the project **hosts and spawns the player cleanly**, and the code-sharing puzzle works: wrong codes are rejected ("Incorrect code, try again"), the right code opens the door. No GDScript parse or compile errors across any of the rewritten scripts. Remaining console noise is just a deprecated-surface-format warning on one column mesh (cosmetic, from the asset pack) — the fatal `OccluderShapePolygon` errors are gone now that the Godot-3 room is out.

## 7. What's Confirmed Working End-to-End

- Interactions now show real text on the player's HUD (logs, codes, pickups), local-player-only
- The full code-sharing puzzle: read code → relay over radio → enter at keypad → door opens for both players
- Narrative log that contextualizes the puzzle instead of a placeholder string
- A recognizably atmospheric space (modular rooms + fog + cold lighting)

## 8. Known Gaps / Not Done Yet

- Room-to-room layout is functional but not hand-tuned — some modular pieces still need alignment/decoration passes
- No persistence yet (Phase 5) — solving the puzzle doesn't save
- The message panel has no default theme/font styling beyond centered text
- Still no audio (ambient hum, radio static SFX) — sound design is its own later arc
- Voice chat still intentionally deferred

## Roadmap Status

| Phase | Goal | Status |
|---|---|---|
| 0 | Learn Godot basics | ✅ Done |
| 1 | Room, walking character, lighting | ✅ Done |
| 2 | Two players connected, see each other move | ✅ Done |
| 3 | Radio/proximity chat | ✅ Done |
| 4 | Wing 1 fully playable start to finish | ✅ First full loop playable |
| 5 | Persistence system | 👉 Next |

## Next Session

Phase 5 — a save/persistence system so a solved puzzle and an opened door stay opened between sessions. After that, more Wing 1 polish (environment tuning, ambient audio) before moving on to Wing 2 and the glyph/symbol system.
