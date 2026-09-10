extends CanvasLayer

signal cutscene_finished

# ---- CONFIG ----
const MAIN_VIDEO := "res://screenshots/shot1_exterior.ogv"  # your current single video

# Swap these later as you generate more real shots:
const VIDEO_OPERATORS := "res://cutscenes/shot3_operators.ogv"
var _use_video_operators := false

const VIDEO_WAITING := "res://cutscenes/shot4_waiting.ogv"
var _use_video_waiting := false
# ------------------

var _label: Label
var _black: ColorRect
var _video: VideoStreamPlayer
var _skip_requested := false

func play_intro() -> void:
	_build_black_backdrop()
	_build_label()

	if _skip_requested:
		_finish(); return

	await _play_beat_exterior()
	if _skip_requested:
		_finish(); return

	await _play_beat_beacon()
	if _skip_requested:
		_finish(); return

	await _play_beat_operators()
	if _skip_requested:
		_finish(); return

	await _play_beat_waiting()
	_finish()

# ---------- SHARED BUILD ----------

func _build_black_backdrop() -> void:
	_black = ColorRect.new()
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black.color = Color.BLACK
	add_child(_black)

func _build_label() -> void:
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 28)
	_label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_label.modulate.a = 0.0
	add_child(_label)  # added last = renders on top of video/black automatically

# ---------- SHOT 1: exterior video, text overlaid DURING playback ----------

func _play_beat_exterior() -> void:
	_video = VideoStreamPlayer.new()
	_video.stream = load(MAIN_VIDEO)
	_video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_video.expand = true
	add_child(_video)
	move_child(_video, 1)  # above black, below label
	_video.play()

	if not ResourceLoader.exists(MAIN_VIDEO):
		push_warning("Video not found: %s — skipping to black" % MAIN_VIDEO)

	await get_tree().create_timer(1.0).timeout  # let the shot breathe before text appears
	if _skip_requested: return

	await _show_line_over_current_visual("BOREAS STATION // 12 YEARS AFTER CONTACT", 2.2)
	if _skip_requested: return

	# let video keep playing after text fades, hold on it a beat, then cut
	if is_instance_valid(_video) and _video.is_playing():
		await _video.finished
	if is_instance_valid(_video):
		_video.queue_free()

	await _fade_to_black(0.6)

# ---------- SHOT 2: procedural beacon, text overlaid on the visual ----------

func _play_beat_beacon() -> void:
	var beacon_layer := Node2D.new()
	add_child(beacon_layer)
	move_child(beacon_layer, 1)

	var vp := get_viewport().get_visible_rect().size
	var glow := ColorRect.new()
	glow.size = Vector2(40, 40)
	glow.position = vp / 2.0 - glow.size / 2.0
	glow.color = Color(0.3, 0.6, 1.0)
	glow.pivot_offset = glow.size / 2.0
	beacon_layer.add_child(glow)

	var pulse := create_tween()
	pulse.set_loops()
	pulse.tween_property(glow, "modulate:a", 0.2, 0.9).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(glow, "modulate:a", 1.0, 0.9).set_trans(Tween.TRANS_SINE)
	pulse.parallel().tween_property(glow, "scale", Vector2(1.15, 1.15), 0.9)
	pulse.chain().tween_property(glow, "scale", Vector2(1.0, 1.0), 0.9)

	await get_tree().create_timer(0.6).timeout  # let the pulse establish before text
	if not _skip_requested:
		await _show_line_over_current_visual("The salvage beacon is still transmitting.", 2.6)

	pulse.kill()
	beacon_layer.queue_free()
	await _fade_to_black(0.4)

# ---------- SHOT 3: operators — video OR procedural fallback, text overlaid ----------

func _play_beat_operators() -> void:
	if _use_video_operators:
		_video = VideoStreamPlayer.new()
		_video.stream = load(VIDEO_OPERATORS)
		_video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_video.expand = true
		add_child(_video)
		move_child(_video, 1)
		_video.play()

		await get_tree().create_timer(0.8).timeout
		if not _skip_requested:
			await _show_line_over_current_visual("Two operators enter the dark.", 2.0)

		if is_instance_valid(_video) and _video.is_playing():
			await _video.finished
		if is_instance_valid(_video):
			_video.queue_free()
		await _fade_to_black(0.6)
	else:
		var layer := await _start_procedural_operators_silhouette()
		if not _skip_requested:
			await _show_line_over_current_visual("Two operators enter the dark.", 2.0)
		if is_instance_valid(layer):
			layer.queue_free()
		await _fade_to_black(0.4)

