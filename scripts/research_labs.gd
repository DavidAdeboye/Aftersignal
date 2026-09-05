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
	terminal.set("message", "GLYPH OVERRIDE REQUIRED\n\nThe lab door will accept a shared symbol only after all three records are reviewed. Open the glyph pad with G, draw the five-point relay mark, then return here and confirm the pattern.")
	add_child(terminal)
	_add_body_visual(terminal, Vector3(1.8, 1.5, 0.4), Color(0.03, 0.11, 0.13), accent)

func record_found(record_id: String) -> void:
	if record_id == "override":
		if _found.size() < 3:
			return
		_override_complete = true
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
