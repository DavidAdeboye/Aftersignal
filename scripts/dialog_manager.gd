extends Node
class_name DialogManager

## Manages radio chatter subtitles and log dialog overlays across players.

signal dialog_triggered(speaker: String, text: String, duration: float)

static var instance: DialogManager = null

func _enter_tree() -> void:
	instance = self


func play_dialog(speaker: String, text: String, duration: float = 4.5) -> void:
	if multiplayer and multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		sync_dialog_rpc.rpc(speaker, text, duration)
	else:
		dialog_triggered.emit(speaker, text, duration)


@rpc("any_peer", "call_local", "reliable")
func sync_dialog_rpc(speaker: String, text: String, duration: float) -> void:
	dialog_triggered.emit(speaker, text, duration)
