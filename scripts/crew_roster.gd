extends Interactable
class_name CrewRosterTerminal

## Interactive terminal displaying the official station personnel manifest (12 crew members).
## Planted in Player A's area / primary hab entry as an environmental story seed.

func _ready() -> void:
	if prompt_text == "Press E to interact":
		prompt_text = "Press E to read station crew roster"
	message = """BOREAS STATION CREW LIST

[01] DR. OSEI FARROW       - Lead Exobiologist / Director
[02] CALLUM BRAY           - Systems Specialist
[03] DR. MARCUS VANCE      - Chief Geologist
[04] ELENA ROSTOVA         - Atmospheric Tech
[05] TARIQ AL-MANSOOR      - Structural Engineer
[06] MAYA LIN              - Hydroponics Specialist
[07] JONAS REED            - Communications Officer
[08] SARAH JENKINS         - Medical Officer
[09] VICTOR CRUZ           - Power Grid Analyst
[10] NADIA KOSTIC          - Drill Operations
[11] LIAM O'CONNOR         - Maintenance Lead
[12] EVELYN THORNE         - Sub-surface Surveyor

All 12 crew were marked alive when the station started."""

func interact(player: Node = null) -> void:
	if player and player.has_method("has_item") and not player.has_item("player1_badge"):
		if _clearance_partner_in_range(player):
			_notify(player, "Terminal requires clearance - your partner might have access.")
		else:
			_notify(player, "Terminal requires clearance.")
		return
	if player and player.has_method("show_reading_panel"):
		player.show_reading_panel("PERSONNEL MANIFEST", message)
	else:
		_notify(player, message)
	PuzzleState.complete_act1_step("roster")
	if DialogManager.instance:
		DialogManager.instance.play_dialog("SALVAGER A", "Manifest registers 12 primary crew... check the room numbers in the hab wing to see where they stayed.")

func _clearance_partner_in_range(player: Node) -> bool:
	if not is_instance_valid(player) or not player.is_inside_tree():
		return false
	var max_range := 6.0
	if "clear_range" in player:
		max_range = float(player.clear_range)
	for candidate in get_tree().get_nodes_in_group("players"):
		if candidate == player or not is_instance_valid(candidate) or not candidate.is_inside_tree():
			continue
		if not candidate.has_method("has_item") or not candidate.has_item("player1_badge"):
			continue
		if candidate is Node3D and player is Node3D and candidate.global_position.distance_to(player.global_position) <= max_range:
			return true
	return false
