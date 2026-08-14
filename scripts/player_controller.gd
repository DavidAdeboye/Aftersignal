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
@onready var keypad_input: Control = $CanvasLayer/KeypadPanel
@onready var message_panel: PanelContainer = $CanvasLayer/MessagePanel
@onready var message_label: Label = $CanvasLayer/MessagePanel/MessageLabel
@onready var glyph_pad: Control = $CanvasLayer/GlyphPad

var anim_player: AnimationPlayer = null
var anim_state: String = "idle"
var anim_speed: float = 1.0

# Network interpolation targets (written by MultiplayerSynchronizer)
var sync_position: Vector3 = Vector3.ZERO
var sync_rotation: Vector3 = Vector3.ZERO
const INTERP_SPEED: float = 25.0

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

# Narrative Systems HUD
var objective_banner: PanelContainer = null
var objective_label: Label = null
var dialog_banner: PanelContainer = null
var dialog_label: RichTextLabel = null
var dialog_timer: float = 0.0
var _narrative_connected: bool = false

# HUD Overlays
var tool_indicator: Label = null
var scanner_display: PanelContainer = null
var scanner_label: RichTextLabel = null
var blackout_rect: ColorRect = null
var central_reticle: Panel = null

# Reading Panel (pickup logs/notepads)
var reading_panel: PanelContainer = null
var reading_title_label: Label = null
var reading_text_label: RichTextLabel = null
var is_reading: bool = false

# 3D Tool meshes & Drawers — GLB instances placed in the scene under ToolHolder / FPS Rig BoneAttachment3D
@onready var tool_holder: Node3D = find_child("ToolHolder", true, false) as Node3D
@onready var torch_mesh: Node3D = find_child("WeldingTorchMesh", true, false) as Node3D
@onready var disruptor_mesh: Node3D = find_child("DisruptorMesh", true, false) as Node3D
@onready var scanner_mesh: Node3D = find_child("ScannerMesh", true, false) as Node3D
var torch_light: OmniLight3D = null
var disruptor_light: OmniLight3D = null
var path_drawer: MeshInstance3D = null
var line_material: StandardMaterial3D = null

# Procedural Viewmodel Sway & Movement Bobbing
var viewmodel_bob_cycle: float = 0.0
var mouse_delta_x: float = 0.0
var mouse_delta_y: float = 0.0


func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))

func _ready() -> void:
	spawn_index = 0 if int(str(name)) == 1 else 1
	position = spawn_points[spawn_index]

	var astronaut_model: Node3D = get_node_or_null("AstronautModel") as Node3D
	if astronaut_model:
		_tint_meshes_recursive(astronaut_model, spawn_colors[spawn_index])

		if is_multiplayer_authority():
			_set_layer_recursive(astronaut_model, 2)
			camera.set_cull_mask_value(2, false)

		var anim_node: AnimationPlayer = astronaut_model.get_node_or_null("AnimationPlayer") as AnimationPlayer
		if anim_node:
			anim_player = anim_node

			if not anim_player.has_animation_library("moves"):
				var lib := AnimationLibrary.new()
				var idle_anim: Animation = load("res://assets/characters/dark_astronaut/animations/idle_anim.res")
				var run_anim: Animation = load("res://assets/characters/dark_astronaut/animations/run_anim.res")
				print("idle_anim loaded: ", idle_anim, " | run_anim loaded: ", run_anim)
				if idle_anim:
					lib.add_animation("idle", idle_anim)
				if run_anim:
					lib.add_animation("run", run_anim)
				anim_player.add_animation_library("moves", lib)

			anim_player.play("moves/idle")

	if not is_multiplayer_authority():
		$CanvasLayer.queue_free()
	else:
		_setup_static_overlay()
		_setup_inventory_hud()
		_setup_combat_systems()
		_setup_reading_panel()
		_setup_message_panel_style()
		_setup_hud_mouse_filters()
		_connect_narrative_managers()
		keypad_input.text_submitted.connect(_on_keypad_submitted)

	call_deferred("_setup_local_player")

