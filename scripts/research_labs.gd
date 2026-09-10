extends StationChapter

var _override_complete := false

func _build_environment() -> void:
	super._build_environment()
	var terminal := StaticBody3D.new()
	terminal.name = "GlyphOverride"
	terminal.set_script(TERMINAL_SCRIPT)
	terminal.position = Vector3(0, 1.1, -20.5)
	terminal.set("record_id", "override")
	terminal.set("record_title", "GLYPH OVERRIDE CONSOLE")
	terminal.set("message", "LAB DOOR LOCKED\n\nRead all three lab records. Then open the drawing pad with G and draw the relay mark. Return here to open the door.")
	add_child(terminal)
	_add_terminal_visual(terminal)
	for z in [-8.0, -16.0, -24.0]:
		_add_box("LabGlassBay", Vector3(0, 2.0, z), Vector3(10.5, 3.2, 0.12), Color(0.05, 0.18, 0.24), false, true)
		_add_box("LabBench", Vector3(-4.6, 0.65, z + 1.0), Vector3(3.5, 0.35, 1.2), Color(0.12, 0.16, 0.18), true)

func record_found(record_id: String) -> void:
	if record_id == "override":
		if _found.size() < 3:
			return
		_override_complete = true
		var local_player := NetworkManager._get_local_player()
		if local_player and local_player.has_method("show_message"):
			local_player.show_message("LAB DOOR OPEN\n\nThe records match. The relay mark is accepted.", 4.0)
		_update_objective()
		return
	super.record_found(record_id)

func can_exit() -> bool:
	return _found.size() >= 3 and _override_complete

func _update_objective() -> void:
	if _objective_label == null:
		return
	if _found.size() < 3:
		_objective_label.text = "RESEARCH LABS // RECOVER RECORDS %d/3" % _found.size()
	elif not _override_complete:
		_objective_label.text = "RESEARCH LABS // COMPLETE THE GLYPH OVERRIDE"
	else:
		_objective_label.text = "RESEARCH LABS // AIRLOCK UNLOCKED"
