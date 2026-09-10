extends StationChapter

func _build_environment() -> void:
	super._build_environment()
	var ending := ""
	for choice in ["awaken", "seal", "communicate"]:
		if PuzzleState.is_puzzle_solved("ending_" + choice):
			ending = choice
	var message := {
		"awaken": "ENDING: AWAKEN\n\nThe core wakes. The station lights return, and the signal answers with a new voice.",
		"seal": "ENDING: SEAL\n\nThe core goes dark. The station is quiet, but the signal cannot reach anyone again.",
		"communicate": "ENDING: COMMUNICATE\n\nYou answer the signal. Twelve voices speak together, and the station finally tells its story.",
	}.get(ending, "ENDING\n\nThe station is quiet. The signal remains in the dark.")
	var terminal := StaticBody3D.new()
	terminal.name = "EndingReport"
	terminal.set_script(preload("res://scripts/chapter_terminal.gd"))
	terminal.position = Vector3(0, 1.1, -8.0)
	terminal.set("record_id", "ending_report")
	terminal.set("record_title", "FINAL REPORT")
	terminal.set("message", message)
	add_child(terminal)
	_add_terminal_visual(terminal)
	_add_box("RescuePlatform", Vector3(0, 0.15, -18), Vector3(8.0, 0.3, 6.0), Color(0.06, 0.16, 0.11), true)
	_add_box("BeaconTower", Vector3(0, 3.0, -18), Vector3(0.5, 5.5, 0.5), accent.darkened(0.35), true, true)
	_add_light(Vector3(0, 4.5, -18), accent)
