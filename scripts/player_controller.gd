extends CharacterBody3D
## First-person controller — Aftersignal
## Attach this script to a CharacterBody3D root that has:
##   - CollisionShape3D (capsule, matching a human-ish height)
##   - A Node3D called "Head" as a child, with a Camera3D as its child
##   - Camera3D should have a RayCast3D child pointed forward (Z: -3)
##   - A MeshInstance3D (capsule) for the visible body
##   - A MultiplayerSynchronizer syncing position and rotation
## Head handles vertical look (pitch); the body handles horizontal look (yaw).

@export var walk_speed: float = 3.5
@export var mouse_sensitivity: float = 0.0025
@export var jump_velocity: float = 4.5
@export var clear_range: float = 2.0
@export var chat_range: float = 5.0
var in_chat_range: bool = false
var signal_quality: float = 0.0

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var interact_ray: RayCast3D = $Head/Camera3D/RayCast3D
@onready var interact_prompt: Label = $CanvasLayer/InteractPrompt
@onready var chat_input: LineEdit = $CanvasLayer/ChatInput
@onready var chat_log: RichTextLabel = $CanvasLayer/ChatLog
@onready var signal_indicator: Label = $CanvasLayer/SignalIndicator
@onready var keypad_input: LineEdit = $CanvasLayer/KeypadInput
@onready var message_panel: PanelContainer = $CanvasLayer/MessagePanel
@onready var message_label: Label = $CanvasLayer/MessagePanel/MessageLabel
@onready var glyph_pad: Control = $CanvasLayer/GlyphPad

var _message_timer: SceneTreeTimer = null

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_interactable: Interactable = null
var current_door_body: Node = null
var active_keypad: Node = null
var static_rect: ColorRect = null
var inventory: Dictionary = {}
var inventory_label: Label = null

var spawn_points: Array = [Vector3(-2, 1, 13), Vector3(2, 1, 13)]
var spawn_colors: Array = [Color(0.15, 0.55, 0.95), Color(0.95, 0.45, 0.15)]
var spawn_index: int = 0
var chat_lines: Array[String] = []

# Combat Prototyping & Tools
var owned_tools: Dictionary = {
	"welding_torch": false,
	"signal_disruptor": false,
	"scanner_attachment": false
}
var equipped_tool: String = ""
var disruptor_charges: int = 5
var is_ko: bool = false
var active_beams: Array[Dictionary] = []
var welding_cooldown: float = 0.0
var disruptor_cooldown: float = 0.0
var disruptor_recharge_timer: float = 0.0
var scanner_retention_timer: float = 0.0

# HUD Overlays
var tool_indicator: Label = null
var scanner_display: PanelContainer = null
var scanner_label: RichTextLabel = null
var blackout_rect: ColorRect = null

# 3D Tool meshes & Drawers
var tool_holder: Node3D = null
var torch_mesh: MeshInstance3D = null
var torch_light: OmniLight3D = null
var disruptor_mesh: MeshInstance3D = null
var disruptor_light: OmniLight3D = null
var scanner_mesh: MeshInstance3D = null
var path_drawer: MeshInstance3D = null
var line_material: StandardMaterial3D = null


func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))


func _ready() -> void:
	spawn_index = 0 if int(str(name)) == 1 else 1
	position = spawn_points[spawn_index]

	var mesh_instance: MeshInstance3D = $MeshInstance3D
	var material := StandardMaterial3D.new()
	material.albedo_color = spawn_colors[spawn_index]
	mesh_instance.set_surface_override_material(0, material)

	if not is_multiplayer_authority():
		$CanvasLayer.visible = false
	else:
		_setup_static_overlay()
		_setup_inventory_hud()
		_setup_combat_systems()
		_setup_hud_mouse_filters()

	keypad_input.text_submitted.connect(_on_keypad_submitted)

	call_deferred("_setup_local_player")


