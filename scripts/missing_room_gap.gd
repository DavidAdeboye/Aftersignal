extends Interactable
class_name MissingRoomGap

## Interactive inspection point on the blank steel wall where Room 12 should be located.
## Planted in Player B's area (Mess Hall / Habitation Wing) as an environmental story seed.

func _ready() -> void:
	if prompt_text == "Press E to interact":
		prompt_text = "Press E to inspect wall gap"
	
	message = """[HABITATION WING STRUCTURAL ANOMALY]

You examine the seamless steel wall between Quarters 11 and the end bulkhead.

According to the station blueprint, this gap should contain Quarters 12. However, the steel plating is completely continuous — there are no door frames, no wiring conduits, and no evidence that a 12th room was ever cut into the station superstructure.

Station personnel manifest lists 12 crew... but this wing was physically built for only 11."""


func interact(player: Node = null) -> void:
	if not PuzzleState.is_act1_step_complete("keypad"):
		_notify(player, "This corridor is still sealed. Unlock the storage door with code 4471 first.")
		return
	_notify(player, message)
	PuzzleState.complete_act1_step("missing_room")
	if DialogManager.instance:
		DialogManager.instance.play_dialog("SALVAGER B", "Hold on... the manifest listed 12 crew, but this wall is seamless steel. Room 12 was never built! Head to Dr. Farrow's lab down the hall.")
