extends StationChapter

const PUZZLE_CONSOLE := preload("res://scripts/puzzle_console.gd")
const DRONE_SCENE := preload("res://scenes/shared/drone.tscn")

var _relays: Dictionary = {}
var _ending_choice := ""

func _build_environment() -> void:
	super._build_environment()
	_add_core_visual()
	for angle in range(0, 360, 45):
		var rad := deg_to_rad(float(angle))
		var pillar := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 0.22
		mesh.bottom_radius = 0.5
		mesh.height = 4.0
		pillar.mesh = mesh
		pillar.position = Vector3(cos(rad) * 5.2, 2.0, -16.0 + sin(rad) * 5.2)
		pillar.material_override = _core_material()
		add_child(pillar)
	for data in [["relay_a", -4.5, -12.0], ["relay_b", 4.5, -18.0], ["relay_c", -4.5, -24.0]]:
		_add_console(str(data[0]), Vector3(float(data[1]), 1.0, float(data[2])), str(data[0]).to_upper())
	for data in [["awaken", -3.8], ["seal", 0.0], ["communicate", 3.8]]:
		_add_console(str(data[0]), Vector3(float(data[1]), 1.0, -28.5), str(data[0]).to_upper())
	for i in 2:
		var drone := DRONE_SCENE.instantiate()
		drone.name = "CoreDrone%d" % (i + 1)
		drone.position = Vector3(-3.0 if i == 0 else 3.0, 1.5, -15.0 - i * 6.0)
		drone.set("drones_active", true)
		drone.set("chase_speed", 2.8)
		add_child(drone)

func _spawn_players() -> void:
	super._spawn_players()
	for player in $Players.get_children():
		if player.has_method("add_item"):
			player.add_item("signal_disruptor")
			player.add_item("welding_torch")

func puzzle_action(action_id: String, player: Node) -> void:
	if action_id.begins_with("relay_"):
		_relays[action_id] = true
		_notify_player(player, "CORE STABILIZER ONLINE %d/3" % _relays.size())
	elif action_id in ["awaken", "seal", "communicate"]:
		if _relays.size() < 3 or _found.size() < 3:
			_notify_player(player, "ENDING CONTROL LOCKED: stabilize all relays and recover the final records.")
			return
		_ending_choice = action_id
		PuzzleState.mark_puzzle_solved("ending_" + action_id)
		_notify_player(player, "FINAL COMMAND ACCEPTED: " + action_id.to_upper())
		for drone in get_tree().get_nodes_in_group("drones"):
			drone.set("drones_active", false)
	_update_objective()

func can_exit() -> bool:
	return _found.size() >= 3 and _relays.size() >= 3 and not _ending_choice.is_empty()

func _update_objective() -> void:
	if _objective_label == null:
		return
	if _found.size() < 3:
		_objective_label.text = "THE CORE // RECOVER FINAL RECORDS %d/3" % _found.size()
	elif _relays.size() < 3:
		_objective_label.text = "THE CORE // STABILIZE RELAYS %d/3 - DRONES ACTIVE" % _relays.size()
	elif _ending_choice.is_empty():
		_objective_label.text = "THE CORE // CHOOSE: AWAKEN, SEAL, OR COMMUNICATE"
	else:
		_objective_label.text = "THE CORE // %s ENDING LOCKED - EVACUATE" % _ending_choice.to_upper()

func _add_console(id: String, pos: Vector3, title: String) -> void:
	var console := StaticBody3D.new()
	console.name = title.capitalize().replace(" ", "")
	console.set_script(PUZZLE_CONSOLE)
	console.position = pos
	console.set("action_id", id)
	console.set("console_title", title)
	add_child(console)
	var color := accent if id.begins_with("relay_") else Color(0.25, 0.9, 0.65)
	_add_terminal_visual(console)

func _add_core_visual() -> void:
	var core := MeshInstance3D.new()
	core.name = "AnomalyCore"
	var sphere := SphereMesh.new()
	sphere.radius = 2.1
	sphere.height = 4.2
	core.mesh = sphere
	core.position = Vector3(0, 2.2, -16)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.01, 0.015)
	mat.emission_enabled = true
	mat.emission = accent
	mat.emission_energy_multiplier = 3.5
	core.material_override = mat
	add_child(core)

func _core_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.015, 0.025)
	mat.emission_enabled = true
	mat.emission = accent
	mat.emission_energy_multiplier = 2.0
	return mat

func _notify_player(player: Node, text: String) -> void:
	if player and player.has_method("show_message"):
		player.show_message(text)
	else:
		print(text)
