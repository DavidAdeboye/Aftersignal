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
const CORRIDOR_SCENE := preload("res://places/sci-fi_corridor.glb")
const MINE_SCENE := preload("res://places/MineAndCavesSet/LoafbrrAssets/MineAndCavesSet/scenes/Modular_Mine_Set.tscn")
const TERMINAL_MODEL := preload("res://models/terminal_02.glb")

var _found: Dictionary = {}
var _objective_label: Label

func _ready() -> void:
	_build_environment()
	_spawn_players()
	_update_objective()

func _build_environment() -> void:
	_build_asset_environment()
	_add_title_panel()
	_add_records()
	_add_exit()
	_add_hud()
	return
	# Legacy procedural fallback retained below for projects without the packs.
	var floor_color := Color(0.075, 0.085, 0.105)
	var wall_color := Color(0.06, 0.075, 0.095)
	if "RESEARCH" in chapter_title:
		floor_color = Color(0.045, 0.09, 0.12)
		wall_color = Color(0.035, 0.07, 0.1)
	elif "REACTOR" in chapter_title:
		floor_color = Color(0.12, 0.065, 0.035)
		wall_color = Color(0.11, 0.045, 0.025)
	elif "EXCAVATION" in chapter_title:
		floor_color = Color(0.09, 0.075, 0.055)
		wall_color = Color(0.07, 0.06, 0.05)
	elif "CORE" in chapter_title:
		floor_color = Color(0.11, 0.025, 0.04)
		wall_color = Color(0.08, 0.015, 0.025)
	elif "AFTERSIGNAL" in chapter_title:
		floor_color = Color(0.035, 0.11, 0.075)
		wall_color = Color(0.02, 0.075, 0.055)
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

	_add_box("Floor", Vector3(0, -0.25, -room_length * 0.5), Vector3(14, 0.5, room_length), floor_color, true)
	_add_box("Ceiling", Vector3(0, 4.5, -room_length * 0.5), Vector3(14, 0.35, room_length), Color(0.035, 0.045, 0.06), true)
	_add_box("LeftWall", Vector3(-7, 2.1, -room_length * 0.5), Vector3(0.35, 4.5, room_length), wall_color, true)
	_add_box("RightWall", Vector3(7, 2.1, -room_length * 0.5), Vector3(0.35, 4.5, room_length), wall_color, true)
	_add_box("EntryWall", Vector3(0, 2.1, 0), Vector3(14, 4.5, 0.35), Color(0.045, 0.055, 0.075), true)
	_add_box("EndWall", Vector3(0, 2.1, -room_length), Vector3(14, 4.5, 0.35), Color(0.045, 0.055, 0.075), true)

	for z in range(3, int(room_length), 5):
		_add_box("CeilingBeam", Vector3(0, 4.15, -float(z)), Vector3(13.6, 0.18, 0.3), accent.darkened(0.55), false)
		_add_light(Vector3(0, 3.75, -float(z)), accent)
	for side in [-1.0, 1.0]:
		for z in range(5, int(room_length) - 2, 7):
			_add_console_cluster(Vector3(side * 5.35, 0, -float(z)), side < 0)

	_add_title_panel()
	_add_chapter_layout()
	_add_records()
	_add_exit()
	_add_hud()

func _build_asset_environment() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.022, 0.028)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.46, 0.5)
	env.ambient_light_energy = 0.72
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.fog_enabled = true
	env.fog_light_color = Color(0.16, 0.2, 0.22)
	env.fog_density = 0.006
	environment.environment = env
	add_child(environment)

	# The downloaded corridor is a finished, textured environment. Repeat it
	# along the chapter spine and keep a simple invisible floor for gameplay.
	var segment := (MINE_SCENE if "EXCAVATION" in chapter_title else CORRIDOR_SCENE).instantiate()
	segment.name = "ChapterEnvironment"
	if "EXCAVATION" in chapter_title:
		segment.scale = Vector3(1.8, 1.8, 1.8)
	else:
		# The source model opens toward +Z. Turn its entrance toward the
		# player's -Z travel direction and pull its end wall behind spawn.
		segment.rotation_degrees.y = 180.0
		segment.position = Vector3(0, 0, 2.0)
	_disable_imported_collision(segment)
	add_child(segment)
	_add_collision_box("GameplayFloor", Vector3(0, -0.3, -room_length * 0.5), Vector3(14, 0.5, room_length))
	for z in range(3, int(room_length), 6):
		_add_light(Vector3(0, 3.0, -float(z)), Color(0.78, 0.88, 0.92))

