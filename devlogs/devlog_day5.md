# Aftersignal — Devlog #5

**Date:** August 4, 2026
**Focus:** Phase 5 — persistence, plus three new co-op mechanics (signal-jamming zones, simultaneous-action pressure plates, and a shared glyph sketch-relay)

---

## Summary

Day 4 got the first full co-op loop playable end-to-end. This session tackled the roadmap's **Phase 5 (persistence)** and, since the systems layer was stable, took the opportunity to bang out three more design-doc mechanics in the same pass. The through-line for all four additions is the *same architectural lesson* that's shaped every session: **shared state must be driven from a node that exists identically on every peer** — so everything routes through autoloads (`NetworkManager`, and a new `PuzzleState`) rather than through any one replicated player.

New this session:

1. **`PuzzleState` autoload** — single source of truth for puzzle progress + the save/load layer (`user://savegame.json`).
2. **Signal-jamming zones** — radio dead-zones that degrade chat while you stand in them.
3. **Simultaneous-action puzzle** — two pressure plates that must be held at the same time to open a shared door.
4. **Shared glyph sketch-relay** — a drawing pad whose strokes stream to your partner's screen.

---

## 1. Persistence — the `PuzzleState` Autoload (Phase 5)

The Day 4 known-gap was blunt: *"solving the puzzle doesn't save."* Fixed by adding a second autoload alongside `NetworkManager`:

```
[autoload]
NetworkManager="*uid://bo7ixopalio5g"
PuzzleState="*uid://cpuzzlestate0001"
```

`PuzzleState` has two jobs:

- **Progress tracking** — dictionaries of permanently-opened doors and named solved-puzzle flags.
- **Save/load** — serialized to `user://savegame.json` with `JSON.stringify`, read back on `_ready()`.

The keypad puzzle now persists on success:

```gdscript
NetworkManager.unlock_door.rpc(_door.get_path())
PuzzleState.mark_door_opened(_door.get_path())   # survives a rejoin
PuzzleState.mark_puzzle_solved(name)
```

On join, once the world has a player in it, `NetworkManager` calls `PuzzleState.apply_persisted_doors()` (deferred), which walks the saved door paths in the current scene and sets any `opened = true`. So a keypad door you cracked last session starts open this session.

**Design note — not everything *should* persist.** The pressure-plate door (below) is deliberately excluded from persistence: it's *meant* to re-lock the instant a plate is released, so saving it would break the puzzle. Only "permanent" solves (keypad) get written. That distinction is baked into the API — `mark_door_opened()` is a separate, opt-in call, not something the generic `unlock_door` RPC does automatically.

## 2. Signal-Jamming Zones

Straight from the design doc's communication section ("rooms built to jam signal"). A `SignalJammer` is a cheap, physics-free spherical dead-zone:

```gdscript
func signal_multiplier_for(world_pos: Vector3) -> float:
    if global_position.distance_to(world_pos) <= radius:
        return 1.0 - jam_strength
    return 1.0
```

The player controller polls every node in the `signal_jammers` group each frame and applies the **worst** jam affecting *either* end of the radio link (a link is only as good as its weakest end):

```gdscript
var jam := _worst_jam_multiplier(global_position)
jam = min(jam, _worst_jam_multiplier(other.global_position))
signal_quality *= jam
```

Because it keys off position (already network-synced) and pure distance math, every peer independently agrees on who's jammed — no extra replication needed. It stacks neatly on top of the Day 3 distance-based garbling: stand in a jammer and your relayed code turns to static even at point-blank range, forcing players to relocate to talk.

## 3. Simultaneous-Action Puzzle (Pressure Plates)

Design-doc puzzle type #2: two plates in different spots, a shared door that's only open while **both** are held. Classic "okay, step on it — *now!*" coordination over the radio.

