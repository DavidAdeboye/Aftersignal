extends Interactable

## A physical item the player can pick up. Removes itself from the world
## and reports what was collected on the player's HUD. Stores the item in
## the player's inventory so locked doors and other scripts can check for it.

@export var item_name: String = "an item"
@export var item_id: String = ""


func _ready() -> void:
	if prompt_text == "Press E to interact":
		prompt_text = "Press E to pick up"
	if item_id == "":
		item_id = item_name.to_snake_case()


func interact(player: Node = null) -> void:
	if player and player.has_method("add_item"):
		player.add_item(item_id)
	_notify(player, "Picked up: " + item_name)
	queue_free()
