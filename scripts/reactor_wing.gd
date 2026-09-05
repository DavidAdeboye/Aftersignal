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
		_notify_player(player, "POWER GRID STABLE: excavation lift power restored.")
		return
	var expected: String = ROUTE[_route_index]
	if action_id != expected:
		_route_index = 0
		_notify_player(player, "ROUTING FAULT: sequence reset. Follow COOLANT > TURBINE > CONTAINMENT.")
	else:
		_route_index += 1
		_notify_player(player, "RELAY ACCEPTED %d/3" % _route_index)
		if _route_index == ROUTE.size():
			_grid_stable = true
	_update_objective()

func can_exit() -> bool:
	return _found.size() >= 3 and _grid_stable

func _update_objective() -> void:
	if _objective_label == null:
		return
	if _found.size() < 3:
		_objective_label.text = "REACTOR // RECOVER GRID RECORDS %d/3" % _found.size()
	elif not _grid_stable:
		_objective_label.text = "REACTOR // ROUTE COOLANT > TURBINE > CONTAINMENT (%d/3)" % _route_index
	else:
		_objective_label.text = "REACTOR // GRID STABLE - LIFT UNLOCKED"

func _add_puzzle_console(node_name: String, pos: Vector3, id: String, title: String, color: Color) -> void:
	var console := StaticBody3D.new()
	console.name = node_name
	console.set_script(PUZZLE_CONSOLE)
	console.position = pos
	console.set("action_id", id)
	console.set("console_title", title)
	add_child(console)
	_add_body_visual(console, Vector3(1.5, 1.6, 0.45), Color(0.04, 0.05, 0.07), color)

func _notify_player(player: Node, text: String) -> void:
	if player and player.has_method("show_message"):
		player.show_message(text)
	else:
		print(text)
