extends Interactable
class_name CrewRosterTerminal

## Interactive terminal displaying the official station personnel manifest (12 crew members).
## Planted in Player A's area / primary hab entry as an environmental story seed.

func _ready() -> void:
	if prompt_text == "Press E to interact":
		prompt_text = "Press E to read station crew roster"
	
	message = """=== BOREAS STATION PERSONNEL MANIFEST (12 CREW) ===

[01] DR. OSEI FARROW       — Lead Exobiologist / Director
[02] CALLUM BRAY            — Systems Specialist
[03] DR. MARCUS VANCE       — Chief Geologist
[04] ELENA ROSTOVA          — Atmospheric Tech
[05] TARIQ AL-MANSOOR       — Structural Engineer
[06] MAYA LIN               — Hydroponics Specialist
[07] JONAS REED             — Communications Officer
[08] SARAH JENKINS          — Medical Officer
[09] VICTOR CRUZ            — Power Grid Analyst
[10] NADIA KOSTIC           — Drill Operations
[11] LIAM O'CONNOR          — Maintenance Lead
[12] EVELYN THORNE          — Sub-surface Surveyor

[SYSTEM NOTE]: All 12 berths verified active at launch."""


func interact(player: Node = null) -> void:
	_notify(player, message)