func _disable_imported_collision(root: Node) -> void:
	for child in root.get_children():
		if child is CollisionShape3D or child is CollisionPolygon3D:
			child.disabled = true
		_disable_imported_collision(child)

func _add_terminal_visual(root: Node3D, collision_size := Vector3(0.9, 1.4, 0.55)) -> void:
	var model := TERMINAL_MODEL.instantiate()
	model.name = "TerminalModel"
	model.scale = Vector3(0.8, 0.8, 0.8)
	root.add_child(model)
	if root is CollisionObject3D:
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = collision_size
		shape.shape = box_shape
		shape.position.y = 0.7
		root.add_child(shape)

func _add_collision_box(node_name: String, pos: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = pos
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(shape)
	add_child(body)
	return body

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
		_add_terminal_visual(body)

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

func _add_chapter_layout() -> void:
	if "LANDING" in chapter_title:
		# Open hangar composition: a landing pad, ship-frame supports, and
		# separated habitation modules replace the standard corridor rhythm.
		_add_box("LandingPad", Vector3(0, 0.08, -8), Vector3(9.5, 0.16, 8.0), accent.darkened(0.7), true)
		for x in [-5.5, 5.5]:
			_add_box("ShipFrame", Vector3(x, 2.2, -8), Vector3(0.35, 4.4, 8.0), accent.darkened(0.55), true)
		_add_box("HabModuleA", Vector3(-4.4, 1.1, -22), Vector3(4.0, 2.2, 4.0), Color(0.08, 0.1, 0.13), true)
		_add_box("HabModuleB", Vector3(4.4, 1.1, -27), Vector3(4.0, 2.2, 4.0), Color(0.08, 0.1, 0.13), true)
	elif "RESEARCH" in chapter_title:
		# Three enclosed lab rooms joined by narrow central openings.
		for z in [-10.0, -20.0]:
			_add_box("LabPartition", Vector3(0, 2.0, z), Vector3(10.5, 4.0, 0.3), wall_color_for_layout(), true)
			_add_box("LabWindow", Vector3(0, 2.2, z + 0.18), Vector3(5.0, 2.0, 0.08), accent, false, true)
	elif "REACTOR" in chapter_title:
		# A central reactor hall with side gantries and a raised control block.
		_add_box("ReactorHall", Vector3(0, 0.8, -18), Vector3(5.5, 1.6, 20.0), Color(0.08, 0.04, 0.02), true)
		_add_box("ControlGantries", Vector3(-4.8, 2.0, -18), Vector3(2.0, 0.25, 18.0), accent.darkened(0.5), true)
		_add_box("ControlGantries", Vector3(4.8, 2.0, -18), Vector3(2.0, 0.25, 18.0), accent.darkened(0.5), true)
	elif "EXCAVATION" in chapter_title:
		# Uneven cave ribs break the straight station corridor into a tunnel.
		for z in range(6, int(room_length) - 2, 6):
			_add_box("CaveRib", Vector3(-4.8, 2.4, -float(z)), Vector3(1.8, 4.8, 1.0), accent.darkened(0.55), true)
			_add_box("CaveRib", Vector3(4.8, 2.4, -float(z)), Vector3(1.8, 4.8, 1.0), accent.darkened(0.55), true)
	elif "CORE" in chapter_title:
		# A broad circular-feeling arena, with four heavy approach blocks.
		for pos in [Vector3(-5.0, 1.0, -12), Vector3(5.0, 1.0, -12), Vector3(-5.0, 1.0, -24), Vector3(5.0, 1.0, -24)]:
			_add_box("CoreButtress", pos, Vector3(2.0, 2.0, 3.0), accent.darkened(0.65), true)
	elif "AFTERSIGNAL" in chapter_title:
		# Open broadcast deck with a separated beacon approach.
		_add_box("DeckDivider", Vector3(0, 1.5, -10), Vector3(12.0, 3.0, 0.35), accent.darkened(0.6), true)
		_add_box("DeckDivider", Vector3(0, 1.5, -20), Vector3(12.0, 3.0, 0.35), accent.darkened(0.6), true)

func wall_color_for_layout() -> Color:
	return accent.darkened(0.75)

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
