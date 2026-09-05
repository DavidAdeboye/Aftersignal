extends Interactable
class_name ChapterTerminal

@export var record_id: String = "record"
@export var record_title: String = "STATION RECORD"
var _read := false

func _ready() -> void:
	prompt_text = "Press E to access " + record_title.to_lower()

func interact(player: Node = null) -> void:
	if player and player.has_method("show_reading_panel"):
		player.show_reading_panel(record_title, message)
	else:
		_notify(player, record_title + "\n\n" + message)
	if _read:
		return
	_read = true
	var wing := get_parent()
	if wing and wing.has_method("record_found"):
		wing.record_found(record_id)