func _tint_meshes_recursive(node: Node, color: Color) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		for surface_idx in mesh_instance.get_surface_override_material_count():
			var material := StandardMaterial3D.new()
			material.albedo_color = color
			mesh_instance.set_surface_override_material(surface_idx, material)
	for child in node.get_children():
		_tint_meshes_recursive(child, color)


func _set_layer_recursive(node: Node, layer: int) -> void:
	if node is VisualInstance3D:
		(node as VisualInstance3D).set_layer_mask_value(1, false)
		(node as VisualInstance3D).set_layer_mask_value(layer, true)
	for child in node.get_children():
		_set_layer_recursive(child, layer)


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
		mouse_delta_x += event.relative.x
		mouse_delta_y += event.relative.y


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return

	if is_ko:
		return

	if is_reading:
		if event.is_action_pressed("interact") or event.is_action_pressed("ui_cancel"):
			_close_reading_panel()
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


func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		# Smoothly interpolate remote player position and rotation
		global_position = global_position.lerp(sync_position, clamp(INTERP_SPEED * delta, 0.0, 1.0))
		rotation = rotation.lerp(sync_rotation, clamp(INTERP_SPEED * delta, 0.0, 1.0))
		_update_animation()
		return

	# Authority keeps sync vars up to date for replication
	sync_position = global_position
	sync_rotation = rotation

	if dialog_timer > 0.0:
		dialog_timer -= delta
		if dialog_timer <= 0.0 and dialog_banner:
			dialog_banner.visible = false

func _update_animation() -> void:
	if not anim_player:
		return
	var target := "moves/" + anim_state
	if anim_player.current_animation != target:
		anim_player.play(target)
	anim_player.speed_scale = anim_speed if anim_state == "run" else 1.0

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
	if dialog_timer > 0.0:
		dialog_timer -= delta
		if dialog_timer <= 0.0 and dialog_banner:
			dialog_banner.visible = false

	if not _narrative_connected:
		_connect_narrative_managers()

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

	# Update movement animation state metrics
	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	if horiz_speed > 0.1:
		anim_state = "run"
		anim_speed = horiz_speed / walk_speed
	else:
		anim_state = "idle"
		anim_speed = 1.0
		
	_update_animation()

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
	_process_viewmodel_sway(delta)


