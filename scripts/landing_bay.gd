extends StationChapter

func _build_environment() -> void:
	super._build_environment()
	_add_act1_clues()
	_add_intro_marker()
	_setup_objective_manager()
	var cutscene := preload("res://scripts/story_cutscene.gd").new()
	add_child(cutscene)
	cutscene.play_intro()

func _add_act1_clues() -> void:
	_add_clue("CrewRoster", preload("res://scripts/crew_roster.gd"), Vector3(-4.8, 1.0, -4.0), "CREW ROSTER")
	_add_clue("AccessTerminal", preload("res://scripts/code_display.gd"), Vector3(4.8, 1.0, -7.0), "ACCESS CODE")
	var keypad := _add_clue("Keypad", preload("res://scripts/keypad.gd"), Vector3(-4.8, 1.0, -11.0), "STORAGE KEYPAD")
	keypad.set("correct_code", "4471")
	_add_clue("MissingQuarter12", preload("res://scripts/missing_room_gap.gd"), Vector3(4.8, 1.2, -14.0), "QUARTER 12")
	var log := _add_clue("FarrowLog", preload("res://scripts/readable_log.gd"), Vector3(-4.8, 1.0, -20.0), "DR. FARROW'S LOG")
	log.set("log_title", "DR. FARROW'S LOG")
	log.set("message", "DR. FARROW'S LOG\n\nThe signal under the ice knows our words before we speak. I think it is learning us.")
	log.set("next_objective", "research")

func _add_clue(node_name: String, script: Script, pos: Vector3, label: String) -> Node3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	body.set_script(script)
	add_child(body)
	_add_terminal_visual(body)
	var marker := Label3D.new()
	marker.text = label
	marker.font_size = 24
	marker.modulate = accent
	marker.position = Vector3(0, 1.8, 0)
	body.add_child(marker)
	return body

func _setup_objective_manager() -> void:
	if ObjectiveManager.instance == null:
		var obj_mgr := ObjectiveManager.new()
		obj_mgr.name = "ObjectiveManager"
		add_child(obj_mgr)
	ObjectiveManager.instance.set_objective("Recover the 3 station records, then reach the airlock.")

func _add_intro_marker() -> void:
	var marker := Label3D.new()
	marker.name = "IntroPrompt"
	marker.text = "Recover the station records.\nFind the airlock when ready."
	marker.font_size = 18
	marker.modulate = accent
	marker.outline_size = 6
	marker.position = Vector3(0, 2.6, -5.0)
	marker.pixel_size = 0.006
	add_child(marker)
