extends Control

signal text_submitted(text: String)

@onready var display_label: Label = $Chassis/VBox/Screen/VBox/DisplayLabel
@onready var status_label: Label = $Chassis/VBox/Screen/VBox/StatusLabel

var typed_code: String = ""
var is_locked_out: bool = false

func _ready() -> void:
	# 1. Style the Chassis PanelContainer
	var chassis := $Chassis as PanelContainer
	var sb_chassis := StyleBoxFlat.new()
	sb_chassis.bg_color = Color(0.02, 0.04, 0.08, 0.95) # Dark translucent chassis
	sb_chassis.border_color = Color(0.1, 0.6, 1.0, 0.8) # Cyan border
	sb_chassis.set_border_width_all(2)
	sb_chassis.set_content_margin_all(14.0)
	sb_chassis.corner_radius_bottom_left = 10
	sb_chassis.corner_radius_bottom_right = 10
	sb_chassis.corner_radius_top_left = 10
	sb_chassis.corner_radius_top_right = 10
	sb_chassis.shadow_color = Color(0.1, 0.6, 1.0, 0.15)
	sb_chassis.shadow_size = 12
	chassis.add_theme_stylebox_override("panel", sb_chassis)

	# 2. Style the Screen PanelContainer
	var screen := $Chassis/VBox/Screen as PanelContainer
	var sb_screen := StyleBoxFlat.new()
	sb_screen.bg_color = Color(0.0, 0.05, 0.02, 0.9) # Dark green terminal screen
	sb_screen.border_color = Color(0.2, 0.9, 0.4, 0.5) # Green screen border
	sb_screen.set_border_width_all(1)
	sb_screen.set_content_margin_all(8.0)
	sb_screen.corner_radius_bottom_left = 4
	sb_screen.corner_radius_bottom_right = 4
	sb_screen.corner_radius_top_left = 4
	sb_screen.corner_radius_top_right = 4
	screen.add_theme_stylebox_override("panel", sb_screen)

	# 3. Style the Screen labels
	display_label.add_theme_color_override("font_color", Color(0.2, 0.95, 0.4)) # Glowing green display text
	display_label.add_theme_font_size_override("font_size", 20)
	status_label.add_theme_color_override("font_color", Color(0.1, 0.75, 1.0)) # Cyan status info
	status_label.add_theme_font_size_override("font_size", 10)

	# 4. Style all the numeric buttons
	var sb_btn_normal := StyleBoxFlat.new()
	sb_btn_normal.bg_color = Color(0.05, 0.08, 0.14, 0.8) # Sleek blue button bg
	sb_btn_normal.border_color = Color(0.1, 0.5, 0.8, 0.3)
	sb_btn_normal.set_border_width_all(1)
	sb_btn_normal.corner_radius_bottom_left = 4
	sb_btn_normal.corner_radius_bottom_right = 4
	sb_btn_normal.corner_radius_top_left = 4
	sb_btn_normal.corner_radius_top_right = 4
	
	var sb_btn_hover := StyleBoxFlat.new()
	sb_btn_hover.bg_color = Color(0.1, 0.2, 0.35, 0.9) # Highlight on hover
	sb_btn_hover.border_color = Color(0.1, 0.75, 1.0, 0.8) # Glowing cyan border on hover
	sb_btn_hover.set_border_width_all(1)
	sb_btn_hover.corner_radius_bottom_left = 4
	sb_btn_hover.corner_radius_bottom_right = 4
	sb_btn_hover.corner_radius_top_left = 4
	sb_btn_hover.corner_radius_top_right = 4

	var sb_btn_pressed := StyleBoxFlat.new()
	sb_btn_pressed.bg_color = Color(0.05, 0.5, 0.75, 0.9) # Dark cyan on click
	sb_btn_pressed.border_color = Color(0.1, 0.75, 1.0, 1.0)
	sb_btn_pressed.set_border_width_all(1)
	sb_btn_pressed.corner_radius_bottom_left = 4
	sb_btn_pressed.corner_radius_bottom_right = 4
	sb_btn_pressed.corner_radius_top_left = 4
	sb_btn_pressed.corner_radius_top_right = 4

	# Connect grid buttons
	for button in get_tree().get_nodes_in_group("keypad_buttons"):
		if button is Button:
			button.pressed.connect(_on_button_pressed.bind(button.text))
			
			# Add theme style overrides
			button.add_theme_stylebox_override("normal", sb_btn_normal)
			button.add_theme_stylebox_override("hover", sb_btn_hover)
			button.add_theme_stylebox_override("pressed", sb_btn_pressed)
			button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
			
			button.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
			button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
			button.add_theme_font_size_override("font_size", 14)
			button.custom_minimum_size = Vector2(50, 40)
	
	visibility_changed.connect(_on_visible_changed)
	_update_display()

func _on_visible_changed() -> void:
	if visible:
		typed_code = ""
		is_locked_out = false
		status_label.text = "ENTER SECURE CODE"
		status_label.add_theme_color_override("font_color", Color(0.1, 0.75, 1.0))
		_update_display()
		# Free mouse cursor when keypad is visible
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_button_pressed(val: String) -> void:
	if is_locked_out:
		return
	match val:
		"C":
			typed_code = ""
			_update_display()
		"OK":
			_submit_code()
		_:
			if typed_code.length() < 8:
				typed_code += val
				_update_display()

func _submit_code() -> void:
	if typed_code.is_empty():
		return
	text_submitted.emit(typed_code)

func show_failure() -> void:
	is_locked_out = true
	status_label.text = "ACCESS DENIED"
	status_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.2))
	typed_code = ""
	_update_display()
	
	var tween = create_tween()
	# Screen flash effect
	tween.tween_property($Chassis/VBox/Screen, "modulate", Color(2.0, 0.2, 0.2), 0.15)
	tween.tween_property($Chassis/VBox/Screen, "modulate", Color(1.0, 1.0, 1.0), 0.15)
	await tween.finished
	is_locked_out = false
	status_label.text = "ENTER SECURE CODE"
	status_label.add_theme_color_override("font_color", Color(0.1, 0.75, 1.0))

func show_success() -> void:
	is_locked_out = true
	status_label.text = "ACCESS GRANTED"
	status_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
	
	var tween = create_tween()
	tween.tween_property($Chassis/VBox/Screen, "modulate", Color(0.2, 2.0, 0.4), 0.15)
	tween.tween_property($Chassis/VBox/Screen, "modulate", Color(1.0, 1.0, 1.0), 0.15)
	await tween.finished
	visible = false

func _update_display() -> void:
	if typed_code.is_empty():
		display_label.text = "[ _ _ _ _ ]"
	else:
		var masked := ""
		for i in typed_code.length():
			masked += "*"
		display_label.text = "[ " + masked + " ]"

func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or is_locked_out:
		return
	if event is InputEventKey and event.pressed:
		var keycode = event.keycode
		if keycode >= KEY_0 and keycode <= KEY_9:
			_on_button_pressed(str(keycode - KEY_0))
		elif keycode >= KEY_KP_0 and keycode <= KEY_KP_9:
			_on_button_pressed(str(keycode - KEY_KP_0))
		elif keycode == KEY_BACKSPACE:
			if typed_code.length() > 0:
				typed_code = typed_code.left(typed_code.length() - 1)
				_update_display()
		elif keycode == KEY_ENTER or keycode == KEY_KP_ENTER:
			_submit_code()
		elif keycode == KEY_ESCAPE:
			visible = false
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