## Procedurally calculates first-person hand & tool viewmodel bobbing while walking/running,
## idle breathing sway, and organic mouse-look rotational lag.
func _process_viewmodel_sway(delta: float) -> void:
	if not tool_holder:
		return
		
	var horiz_speed: float = Vector2(velocity.x, velocity.z).length()
	var on_ground: bool = is_on_floor()
	
	var bob_x: float = 0.0
	var bob_y: float = 0.0
	var tilt_z: float = 0.0
	
	if on_ground and horiz_speed > 0.1:
		# Dynamic gait bobbing scaled to movement velocity
		var bob_frequency: float = 10.0 if horiz_speed <= walk_speed else 14.0
		var bob_amount_x: float = 0.012
		var bob_amount_y: float = 0.010
		
		viewmodel_bob_cycle += delta * bob_frequency
		bob_x = cos(viewmodel_bob_cycle * 0.5) * bob_amount_x
		bob_y = sin(viewmodel_bob_cycle) * bob_amount_y
		tilt_z = sin(viewmodel_bob_cycle * 0.5) * 0.025
	else:
		# Gentle idle breathing sway
		viewmodel_bob_cycle += delta * 2.0
		bob_x = cos(viewmodel_bob_cycle * 0.5) * 0.0025
		bob_y = sin(viewmodel_bob_cycle) * 0.0025
		
	# Mouse look rotational sway (viewmodel lags slightly behind mouse turn)
	var sway_x: float = clampf(-mouse_delta_x * 0.00025, -0.025, 0.025)
	var sway_y: float = clampf(mouse_delta_y * 0.00025, -0.025, 0.025)
	mouse_delta_x = move_toward(mouse_delta_x, 0.0, delta * 300.0)
	mouse_delta_y = move_toward(mouse_delta_y, 0.0, delta * 300.0)
	
	# Blend sway into viewmodel position & rotation
	var target_pos: Vector3 = Vector3(bob_x + sway_x, bob_y + sway_y, 0.0)
	var target_rot: Vector3 = Vector3(sway_y * 0.6, sway_x * 0.6, tilt_z)
	
	tool_holder.position = tool_holder.position.lerp(target_pos, clampf(delta * 12.0, 0.0, 1.0))
	tool_holder.rotation.x = lerp_angle(tool_holder.rotation.x, target_rot.x, clampf(delta * 12.0, 0.0, 1.0))
	tool_holder.rotation.y = lerp_angle(tool_holder.rotation.y, target_rot.y, clampf(delta * 12.0, 0.0, 1.0))
	tool_holder.rotation.z = lerp_angle(tool_holder.rotation.z, target_rot.z, clampf(delta * 12.0, 0.0, 1.0))





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
	var can_interact := false
	if interact_ray.is_colliding():
		var collider = interact_ray.get_collider()

		# Check if the collider itself is an Interactable, or walk up the
		# parent chain.  This handles editable-children setups where a
		# StaticBody3D + CollisionShape3D lives deep inside a GLB mesh
		# hierarchy — the raycast returns that child body, not the root
		# pickup node.
		var interactable_node: Interactable = _find_interactable_ancestor(collider)
		if interactable_node:
			current_interactable = interactable_node
			current_door_body = null
			interact_prompt.text = interactable_node.prompt_text if interactable_node.prompt_text != "" else "Press E to interact"
			interact_prompt.visible = interactable_node.prompt_text != ""
			can_interact = interactable_node.prompt_text != ""
		elif collider is QuaterniusDoorBody:
			current_door_body = collider
			current_interactable = null
			var door_node: Node = collider.get("door")
			if door_node and "opened" in door_node:
				interact_prompt.text = "Press E to close" if door_node.opened else "Press E to open"
			else:
				interact_prompt.text = "Press E to open"
			interact_prompt.visible = true
			can_interact = true

	if not can_interact:
		current_interactable = null
		current_door_body = null
		interact_prompt.visible = false

	if central_reticle:
		if can_interact:
			central_reticle.modulate = Color(0.2, 0.95, 0.4) # Glowing emerald green
			central_reticle.scale = Vector2(1.5, 1.5)
		else:
			central_reticle.modulate = Color(1.0, 1.0, 1.0, 0.85) # Semi-transparent white
			central_reticle.scale = Vector2(1.0, 1.0)


## Walks up the scene tree from `node` looking for the nearest Interactable
## ancestor (or the node itself). Returns null if none is found within a
## reasonable depth to avoid traversing the entire tree.
func _find_interactable_ancestor(node: Node) -> Interactable:
	var current := node
	var depth := 0
	while current != null and depth < 10:
		if current is Interactable:
			return current as Interactable
		current = current.get_parent()
		depth += 1
	return null


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
		if keypad_input.has_method("show_failure"):
			keypad_input.show_failure()
		else:
			keypad_input.modulate = Color.RED
			await get_tree().create_timer(0.3).timeout
			keypad_input.modulate = Color.WHITE
		return
	
	if keypad_input.has_method("show_success"):
		keypad_input.show_success()
	else:
		keypad_input.visible = false
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
#  READING PANEL (pickup logs/notepads)
# ============================================================================

