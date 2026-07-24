# Aftersignal — Devlog #2

**Date:** July 24, 2026
**Focus:** Phase 3 — Multiplayer networking (per the milestone roadmap)

---

## Summary

This session was entirely about getting two players actually connected and visible to each other in Godot's multiplayer API — the hardest phase on the whole roadmap, according to the original design doc, and it lived up to that reputation. Ran into a chain of real bugs, each hiding behind the last, plus a couple of visibility/polish issues once the core connection was solid. By the end: two players can host and join, each has working per-player camera and controls, both spawn on solid ground in distinct colors, and both can actually see each other move in real time.

---

## 1. Manual Host/Join Controls

Set up `network_manager.gd` as an autoload singleton, with temporary key-bound controls for testing (no menu yet):
- **H** → host a game (`ENetMultiplayerPeer.create_server`)
- **J** → join a game at `127.0.0.1` (`ENetMultiplayerPeer.create_client`)

Added dedicated input actions (`host_game`, `join_game`) rather than reusing built-in UI actions, bound to H and J.

## 2. Bug — Wrong Node Path

**Symptom:** `Node not found` error referencing `TestRoom/Players`.

**Cause:** `test_room.tscn`'s root node is itself named `TestRoom`. `get_tree().current_scene` already *is* that root, so `get_node("TestRoom/Players")` was effectively asking for `TestRoom/TestRoom/Players`.

**Fix:** Changed the lookup to `get_node("Players")`.

## 3. Bug — Duplicate Spawner Nodes

**Symptom:** Persistent `ERR_ALREADY_IN_USE` on `_spawn_player()`, plus a related `ERR_INVALID_PARAMETER` on despawn — even after adding guards against double-triggering `host_game()`/`join_game()`.

**Diagnosis:** Added debug `print()` statements to trace exactly how often spawning fired. Logs showed each function firing exactly once — so the code wasn't the problem. Checked the scene tree directly and found **two separate spawner nodes** (`PlayerSpawner` and `MultiplayerSpawner`) both watching the same `Players` path.

**Fix:** Deleted the duplicate leftover spawner, keeping one `MultiplayerSpawner` with Spawn Path set to `Players` and `player.tscn` in its Auto Spawn List.

## 4. Bug — Client Freezes / Blank Gray Screen

**Symptom:** Host window worked every time. The joining client consistently showed a flat, unresponsive gray screen — not even Esc worked.

**Ruled out first:** GPU load (Task Manager showed 5% usage) and debugger pause state (engine was running normally).

**Root cause:** `set_multiplayer_authority(id)` was only ever called locally, on the server, inside `_spawn_player()`. `MultiplayerSpawner`'s automatic scene-list spawning doesn't replicate that setting — it just re-instantiates a fresh copy of `player.tscn` on each peer. Meanwhile the node's **name** (`str(id)`) *does* replicate, since it's part of the actual scene structure being recreated.

Net effect: on the client, both player nodes defaulted to server-authority, since nothing on the client side ever set authority for either one. `is_multiplayer_authority()` returned false for both, on the client, always — so the camera never activated and the client saw nothing.

**Fix:** Added logic so every peer derives its own authority from the player node's replicated name, instead of depending on authority being pushed over the network:
```gdscript
set_multiplayer_authority(int(str(name)))
```

## 5. Bug — Falling Into the Void on Join

**Symptom:** After the authority fix, the client could see and control its own camera, but immediately fell through empty space.

**Cause:** Spawn position was randomized (`randf_range`) directly on the server's live runtime object — but `MultiplayerSpawner` replicates by re-instantiating fresh copies of the `.tscn` file on each client, not by cloning the server's modified instance. The random position never made it across.

**Fix:** Made spawn position deterministic — every peer computes the same position independently, based on their own (replicated) node name:
```gdscript
var spawn_index := 0 if int(str(name)) == 1 else 1
position = spawn_points[spawn_index]
```

## 6. Bug — Authority Set Too Late for MultiplayerSynchronizer

**Symptom (after adding a MultiplayerSynchronizer, see below):** Console warning — *"unable to process the pending spawn since it has no network ID... make sure to only change authority during `_enter_tree`."*

**Cause:** `set_multiplayer_authority()` was running inside `_ready()`, which fires slightly after `_enter_tree()`. `MultiplayerSynchronizer` needs authority set by the time the node enters the tree, not after.

**Fix:** Moved the authority line into its own `_enter_tree()` function, which runs earlier automatically:
```gdscript
func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))
```

## 7. Player Colors

Gave each player a distinct color (blue for host, orange for client) based on the same `spawn_index` already used for spawn position — applied via a runtime `StandardMaterial3D` override on the capsule mesh, so both players share one scene file but render differently.

## 8. Visibility Bug — Nobody Could See Anybody

**Symptom:** Even after fixing all networking bugs, players still couldn't see each other's capsules.

**Cause:** A "hide your own body" trick from Day 1 put the player mesh on render Layer 2 and configured the camera to exclude Layer 2, so you wouldn't see your own body from inside your own head. Since *every* player capsule uses that same layer, and *every* camera excludes it, **no camera could see any capsule at all** — not even a partner's.

**Fix:** Re-enabled Layer 2 on the Camera3D's Cull Mask. Own-body visibility became a minor cosmetic non-issue, revisit later if needed.

## 9. Position/Rotation Syncing

Even after fixing visibility, the other player's capsule sat frozen at spawn — nothing was broadcasting movement.

**Fix:** Added a `MultiplayerSynchronizer` node to the Player scene, configured to sync `position` and `rotation` on every peer, set to "Always" replication. No scripting required — only the node authoring in the editor plus the `_enter_tree()` timing fix above.

## 10. Fall-Into-Void Safety Net

Added a simple check in `_physics_process()`: if a player's Y position drops below -20 (well under the test room floor), they're teleported back to their spawn point with velocity reset to zero. Cheap insurance against falling forever during testing.

---

## 11. What's Confirmed Working End-to-End

- Host and client connect over local network (`127.0.0.1`)
- Each peer has a correctly activated first-person camera and independent controls
- Players spawn on solid ground at fixed, non-overlapping positions
- Players are visually distinct (blue vs. orange)
- Players can see each other, and see each other move in real time
- Falling off the map returns you to spawn instead of falling forever

## 12. Known Gaps / Not Done Yet

- No radio/proximity chat yet (next up)
- No voice chat yet — flagged as its own larger effort, planned as a separate phase after text-based proximity chat is working
- Still testing host + client on one machine — real cross-network testing not yet attempted
- Manual H/J key controls are a placeholder — real menu still to come

## Key Takeaway

Nearly every bug this session traced back to one lesson: **code that runs locally on the server does not automatically apply to clients** under `MultiplayerSpawner`'s automatic replication. Only actual scene structure (node names, hierarchy, and anything explicitly wired through a `MultiplayerSynchronizer`) replicates automatically. Anything else set imperatively in a script has to be recomputed identically on every peer, or explicitly synced. This same pattern will almost certainly resurface with chat and shared puzzle state — worth keeping front of mind going forward.

## Next Session

Proximity-based text chat: detect distance between players, and once in range, let them send short text messages to each other over RPC. This proves the core "you must be near each other to communicate" mechanic before tackling actual voice chat as its own dedicated phase later.
