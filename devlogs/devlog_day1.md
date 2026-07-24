# Aftersignal — Devlog #1

**Date:** July 23–24, 2026
**Time tracked:** ~26m+ logged in Hackatime (GDScript, coding category) after getting time tracking properly configured — actual hands-on time was considerably longer once you count Godot editor learning, troubleshooting, and setup.

---

## Summary

First real day working on Aftersignal. Went from "Godot installed, nothing built" to a fully playable test environment: a first-person character that walks, jumps, collides with the world, and can interact with objects — including a working prompt UI and multiple interactable types (a readable terminal, a lore log, and a pickup item that removes itself from the world).

This entry covers setup pain as much as feature work, since a chunk of today was fighting tooling rather than writing gameplay code — which is normal for day one on a new engine, and worth documenting honestly.

---

## 1. Project Setup

- Created the Godot 4 project (`Aftersignal`), Forward+ renderer (needed for the volumetric fog / emissive crystal lighting planned in the art direction doc), Git version control metadata enabled.
- Set up the initial folder structure to match the game's wing-based level design:
  ```
  Aftersignal/
    scenes/
      wings/01_landing_bay/
      shared/
    scripts/
    assets/
    addons/
  ```
- Wrote a full project README covering the high concept, communication system, wing structure, and scope guardrails, based on the original game design doc.

## 2. Hackatime / Time Tracking

This ended up being its own small saga:

- Linking Hackatime to a general IDE only tracks files edited *outside* Godot (e.g. the README) — it does **not** see anything happening inside Godot's own script/scene editor.
- Godot requires its own dedicated plugin (**Godot Super Wakatime**) installed *per project* to send heartbeats from in-editor activity. This is a known Godot-specific limitation, not a misconfiguration on our end.
- Installed the plugin manually (AssetLib search wasn't finding it, so pulled it directly from GitHub and copied the `addons/` folder in), enabled it under Project Settings → Plugins.
- Found a config file mismatch: had `wakatime.cfg` instead of the required `.wakatime.cfg` (leading dot matters — Windows makes this mildly annoying to create via File Explorer). Fixed via command line (`copy wakatime.cfg .wakatime.cfg`).
- Confirmed working: dashboard now correctly shows **GDScript** as top language and **coding** as top category, with real per-file breakdowns.
- Learned that Wakatime-style tracking only counts active edits (keystrokes, saves, file switches) — not time spent just playtesting/running the game. This is expected behavior, not a bug.

## 3. Player Character (Phase 1 of the roadmap)

Built a reusable `Player` scene (`scenes/shared/player.tscn`):

- `CharacterBody3D` root with a `CapsuleShape3D` collision shape (height 1.8, radius 0.4)
- `Head` node (Node3D) at eye height (Y: 1.6) holding the `Camera3D`, separating pitch (head) from yaw (body) rotation
- Wrote `player_controller.gd` from scratch: WASD movement, mouse look with clamped pitch, gravity, and jump, using Godot's `move_and_slide()`
- Set up the Input Map: `move_forward/back/left/right`, `jump`

Added a visible **CapsuleMesh** to the Player (matching the collision capsule's dimensions) with a colored `StandardMaterial3D` override, so there's now an actual visible character instead of an invisible collider. Character/asset polish is intentionally deferred — per the design doc's own scope guardrails, a simple placeholder capsule is explicitly acceptable, and real models (Kenney.nl / Quaternius, CC0) will come later without needing to touch any logic.

## 4. Test Room

Built `scenes/wings/01_landing_bay/test_room.tscn`:

- A `CSGBox3D` floor and two walls, a `DirectionalLight3D` for basic lighting
- Debugged an early issue where the player fell straight through the floor — turned out CSG shapes don't have collision enabled by default (**Use Collision** has to be explicitly turned on per shape)
- Player now spawns correctly, walks, jumps, and collides with the floor/walls as expected

## 5. Interaction System (Phase 2, done ahead of schedule)

This was the bulk of today's actual scripting work.

**Base class** — `scripts/interactable.gd`:
```gdscript
extends Node3D
class_name Interactable

@export var prompt_text: String = "Press E to interact"

func interact() -> void:
	print("Interacted with: ", name)
```

**Detection** — added a `RayCast3D` under the Player's `Camera3D` (pointed 3 meters forward), and updated `player_controller.gd` to:
- Check every physics frame whether the raycast is hitting something that `is Interactable`
- Track the current target in a `current_interactable` variable
- Call `.interact()` on it when the `interact` action (bound to **E**) is pressed

**Prompt UI** — added a `CanvasLayer` + `Label` ("Press E to interact") to the Player scene, toggled visible/hidden based on whether something is currently targeted. Hit a small bug here where the label stayed visible constantly — traced to a typo/logic error in the visibility-toggle line, found and fixed independently.

**Proving the system generalizes** — rather than just one hardcoded object, built out:
- `TestTerminal` — uses the base `interactable.gd` directly, generic print
- `test_log.gd` (extends `Interactable`) → attached to `TestLog` — overrides `interact()` with its own unique message, proving the class hierarchy actually works for varied content, not just one object
- `pickup_item.gd` (extends `Interactable`) → attached to `TestPickup` — overrides `interact()` to print a pickup message *and* call `queue_free()`, removing the object from the world entirely. Had one round of debugging here (a mis-set-up collision layer/shape on the first attempt); rebuilt the object from scratch mirroring the working `TestTerminal` setup, which resolved it.

**Hide-own-body setup** — configured the Player's visible mesh to sit on render Layer 2, and set the Camera3D's Cull Mask to exclude Layer 2, so the player won't see their own body from inside their own head once we're in first-person — this will matter once networking is in and you can see your *partner's* model but not your own.

## 6. What's Confirmed Working End-to-End

- Movement, mouse look, jump, gravity, collision
- Visible player character (capsule placeholder)
- Interaction raycast + "Press E to interact" prompt UI
- Three distinct interactable behaviors sharing one base class (generic, custom-text, and destroy-on-interact)

## 7. Known Gaps / Not Done Yet

- No real character model — capsule placeholder only (intentional, per design doc guardrails)
- No networking yet — this is single-player testing only so far
- No audio, no real art pass, no actual wing content beyond the test room

## Next Session: Phase 3 — Networking

Per the milestone roadmap, next up is the big one: getting two players connected via Godot's `MultiplayerAPI` / `ENetMultiplayerPeer`, seeing each other move in real time, and — once that's in — actually testing the hide-own-body layer setup properly (seeing a partner's model while your own stays invisible to yourself).
