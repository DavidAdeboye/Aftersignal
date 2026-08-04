extends Node

## PuzzleState — the single, peer-identical source of truth for puzzle progress,
## plus the save/persistence layer (roadmap Phase 5).
##
## It exists as an autoload (like NetworkManager) so every peer has one, and so
## door/puzzle state can be driven from a node that isn't tied to any one
## replicated player. Two responsibilities:
##
##   1. SIMULTANEOUS-ACTION PUZZLES — tracks which pressure plates in a group are
##      currently pressed and opens/closes the shared door the instant all of a
##      group are (or aren't) held. The server is authoritative and fans the
##      result out to every peer via NetworkManager.unlock_door / lock_door.
##
##   2. PERSISTENCE — remembers which doors have been permanently opened and which
##      puzzles are solved, and writes/reads them to user://savegame.json so a
##      solved keypad or opened door stays that way between sessions.

const SAVE_PATH := "user://savegame.json"

# --- Simultaneous-action puzzle tracking -------------------------------------
# group_id -> { "plates": { plate_instance_id: bool_pressed }, "door": NodePath }
var _plate_groups: Dictionary = {}

# --- Persistence -------------------------------------------------------------
# Doors that should be open forever once solved (stored as NodePath strings).
var _opened_doors: Dictionary = {}
# Arbitrary named puzzle flags, e.g. "storage_keypad" -> true.
var _solved_puzzles: Dictionary = {}


func _ready() -> void:
	load_progress()


# ============================================================================
#  PRESSURE-PLATE GROUPS (simultaneous action)
# ============================================================================

func register_plate(group_id: String, plate: Node, door_path: NodePath) -> void:
	if not _plate_groups.has(group_id):
		_plate_groups[group_id] = {"plates": {}, "door": NodePath("")}
	var group: Dictionary = _plate_groups[group_id]
	group["plates"][plate.get_instance_id()] = false
	# The first plate that supplies a real door_path wins; others may leave it blank.
	if door_path != NodePath("") and group["door"] == NodePath(""):
		group["door"] = door_path


func set_plate_pressed(group_id: String, plate: Node, pressed: bool) -> void:
	if not _plate_groups.has(group_id):
		return
	var group: Dictionary = _plate_groups[group_id]
	group["plates"][plate.get_instance_id()] = pressed
	_evaluate_group(group_id)


## Opens the group's door while every plate is pressed, closes it otherwise.
## Only the server actually fires the networked door change to avoid double-RPCs.
func _evaluate_group(group_id: String) -> void:
	var group: Dictionary = _plate_groups[group_id]
	var door_path: NodePath = group["door"]
	if door_path == NodePath(""):
		return

	var all_pressed := true
	for is_down in group["plates"].values():
		if not is_down:
			all_pressed = false
			break

	# Guard: in single-player editor testing there may be no active multiplayer
	# peer — treat that as "server" so the mechanic still works solo.
	var is_server := (not multiplayer.has_multiplayer_peer()) or multiplayer.is_server()
	if not is_server:
		return

	if all_pressed:
		NetworkManager.unlock_door.rpc(door_path)
	else:
		NetworkManager.lock_door.rpc(door_path)


# ============================================================================
#  PERSISTENCE
# ============================================================================

## Marks a door permanently opened and saves. Call this for puzzles whose result
## should survive a rejoin (e.g. the keypad-unlocked storage door). Simultaneous
## plate doors are intentionally NOT persisted — they're meant to re-lock.
func mark_door_opened(door_path: NodePath) -> void:
	_opened_doors[str(door_path)] = true
	save_progress()


func mark_puzzle_solved(puzzle_id: String) -> void:
	_solved_puzzles[puzzle_id] = true
	save_progress()


func is_puzzle_solved(puzzle_id: String) -> bool:
	return _solved_puzzles.get(puzzle_id, false)


func is_door_opened(door_path: NodePath) -> bool:
	return _opened_doors.get(str(door_path), false)


func save_progress() -> void:
	var data := {
		"opened_doors": _opened_doors,
		"solved_puzzles": _solved_puzzles,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("PuzzleState: could not open save file for writing.")
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	_opened_doors = parsed.get("opened_doors", {})
	_solved_puzzles = parsed.get("solved_puzzles", {})


## Re-applies persisted "opened" doors to the currently loaded scene. Call this
## after a wing scene finishes loading so previously solved doors start open.
func apply_persisted_doors() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	for door_path_str in _opened_doors.keys():
		if not _opened_doors[door_path_str]:
			continue
		var door := scene.get_node_or_null(NodePath(door_path_str))
		if door != null and "opened" in door:
			door.opened = true


## Wipes saved progress (handy for a "New Game" menu button / debugging).
func reset_progress() -> void:
	_opened_doors.clear()
	_solved_puzzles.clear()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
