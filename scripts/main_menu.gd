extends Control

@onready var host_button: Button = $Panel1/HostButton
@onready var join_button: Button = $Panel1/HBoxContainer/JoinButton
@onready var ip_input: LineEdit = $Panel1/HBoxContainer/IPInput
@onready var status_label: Label = $Panel1/StatusLabel
@onready var reset_button: Button = $Panel1/ResetButton


func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

	_setup_background_shader()
	_setup_menu_styling()


func _setup_background_shader() -> void:
	var bg_rect := ColorRect.new()
	bg_rect.name = "ShaderBackground"
	bg_rect.anchors_preset = Control.PRESET_FULL_RECT
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_rect)
	move_child(bg_rect, 0) # Send to back

	var shader := Shader.new()
	shader.code = """shader_type canvas_item;
uniform vec4 grid_color = vec4(0.1, 0.45, 0.8, 0.22);
uniform float grid_size = 40.0;
uniform float scanline_speed = 2.0;

void fragment() {
	vec2 uv = FRAGCOORD.xy;
	float grid_x = step(grid_size - 1.0, mod(uv.x, grid_size));
	float grid_y = step(grid_size - 1.0, mod(uv.y, grid_size));
	float grid = max(grid_x, grid_y);
	
	float scan = sin(uv.y * 0.04 - TIME * scanline_speed) * 0.5 + 0.5;
	float scan_bright = step(0.97, scan) * 0.12;
	float scanlines = sin(uv.y * 1.5) * 0.03;
	
	vec4 bg = mix(vec4(0.01, 0.02, 0.04, 1.0), vec4(0.02, 0.05, 0.1, 1.0), UV.y);
	vec4 grid_layer = grid * grid_color;
	COLOR = bg + grid_layer + vec4(vec3(scan_bright), 0.0) + vec4(vec3(scanlines), 0.0);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	bg_rect.material = material


func _setup_menu_styling() -> void:
	var panel1 := $Panel1 as VBoxContainer
	
	# Reparent Panel1 into a beautiful styled PanelContainer
	var chassis := PanelContainer.new()
	chassis.name = "MenuChassis"
	add_child(chassis)
	move_child(chassis, 1) # Above bg shader
	
	remove_child(panel1)
	chassis.add_child(panel1)
	
	var sb_chassis := StyleBoxFlat.new()
	sb_chassis.bg_color = Color(0.02, 0.04, 0.08, 0.85) # Glass dark
	sb_chassis.border_color = Color(0.1, 0.75, 1.0, 0.8) # Neon cyan border outline
	sb_chassis.set_border_width_all(2)
	sb_chassis.set_content_margin_all(24.0)
	sb_chassis.corner_radius_bottom_left = 12
	sb_chassis.corner_radius_bottom_right = 12
	sb_chassis.corner_radius_top_left = 12
	sb_chassis.corner_radius_top_right = 12
	sb_chassis.shadow_color = Color(0.1, 0.75, 1.0, 0.12)
	sb_chassis.shadow_size = 18
	chassis.add_theme_stylebox_override("panel", sb_chassis)
	
	chassis.custom_minimum_size = Vector2(360, 280)
	chassis.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	
	var title_lbl := panel1.get_node("Label") as Label
	title_lbl.text = "AFTERSIGNAL"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", Color(0.1, 0.75, 1.0))
	
	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "CO-OP MULTIPLAYER TACTICAL RELAY"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", Color(1.0, 0.65, 0.1)) # Amber accent
	panel1.add_child(subtitle)
	panel1.move_child(subtitle, 1)

	panel1.add_theme_constant_override("separation", 12)
	
	var ip_box := panel1.get_node("HBoxContainer/IPInput") as LineEdit
	ip_box.custom_minimum_size = Vector2(160, 32)
	ip_box.alignment = HORIZONTAL_ALIGNMENT_CENTER
	ip_box.placeholder_text = "Target Comms IP"
	
	var sb_ip := StyleBoxFlat.new()
	sb_ip.bg_color = Color(0.01, 0.02, 0.04, 0.9)
	sb_ip.border_color = Color(0.1, 0.5, 0.8, 0.4)
	sb_ip.set_border_width_all(1)
	sb_ip.set_content_margin_all(6.0)
	sb_ip.corner_radius_bottom_left = 4
	sb_ip.corner_radius_bottom_right = 4
	sb_ip.corner_radius_top_left = 4
	sb_ip.corner_radius_top_right = 4
	ip_box.add_theme_stylebox_override("normal", sb_ip)
	ip_box.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	ip_box.add_theme_font_size_override("font_size", 13)

	var sb_btn := StyleBoxFlat.new()
	sb_btn.bg_color = Color(0.05, 0.08, 0.14, 0.8) # Sleek cyber blue
	sb_btn.border_color = Color(0.1, 0.6, 1.0, 0.4)
	sb_btn.set_border_width_all(1)
	sb_btn.set_content_margin_all(8.0)
	sb_btn.corner_radius_bottom_left = 6
	sb_btn.corner_radius_bottom_right = 6
	sb_btn.corner_radius_top_left = 6
	sb_btn.corner_radius_top_right = 6

	var sb_btn_hover := StyleBoxFlat.new()
	sb_btn_hover.bg_color = Color(0.1, 0.2, 0.4, 0.95)
	sb_btn_hover.border_color = Color(0.1, 0.75, 1.0, 0.8)
	sb_btn_hover.set_border_width_all(1)
	sb_btn_hover.set_content_margin_all(8.0)
	sb_btn_hover.corner_radius_bottom_left = 6
	sb_btn_hover.corner_radius_bottom_right = 6
	sb_btn_hover.corner_radius_top_left = 6
	sb_btn_hover.corner_radius_top_right = 6

	var sb_btn_pressed := StyleBoxFlat.new()
	sb_btn_pressed.bg_color = Color(0.0, 0.45, 0.75, 0.9)
	sb_btn_pressed.border_color = Color(0.1, 0.75, 1.0, 1.0)
	sb_btn_pressed.set_border_width_all(1)
	sb_btn_pressed.set_content_margin_all(8.0)
	sb_btn_pressed.corner_radius_bottom_left = 6
	sb_btn_pressed.corner_radius_bottom_right = 6
	sb_btn_pressed.corner_radius_top_left = 6
	sb_btn_pressed.corner_radius_top_right = 6

	var buttons: Array[Button] = [
		host_button,
		join_button,
		reset_button
	]
	
	for btn in buttons:
		btn.add_theme_stylebox_override("normal", sb_btn)
		btn.add_theme_stylebox_override("hover", sb_btn_hover)
		btn.add_theme_stylebox_override("pressed", sb_btn_pressed)
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		btn.add_theme_font_size_override("font_size", 13)
		btn.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
		
	var sb_reset := sb_btn.duplicate() as StyleBoxFlat
	sb_reset.border_color = Color(1.0, 0.45, 0.1, 0.4)
	var sb_reset_hover := sb_btn_hover.duplicate() as StyleBoxFlat
	sb_reset_hover.border_color = Color(1.0, 0.55, 0.2, 0.8)
	reset_button.add_theme_stylebox_override("normal", sb_reset)
	reset_button.add_theme_stylebox_override("hover", sb_reset_hover)
	reset_button.add_theme_color_override("font_color", Color(1.0, 0.8, 0.6))
	
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))


func _on_reset_pressed() -> void:
	PuzzleState.reset_progress()
	status_label.text = "Save progress cleared!"
	await get_tree().create_timer(1.5).timeout
	status_label.text = ""


func _on_host_pressed() -> void:
	status_label.text = "Hosting..."
	get_tree().change_scene_to_file("res://scenes/wings/01_landing_bay/landing_bay.scn")
	NetworkManager.request_host()


func _on_join_pressed() -> void:
	var ip: String = ip_input.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
	status_label.text = "Joining " + ip + "..."
	get_tree().change_scene_to_file("res://scenes/wings/01_landing_bay/landing_bay.scn")
	NetworkManager.request_join(ip)


func _go_to_game() -> void:
	get_tree().change_scene_to_file("res://scenes/wings/01_landing_bay/landing_bay.scn")
