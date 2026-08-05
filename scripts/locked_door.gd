extends Interactable

## A locked door that requires a specific inventory item to open. When the
## player interacts: if they have the required item, the linked door unlocks
## for both peers and the item is consumed; otherwise they see a "locked"
## message telling them what they need.

@export var required_item: String = ""
@export var key_display_name: String = "a key"
@export var door_path: NodePath

var _unlocked: bool = false


func _ready() -> void:
	if prompt_text == "Press E to interact":
		prompt_text = "Press E to open"
	# If this door was already solved in a previous session, mark it open.
	if PuzzleState.is_puzzle_solved(name):
		_unlocked = true
		_open_door_silently()


func interact(player: Node = null) -> void:
	if _unlocked:
		_notify(player, "This door is already unlocked.")
		return
	if player == null or not player.has_method("has_item"):
		_notify(player, "Locked. Requires " + key_display_name + ".")
		return

	if player.has_item(required_item):
		player.remove_item(required_item)
		_unlocked = true
		var door = get_node_or_null(door_path)
		if door:
			NetworkManager.unlock_door.rpc(door.get_path())
			PuzzleState.mark_door_opened(door.get_path())
		PuzzleState.mark_puzzle_solved(name)
		_notify(player, "Used " + key_display_name + ". Door unlocked.")
	else:
		_notify(player, "Locked. Requires " + key_display_name + ".")


## Opens the linked door without animation or network RPC — used on load when
## persistence says this was already solved.
func _open_door_silently() -> void:
	if door_path == NodePath(""):
		return
	# Deferred because the door node may not be ready yet at _ready time.
	call_deferred("_deferred_open")


func _deferred_open() -> void:
	var door = get_node_or_null(door_path)
	if door and "opened" in door:
		door.opened = true
