extends Interactable

## A locked keypad. The player types a code; if it matches, the linked door
## unlocks for BOTH players over the network. The matching code is found by
## the OTHER player at a CodeDisplay elsewhere in the wing — forcing the
## radio-relay communication that the whole game is built around.

@export var correct_code: String = "4471"
@export var door_path: NodePath

var _door: Node


func _ready() -> void:
	if door_path != NodePath(""):
		_door = get_node_or_null(door_path)
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
	if code == correct_code:
		if _door == null and door_path != NodePath(""):
			_door = get_node_or_null(door_path)
		if _door != null:
			NetworkManager.unlock_door.rpc(_door.get_path())
			# Persist this one — a keypad door should stay open across sessions
			# (unlike simultaneous-plate doors, which are meant to re-lock).
			PuzzleState.mark_door_opened(_door.get_path())
			PuzzleState.mark_puzzle_solved(name)
			print("Correct code — door unlocked!")
		else:
			push_warning("Keypad has no valid door_path assigned.")
		return true
	else:
		print("Incorrect code, try again.")
		return false
