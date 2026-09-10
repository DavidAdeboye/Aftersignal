extends StationChapter

const PUZZLE_CONSOLE := preload("res://scripts/puzzle_console.gd")
const DRONE_SCENE := preload("res://scenes/shared/drone.tscn")
const ROUTE := ["coolant", "turbine", "containment"]

var _route_index := 0
var _grid_stable := false

func _build_environment() -> void:
	super._build_environment()
	_add_puzzle_console("CoolantRelay", Vector3(-3.8, 1.0, -11), "coolant", "COOLANT RELAY", Color(0.15, 0.65, 1.0))
	_add_puzzle_console("TurbineRelay", Vector3(3.8, 1.0, -20), "turbine", "TURBINE BUS", Color(1.0, 0.65, 0.1))
	_add_puzzle_console("ContainmentRelay", Vector3(-3.8, 1.0, -29), "containment", "CONTAINMENT GRID", Color(1.0, 0.18, 0.08))
	for z in [-8.0, -16.0, -24.0, -32.0]:
		_add_box("ReactorPipe", Vector3(4.8, 2.4, z), Vector3(0.45, 3.8, 0.45), Color(0.22, 0.08, 0.03), true, true)
		_add_light(Vector3(4.2, 2.8, z), accent)
	var drone := DRONE_SCENE.instantiate()
	drone.name = "ReactorDrone"
	drone.position = Vector3(0, 1.5, -18)
	drone.set("drones_active", true)
	add_child(drone)

func _spawn_players() -> void:
	super._spawn_players()
	for player in $Players.get_children():
		if player.has_method("add_item"):
			player.add_item("signal_disruptor")

func puzzle_action(action_id: String, player: Node) -> void:
	if _grid_stable:
		_notify_player(player, "POWER IS ON. The lift is ready.")
		return
	var expected: String = ROUTE[_route_index]
	if action_id != expected:
		_route_index = 0
		_notify_player(player, "Wrong switch. Start again: COOLANT, then TURBINE, then CONTAINMENT.")
	else:
		_route_index += 1
		_notify_player(player, "Correct switch: %d of 3" % _route_index)
		if _route_index == ROUTE.size():
			_grid_stable = true
	_update_objective()

func can_exit() -> bool:
	return _found.size() >= 3 and _grid_stable

func _update_objective() -> void:
	if _objective_label == null:
		return
	if _found.size() < 3:
		_objective_label.text = "REACTOR: Read the power records (%d/3)" % _found.size()
	elif not _grid_stable:
		_objective_label.text = "REACTOR: Use COOLANT, TURBINE, then CONTAINMENT (%d/3)" % _route_index
	else:
		_objective_label.text = "REACTOR: Power on. Use the lift."

func _add_puzzle_console(node_name: String, pos: Vector3, id: String, title: String, color: Color) -> void:
	var console := StaticBody3D.new()
	console.name = node_name
	console.set_script(PUZZLE_CONSOLE)
	console.position = pos
	console.set("action_id", id)
	console.set("console_title", title)
	add_child(console)
	_add_terminal_visual(console)

func _notify_player(player: Node, text: String) -> void:
	if player and player.has_method("show_message"):
		player.show_message(text)
	else:
		print(text)
