class_name PrototypeTimelineGauge
extends Control

var months := 13
var visible_to_player := false
var confirmed := false


func _ready() -> void:
	custom_minimum_size = Vector2(142, 142)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_state(value: int, is_visible: bool, is_confirmed: bool) -> void:
	months = value
	visible_to_player = is_visible
	confirmed = is_confirmed
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.36
	var accent := _accent_color()
	draw_circle(center, radius + 10.0, Color("#18222d"))
	draw_arc(center, radius, -PI * 0.5, PI * 1.5, 72, Color("#344150"), 8.0)
	var ratio := clampf(float(months) / 13.0, 0.0, 1.0)
	draw_arc(
		center,
		radius,
		-PI * 0.5,
		-PI * 0.5 + TAU * ratio,
		72,
		accent,
		8.0
	)
	var font := ThemeDB.fallback_font
	var headline := str(months) if visible_to_player else "?"
	draw_string(
		font,
		Vector2(center.x - 46.0, center.y + 9.0),
		headline,
		HORIZONTAL_ALIGNMENT_CENTER,
		92.0,
		31,
		Color("#f6f0e3")
	)
	draw_string(
		font,
		Vector2(center.x - 46.0, center.y + 33.0),
		"个月" if visible_to_player else "未记录",
		HORIZONTAL_ALIGNMENT_CENTER,
		92.0,
		12,
		Color("#aab6c4")
	)
	var state_text := "报纸确认" if confirmed else ("预测记录" if visible_to_player else "未知风险")
	draw_string(
		font,
		Vector2(center.x - 56.0, size.y - 4.0),
		state_text,
		HORIZONTAL_ALIGNMENT_CENTER,
		112.0,
		12,
		accent
	)


func _accent_color() -> Color:
	if confirmed and months <= 1:
		return Color("#ff616a")
	if confirmed and months == 2:
		return Color("#ff9d5c")
	if confirmed:
		return Color("#f2cc60")
	if visible_to_player:
		return Color("#65c6bd")
	return Color("#5c6876")