func _setup_reading_panel() -> void:
	reading_panel = PanelContainer.new()
	reading_panel.name = "ReadingPanel"
	reading_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reading_panel.visible = false
	reading_panel.custom_minimum_size = Vector2(700, 420)

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.01, 0.02, 0.04, 0.96)
	sb.border_color = Color(0.1, 0.75, 1.0, 0.9)
	sb.set_border_width_all(2)
	sb.set_content_margin_all(20.0)
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.shadow_color = Color(0.1, 0.75, 1.0, 0.15)
	sb.shadow_size = 15
	reading_panel.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 12)
	reading_panel.add_child(vbox)

	# Header metadata
	var header_hbox := HBoxContainer.new()
	header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var mock_model := Label.new()
	mock_model.text = "SYS_RECOVERY: DATAPAD_v1.09"
	mock_model.add_theme_font_size_override("font_size", 11)
	mock_model.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	header_hbox.add_child(mock_model)
	
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.add_child(spacer)
	
	var mock_status := Label.new()
	mock_status.text = "DECRYPTION: ACTIVE"
	mock_status.add_theme_font_size_override("font_size", 11)
	mock_status.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
	header_hbox.add_child(mock_status)
	
	vbox.add_child(header_hbox)

	# Divider line
	var div := ColorRect.new()
	div.custom_minimum_size = Vector2(0, 2)
	div.color = Color(0.1, 0.75, 1.0, 0.4)
	div.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(div)

	# Title
	reading_title_label = Label.new()
	reading_title_label.name = "ReadingTitleLabel"
	reading_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reading_title_label.add_theme_font_size_override("font_size", 24)
	reading_title_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.1)) # Amber
	vbox.add_child(reading_title_label)

	# Content scroll container
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(660, 240)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(scroll)

	reading_text_label = RichTextLabel.new()
	reading_text_label.name = "ReadingTextLabel"
	reading_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	reading_text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reading_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	reading_text_label.bbcode_enabled = true
	reading_text_label.fit_content = true
	reading_text_label.add_theme_font_size_override("normal_font_size", 15)
	reading_text_label.add_theme_color_override("default_color", Color(0.9, 0.9, 0.95))
	scroll.add_child(reading_text_label)

	# Bottom divider
	var div2 := ColorRect.new()
	div2.custom_minimum_size = Vector2(0, 1)
	div2.color = Color(0.5, 0.5, 0.5, 0.2)
	div2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(div2)

	# Close hint
	var close_hint := Label.new()
	close_hint.name = "CloseHintLabel"
	close_hint.text = "Press E or ESC to exit datapad link"
	close_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_hint.add_theme_font_size_override("font_size", 12)
	close_hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(close_hint)

	$CanvasLayer.add_child(reading_panel)
	reading_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)