func _setup_local_player() -> void:
	if not is_multiplayer_authority():
		return
	camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
	if is_ko:
		return

	if event is InputEventMouseButton and event.pressed:
		if not chat_input.visible and not keypad_input.visible and (glyph_pad == null or not glyph_pad.visible):
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if is_ko:
		return

	if event.is_action_pressed("select_tool_1") and owned_tools.get("welding_torch", false):
		_equip_tool("welding_torch")
	elif event.is_action_pressed("select_tool_2") and owned_tools.get("signal_disruptor", false):
		_equip_tool("signal_disruptor")
	elif event.is_action_pressed("select_tool_3") and owned_tools.get("scanner_attachment", false):
		_equip_tool("scanner_attachment")

	if event.is_action_pressed("use_tool") and equipped_tool != "":
		_use_equipped_tool()

	if event.is_action_pressed("toggle_chat") and in_chat_range and not chat_input.visible:
		chat_input.visible = true
		chat_input.grab_focus()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Glyph sketch pad — toggle the shared drawing device on/off.
	if event.is_action_pressed("toggle_glyph") and not chat_input.visible and not keypad_input.visible:
		_toggle_glyph_pad()

	if glyph_pad and glyph_pad.visible and event is InputEventKey and event.pressed and event.keycode == KEY_C:
		NetworkManager.clear_glyphs.rpc()

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event.is_action_pressed("interact"):
		if current_interactable:
			if current_interactable.has_method("check_code"):
				active_keypad = current_interactable
				keypad_input.visible = true
				keypad_input.grab_focus()
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				current_interactable.interact(self)
		elif current_door_body:
			var door: Node = current_door_body.get("door")
			if door:
				NetworkManager.toggle_door.rpc(door.get_path())


func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return

	if is_ko:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Decrement cooldowns
	if welding_cooldown > 0.0:
		welding_cooldown -= delta
	if disruptor_cooldown > 0.0:
		disruptor_cooldown -= delta

	# Passive Signal Disruptor cell/battery recharge
	if owned_tools.get("signal_disruptor", false) and disruptor_charges < 5:
		disruptor_recharge_timer += delta
		if disruptor_recharge_timer >= 12.0:
			disruptor_charges += 1
			disruptor_recharge_timer = 0.0
			_update_tool_hud()

	# Handle controller look (right stick)
	var look_dir := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if look_dir.length_squared() > 0.0:
		# Map rotation based on stick deflection, delta-time, mouse_sensitivity, and controller speed scalar
		var controller_sensitivity := 15.0
		rotate_y(-look_dir.x * mouse_sensitivity * controller_sensitivity * delta * 60.0)
		head.rotate_x(-look_dir.y * mouse_sensitivity * controller_sensitivity * delta * 60.0)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-85), deg_to_rad(85))

	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * walk_speed
		velocity.z = direction.z * walk_speed
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed)
		velocity.z = move_toward(velocity.z, 0, walk_speed)

	move_and_slide()
	_update_interactable()
	_update_chat_range()

	if global_position.y < -20:
		global_position = spawn_points[spawn_index]
		velocity = Vector3.ZERO

	# Update active beams
	for i in range(active_beams.size() - 1, -1, -1):
		active_beams[i]["time"] -= delta
		if active_beams[i]["time"] <= 0.0:
			active_beams.remove_at(i)

	_process_scanner(delta)
	_draw_scanner_paths()


func _update_chat_range() -> void:
	if not is_multiplayer_authority():
		return
	var other := _get_other_player()
	if other:
		var distance := global_position.distance_to(other.global_position)
		in_chat_range = distance <= chat_range

		if distance <= clear_range:
			signal_quality = 1.0
		elif distance <= chat_range:
			signal_quality = 1.0 - ((distance - clear_range) / (chat_range - clear_range))
		else:
			signal_quality = 0.0

		# Radio dead-zones (SignalJammer nodes) further degrade the signal while
		# either player stands inside them — forcing the pair to relocate for a
		# clean channel. We apply the worst jam affecting EITHER player, since a
		# radio link is only as good as its weakest end.
		var jam := _worst_jam_multiplier(global_position)
		jam = min(jam, _worst_jam_multiplier(other.global_position))
		signal_quality *= jam
		if signal_quality <= 0.0:
			in_chat_range = false
	else:
		in_chat_range = false
		signal_quality = 0.0

	# Update screen static overlay based on local jamming
	if static_rect and static_rect.material:
		var local_jam := 1.0 - _worst_jam_multiplier(global_position)
		static_rect.material.set_shader_parameter("static_intensity", local_jam)

	_update_signal_indicator()


