class_name PrototypeVoteMeter
extends Control

var breakdown: Dictionary = {
	"player": 0,
	"party": 0,
	"lobby": 0,
	"bribe": 0,
	"opposition": 0,
	"yes": 0,
}


func _ready() -> void:
	custom_minimum_size = Vector2(0, 42)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_breakdown(value: Dictionary) -> void:
	breakdown = value.duplicate(true)
	queue_redraw()


func _draw() -> void:
	var gap := 2.0
	var light_height := 22.0
	var cell_width := (size.x - gap * 59.0) / 60.0
	var yes_votes := int(breakdown.get("yes", 0))
	var opposition := int(breakdown.get("opposition", 0))
	var player_end := int(breakdown.get("player", 0))
	var party_end := player_end + int(breakdown.get("party", 0))
	var lobby_end := party_end + int(breakdown.get("lobby", 0))
	var bribe_end := lobby_end + int(breakdown.get("bribe", 0))
	for index in range(60):
		var color := Color("#26313f")
		if index < yes_votes:
			if index < player_end:
				color = Color("#8dd7c1")
			elif index < party_end:
				color = Color("#8fa7ff")
			elif index < lobby_end:
				color = Color("#e2bd71")
			elif index < bribe_end:
				color = Color("#d895d8")
			else:
				color = Color("#73c99e")
		elif index < yes_votes + opposition:
			color = Color("#9a4d54")
		var rect := Rect2(
			Vector2(index * (cell_width + gap), 4.0),
			Vector2(maxf(1.0, cell_width), light_height)
		)
		draw_rect(rect, color, true)
	var threshold_x := 31.0 * (cell_width + gap) - gap * 0.5
	draw_line(
		Vector2(threshold_x, 0),
		Vector2(threshold_x, 32),
		Color("#f4ead2"),
		2.0
	)
	var font := ThemeDB.fallback_font
	draw_string(
		font,
		Vector2(maxf(0.0, threshold_x - 34.0), 41.0),
		"31票",
		HORIZONTAL_ALIGNMENT_CENTER,
		68.0,
		11,
		Color("#aeb8c5")
	)
