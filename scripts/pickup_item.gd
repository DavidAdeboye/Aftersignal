extends Interactable

## A physical item the player can pick up. Removes itself from the world
## and reports what was collected on the player's HUD.

@export var item_name: String = "an item"


func _ready() -> void:
	if prompt_text == "Press E to interact":
		prompt_text = "Press E to pick up"


func interact(player: Node = null) -> void:
	_notify(player, "Picked up: " + item_name)
	queue_free()
