# Aftersignal — Devlog #2

**Date:** July 24, 2026
**Focus:** Phase 3 — Multiplayer networking (per the milestone roadmap)

---

## Summary

Today was entirely about getting two players connected over Godot's high-level multiplayer API — the single hardest phase on the whole roadmap, according to the original design doc, and it lived up to that reputation. Host/client connection, player spawning, camera ownership, and spawn positioning all had real, separate bugs that had to be diagnosed one at a time. By the end of the session: two players can host/join, each has their own working first-person camera and controls, both spawn correctly on solid ground, and neither can see or control the other's character.

This entry documents the actual debugging path — not just the final fix — since most of today's real work was diagnosis, not new feature code.

---

## 1. Manual Host/Join Controls

Set up `network_manager.gd` as an autoload singleton, with temporary key-bound controls for testing (no menu yet):
- **H** → host a game (`ENetMultiplayerPeer.create_server`)
- **J** → join a game at `127.0.0.1` (`ENetMultiplayerPeer.create_client`)

Added dedicated input actions (`host_game`, `join_game`) rather than reusing built-in UI actions, bound to H and J in the Input Map.

## 2. Bug #1 — Wrong Node Path

**Symptom:** `Node not found` error referencing `TestRoom/Players`.

**Cause:** `test_room.tscn`'s root node is itself named `TestRoom`. `get_tree().current_scene` already *is* that root, so `get_node("TestRoom/Players")` was effectively asking for `TestRoom/TestRoom/Players` — which doesn't exist.

**Fix:** Changed the lookup to `get_node("Players")`, since `Players` is a direct child of the current scene's root.

## 3. Bug #2 — Duplicate Spawner Nodes

**Symptom:** Persistent `ERR_ALREADY_IN_USE` errors from `_spawn_player()`, plus a related `ERR_INVALID_PARAMETER` on despawn — even after adding guards against double-triggering `host_game()`/`join_game()`.

**Diagnosis:** Added debug `print()` statements to `_spawn_player()` and `_on_peer_connected()` to trace exactly how many times spawning was being triggered, and from where. Logs showed each function firing exactly once per player — so the *code* wasn't the problem. Checked the scene tree directly and found **two separate spawner nodes** (`PlayerSpawner` and `MultiplayerSpawner`) both watching the same `Players` path — both trying to claim authority over the same spawned node.

**Fix:** Deleted the duplicate leftover spawner node, keeping only one `MultiplayerSpawner` with Spawn Path set to `Players` and `player.tscn` in its Auto Spawn List.

## 4. Bug #3 — Client Freezes / Blank Gray Screen

**Symptom:** Host window worked perfectly every time. The joining client consistently showed a flat, non-interactive gray screen — no depth, no response to input, not even Esc.

**Ruled out first:**
- GPU load (checked Task Manager — 5% usage, nowhere near a bottleneck)
- Debugger pause state (engine was running normally, not actually halted)

**Root cause — the real one:** `set_multiplayer_authority(id)` is called in `_spawn_player()`, but that only runs **locally on the server**, at the moment the server creates its own copy of the node. `MultiplayerSpawner`'s automatic scene-list spawning does *not* replicate that authority setting to clients — it just re-instantiates a fresh copy of `player.tscn` on each peer. Meanwhile the node's **name** (`str(id)`) *is* replicated, since it's part of the actual scene-tree structure being recreated.

Net effect: on the client, **both** player nodes ended up defaulting to server-authority, since nothing on the client side ever called `set_multiplayer_authority()` for either of them. `is_multiplayer_authority()` returned `false` for both, on the client, always — so `camera.current = true` never fired, leaving the client with zero active cameras and a blank viewport.

**Fix:** Added one line to `player_controller.gd`'s `_ready()`:
```gdscript
set_multiplayer_authority(int(str(name)))
```
Since the node's name reliably replicates to every peer, each peer can now independently determine "is this node mine?" by comparing its own peer ID to the node's name — no dependency on authority ever being pushed across the network.

Also wrapped the camera/input setup in a `call_deferred("_setup_local_player")` call, to guard against a possible one-frame race condition where authority data might not be fully settled the instant `_ready()` runs.

## 5. Bug #4 — Falling Into the Void on Join

**Symptom:** After fixing the authority bug, the client could finally see and control its own camera — but immediately fell through empty space instead of landing on the test room floor.

**Cause:** The original spawn code set a random position (`randf_range`) directly on the server's live, runtime-instantiated player object — but `MultiplayerSpawner` replicates scenes by re-instantiating fresh copies of the `.tscn` file on each client, not by cloning the server's modified runtime instance. So the random position picked by the server never made it to the client's copy, and each peer could end up with a different, unsynced (or default, `0,0,0`) position.

**Fix:** Made spawn position deterministic instead of random, computed independently and identically by every peer based on the node's own (replicated) name:
```gdscript
var spawn_points := [Vector3(-2, 1, 0), Vector3(2, 1, 0)]
var spawn_index := 0 if int(str(name)) == 1 else 1
position = spawn_points[spawn_index]
```
Peer ID `1` is always the host/server by Godot convention, so this reliably assigns each side a distinct, solid spawn point with zero network dependency.

---

## 6. What's Confirmed Working End-to-End

- Host and client can connect over local network (`127.0.0.1`)
- Each peer sees its own correctly-activated first-person camera
- Each peer controls only their own character (movement, look, jump)
- Both peers spawn on solid ground at fixed, non-overlapping positions
- No more `ERR_ALREADY_IN_USE`, no more blank/frozen client view, no more falling through the floor

## 7. Known Gaps / Not Done Yet

- No position/rotation sync yet — players can't currently *see* each other move (next step)
- No `MultiplayerSynchronizer` node on the Player scene yet
- No radio/proximity chat (Phase 3 continuation per roadmap)
- Still testing host + client on one machine — real cross-network testing (not just `127.0.0.1`) not yet attempted
- Manual H/J key controls are a placeholder — real menu still to come

## Key Takeaway

Almost every bug today traced back to the same underlying lesson: **code that runs locally on the server does not automatically apply to clients** under `MultiplayerSpawner`'s automatic scene replication. Only the actual scene-tree structure (node names, hierarchy, exported/synced properties) replicates automatically. Anything set imperatively in a script — multiplayer authority, runtime position, etc. — has to either be recomputed independently and identically on every peer (what we did here, using the node's name as the shared source of truth) or explicitly synced via a `MultiplayerSynchronizer` or RPC. Worth keeping this front of mind for every networked feature going forward — chat, puzzle state, persistence will all hit variations of this same trap.

## Next Session

Per the roadmap: get player position/rotation actually syncing (`MultiplayerSynchronizer`), so both peers can finally see each other move in real time — the "holy crap it works" moment the original design doc called out as milestone #2.
