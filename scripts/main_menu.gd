extends Control

@onready var host_button: Button = $Panel1/HostButton
@onready var join_button: Button = $Panel1/HBoxContainer/JoinButton
@onready var ip_input: LineEdit = $Panel1/HBoxContainer/IPInput
@onready var status_label: Label = $Panel1/StatusLabel


func _ready() -> void:
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)


func _on_host_pressed() -> void:
	status_label.text = "Hosting..."
	get_tree().change_scene_to_file("res://scenes/wings/01_landing_bay/test_room.tscn")
	NetworkManager.request_host()


func _on_join_pressed() -> void:
	var ip: String = ip_input.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
	status_label.text = "Joining " + ip + "..."
	get_tree().change_scene_to_file("res://scenes/wings/01_landing_bay/test_room.tscn")
	NetworkManager.request_join(ip)
	
	
func _go_to_game() -> void:
	get_tree().change_scene_to_file("res://scenes/wings/01_landing_bay/test_room.tscn")
