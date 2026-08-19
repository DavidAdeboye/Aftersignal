extends Interactable

## A locked keypad. The player types a code; if it matches, the linked door
## unlocks for BOTH players over the network. The matching code is found by
## the OTHER player at a CodeDisplay elsewhere in the wing — forcing the
## radio-relay communication that the whole game is built around.

@export var correct_code: String = "4471"
@export var door_path: NodePath

var _door: Node
var _resolved_door_path: NodePath


func _ready() -> void:
	_resolve_door()
	if prompt_text == "Press E to interact":
		prompt_text = "Press E to enter code"


func interact(player: Node = null) -> void:
	# Actual code entry is driven by player_controller.gd, which opens the
	# on-screen keypad input when it detects a check_code() method. Nothing
	# to do here.
	pass


## Returns true if the code is correct. On success, unlocks the door for
## every peer via the NetworkManager RPC.
func check_code(code: String) -> bool:
	if not PuzzleState.has_act1_clue("access_code"):
		return false
	if code == correct_code:
		_resolve_door()
		if _door != null:
			NetworkManager.unlock_door.rpc(_resolved_door_path)
			# Persist this one — a keypad door should stay open across sessions
			# (unlike simultaneous-plate doors, which are meant to re-lock).
			PuzzleState.mark_door_opened(_resolved_door_path)
			PuzzleState.mark_puzzle_solved(name)
			if name == "Keypad":
				PuzzleState.complete_act1_step("keypad")
			print("Correct code — door unlocked!")
		else:
			push_warning("Keypad has no valid door_path assigned.")
			return false
		return true
	else:
		print("Incorrect code, try again.")
		return false

func get_failure_reason() -> String:
	if _door == null:
		return "DOOR LINK ERROR: This keypad is not connected to its door."
	if not PuzzleState.is_act1_step_complete("roster"):
		return "Read the crew roster before using this keypad."
	if not PuzzleState.has_act1_clue("access_code"):
		return "No code has been recovered. Your partner must inspect the access terminal first."
	return "Incorrect code. Ask your partner for the access code."


func _resolve_door() -> void:
	_door = null
	_resolved_door_path = NodePath("")
	if door_path == NodePath(""):
		return
	_door = get_node_or_null(door_path)
	var scene := get_tree().current_scene
	if _door == null and scene:
		_door = scene.get_node_or_null(door_path)
	if _door != null and scene:
		_resolved_door_path = scene.get_path_to(_door)
