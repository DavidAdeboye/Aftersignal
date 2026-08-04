extends Interactable

@export var correct_code: String = "4471"
@export var door_path: NodePath

var _door: Node


func _ready() -> void:
	_door = get_node(door_path)


func interact() -> void:
	pass  # handled by player_controller.gd instead


func check_code(code: String) -> bool:
	if code == correct_code:
		NetworkManager.unlock_door.rpc(_door.get_path())
		print("Correct code — door unlocked!")
		return true
	else:
		print("Incorrect code, try again.")
		return false