## Opens the full-screen reading panel with the given title/text. Called by
## ReadableLog interactables (notepads, terminals) instead of the quick
## show_message() popup, for a more deliberate "pick up and read" moment.
func show_reading_panel(title: String, text: String) -> void:
	if not is_multiplayer_authority() or reading_panel == null:
		return
	reading_title_label.text = title
	reading_text_label.text = text
	reading_panel.visible = true
	is_reading = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _close_reading_panel() -> void:
	reading_panel.visible = false
	is_reading = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


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
	
	# Premium translucent cyber styled box flat
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.01, 0.03, 0.06, 0.75)
	sb.border_color = Color(0.1, 0.6, 1.0, 0.5) # Neon cyan border accent
	sb.border_width_left = 4
	sb.set_content_margin_all(8.0)
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_right = 6
	inventory_label.add_theme_stylebox_override("normal", sb)
	inventory_label.add_theme_font_size_override("font_size", 13)
	inventory_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	
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

	# 2. Reference the GLB tool meshes already placed under ToolHolder / BoneAttachment3D in the scene
	if tool_holder == null:
		tool_holder = find_child("ToolHolder", true, false) as Node3D
	if torch_mesh == null:
		torch_mesh = find_child("WeldingTorchMesh", true, false) as Node3D
	if disruptor_mesh == null:
		disruptor_mesh = find_child("DisruptorMesh", true, false) as Node3D
	if scanner_mesh == null:
		scanner_mesh = find_child("ScannerMesh", true, false) as Node3D
	
	# Transforms (Position, Rotation, Scale) are controlled directly in player.tscn / Inspector.
	if is_instance_valid(torch_mesh): torch_mesh.visible = false
	if is_instance_valid(disruptor_mesh): disruptor_mesh.visible = false
	if is_instance_valid(scanner_mesh): scanner_mesh.visible = false
	
	# Torch tip fire-light (for flash effect on use)
	if is_instance_valid(torch_mesh) and torch_light == null:
		torch_light = OmniLight3D.new()
		torch_light.light_color = Color(0.1, 0.7, 1.0)
		torch_light.light_energy = 0.0
		torch_light.omni_range = 3.0
		torch_light.position = Vector3(0, 0.2, 0)
		torch_mesh.add_child(torch_light)
	
	# Disruptor tip beam-light (for flash effect on use)
	if is_instance_valid(disruptor_mesh) and disruptor_light == null:
		disruptor_light = OmniLight3D.new()
		disruptor_light.light_color = Color(1.0, 0.35, 0.1)
		disruptor_light.light_energy = 0.0
		disruptor_light.omni_range = 4.0
		disruptor_light.position = Vector3(0, 0, -0.25)
		disruptor_mesh.add_child(disruptor_light)

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
	sb.bg_color = Color(0.01, 0.03, 0.06, 0.75)
	sb.border_color = Color(1.0, 0.65, 0.1, 0.5) # Amber/orange border accent
	sb.border_width_right = 4
	sb.set_content_margin_all(8.0)
	sb.corner_radius_top_left = 6
	sb.corner_radius_bottom_left = 6
	tool_indicator.add_theme_stylebox_override("normal", sb)
	tool_indicator.add_theme_font_size_override("font_size", 13)
	tool_indicator.add_theme_color_override("font_color", Color(1.0, 0.9, 0.8))
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
	sb_scan.bg_color = Color(0.0, 0.04, 0.02, 0.85) # matrix dark green
	sb_scan.border_color = Color(0.2, 0.95, 0.4, 0.8) # emerald green border
	sb_scan.set_border_width_all(2)
	sb_scan.set_content_margin_all(12.0)
	sb_scan.corner_radius_top_left = 8
	sb_scan.corner_radius_bottom_left = 8
	sb_scan.shadow_color = Color(0.2, 0.95, 0.4, 0.1)
	sb_scan.shadow_size = 8
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
	central_reticle = Panel.new()
	central_reticle.name = "CentralReticle"
	central_reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	central_reticle.custom_minimum_size = Vector2(6, 6)
	central_reticle.size = Vector2(6, 6)
	central_reticle.pivot_offset = Vector2(3, 3)
	
	var reticle_style = StyleBoxFlat.new()
	reticle_style.bg_color = Color(1.0, 1.0, 1.0, 0.85) # Semi-transparent white
	reticle_style.corner_radius_top_left = 3
	reticle_style.corner_radius_top_right = 3
	reticle_style.corner_radius_bottom_left = 3
	reticle_style.corner_radius_bottom_right = 3
	reticle_style.shadow_color = Color(0, 0, 0, 0.45)
	reticle_style.shadow_size = 1
	central_reticle.add_theme_stylebox_override("panel", reticle_style)
	
	$CanvasLayer.add_child(central_reticle)
	central_reticle.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)

	# Objective HUD Banner (Top Center)
	objective_banner = PanelContainer.new()
	objective_banner.name = "ObjectiveBanner"
	objective_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	
	var sb_obj = StyleBoxFlat.new()
	sb_obj.bg_color = Color(0.01, 0.03, 0.06, 0.85) # dark sci-fi blue/black
	sb_obj.border_color = Color(1.0, 0.6, 0.1, 0.85) # Amber outline
	sb_obj.border_width_bottom = 3 # bottom highlight line
	sb_obj.set_content_margin_all(10.0)
	sb_obj.corner_radius_bottom_left = 6
	sb_obj.corner_radius_bottom_right = 6
	objective_banner.add_theme_stylebox_override("panel", sb_obj)
	
	objective_label = Label.new()
	objective_label.name = "ObjectiveLabel"
	objective_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective_label.text = "OBJECTIVE: Investigate Habitation Wing & Locate Crew Manifest"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 14)
	objective_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5)) # Amber yellow text
	objective_banner.add_child(objective_label)
	$CanvasLayer.add_child(objective_banner)
	objective_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE)
	objective_banner.offset_top = 16.0

	# Dialog Subtitle Panel (Bottom Center)
	dialog_banner = PanelContainer.new()
	dialog_banner.name = "DialogBanner"
	dialog_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	dialog_banner.visible = false
	
	var sb_dia = StyleBoxFlat.new()
	sb_dia.bg_color = Color(0.01, 0.02, 0.04, 0.9) # deeper translucent dark
	sb_dia.border_color = Color(0.1, 0.75, 1.0, 0.8) # cyan highlight outline
	sb_dia.border_width_top = 2 # top highlight line
	sb_dia.set_content_margin_all(12.0)
	sb_dia.corner_radius_top_left = 8
	sb_dia.corner_radius_top_right = 8
	dialog_banner.add_theme_stylebox_override("panel", sb_dia)
	
	dialog_label = RichTextLabel.new()
	dialog_label.name = "DialogLabel"
	dialog_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialog_label.custom_minimum_size = Vector2(520, 50)
	dialog_label.bbcode_enabled = true
	dialog_banner.add_child(dialog_label)
	$CanvasLayer.add_child(dialog_banner)
	dialog_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_MINSIZE)
	dialog_banner.offset_top = -120.0
	dialog_banner.offset_bottom = -70.0