func _start_procedural_operators_silhouette() -> Node2D:
	var layer := Node2D.new()
	add_child(layer)
	move_child(layer, 1)

	var vp := get_viewport().get_visible_rect().size
	var fig_a := ColorRect.new()
	var fig_b := ColorRect.new()
	for fig in [fig_a, fig_b]:
		fig.size = Vector2(16, 40)
		fig.color = Color(0.05, 0.05, 0.06)
		layer.add_child(fig)

	fig_a.position = Vector2(vp.x * 0.3, vp.y * 0.75)
	fig_b.position = Vector2(vp.x * 0.4, vp.y * 0.8)

	var move := create_tween()
	move.set_parallel(true)
	move.tween_property(fig_a, "position", Vector2(vp.x * 0.48, vp.y * 0.5), 2.5)
	move.tween_property(fig_b, "position", Vector2(vp.x * 0.52, vp.y * 0.52), 2.5)

	return layer

# ---------- SHOT 4: waiting — video OR procedural fallback, text + shake overlaid ----------

func _play_beat_waiting() -> void:
	if _use_video_waiting:
		_video = VideoStreamPlayer.new()
		_video.stream = load(VIDEO_WAITING)
		_video.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_video.expand = true
		add_child(_video)
		move_child(_video, 1)
		_video.play()

		await get_tree().create_timer(0.8).timeout
		if not _skip_requested:
			await _show_line_over_current_visual("The station is waiting.", 2.4, true)

		if is_instance_valid(_video) and _video.is_playing():
			await _video.finished
		if is_instance_valid(_video):
			_video.queue_free()
		await _fade_to_black(0.6)
	else:
		var layer := await _start_procedural_corridor()
		if not _skip_requested:
			await _show_line_over_current_visual("The station is waiting.", 2.4, true)
		if is_instance_valid(layer):
			layer.queue_free()
		await _fade_to_black(0.4)

func _start_procedural_corridor() -> Node2D:
	var corridor_layer := Node2D.new()
	add_child(corridor_layer)
	move_child(corridor_layer, 1)

	var flicker := ColorRect.new()
	flicker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flicker.color = Color(0.5, 0.05, 0.05, 0.0)
	corridor_layer.add_child(flicker)

	# fire-and-forget flicker loop that keeps running under the text
	var flicker_loop := func():
		while is_instance_valid(flicker):
			var target_a := randf_range(0.05, 0.25)
			var t := create_tween()
			t.tween_property(flicker, "color:a", target_a, randf_range(0.1, 0.4))
			await t.finished
			await get_tree().create_timer(randf_range(0.2, 0.6)).timeout
	flicker_loop.call()

	return corridor_layer

# ---------- TEXT OVERLAY HELPER (renders on top of whatever's currently showing) ----------

func _show_line_over_current_visual(text: String, hold: float, shake: bool = false) -> void:
	if _skip_requested:
		return
	_label.text = ""
	_label.modulate.a = 1.0
	for i in range(text.length() + 1):
		if _skip_requested:
			_label.text = text
			break
		_label.text = text.substr(0, i)
		await get_tree().create_timer(0.035).timeout

	if shake:
		await _screen_shake(0.4, 6.0)

	await get_tree().create_timer(hold).timeout
	if _skip_requested:
		return

	var fade := create_tween()
	fade.tween_property(_label, "modulate:a", 0.0, 0.8)
	await fade.finished

func _fade_to_black(duration: float) -> void:
	_black.color.a = 0.0
	_black.show()
	var fade := create_tween()
	fade.tween_property(_black, "color:a", 1.0, duration)
	await fade.finished

func _screen_shake(duration: float, strength: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		self.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * strength
		await get_tree().create_timer(0.03).timeout
		elapsed += 0.03
	self.offset = Vector2.ZERO

# ---------- SKIP / FINISH ----------

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		_skip_requested = true
		if is_instance_valid(_video):
			_video.stop()

func _finish() -> void:
	cutscene_finished.emit()
	queue_free()
