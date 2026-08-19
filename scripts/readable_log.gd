extends Interactable
class_name ReadableLog

@export var log_title: String = "RESEARCH LOG"
@export var next_objective: String = ""
@export var remove_after_read: bool = false
@export var required_badge: String = ""


func _ready() -> void:
	if prompt_text == "Press E to interact":
		prompt_text = "Press E to pick up and read"
	if message.strip_edges().is_empty():
		message = "FIELD NOTE - E. THORNE\n\nFarrow split the storage override between two stations so no one could enter alone. One station displays the access credential. The second station accepts it.\n\nPROCEDURE\n1. Split up and locate the access terminal and keypad.\n2. Relay the credential to the player at the keypad.\n3. Regroup beyond storage.\n4. Stand on both pressure plates simultaneously."


func interact(player: Node = null) -> void:
	if next_objective != "" and not PuzzleState.is_act1_step_complete("missing_room"):
		_notify(player, "The habitation discrepancy needs to be documented first.")
		return
	if required_badge != "" and player and player.has_method("has_item") and not player.has_item(required_badge):
		_notify(player, "This requires clearance you don't have — your partner might.")
		return

	if player and player.has_method("show_reading_panel"):
		player.show_reading_panel(log_title, message)
	else:
		_notify(player, message)

	if next_objective != "":
		PuzzleState.complete_act1_step("research_logs")
		if log_title.to_lower().contains("final") or log_title.to_lower().contains("evidence"):
			PuzzleState.complete_act1_step("lab_evidence")

	if remove_after_read:
		queue_free()
