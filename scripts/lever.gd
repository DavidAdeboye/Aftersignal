extends Interactable

## A lever / switch that toggles a linked door when pulled. Unlike pressure
## plates (which require continuous presence), a lever stays flipped. If
## `stays_on` is false, it acts as a timed switch that resets after a delay.
##
## The toggle fires through NetworkManager so both peers see the door animate.

@export var door_path: NodePath
## If true the lever stays in its new position permanently. If false it
## resets after `reset_delay` seconds (useful for timed puzzles).
@export var stays_on: bool = true
@export var reset_delay: float = 5.0

var _is_on: bool = false


func _ready() -> void:
	if prompt_text == "Press E to interact":
		prompt_text = "Press E to pull lever"
	if PuzzleState.is_puzzle_solved(name):
		_is_on = true
		prompt_text = "Lever (active)"
		call_deferred("_deferred_open")


func interact(player: Node = null) -> void:
	if _is_on and stays_on:
		_notify(player, "The lever is already active.")
		return

	_is_on = true
	prompt_text = "Lever (active)"

	var door = get_node_or_null(door_path)
	if door:
		NetworkManager.unlock_door.rpc(door.get_path())

	if stays_on:
		if door:
			PuzzleState.mark_door_opened(door.get_path())
		PuzzleState.mark_puzzle_solved(name)
		_notify(player, "Lever pulled. Door unlocked permanently.")
	else:
		_notify(player, "Lever pulled. Door opens for " + str(int(reset_delay)) + " seconds.")
		await get_tree().create_timer(reset_delay).timeout
		_is_on = false
		prompt_text = "Press E to pull lever"
		if door:
			NetworkManager.lock_door.rpc(door.get_path())


func _deferred_open() -> void:
	var door = get_node_or_null(door_path)
	if door and "opened" in door:
		door.opened = true