## Returns the strongest jam multiplier (lowest value) affecting a world point,
## by polling every registered SignalJammer. 1.0 = no jamming here.
func _worst_jam_multiplier(world_pos: Vector3) -> float:
	var worst := 1.0
	for jammer in get_tree().get_nodes_in_group("signal_jammers"):
		if jammer.has_method("signal_multiplier_for"):
			worst = min(worst, jammer.signal_multiplier_for(world_pos))
	return worst


func _update_signal_indicator() -> void:
	if not in_chat_range:
		signal_indicator.text = ""
	elif signal_quality > 0.75:
		signal_indicator.text = "Signal: Strong"
	elif signal_quality > 0.35:
		signal_indicator.text = "Signal: Weak"
	else:
		signal_indicator.text = "Signal: Static"


func _update_interactable() -> void:
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()
		if collider is Interactable:
			current_interactable = collider
			current_door_body = null
			interact_prompt.text = collider.prompt_text if collider.prompt_text != "" else "Press E to interact"
			interact_prompt.visible = collider.prompt_text != ""
			return
		if collider is QuaterniusDoorBody:
			current_door_body = collider
			current_interactable = null
			var door_node: Node = collider.get("door")
			if door_node and "opened" in door_node:
				interact_prompt.text = "Press E to close" if door_node.opened else "Press E to open"
			else:
				interact_prompt.text = "Press E to open"
			interact_prompt.visible = true
			return

	current_interactable = null
	current_door_body = null
	interact_prompt.visible = false


func _get_other_player() -> Node3D:
	var players_node := get_parent()
	for child in players_node.get_children():
		if child != self and child is CharacterBody3D:
			return child
	return null


func _on_chat_submitted(text: String) -> void:
	chat_input.visible = false
	chat_input.text = ""
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if text.strip_edges() != "":
		var garbled: String = _garble_text(text, signal_quality)
		var player_label: String = "Player " + str(spawn_index + 1)
		var color: Color = spawn_colors[spawn_index]
		var hex: String = color.to_html(false)
		NetworkManager.receive_chat_message.rpc("[color=#" + hex + "]" + player_label + ":[/color] " + garbled)


func _append_chat_line(formatted_text: String) -> void:
	chat_lines.append(formatted_text)
	if chat_lines.size() > 8:
		chat_lines.pop_front()
	chat_log.text = "\n".join(chat_lines)


func _garble_text(text: String, quality: float) -> String:
	if quality >= 1.0:
		return text
	var result: String = ""
	for character in text:
		if character == " " or randf() <= quality:
			result += character
		else:
			result += "-"
	return result


func _on_keypad_submitted(text: String) -> void:
	if active_keypad and not active_keypad.check_code(text.strip_edges()):
		keypad_input.modulate = Color.RED
		await get_tree().create_timer(0.3).timeout
		keypad_input.modulate = Color.WHITE
		keypad_input.text = ""
		return
	keypad_input.visible = false
	keypad_input.text = ""
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	active_keypad = null
	show_message("Access granted. Door unlocked.")


# ============================================================================
#  GLYPH SKETCH PAD (shared drawing relay)
# ============================================================================

## Opens/closes the handheld sketch pad. While open the mouse is freed so the
## player can draw; closing it recaptures the mouse for look controls.
func _toggle_glyph_pad() -> void:
	if glyph_pad == null:
		return
	var should_show := not glyph_pad.visible
	glyph_pad.visible = should_show
	if should_show:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Called by NetworkManager when the partner draws a stroke on their pad.