func _setup_message_panel_style() -> void:
	if message_panel == null or message_label == null:
		return
	# Reposition to true center-bottom
	message_panel.anchors_preset = Control.PRESET_CENTER_BOTTOM
	message_panel.anchor_left = 0.5
	message_panel.anchor_top = 1.0
	message_panel.anchor_right = 0.5
	message_panel.anchor_bottom = 1.0
	message_panel.offset_left = -260.0
	message_panel.offset_top = -120.0
	message_panel.offset_right = 260.0
	message_panel.offset_bottom = -60.0
	message_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	message_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	# Premium glassmorphic style
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.01, 0.03, 0.06, 0.88)
	sb.border_color = Color(0.1, 0.75, 1.0, 0.7)
	sb.border_width_top = 2
	sb.set_content_margin_all(14.0)
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	sb.shadow_color = Color(0.1, 0.75, 1.0, 0.1)
	sb.shadow_size = 10
	message_panel.add_theme_stylebox_override("panel", sb)
	
	# Style the label text
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))


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


func _connect_narrative_managers() -> void:
	var obj_connected := false
	var dia_connected := false

	var obj_mgr = ObjectiveManager.instance
	if not obj_mgr and get_tree() and get_tree().current_scene:
		obj_mgr = get_tree().current_scene.get_node_or_null("ObjectiveManager")
	if obj_mgr:
		if not obj_mgr.objective_updated.is_connected(_on_objective_updated):
			obj_mgr.objective_updated.connect(_on_objective_updated)
		_on_objective_updated(obj_mgr.current_objective)
		obj_connected = true

	var dia_mgr = DialogManager.instance
	if not dia_mgr and get_tree() and get_tree().current_scene:
		dia_mgr = get_tree().current_scene.get_node_or_null("DialogManager")
	if dia_mgr:
		if not dia_mgr.dialog_triggered.is_connected(_on_dialog_triggered):
			dia_mgr.dialog_triggered.connect(_on_dialog_triggered)
		dia_connected = true

	_narrative_connected = obj_connected and dia_connected


func _on_objective_updated(new_text: String) -> void:
	if objective_label:
		objective_label.text = new_text


func _on_dialog_triggered(speaker: String, text: String, duration: float) -> void:
	if dialog_banner and dialog_label:
		dialog_label.text = "[color=orange][%s][/color] %s" % [speaker, text]
		dialog_banner.visible = true
		dialog_timer = duration


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
		
	if is_instance_valid(torch_mesh):
		torch_mesh.visible = (equipped_tool == "welding_torch")
	if is_instance_valid(disruptor_mesh):
		disruptor_mesh.visible = (equipped_tool == "signal_disruptor")
	if is_instance_valid(scanner_mesh):
		scanner_mesh.visible = (equipped_tool == "scanner_attachment")
	
	print("[EquipTool] tool_id: ", tool_id, " | equipped_tool: ", equipped_tool, " | torch: ", is_instance_valid(torch_mesh) and torch_mesh.visible, " | disruptor: ", is_instance_valid(disruptor_mesh) and disruptor_mesh.visible, " | scanner: ", is_instance_valid(scanner_mesh) and scanner_mesh.visible)
	
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
	if is_instance_valid(torch_light):
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
	if is_instance_valid(disruptor_light):
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
# wakatime_sync
