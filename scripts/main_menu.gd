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


func _on_reset_pressed() -> void:
	PuzzleState.reset_progress()
	status_label.text = "Save progress cleared!"
	await get_tree().create_timer(1.5).timeout
	status_label.text = ""


func _on_host_pressed() -> void:
	status_label.text = "Hosting..."
	get_tree().change_scene_to_file("res://scenes/wings/01_landing_bay/landing_bay.tscn")
	NetworkManager.request_host()


func _on_join_pressed() -> void:
	var ip: String = ip_input.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
	status_label.text = "Joining " + ip + "..."
	get_tree().change_scene_to_file("res://scenes/wings/01_landing_bay/landing_bay.tscn")
	NetworkManager.request_join(ip)


func _go_to_game() -> void:
	get_tree().change_scene_to_file("res://scenes/wings/01_landing_bay/landing_bay.tscn")
