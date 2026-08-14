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
	_notify(player, message)
	if ObjectiveManager.instance:
		ObjectiveManager.instance.set_objective("OBJECTIVE: Access Science Lab & Investigate Dr. Farrow's Research")
	if DialogManager.instance:
		DialogManager.instance.play_dialog("SALVAGER B", "Hold on... the manifest listed 12 crew, but this wall is seamless steel. Room 12 was never built! Head to Dr. Farrow's lab down the hall.")
