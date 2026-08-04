extends Control

## Shared glyph sketch-relay (design doc §4 "Shared symbols/glyphs" + puzzle
## type #5). Lives on the player's CanvasLayer, hidden until toggled with the
## `toggle_glyph` key. The local player drags to draw strokes on this pad; the
## strokes are streamed to the OTHER player's pad over the network so they can
## reconstruct a symbol that's too fiddly to describe over garbled radio.
##
## Strokes are sent through the NetworkManager autoload (same routing lesson as
## chat: shared comms must go through a node that exists identically on every
## peer, then be resolved to the locally-authoritative player's UI on the
## receiving side).

## Normalized points (0..1 within the pad) of the stroke currently being drawn.
var _current_stroke: PackedVector2Array = PackedVector2Array()
## Completed strokes drawn by the local player (what we're sending).
var _local_strokes: Array = []
## Strokes received from the partner (what we're receiving).
var _remote_strokes: Array = []

## Which side we're rendering. The local sketch draws in the player's own color;
## the incoming partner sketch draws in a contrasting "received" tint.
@export var local_color: Color = Color(0.2, 0.9, 1.0)
@export var remote_color: Color = Color(1.0, 0.75, 0.2)

var _drawing: bool = false


func _ready() -> void:
	# Fill the pad area and draw a faint frame so it reads as a device screen.
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_drawing = true
			_current_stroke = PackedVector2Array()
			_add_point(event.position)
		else:
			_end_stroke()
	elif event is InputEventMouseMotion and _drawing:
		_add_point(event.position)


func _add_point(local_pos: Vector2) -> void:
	# Store normalized so it maps correctly onto the partner's (possibly
	# different-sized) pad.
	var norm := Vector2(
		clampf(local_pos.x / max(size.x, 1.0), 0.0, 1.0),
		clampf(local_pos.y / max(size.y, 1.0), 0.0, 1.0)
	)
	_current_stroke.append(norm)
	queue_redraw()


func _end_stroke() -> void:
	_drawing = false
	if _current_stroke.size() < 2:
		_current_stroke = PackedVector2Array()
		return
	_local_strokes.append(_current_stroke)
	# Ship the finished stroke to the partner.
	NetworkManager.send_glyph_stroke.rpc(_current_stroke)
	_current_stroke = PackedVector2Array()
	queue_redraw()


## Called (via NetworkManager) when the partner completes a stroke on their pad.
func receive_remote_stroke(stroke: PackedVector2Array) -> void:
	_remote_strokes.append(stroke)
	queue_redraw()


## Clears everything on both pads. Broadcast so a "clear" is shared.
func clear_all() -> void:
	_local_strokes.clear()
	_remote_strokes.clear()
	_current_stroke = PackedVector2Array()
	queue_redraw()


func _draw() -> void:
	# Backing panel.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.07, 0.1, 0.9))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.3, 0.5, 0.65, 0.8), false, 2.0)

	_draw_strokes(_remote_strokes, remote_color)
	_draw_strokes(_local_strokes, local_color)
	if _current_stroke.size() >= 2:
		_draw_single(_current_stroke, local_color)


func _draw_strokes(strokes: Array, color: Color) -> void:
	for stroke in strokes:
		_draw_single(stroke, color)


func _draw_single(stroke: PackedVector2Array, color: Color) -> void:
	for i in range(stroke.size() - 1):
		draw_line(stroke[i] * size, stroke[i + 1] * size, color, 3.0, true)
