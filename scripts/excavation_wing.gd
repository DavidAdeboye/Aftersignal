extends StationChapter

const PUZZLE_CONSOLE := preload("res://scripts/puzzle_console.gd")
const JAMMER_SCRIPT := preload("res://scripts/signal_jammer.gd")
const FRAGMENT_ORDER := ["farrow", "bray", "surge"]

var _fragment_index := 0
var _recorder_complete := false

func _build_environment() -> void:
	super._build_environment()
	for data in [["bray", -12.0, -4.2], ["surge", -22.0, 4.2], ["farrow", -32.0, -4.2]]:
		_add_fragment(str(data[0]), Vector3(float(data[2]), 1.0, float(data[1])))
	for z in [-14.0, -27.0]:
		var jammer := Node3D.new()
		jammer.name = "CrystalJammer"
		jammer.set_script(JAMMER_SCRIPT)
		jammer.position = Vector3(0, 1.0, z)
		jammer.set("radius", 5.5)
		jammer.set("jam_strength", 0.75)
		add_child(jammer)
		_add_crystal_cluster(jammer)

func puzzle_action(action_id: String, player: Node) -> void:
	if _recorder_complete:
		_notify_player(player, "The flight recorder is complete. You know who caused the blackout.")
		return
	var expected: String = FRAGMENT_ORDER[_fragment_index]
	if action_id != expected:
		_fragment_index = 0
		_notify_player(player, "Wrong order. Try FARROW, then BRAY, then SURGE.")
	else:
		_fragment_index += 1
		_notify_player(player, "Recorder piece found: %d of 3" % _fragment_index)
		if _fragment_index == FRAGMENT_ORDER.size():
			_recorder_complete = true
	_update_objective()

func can_exit() -> bool:
	return _found.size() >= 3 and _recorder_complete

func _update_objective() -> void:
	if _objective_label == null:
		return
	if _found.size() < 3:
		_objective_label.text = "EXCAVATION // RECOVER FLIGHT LOGS %d/3" % _found.size()
	elif not _recorder_complete:
		_objective_label.text = "EXCAVATION // REBUILD BLACK BOX (%d/3)" % _fragment_index
	else:
		_objective_label.text = "EXCAVATION // BLACK BOX COMPLETE - CORE ACCESS OPEN"

func _add_fragment(id: String, pos: Vector3) -> void:
	var console := StaticBody3D.new()
	console.name = id.capitalize() + "Fragment"
	console.set_script(PUZZLE_CONSOLE)
	console.position = pos
	console.set("action_id", id)
	console.set("console_title", id.to_upper() + " FRAGMENT")
	add_child(console)
	_add_terminal_visual(console)

func _add_crystal_cluster(root: Node3D) -> void:
	for x in [-1.0, 0.0, 1.0]:
		var crystal := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.0
		mesh.bottom_radius = 0.35
		mesh.height = 2.0 + abs(x)
		crystal.mesh = mesh
		crystal.position = Vector3(x, mesh.height * 0.5, 0)
		crystal.rotation_degrees.z = x * 18.0
		var mat := StandardMaterial3D.new()
		mat.albedo_color = accent.darkened(0.25)
		mat.emission_enabled = true
		mat.emission = accent
		mat.emission_energy_multiplier = 2.2
		crystal.material_override = mat
		root.add_child(crystal)

func _notify_player(player: Node, text: String) -> void:
	if player and player.has_method("show_message"):
		player.show_message(text)
	else:
		print(text)
