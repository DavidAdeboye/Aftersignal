extends Node3D
class_name StationChapter

@export var chapter_title := "RESEARCH LABS"
@export var chapter_subtitle := "ACT II"
@export var accent := Color(0.15, 0.75, 1.0)
@export var room_length := 34.0
@export_file("*.tscn") var next_scene_path := ""
@export var records: Array[String] = []

const PLAYER_SCENE := preload("res://scenes/shared/player.tscn")
const TERMINAL_SCRIPT := preload("res://scripts/chapter_terminal.gd")
const EXIT_SCRIPT := preload("res://scripts/chapter_exit.gd")

var _found: Dictionary = {}
var _objective_label: Label

func _ready() -> void:
	_build_environment()
	_spawn_players()
	_update_objective()

func _build_environment() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.006, 0.01, 0.018)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.18, 0.22, 0.3)
	env.ambient_light_energy = 0.42
	env.fog_enabled = true
	env.fog_light_color = accent.darkened(0.65)
	env.fog_density = 0.012
	environment.environment = env
	add_child(environment)

	_add_box("Floor", Vector3(0, -0.25, -room_length * 0.5), Vector3(14, 0.5, room_length), Color(0.075, 0.085, 0.105), true)
	_add_box("Ceiling", Vector3(0, 4.5, -room_length * 0.5), Vector3(14, 0.35, room_length), Color(0.035, 0.045, 0.06), true)
	_add_box("LeftWall", Vector3(-7, 2.1, -room_length * 0.5), Vector3(0.35, 4.5, room_length), Color(0.06, 0.075, 0.095), true)
	_add_box("RightWall", Vector3(7, 2.1, -room_length * 0.5), Vector3(0.35, 4.5, room_length), Color(0.06, 0.075, 0.095), true)
	_add_box("EntryWall", Vector3(0, 2.1, 0), Vector3(14, 4.5, 0.35), Color(0.045, 0.055, 0.075), true)
	_add_box("EndWall", Vector3(0, 2.1, -room_length), Vector3(14, 4.5, 0.35), Color(0.045, 0.055, 0.075), true)

	for z in range(3, int(room_length), 5):
		_add_box("CeilingBeam", Vector3(0, 4.15, -float(z)), Vector3(13.6, 0.18, 0.3), accent.darkened(0.55), false)
		_add_light(Vector3(0, 3.75, -float(z)), accent)
	for side in [-1.0, 1.0]:
		for z in range(5, int(room_length) - 2, 7):
			_add_console_cluster(Vector3(side * 5.35, 0, -float(z)), side < 0)

	_add_title_panel()
	_add_records()
	_add_exit()
	_add_hud()

func _add_console_cluster(pos: Vector3, face_right: bool) -> void:
	_add_box("Workstation", pos + Vector3(0, 0.55, 0), Vector3(2.2, 1.1, 0.8), Color(0.09, 0.105, 0.125), true)
	_add_box("Screen", pos + Vector3(0, 1.25, -0.28), Vector3(1.45, 0.75, 0.12), accent.darkened(0.25), false, true)
	_add_box("SupplyCrate", pos + Vector3(0.8 if face_right else -0.8, 0.35, 1.15), Vector3(0.75, 0.7, 0.75), Color(0.18, 0.15, 0.08), true)

func _add_records() -> void:
	var positions := [Vector3(-5.65, 1.1, -8), Vector3(5.65, 1.1, -17), Vector3(-5.65, 1.1, -26)]
	for i in 3:
		var body := StaticBody3D.new()
		body.name = "RecordTerminal%d" % (i + 1)
		body.set_script(TERMINAL_SCRIPT)
		body.position = positions[i]
		body.set("record_id", "record_%d" % i)
		body.set("record_title", "%s // RECORD %02d" % [chapter_title, i + 1])
		body.set("message", records[i] if i < records.size() else "The archive is damaged, but the signal persists beneath the ice.")
		add_child(body)
		_add_body_visual(body, Vector3(1.15, 1.5, 0.35), Color(0.04, 0.08, 0.11), accent)

func _add_exit() -> void:
	var exit := StaticBody3D.new()
	exit.name = "ChapterAirlock"
	exit.set_script(EXIT_SCRIPT)
	exit.position = Vector3(0, 1.35, -room_length + 0.4)
	exit.set("next_scene_path", next_scene_path)
	add_child(exit)
	_add_body_visual(exit, Vector3(3.2, 2.7, 0.3), Color(0.08, 0.1, 0.12), accent)

func _add_title_panel() -> void:
	var label := Label3D.new()
	label.text = chapter_subtitle + "\n" + chapter_title
	label.font_size = 72
	label.modulate = accent
	label.outline_size = 8
	label.position = Vector3(0, 2.5, -0.3)
	label.rotation_degrees = Vector3(0, 180, 0)
	label.pixel_size = 0.008
	add_child(label)

func _add_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_objective_label = Label.new()
	_objective_label.position = Vector2(24, 24)
	_objective_label.add_theme_font_size_override("font_size", 16)
	_objective_label.add_theme_color_override("font_color", accent)
	layer.add_child(_objective_label)

func _add_light(pos: Vector3, color: Color) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = 2.2
	light.omni_range = 7.0
	light.shadow_enabled = false
	add_child(light)

func _add_box(node_name: String, pos: Vector3, size: Vector3, color: Color, collision: bool, emission := false) -> Node3D:
	var root: Node3D = StaticBody3D.new() if collision else Node3D.new()
	root.name = node_name
	root.position = pos
	add_child(root)
	_add_body_visual(root, size, color, color if emission else Color.BLACK, collision)
	return root

func _add_body_visual(root: Node3D, size: Vector3, color: Color, emission: Color, collision := true) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.55
	material.roughness = 0.42
	if emission != Color.BLACK:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = 2.4
	mesh.material_override = material
	root.add_child(mesh)
	if collision and root is CollisionObject3D:
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = size
		shape.shape = box_shape
		root.add_child(shape)

func _spawn_players() -> void:
	var players := Node3D.new()
	players.name = "Players"
	add_child(players)
	if multiplayer.has_multiplayer_peer():
		if multiplayer.is_server():
			NetworkManager.players_node = players
			NetworkManager._spawn_player(multiplayer.get_unique_id())
	else:
		var player := PLAYER_SCENE.instantiate()
		player.name = "1"
		player.position = Vector3(0, 1.0, -2.5)
		players.add_child(player)

func record_found(record_id: String) -> void:
	_found[record_id] = true
	_update_objective()

func can_exit() -> bool:
	return _found.size() >= 3

func _update_objective() -> void:
	if _objective_label == null:
		return
	if can_exit():
		_objective_label.text = "%s // AIRLOCK UNLOCKED" % chapter_title
	else:
		_objective_label.text = "%s // RECOVER RECORDS %d/3" % [chapter_title, _found.size()]
