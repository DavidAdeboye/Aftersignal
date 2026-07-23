extends Node3D
class_name Interactable

## Base class for anything the player can interact with —
## logs, terminals, buttons, pickups. Attach a script that
## extends this to any object, and override interact().

@export var prompt_text: String = "Press E to interact"

func interact() -> void:
	# Override this in child scripts/scenes with the specific behavior
	print("Interacted with: ", name)
