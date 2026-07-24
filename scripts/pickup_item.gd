extends Interactable

func interact() -> void:
	print("Picked up: ", name)
	queue_free()