- `PressurePlate` auto-presses via a child `Area3D` (stand on it, no interact key), tweens down for tactile feedback, and reports its state to `PuzzleState`.
- `PuzzleState` tracks plate groups by a shared `group_id`. The moment **all** plates in a group are pressed, the **server** fires `NetworkManager.unlock_door.rpc(...)`; releasing any plate fires the new `lock_door.rpc(...)`.

```gdscript
var is_server := (not multiplayer.has_multiplayer_peer()) or multiplayer.is_server()
if not is_server:
    return
if all_pressed:
    NetworkManager.unlock_door.rpc(door_path)
else:
    NetworkManager.lock_door.rpc(door_path)
```

Only the server evaluates the group, avoiding double-RPCs — and the single-player-editor guard means it still works when testing solo with no peer connected. Added a matching `lock_door` RPC to `NetworkManager` (Day 4 only had `unlock_door`, since nothing re-locked before).

## 4. Shared Glyph Sketch-Relay

Design-doc §4 "shared symbols/glyphs." A `GlyphPad` `Control` on the player's `CanvasLayer`, toggled with a new **G** key (`toggle_glyph` input action). You drag to draw; finished strokes stream to your partner so they can reconstruct a symbol that's too fiddly to describe over garbled radio.

Strokes are stored **normalized** (0..1) so they map correctly onto a partner's differently-sized pad, then relayed with the exact same routing pattern as chat:

```gdscript
@rpc("any_peer", "call_remote")
func send_glyph_stroke(stroke: PackedVector2Array) -> void:
    var local_player = _get_local_player()
    if local_player and local_player.has_method("receive_glyph_stroke"):
        local_player.receive_glyph_stroke(stroke)
```

`call_remote` (not `call_local`) because the sender already sees their own stroke locally — the partner renders it in a contrasting "received" tint. Same lesson as the Day 3 chat bug: resolve the RPC to the *locally-authoritative* player on the receiving side, never the remote copy.

## 5. Wiring It Into Wing 1

Added to `landing_bay.tscn`:

- A `SignalJammer` (radius 7, 85% jam) over the far hall-end, so the far half of the wing is a comms-dead area.
- Two `PressurePlate`s sharing `group_id = "storage_plates"`, controlling the hall's second double door, placed far apart so one player can't reach both.

And to `player.tscn`: the hidden `GlyphPad` + a small hint label, centered on the HUD.

## 6. A Note on the Tooling Friction

Godot isn't on PATH in this environment, so I couldn't do the Day-4-style "actually host it and walk the loop" verification from the terminal this session. Everything was built against the patterns already proven working on Days 3–4 (the autoload-RPC routing, the `Interactable` base, the door tween), and cross-checked against the real node paths in the asset-pack rooms (e.g. confirming the plate puzzle targets `Hall/Doors/DoorDouble2`, a real `format=3` door, after finding the storage room has no Godot-4-compatible door node). **Live playtest verification is the first task for next session.**

## 7. Known Gaps / Not Done Yet

- **Not yet playtested live** (see §6) — needs a host-and-walk pass in the editor.
- Glyph pad has no "clear" button wired to a key yet (the `clear_glyphs` RPC exists, just isn't bound).
- Plate puzzle door re-locks instantly with no grace period — may feel harsh; a short "closing…" delay could be kinder.
- Jammer zones have no visual/audio tell yet — a player has no in-world cue they've entered one beyond the signal meter dropping.
- Save file is never surfaced to the player (no "continue / new game" menu split yet).

## Roadmap Status

| Phase | Goal | Status |
|---|---|---|
| 0 | Learn Godot basics | ✅ Done |
| 1 | Room, walking character, lighting | ✅ Done |
| 2 | Two players connected, see each other move | ✅ Done |
| 3 | Radio/proximity chat | ✅ Done |
| 4 | Wing 1 fully playable start to finish | ✅ Done |
| 5 | Persistence system | ✅ Implemented (pending live test) |

## Next Session

Live playtest pass on all four new systems, then bind the glyph-clear key and give the jammer zones an in-world tell. After that: a "continue vs. new game" menu that actually reads the save file, and on toward Wing 2.