func receive_glyph_stroke(stroke: PackedVector2Array) -> void:
	if glyph_pad and glyph_pad.has_method("receive_remote_stroke"):
		glyph_pad.receive_remote_stroke(stroke)


## Called by NetworkManager when a shared "clear" is broadcast.
func clear_glyph_pad() -> void:
	if glyph_pad and glyph_pad.has_method("clear_all"):
		glyph_pad.clear_all()


## Shows a message on this player's HUD for a few seconds. Called by
## interactables (logs, code displays, pickups) and by puzzle feedback.
## Safe to call on non-authoritative instances — it just no-ops there.
func show_message(text: String, duration: float = 4.0) -> void:
	if not is_multiplayer_authority():
		return
	if message_label == null or message_panel == null:
		return
	message_label.text = text
	message_panel.visible = true
	_message_timer = get_tree().create_timer(duration)
	var timer_ref := _message_timer
	await timer_ref.timeout
	# Only hide if no newer message replaced this one in the meantime.
	if _message_timer == timer_ref:
		message_panel.visible = false


func _setup_static_overlay() -> void:
	static_rect = ColorRect.new()
	static_rect.name = "SignalStaticOverlay"
	static_rect.anchors_preset = Control.PRESET_FULL_RECT
	static_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var shader := Shader.new()
	shader.code = """shader_type canvas_item;

uniform float static_intensity : hint_range(0.0, 1.0) = 0.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;

float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
	vec4 color = texture(screen_texture, SCREEN_UV);
	float noise = random(SCREEN_UV + vec2(TIME * 11.7, TIME * 7.3));
	vec3 noise_rgb = vec3(noise);
	COLOR = mix(color, vec4(noise_rgb, 1.0), static_intensity * 0.12);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	static_rect.material = material
	$CanvasLayer.add_child(static_rect)


# ============================================================================
#  INVENTORY (simple string-key bag)
# ============================================================================

func add_item(item_id: String) -> void:
	if item_id in ["welding_torch", "signal_disruptor", "scanner_attachment"]:
		owned_tools[item_id] = true
		var name_map = {
			"welding_torch": "Welding Torch (Key 1)",
			"signal_disruptor": "Signal Disruptor (Key 2)",
			"scanner_attachment": "Scanner Attachment (Key 3)"
		}
		show_message("Acquired: " + name_map[item_id])
		if equipped_tool == "":
			_equip_tool(item_id)
	else:
		inventory[item_id] = true
	_update_inventory_hud()


func has_item(item_id: String) -> bool:
	return inventory.has(item_id)


func remove_item(item_id: String) -> void:
	inventory.erase(item_id)
	_update_inventory_hud()


func _setup_inventory_hud() -> void:
	inventory_label = Label.new()
	inventory_label.name = "InventoryHUD"
	inventory_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inventory_label.anchors_preset = Control.PRESET_BOTTOM_LEFT
	inventory_label.offset_left = 20.0
	inventory_label.offset_top = -40.0
	inventory_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	inventory_label.text = "Items: None"
	
	# Simple styled theme overlay background for the HUD items
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.1, 0.7)
	sb.set_content_margin_all(6.0)
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	inventory_label.add_theme_stylebox_override("normal", sb)
	
	$CanvasLayer.add_child(inventory_label)


func _update_inventory_hud() -> void:
	if inventory_label == null:
		return
	if inventory.is_empty():
		inventory_label.text = "Items: None"
	else:
		var item_names := []
		for id in inventory.keys():
			var formatted = id.replace("_", " ").capitalize()
			item_names.append(formatted)
		inventory_label.text = "Items: " + ", ".join(item_names)


# ============================================================================
#  COMBAT & REPURPOSED TOOLS PROTOTYPING
# ============================================================================

func _setup_combat_systems() -> void:
	# 1. Register input mapping programmatically
	_ensure_input_action("select_tool_1", KEY_1)
	_ensure_input_action("select_tool_2", KEY_2)
	_ensure_input_action("select_tool_3", KEY_3)
	
	if not InputMap.has_action("use_tool"):
		InputMap.add_action("use_tool")
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		InputMap.action_add_event("use_tool", event)

	# 2. Build Tool holder & 3D visual placeholders
	tool_holder = Node3D.new()
	tool_holder.name = "ToolHolder"
	camera.add_child(tool_holder)
	
	# Welding Torch Mesh: Cylinder
	torch_mesh = MeshInstance3D.new()
	torch_mesh.name = "WeldingTorchMesh"
	var torch_geom = CylinderMesh.new()
	torch_geom.top_radius = 0.04
	torch_geom.bottom_radius = 0.04
	torch_geom.height = 0.35
	torch_mesh.mesh = torch_geom
	
	var torch_mat = StandardMaterial3D.new()
	torch_mat.albedo_color = Color(0.2, 0.6, 0.95) # Cyan-blue gas cylinder
	torch_mat.metallic = 0.8
	torch_mat.roughness = 0.2
	torch_mesh.material_override = torch_mat
	
	torch_mesh.position = Vector3(0.25, -0.22, -0.45)
	torch_mesh.rotation_degrees = Vector3(-80, 15, 0)
	torch_mesh.visible = false
	tool_holder.add_child(torch_mesh)
	
	# Torch tip fire-light
	torch_light = OmniLight3D.new()
	torch_light.light_color = Color(0.1, 0.7, 1.0)
	torch_light.light_energy = 0.0
	torch_light.omni_range = 3.0
	torch_light.position = Vector3(0, 0.2, 0)
	torch_mesh.add_child(torch_light)

	# Signal Disruptor Mesh: Box
	disruptor_mesh = MeshInstance3D.new()
	disruptor_mesh.name = "SignalDisruptorMesh"
	var disrupt_geom = BoxMesh.new()
	disrupt_geom.size = Vector3(0.1, 0.1, 0.4)
	disruptor_mesh.mesh = disrupt_geom
	
	var disrupt_mat = StandardMaterial3D.new()
	disrupt_mat.albedo_color = Color(0.9, 0.3, 0.15) # Safety orange
	disrupt_mat.metallic = 0.5
	disrupt_mat.roughness = 0.4
	disruptor_mesh.material_override = disrupt_mat
	
	disruptor_mesh.position = Vector3(0.25, -0.22, -0.45)
	disruptor_mesh.rotation_degrees = Vector3(-10, 5, 0)
	disruptor_mesh.visible = false
	tool_holder.add_child(disruptor_mesh)
	
	# Disruptor tip beam-light
	disruptor_light = OmniLight3D.new()
	disruptor_light.light_color = Color(1.0, 0.35, 0.1)
	disruptor_light.light_energy = 0.0
	disruptor_light.omni_range = 4.0
	disruptor_light.position = Vector3(0, 0, -0.25)
	disruptor_mesh.add_child(disruptor_light)

	# Scanner Mesh: Flat plate/box
	scanner_mesh = MeshInstance3D.new()
	scanner_mesh.name = "ScannerMesh"
	var scanner_geom = BoxMesh.new()
	scanner_geom.size = Vector3(0.2, 0.15, 0.02)
	scanner_mesh.mesh = scanner_geom
	
	var scanner_mat = StandardMaterial3D.new()
	scanner_mat.albedo_color = Color(0.08, 0.4, 0.18) # Military Green
	scanner_mat.roughness = 0.7
	scanner_mesh.material_override = scanner_mat
	
	scanner_mesh.position = Vector3(0.2, -0.18, -0.38)
	scanner_mesh.rotation_degrees = Vector3(-35, 20, -10)
	scanner_mesh.visible = false
	tool_holder.add_child(scanner_mesh)

	# 3. Path Drawer & beam line materials
	path_drawer = MeshInstance3D.new()
	path_drawer.name = "PathDrawer"
	path_drawer.mesh = ImmediateMesh.new()
	add_child(path_drawer)
	
	line_material = StandardMaterial3D.new()
	line_material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	line_material.albedo_color = Color(0.0, 0.85, 1.0)
	line_material.use_point_size = true
	line_material.point_size = 3.0

	# 4. CanvasLayer HUD setups
	# Tool indicator label
	tool_indicator = Label.new()
	tool_indicator.name = "ToolIndicator"
	tool_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tool_indicator.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	tool_indicator.offset_right = -20.0
	tool_indicator.offset_top = -40.0
	tool_indicator.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	tool_indicator.grow_vertical = Control.GROW_DIRECTION_BEGIN
	tool_indicator.text = "Held Tool: None"
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.1, 0.7)
	sb.set_content_margin_all(6.0)
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	tool_indicator.add_theme_stylebox_override("normal", sb)
	$CanvasLayer.add_child(tool_indicator)
	
	# Scanner targeted info panel
	scanner_display = PanelContainer.new()
	scanner_display.name = "ScannerDisplay"
	scanner_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scanner_display.anchors_preset = Control.PRESET_CENTER_RIGHT
	scanner_display.offset_right = -40.0
	scanner_display.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	scanner_display.grow_vertical = Control.GROW_DIRECTION_BOTH
	scanner_display.visible = false
	
	var sb_scan = StyleBoxFlat.new()
	sb_scan.bg_color = Color(0.02, 0.15, 0.06, 0.85)
	sb_scan.border_color = Color(0.1, 0.9, 0.3)
	sb_scan.set_border_width_all(2)
	sb_scan.set_content_margin_all(12.0)
	sb_scan.corner_radius_top_left = 6
	sb_scan.corner_radius_bottom_left = 6
	scanner_display.add_theme_stylebox_override("panel", sb_scan)
	
	scanner_label = RichTextLabel.new()
	scanner_label.name = "ScannerLabel"
	scanner_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scanner_label.custom_minimum_size = Vector2(240, 140)
	scanner_label.bbcode_enabled = true
	scanner_label.text = "Scanning..."
	scanner_display.add_child(scanner_label)
	$CanvasLayer.add_child(scanner_display)

	# Full-screen Blackout Overlay
	blackout_rect = ColorRect.new()
	blackout_rect.name = "BlackoutOverlay"
	blackout_rect.anchors_preset = Control.PRESET_FULL_RECT
	blackout_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blackout_rect.color = Color(0, 0, 0, 0)
	$CanvasLayer.add_child(blackout_rect)

	# Central Reticle/Crosshair Dot
	var reticle = Panel.new()
	reticle.name = "CentralReticle"
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reticle.custom_minimum_size = Vector2(6, 6)
	reticle.size = Vector2(6, 6)
	
	# Round white dot style box
	var reticle_style = StyleBoxFlat.new()
	reticle_style.bg_color = Color(1.0, 1.0, 1.0, 0.85) # Semi-transparent white
	reticle_style.corner_radius_top_left = 3
	reticle_style.corner_radius_top_right = 3
	reticle_style.corner_radius_bottom_left = 3
	reticle_style.corner_radius_bottom_right = 3
	reticle_style.shadow_color = Color(0, 0, 0, 0.45) # Dark shadow for visibility against bright backgrounds
	reticle_style.shadow_size = 1
	reticle.add_theme_stylebox_override("panel", reticle_style)
	
	$CanvasLayer.add_child(reticle)
	reticle.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


func _setup_hud_mouse_filters() -> void:
	var node_paths = [
		"InteractPrompt",
		"ChatLog",
		"SignalIndicator",
		"MessagePanel",
		"MessagePanel/MessageLabel"
	]
	for p in node_paths:
		var node = $CanvasLayer.get_node_or_null(p)
		if node:
			node.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ensure_input_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		InputMap.action_add_event(action_name, event)


func _equip_tool(tool_id: String) -> void:
	if tool_id == equipped_tool:
		equipped_tool = ""
	else:
		equipped_tool = tool_id
		
	torch_mesh.visible = (equipped_tool == "welding_torch")
	disruptor_mesh.visible = (equipped_tool == "signal_disruptor")
	scanner_mesh.visible = (equipped_tool == "scanner_attachment")
	
	_update_tool_hud()


func _update_tool_hud() -> void:
	if not tool_indicator:
		return
	if equipped_tool == "":
		tool_indicator.text = "Held Tool: None"
	elif equipped_tool == "welding_torch":
		tool_indicator.text = "Held Tool: Welding Torch [READY]"
	elif equipped_tool == "signal_disruptor":
		tool_indicator.text = "Held Tool: Signal Disruptor [CHARGES: %d/5]" % disruptor_charges
	elif equipped_tool == "scanner_attachment":
		tool_indicator.text = "Held Tool: Scanner Attachment [ACTIVE]"


func _get_drone_from_node(node: Node) -> PatrolDrone:
	var n = node
	while n:
		if n is PatrolDrone:
			return n
		n = n.get_parent()
	return null


func _use_equipped_tool() -> void:
	if equipped_tool == "":
		if owned_tools.get("signal_disruptor", false):
			_equip_tool("signal_disruptor")
		elif owned_tools.get("welding_torch", false):
			_equip_tool("welding_torch")
		elif owned_tools.get("scanner_attachment", false):
			_equip_tool("scanner_attachment")

	if equipped_tool == "welding_torch":
		_use_welding_torch()
	elif equipped_tool == "signal_disruptor":
		_use_signal_disruptor()


func _use_welding_torch() -> void:
	if welding_cooldown > 0.0:
		return
	welding_cooldown = 0.4
	
	# Thrust animation
	var tween = create_tween()
	tween.tween_property(tool_holder, "position", Vector3(0.08, -0.06, -0.2), 0.08)
	tween.tween_property(tool_holder, "position", Vector3.ZERO, 0.12)
	
	# Tip flash
	torch_light.light_energy = 5.0
	var flash_tween = create_tween()
	flash_tween.tween_property(torch_light, "light_energy", 0.0, 0.3)
	
	# Welder Raycast (Extended Range: 6.0m)
	var space_state = get_world_3d().direct_space_state
	var start = camera.global_position
	var end = start - camera.global_basis.z * 6.0
	var query = PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [self.get_rid()]
	
	var result = space_state.intersect_ray(query)
	if result and is_instance_valid(result.collider):
		var drone = _get_drone_from_node(result.collider)
		if drone:
			NetworkManager.stun_drone.rpc(drone.get_path(), "welding_torch")
			show_message("DRONE CONDUIT SHORTED: SYSTEM SHUTDOWN")


func _use_signal_disruptor() -> void:
	if disruptor_cooldown > 0.0:
		return
	if disruptor_charges <= 0:
		show_message("DISRUPTOR CELL DEPLETED")
		return
		
	disruptor_cooldown = 0.3
	disruptor_charges -= 1
	_update_tool_hud()
	
	# Recoil animation
	var tween = create_tween()
	tween.tween_property(tool_holder, "position", Vector3(0.0, 0.05, 0.1), 0.06)
	tween.tween_property(tool_holder, "position", Vector3.ZERO, 0.15)
	
	# Tip flash
	disruptor_light.light_energy = 6.0
	var flash_tween = create_tween()
	flash_tween.tween_property(disruptor_light, "light_energy", 0.0, 0.2)
	
	# Fire Raycast (Extended Range: 60.0m)
	var space_state = get_world_3d().direct_space_state
	var start = camera.global_position
	var end = start - camera.global_basis.z * 60.0
	var query = PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [self.get_rid()]
	
	var result = space_state.intersect_ray(query)
	var hit_point = end
	
	if result:
		hit_point = result.position
		if is_instance_valid(result.collider):
			var drone = _get_drone_from_node(result.collider)
			if drone:
				NetworkManager.stun_drone.rpc(drone.get_path(), "signal_disruptor")
				show_message("DRONE FREQUENCY JAMMED - CHARGES LEFT: %d" % disruptor_charges)
			
	# Render electric beam line
	var beam_start = camera.global_position + camera.global_basis * Vector3(0.2, -0.15, -0.4)
	active_beams.append({"start": beam_start, "end": hit_point, "time": 0.2})


func _process_scanner(delta: float) -> void:
	if not scanner_display:
		return
	if equipped_tool != "scanner_attachment":
		scanner_display.visible = false
		return
		
	var space_state = get_world_3d().direct_space_state
	var start = camera.global_position
	var end = start - camera.global_basis.z * 50.0
	var query = PhysicsRayQueryParameters3D.create(start, end)
	query.exclude = [self.get_rid()]
	
	var result = space_state.intersect_ray(query)
	if result and is_instance_valid(result.collider):
		var drone = _get_drone_from_node(result.collider)
		if drone:
			var dist = global_position.distance_to(drone.global_position)
			var state_str = "UNKNOWN"
			match drone.current_state:
				0: state_str = "PATROL"
				1: state_str = "CHASE"
				2: state_str = "STUNNED"
				
			scanner_label.text = "=== SCANNER LINK ===\n" + \
				"Target: Patrol Drone\n" + \
				"State: [color=green]%s[/color]\n" % state_str + \
				"Distance: %.1fm\n" % dist + \
				"Bypass Weakpoint: \n" + \
				"[font_size=18][color=orange]%s[/color][/font_size]" % drone.disrupt_code
			scanner_display.visible = true
			scanner_retention_timer = 5.0
			return

	if scanner_retention_timer > 0.0:
		scanner_retention_timer -= delta
	else:
		scanner_display.visible = false


func _draw_scanner_paths() -> void:
	if not path_drawer:
		return
		
	var imm: ImmediateMesh = path_drawer.mesh
	imm.clear_surfaces()
	
	var has_scanner = (equipped_tool == "scanner_attachment")
	var has_beams = not active_beams.is_empty()
	
	if not has_scanner and not has_beams:
		return
		
	var lines: Array[Vector3] = []
	
	# Draw scanner paths if scanner is equipped
	if has_scanner:
		var drones = get_tree().get_nodes_in_group("drones")
		for drone in drones:
			if not is_instance_valid(drone) or not "waypoints" in drone:
				continue
			var wps = drone.waypoints
			if wps.size() < 2:
				continue
			
			# Draw patrol path nodes loop
			for i in range(wps.size()):
				var start = wps[i] - global_position
				var end = wps[(i + 1) % wps.size()] - global_position
				lines.append(start)
				lines.append(end)
				
			# Draw line directly connecting drone to target waypoint
			var current_wp = wps[drone.current_waypoint_idx]
			var drone_pos = drone.global_position - global_position
			lines.append(drone_pos)
			lines.append(current_wp - global_position)
			
	# Draw active disruptor weapon beams
	for beam in active_beams:
		var start = beam["start"] - global_position
		var end = beam["end"] - global_position
		lines.append(start)
		lines.append(end)
		
	if lines.is_empty():
		return
		
	imm.surface_begin(Mesh.PRIMITIVE_LINES, line_material)
	for vertex in lines:
		imm.surface_add_vertex(vertex)
	imm.surface_end()


func knockout() -> void:
	if is_ko:
		return
	is_ko = true
	
	# Play shock indicator locally / halt player
	velocity = Vector3.ZERO
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	show_message("CRITICAL DAMAGE DETECTED - SYSTEM REBOOT REQUIRED", 3.0)
	
	# Tell the server/all clients to reset all drones
	NetworkManager.reset_all_drones.rpc()
	
	# Screen fade out
	var fade_tween = create_tween()
	fade_tween.tween_property(blackout_rect, "color", Color(0, 0, 0, 1), 0.8)
	await fade_tween.finished
	
	# Teleport player to start
	global_position = spawn_points[spawn_index]
	velocity = Vector3.ZERO
	
	# Recharge weapons
	disruptor_charges = 5
	_update_tool_hud()
	
	await get_tree().create_timer(1.2).timeout
	
	# Fade back in
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(blackout_rect, "color", Color(0, 0, 0, 0), 0.8)
	await fade_in_tween.finished
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	is_ko = false
