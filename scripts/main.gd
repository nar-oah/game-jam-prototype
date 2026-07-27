extends Control

const ModelScript = preload("res://scripts/prototype_model.gd")
const VoteMeterScript = preload("res://scripts/vote_meter.gd")
const TimelineGaugeScript = preload("res://scripts/timeline_gauge.gd")

const BG := Color("#0c131b")
const PANEL := Color("#121c27")
const PANEL_ALT := Color("#182431")
const BORDER := Color("#2b3a49")
const TEXT := Color("#f2ebdc")
const MUTED := Color("#9ba9b7")
const TEAL := Color("#61c5b7")
const BLUE := Color("#7f9df2")
const GOLD := Color("#ddba70")
const PURPLE := Color("#c190cb")
const RED := Color("#f06b72")
const GREEN := Color("#78c99d")

const STAT_LABELS := {
	"wage": "平均工资",
	"price": "消费品价格",
	"jobs": "就业水平",
	"business": "企业活力",
	"services": "公共服务",
	"budget": "财政余量",
}

const PROPOSAL_ORDER := [
	"gov_min_wage",
	"gov_essentials",
	"gov_public_jobs",
	"gov_progressive_tax",
	"party_labor",
	"interest_pharma",
	"interest_finance",
	"interest_agriculture",
]

var model
var bribe_value := 0
var modal_kind := ""
var agriculture_size := 1
var agriculture_execution := 0
var agriculture_pledge := 1

var month_label: Label
var collapse_label: Label
var donation_label: Label
var phase_label: Label
var intel_title: Label
var intel_body: RichTextLabel
var history_label: RichTextLabel
var timeline_gauge
var visitor_button: Button
var library_list: VBoxContainer
var draft_list: VBoxContainer
var current_list: VBoxContainer
var vote_meter
var vote_breakdown_label: Label
var vote_state_label: Label
var loss_warning_label: Label
var stat_value_labels: Dictionary = {}
var assessment_label: Label
var synergy_label: RichTextLabel
var cd_label: RichTextLabel
var finance_button: Button
var agriculture_button: Button
var bribe_label: Label
var bribe_minus: Button
var bribe_plus: Button
var vote_button: Button
var advance_button: Button
var toast_label: Label
var modal_layer: ColorRect
var modal_panel: PanelContainer
var modal_content: VBoxContainer
var agriculture_preview: RichTextLabel
var agriculture_choice_buttons: Dictionary = {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	model = ModelScript.new()
	_build_interface()
	_refresh()
	resized.connect(queue_redraw)
	call_deferred("_show_prediction_modal")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	draw_circle(
		Vector2(size.x * 0.84, size.y * 0.13),
		minf(size.x, size.y) * 0.42,
		Color(0.12, 0.34, 0.34, 0.11)
	)
	draw_circle(
		Vector2(size.x * 0.08, size.y * 0.92),
		minf(size.x, size.y) * 0.33,
		Color(0.34, 0.24, 0.39, 0.09)
	)
	for index in range(12):
		var x := size.x * float(index) / 11.0
		draw_line(
			Vector2(x, 0),
			Vector2(x, size.y),
			Color(0.3, 0.45, 0.52, 0.025),
			1.0
		)


func _build_interface() -> void:
	var margin := MarginContainer.new()
	margin.name = "SafeArea"
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 14)
	margin.add_child(page)
	page.add_child(_build_header())
	page.add_child(_build_workspace())
	page.add_child(_build_action_bar())
	_build_toast()
	_build_modal_layer()


func _build_header() -> Control:
	var panel := _make_panel(PANEL, BORDER, 14, 18)
	panel.custom_minimum_size.y = 82
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)

	var identity := VBoxContainer.new()
	identity.add_theme_constant_override("separation", 2)
	var eyebrow := _make_label("有效期 / PLAYTEST PROTOTYPE", 11, TEAL)
	eyebrow.add_theme_constant_override("letter_spacing", 2)
	identity.add_child(eyebrow)
	var title := _make_label("任期后生效", 28, TEXT)
	title.add_theme_font_size_override("font_size", 28)
	identity.add_child(title)
	row.add_child(identity)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	month_label = _status_chip(row, "任期", BLUE)
	collapse_label = _status_chip(row, "崩溃度", RED)
	donation_label = _status_chip(row, "政治献金", GOLD)
	phase_label = _status_chip(row, "阶段", TEAL, 170)
	return panel


func _build_workspace() -> Control:
	var row := HBoxContainer.new()
	row.name = "Workspace"
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)

	var intel := _build_intelligence_panel()
	intel.custom_minimum_size.x = 330
	intel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(intel)

	var builder := _build_bill_panel()
	builder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	builder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(builder)

	var inspector := _build_inspector_panel()
	inspector.custom_minimum_size.x = 348
	inspector.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_child(inspector)
	return row


func _build_intelligence_panel() -> Control:
	var panel := _make_panel(PANEL, BORDER, 14, 16)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	panel.add_child(column)
	column.add_child(_section_heading("情报台", "INTELLIGENCE"))
	intel_title = _make_label("尚未确认的风险", 19, TEXT)
	column.add_child(intel_title)

	var gauge_center := CenterContainer.new()
	timeline_gauge = TimelineGaugeScript.new()
	timeline_gauge.name = "CrisisCountdown"
	gauge_center.add_child(timeline_gauge)
	column.add_child(gauge_center)

	intel_body = RichTextLabel.new()
	intel_body.name = "IntelligenceBrief"
	intel_body.bbcode_enabled = true
	intel_body.fit_content = true
	intel_body.custom_minimum_size.y = 118
	intel_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intel_body.add_theme_font_size_override("normal_font_size", 13)
	intel_body.add_theme_color_override("default_color", MUTED)
	column.add_child(intel_body)

	visitor_button = _make_button("重新打开来访简报", TEAL)
	visitor_button.name = "VisitorButton"
	visitor_button.pressed.connect(_on_visitor_button)
	column.add_child(visitor_button)

	var divider := HSeparator.new()
	divider.add_theme_color_override("separator", BORDER)
	column.add_child(divider)
	column.add_child(_make_label("本届记录", 13, MUTED))
	history_label = RichTextLabel.new()
	history_label.name = "HistoryLog"
	history_label.bbcode_enabled = true
	history_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	history_label.custom_minimum_size.y = 118
	history_label.scroll_active = true
	history_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	history_label.add_theme_font_size_override("normal_font_size", 12)
	history_label.add_theme_color_override("default_color", MUTED)
	column.add_child(history_label)
	return panel


func _build_bill_panel() -> Control:
	var panel := _make_panel(PANEL, BORDER, 14, 16)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	panel.add_child(column)

	var header := HBoxContainer.new()
	header.add_child(_section_heading("综合法案", "BILL BUILDER"))
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)
	vote_state_label = _pill_label("等待草案", MUTED)
	header.add_child(vote_state_label)
	column.add_child(header)

	vote_meter = VoteMeterScript.new()
	vote_meter.name = "VoteMeter"
	column.add_child(vote_meter)
	vote_breakdown_label = _make_label("", 12, MUTED)
	vote_breakdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(vote_breakdown_label)

	var lists := HBoxContainer.new()
	lists.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lists.add_theme_constant_override("separation", 10)
	var library_box := _proposal_column("提案库 · 点击加入", GOLD)
	library_list = library_box["list"]
	lists.add_child(library_box["root"])
	var draft_box := _proposal_column("草案 · 点击移除", TEAL)
	draft_list = draft_box["list"]
	lists.add_child(draft_box["root"])
	column.add_child(lists)

	var current_header := HBoxContainer.new()
	current_header.add_child(_make_label("现行法案 / 独立 CD", 13, MUTED))
	var current_spacer := Control.new()
	current_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_header.add_child(current_spacer)
	loss_warning_label = _make_label("", 12, RED)
	current_header.add_child(loss_warning_label)
	column.add_child(current_header)
	var current_scroll := ScrollContainer.new()
	current_scroll.custom_minimum_size.y = 94
	current_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	current_list = VBoxContainer.new()
	current_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	current_list.add_theme_constant_override("separation", 5)
	current_scroll.add_child(current_list)
	column.add_child(current_scroll)
	return panel


func _proposal_column(title: String, accent: Color) -> Dictionary:
	var panel := _make_panel(PANEL_ALT, BORDER, 10, 10)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 7)
	panel.add_child(column)
	var label := _make_label(title, 12, accent)
	column.add_child(label)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 7)
	scroll.add_child(list)
	column.add_child(scroll)
	return {"root": panel, "list": list}


func _build_inspector_panel() -> Control:
	var panel := _make_panel(PANEL, BORDER, 14, 16)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	column.add_child(_section_heading("政策预演", "IMPACT FORECAST"))

	var stats_header := GridContainer.new()
	stats_header.columns = 4
	stats_header.add_theme_constant_override("h_separation", 8)
	stats_header.add_child(_make_label("指标", 11, MUTED))
	stats_header.add_child(_make_label("基础", 11, MUTED))
	stats_header.add_child(_make_label("当前", 11, MUTED))
	stats_header.add_child(_make_label("草案", 11, TEAL))
	for stat_key in STAT_LABELS:
		stats_header.add_child(_make_label(STAT_LABELS[stat_key], 12, TEXT))
		stats_header.add_child(_make_label(str(ModelScript.BASE_STATS[stat_key]), 12, MUTED))
		var current_value := _make_label("", 12, TEXT)
		current_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_header.add_child(current_value)
		var projected_value := _make_label("", 13, TEAL)
		projected_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_header.add_child(projected_value)
		stat_value_labels[stat_key] = {
			"current": current_value,
			"projected": projected_value,
		}
	column.add_child(stats_header)

	var divider := HSeparator.new()
	divider.add_theme_color_override("separator", BORDER)
	column.add_child(divider)
	column.add_child(_make_label("危机结算预估", 12, MUTED))
	assessment_label = _pill_label("当前：将爆发", RED)
	assessment_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(assessment_label)

	column.add_child(_make_label("羁绊", 12, MUTED))
	synergy_label = RichTextLabel.new()
	synergy_label.bbcode_enabled = true
	synergy_label.fit_content = true
	synergy_label.custom_minimum_size.y = 66
	synergy_label.add_theme_font_size_override("normal_font_size", 12)
	synergy_label.add_theme_color_override("default_color", MUTED)
	column.add_child(synergy_label)

	column.add_child(_make_label("生效时间表", 12, MUTED))
	cd_label = RichTextLabel.new()
	cd_label.bbcode_enabled = true
	cd_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cd_label.custom_minimum_size.y = 148
	cd_label.add_theme_font_size_override("normal_font_size", 12)
	cd_label.add_theme_color_override("default_color", MUTED)
	cd_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(cd_label)

	var condition_box := _make_panel(Color("#101923"), Color("#344556"), 9, 10)
	var conditions := RichTextLabel.new()
	conditions.bbcode_enabled = true
	conditions.fit_content = true
	conditions.text = (
		"[color=#9ba9b7]解决[/color]  工资 ≥13  [color=#65717e]或[/color]  价格 ≤10\n"
		+ "[color=#9ba9b7]强延缓[/color]  工资 ≥10  [color=#65717e]或[/color]  价格 ≤12\n"
		+ "[color=#9ba9b7]弱延缓[/color]  工资 ≥9    [color=#65717e]或[/color]  价格 ≤13"
	)
	conditions.add_theme_font_size_override("normal_font_size", 12)
	condition_box.add_child(conditions)
	column.add_child(condition_box)
	return panel


func _build_action_bar() -> Control:
	var panel := _make_panel(PANEL, BORDER, 14, 14)
	panel.custom_minimum_size.y = 76
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	panel.add_child(row)

	finance_button = _make_button("主动联系金融集团  [F]", GOLD)
	finance_button.name = "FinanceContactButton"
	finance_button.pressed.connect(_show_finance_modal)
	row.add_child(finance_button)
	agriculture_button = _make_button("接待农业集团", GOLD)
	agriculture_button.name = "AgricultureVisitButton"
	agriculture_button.pressed.connect(_show_agriculture_modal)
	row.add_child(agriculture_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(_make_label("本次献金票", 12, MUTED))
	bribe_minus = _make_button("−", PURPLE, 42)
	bribe_minus.name = "BribeMinusButton"
	bribe_minus.pressed.connect(_change_bribe.bind(-1))
	row.add_child(bribe_minus)
	bribe_label = _pill_label("0", PURPLE)
	bribe_label.custom_minimum_size.x = 48
	bribe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(bribe_label)
	bribe_plus = _make_button("+", PURPLE, 42)
	bribe_plus.name = "BribePlusButton"
	bribe_plus.pressed.connect(_change_bribe.bind(1))
	row.add_child(bribe_plus)

	vote_button = _make_button("提交表决  [V]", TEAL, 150)
	vote_button.name = "SubmitVoteButton"
	vote_button.pressed.connect(_submit_vote)
	row.add_child(vote_button)
	advance_button = _make_button("推进一月  [N]", BLUE, 150)
	advance_button.name = "AdvanceMonthButton"
	advance_button.pressed.connect(_advance_month)
	row.add_child(advance_button)
	return panel


func _build_toast() -> void:
	toast_label = _pill_label("", TEAL)
	toast_label.name = "Toast"
	toast_label.visible = false
	toast_label.z_index = 20
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_label.position = Vector2(-240, 112)
	toast_label.custom_minimum_size = Vector2(480, 42)
	add_child(toast_label)


func _build_modal_layer() -> void:
	modal_layer = ColorRect.new()
	modal_layer.name = "ModalLayer"
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.color = Color(0.025, 0.045, 0.065, 0.82)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_layer.z_index = 50
	modal_layer.visible = false
	add_child(modal_layer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(center)
	modal_panel = _make_panel(Color("#17232f"), Color("#476071"), 16, 24)
	modal_panel.custom_minimum_size = Vector2(700, 0)
	center.add_child(modal_panel)
	modal_content = VBoxContainer.new()
	modal_content.add_theme_constant_override("separation", 13)
	modal_panel.add_child(modal_content)


func _refresh() -> void:
	month_label.text = "任期\n%d / 48 月" % model.term_month
	collapse_label.text = "崩溃度\n%d / 10" % model.collapse
	donation_label.text = "库存献金\n%d" % model.donation
	phase_label.text = "当前阶段\n%s" % model.get_month_phase_text()
	_refresh_intelligence()
	_refresh_proposal_lists()
	_refresh_vote()
	_refresh_inspector()
	_refresh_actions()


func _refresh_intelligence() -> void:
	var is_visible: bool = model.prediction_recorded or model.newspaper_confirmed
	timeline_gauge.set_state(
		model.event_months,
		is_visible,
		model.newspaper_confirmed
	)
	if model.newspaper_confirmed:
		intel_title.text = "全国乳制品库存创历史新高"
		intel_title.add_theme_color_override("font_color", _deadline_color())
		intel_body.text = (
			"[color=#f2ebdc][b]报纸确认 · 情报可靠[/b][/color]\n"
			+ "剩余 [color=%s][b]%d个月[/b][/color] · 爆发后崩溃度 +2\n"
			% [_deadline_color().to_html(), model.event_months]
			+ "政策必须先完成 CD，才会进入最终数值。"
		)
	elif model.prediction_recorded:
		intel_title.text = "乳制品过剩风险（预测）"
		intel_title.add_theme_color_override("font_color", TEAL)
		intel_body.text = (
			"[color=#61c5b7][b]农业研究员 · 提前预警[/b][/color]\n"
			+ "预测约在任期末显现，时间和门槛尚未确认。\n"
			+ "[color=#9ba9b7]报纸只会在剩余3个月时给出确定消息。[/color]"
		)
	else:
		intel_title.text = "时间轴上没有已记录风险"
		intel_title.add_theme_color_override("font_color", MUTED)
		intel_body.text = (
			"[color=#9ba9b7]你忽略了早期预测。[/color]\n"
			+ "如果风险真实存在，报纸仍会在最后3个月报道；"
			+ "届时长 CD 政策可能已来不及。"
		)
	if not model.prediction_handled:
		visitor_button.text = "处理农业研究员来访"
		visitor_button.visible = true
	elif model.agriculture_visit_available:
		visitor_button.text = "农业集团正在候见 · 可谈判"
		visitor_button.visible = true
	else:
		visitor_button.visible = false
	var entries: Array[String] = model.history
	var start: int = maxi(0, entries.size() - 6)
	var lines: Array[String] = []
	for index in range(start, entries.size()):
		lines.append("• %s" % entries[index])
	history_label.text = "[color=#8f9ead]%s[/color]" % "\n".join(lines)
	history_label.scroll_to_line(history_label.get_line_count())


func _refresh_proposal_lists() -> void:
	_clear_children(library_list)
	_clear_children(draft_list)
	_clear_children(current_list)
	for proposal_id in PROPOSAL_ORDER:
		if not model.library.has(proposal_id):
			continue
		library_list.add_child(_make_proposal_button(proposal_id, false))
	for proposal_id in model.draft:
		draft_list.add_child(_make_proposal_button(proposal_id, true))
	if model.draft.is_empty():
		draft_list.add_child(_empty_state("点击左侧提案，将它加入草案。"))
	if model.current_bill.is_empty():
		current_list.add_child(_empty_state("尚无法案生效。通过草案后，每张提案独立倒计时。"))
	else:
		for entry in model.current_bill:
			current_list.add_child(_make_current_row(entry))
	var pending_loss: int = model.get_pending_cd_loss()
	loss_warning_label.text = (
		"通过将损失 %d 月已等待 CD" % pending_loss
		if pending_loss > 0
		else ""
	)


func _make_proposal_button(proposal_id: String, in_draft_column: bool) -> Button:
	var proposal: Dictionary = model.get_definition(proposal_id)
	var button := Button.new()
	button.name = ("Draft_" if in_draft_column else "Library_") + proposal_id
	button.text = _proposal_card_text(proposal, in_draft_column)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 88
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = model.vote_used or not model.result.is_empty()
	button.tooltip_text = "点击移出草案" if in_draft_column else "点击加入/移出草案"
	button.pressed.connect(_toggle_proposal.bind(proposal_id))
	var selected: bool = model.draft.has(proposal_id)
	_style_proposal_button(button, String(proposal["kind"]), selected)
	return button


func _proposal_card_text(proposal: Dictionary, in_draft_column: bool) -> String:
	var kind_label: String = {
		"government": "政府",
		"party": "政党",
		"interest": "集团",
	}.get(String(proposal["kind"]), "提案")
	var prefix := "− " if in_draft_column else ("✓ " if model.draft.has(proposal["id"]) else "+ ")
	var second_line := "CD %d月" % int(proposal["cd"])
	if int(proposal["opposition"]) > 0:
		second_line += " · 反对 −%d票" % int(proposal["opposition"])
	if int(proposal["lobby"]) > 0:
		second_line += " · 游说 +%d票" % int(proposal["lobby"])
	if not String(proposal["party"]).is_empty():
		second_line += " · %s 18席" % proposal["party"]
	var third_line := _effects_text(proposal["effects"])
	var stamp := (
		"\n%s" % proposal["stamp"]
		if not String(proposal["stamp"]).is_empty()
		else ""
	)
	return "%s[%s] %s\n%s\n%s%s" % [
		prefix,
		kind_label,
		proposal["title"],
		second_line,
		third_line,
		stamp,
	]


func _make_current_row(entry: Dictionary) -> Control:
	var proposal: Dictionary = model.get_definition(String(entry["id"]))
	var panel := _make_panel(Color("#16222d"), _kind_color(proposal["kind"]), 8, 8)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	var title := _make_label("[%s] %s" % [
		_kind_short(proposal["kind"]),
		proposal["title"],
	], 12, TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var state: Label
	if bool(entry["active"]):
		state = _pill_label("已生效 · 盖章", GREEN)
	else:
		state = _pill_label("沙漏 %d月" % int(entry["remaining_cd"]), GOLD)
	row.add_child(state)
	return panel


func _refresh_vote() -> void:
	var preview: Dictionary = model.get_vote_breakdown(bribe_value)
	bribe_value = clampi(bribe_value, 0, int(preview["available"]))
	preview = model.get_vote_breakdown(bribe_value)
	vote_meter.set_breakdown(preview)
	vote_breakdown_label.text = (
		"总统党 %d  +  党团 %d  +  游说 %d  +  献金 %d  −  锁定反对 %d  =  %d"
		% [
			preview["player"],
			preview["party"],
			preview["lobby"],
			preview["bribe"],
			preview["opposition"],
			preview["yes"],
		]
	)
	var yes_votes := int(preview["yes"])
	if model.draft.is_empty():
		vote_state_label.text = "等待草案"
		_set_pill_color(vote_state_label, MUTED)
	elif yes_votes >= ModelScript.VOTE_THRESHOLD:
		vote_state_label.text = "预计通过 · %d票" % yes_votes
		_set_pill_color(vote_state_label, GREEN)
	else:
		vote_state_label.text = "还差 %d 票" % (ModelScript.VOTE_THRESHOLD - yes_votes)
		_set_pill_color(vote_state_label, RED)
	bribe_label.text = str(bribe_value)


func _refresh_inspector() -> void:
	var current: Dictionary = model.get_stats()
	var projected: Dictionary = model.get_projected_stats()
	for stat_key in STAT_LABELS:
		var labels: Dictionary = stat_value_labels[stat_key]
		labels["current"].text = str(current[stat_key])
		labels["projected"].text = str(projected[stat_key])
		var delta: int = int(projected[stat_key]) - int(ModelScript.BASE_STATS[stat_key])
		labels["projected"].tooltip_text = "相对基础值 %+d" % delta
	var assessment: String = model.get_event_assessment(projected)
	var assessment_data := {
		"solved": ["草案完全生效后：彻底解决", GREEN],
		"strong_delay": ["草案完全生效后：强延缓 13月", TEAL],
		"weak_delay": ["草案完全生效后：弱延缓 6月", GOLD],
		"failed": ["草案完全生效后：仍将爆发", RED],
	}
	assessment_label.text = assessment_data[assessment][0]
	_set_pill_color(assessment_label, assessment_data[assessment][1])
	var synergies: Array[String] = model.get_projected_synergies()
	synergy_label.text = (
		"[color=#61c5b7]✓ %s[/color]" % "\n✓ ".join(synergies)
		if not synergies.is_empty()
		else "[color=#65717e]尚未触发羁绊。尝试组合相同或互补标签。[/color]"
	)
	var cd_lines: Array[String] = []
	for proposal_id in model.draft:
		var proposal: Dictionary = model.get_definition(proposal_id)
		var current_entry: Dictionary = model.get_current_entry(proposal_id)
		if not current_entry.is_empty():
			var state_text := (
				"已生效，保留状态"
				if bool(current_entry["active"])
				else "保留剩余 CD %d月" % int(current_entry["remaining_cd"])
			)
			cd_lines.append("[color=#78c99d]保留[/color] %s · %s" % [
				proposal["title"],
				state_text,
			])
		else:
			var cd: int = int(proposal["cd"])
			var timing := "赶得上" if cd <= model.event_months else "来不及"
			var timing_color := "#78c99d" if cd <= model.event_months else "#f06b72"
			cd_lines.append("⌛ %s · %d月 · [color=%s]%s[/color]" % [
				proposal["title"],
				cd,
				timing_color,
				timing,
			])
	cd_label.text = (
		"\n".join(cd_lines)
		if not cd_lines.is_empty()
		else "[color=#65717e]加入提案后，这里会显示各自的政策滞后。[/color]"
	)


func _refresh_actions() -> void:
	finance_button.disabled = (
		not model.can_contact_finance()
		or not modal_kind.is_empty()
	)
	finance_button.text = (
		"金融最终报价已入库"
		if model.library.has("interest_finance")
		else (
			"本月主动行动已使用"
			if model.action_used
			else "主动联系金融集团  [F]"
		)
	)
	agriculture_button.visible = (
		model.agriculture_visit_available
		or model.agriculture_negotiated
	)
	agriculture_button.disabled = (
		not model.agriculture_visit_available
		or not modal_kind.is_empty()
	)
	agriculture_button.text = (
		"农业谈判提案已入库"
		if model.agriculture_negotiated
		else "接待农业集团 · 可谈判"
	)
	var preview: Dictionary = model.get_vote_breakdown(bribe_value)
	bribe_minus.disabled = bribe_value <= 0 or model.vote_used
	bribe_plus.disabled = (
		bribe_value >= int(preview["available"])
		or model.vote_used
	)
	vote_button.disabled = (
		not model.prediction_handled
		or model.draft.is_empty()
		or model.vote_used
		or not model.result.is_empty()
	)
	vote_button.text = (
		"本月已表决"
		if model.vote_used
		else "提交表决 %d票  [V]" % int(preview["yes"])
	)
	advance_button.disabled = (
		not model.prediction_handled
		or not model.result.is_empty()
	)
	advance_button.text = "推进至第%d月  [N]" % mini(48, model.term_month + 1)


func _toggle_proposal(proposal_id: String) -> void:
	if model.draft.has(proposal_id):
		var current_entry: Dictionary = model.get_current_entry(proposal_id)
		if not current_entry.is_empty():
			var invested: int = int(model.get_definition(proposal_id)["cd"])
			if not bool(current_entry["active"]):
				invested -= int(current_entry["remaining_cd"])
			if invested > 0:
				_show_toast("警告：若新法案通过，这 %d 个月 CD 进度会清零。" % invested, RED)
	model.toggle_draft(proposal_id)
	_refresh()


func _change_bribe(delta: int) -> void:
	var available := int(model.get_vote_breakdown(bribe_value)["available"])
	bribe_value = clampi(bribe_value + delta, 0, available)
	_refresh()


func _submit_vote() -> void:
	if vote_button.disabled:
		return
	var breakdown: Dictionary = model.submit_vote(bribe_value)
	if breakdown.is_empty():
		return
	bribe_value = 0
	_refresh()
	_show_vote_result_modal(breakdown)


func _advance_month() -> void:
	if advance_button.disabled:
		return
	var tick: Dictionary = model.advance_month()
	if tick.is_empty():
		return
	_refresh()
	var activated: Array = tick["activated"]
	if not activated.is_empty():
		_show_toast("盖章生效：%s" % "、".join(activated), GREEN)
	if not String(tick["result"]).is_empty():
		_show_result_modal()
	elif bool(tick["visitor"]):
		_show_agriculture_modal()
	elif bool(tick["newspaper"]):
		_show_newspaper_modal()


func _on_visitor_button() -> void:
	if not model.prediction_handled:
		_show_prediction_modal()
	elif model.agriculture_visit_available:
		_show_agriculture_modal()


func _show_prediction_modal() -> void:
	_open_modal("prediction")
	_add_modal_eyebrow("主动来访 · 未经证实", TEAL)
	_add_modal_title("农业研究员的提前预警")
	_add_modal_body(
		"“现有收储和消费曲线正在背离。大约十三个月后，"
		+ "全国乳制品库存可能越过警戒线。”\n\n"
		+ "[color=#9ba9b7]来访者能提前预警，但时间和门槛可能带有稳定偏见；"
		+ "报纸永远正确，却只会在最后3个月报道。[/color]"
	)
	var response := _add_modal_response("你可以先追问，也可以直接决定是否记录。")
	var questions := HBoxContainer.new()
	questions.add_theme_constant_override("separation", 8)
	var evidence := _make_button("你凭什么这样判断？", TEAL)
	evidence.name = "AskEvidenceButton"
	evidence.pressed.connect(
		_set_response.bind(
			response,
			"“冷库周转率连续四季下降。农业协会仍在强调短缺，"
			+ "但他们一贯淡化未来过剩。”"
		)
	)
	questions.add_child(evidence)
	var beneficiary := _make_button("谁会从中获利？", TEAL)
	beneficiary.name = "AskBeneficiaryButton"
	beneficiary.pressed.connect(
		_set_response.bind(
			response,
			"“提前收储会让农业集团获利；但忽略风险，最后求援的报价会更差。”"
		)
	)
	questions.add_child(beneficiary)
	modal_content.add_child(questions)
	var actions := _modal_actions()
	var ignore := _make_button("不记录，等待报纸", MUTED)
	ignore.name = "IgnorePredictionButton"
	ignore.pressed.connect(_resolve_prediction.bind(false))
	actions.add_child(ignore)
	var record := _make_button("记录到时间轴", TEAL)
	record.name = "RecordPredictionButton"
	record.pressed.connect(_resolve_prediction.bind(true))
	actions.add_child(record)


func _resolve_prediction(recorded: bool) -> void:
	model.resolve_prediction(recorded)
	_close_modal()
	_refresh()
	_show_toast(
		"预测已记录：可以提前布局长 CD 政策。"
		if recorded
		else "预测已忽略：你将等待报纸确认。",
		TEAL if recorded else MUTED
	)


func _show_finance_modal() -> void:
	if not model.can_contact_finance():
		return
	_open_modal("finance")
	_add_modal_eyebrow("主动求援 · 最终报价", RED)
	_add_modal_title("金融集团：《消费信贷扩张》")
	_add_modal_body(
		"[color=#f06b72][b]不可谈判[/b][/color]  你主动找上门，集团掌握全部主动权。\n\n"
		+ "[color=#f2ebdc]CD 2月[/color]  ·  平均工资 +1  ·  消费品价格 −2"
		+ "  ·  财政余量 −2\n"
		+ "[color=#ddba70]游说票 +7  ·  承诺献金 +3[/color]\n"
		+ "[color=#9ba9b7]标签：金融 / 消费 / 延缓[/color]"
	)
	var warning := _add_modal_response(
		"越晚处理问题，越需要接受更差的牌。本月只有一次主动行动。"
	)
	warning.add_theme_color_override("default_color", GOLD)
	var actions := _modal_actions()
	var decline := _make_button("拒绝报价", MUTED)
	decline.name = "DeclineFinanceButton"
	decline.pressed.connect(_decline_finance_offer)
	actions.add_child(decline)
	var accept := _make_button("接受最终报价", RED)
	accept.name = "AcceptFinanceButton"
	accept.pressed.connect(_accept_finance_offer)
	actions.add_child(accept)


func _accept_finance_offer() -> void:
	model.accept_finance_offer()
	_close_modal()
	_refresh()
	_show_toast("最终报价已进入提案库：短 CD、高票数，但财政代价更大。", GOLD)


func _decline_finance_offer() -> void:
	model.decline_finance_offer()
	_close_modal()
	_refresh()
	_show_toast("已拒绝最终报价；可在下个月重新联系。", MUTED)


func _show_agriculture_modal() -> void:
	if not model.agriculture_visit_available:
		return
	agriculture_size = 1
	agriculture_execution = 0
	agriculture_pledge = 1
	agriculture_choice_buttons.clear()
	_open_modal("agriculture")
	_add_modal_eyebrow("集团主动来访 · 你拥有谈判权", GOLD)
	_add_modal_title("农业集团：《政府乳制品收储》")
	_add_modal_body(
		"集团给出多个可接受版本。没有满意度条，"
		+ "你可以在离开会面前自由调整条款。"
	)
	_add_agriculture_choice_row("收储规模", "size", ["小", "中", "大"], agriculture_size)
	_add_agriculture_choice_row(
		"执行方式",
		"execution",
		["直接收储", "学校采购", "出口补贴"],
		agriculture_execution
	)
	_add_agriculture_choice_row(
		"政治献金",
		"pledge",
		["低", "中", "高"],
		agriculture_pledge
	)
	agriculture_preview = RichTextLabel.new()
	agriculture_preview.name = "AgriculturePreview"
	agriculture_preview.bbcode_enabled = true
	agriculture_preview.fit_content = true
	agriculture_preview.custom_minimum_size.y = 108
	agriculture_preview.add_theme_font_size_override("normal_font_size", 13)
	agriculture_preview.add_theme_stylebox_override(
		"normal",
		_make_style(Color("#101923"), Color("#3d4f5d"), 9, 12)
	)
	modal_content.add_child(agriculture_preview)
	_update_agriculture_preview()
	var actions := _modal_actions()
	var dismiss := _make_button("暂不接待", MUTED)
	dismiss.name = "DismissAgricultureButton"
	dismiss.pressed.connect(_dismiss_agriculture)
	actions.add_child(dismiss)
	var confirm := _make_button("确认谈判版本", GOLD)
	confirm.name = "ConfirmAgricultureButton"
	confirm.pressed.connect(_confirm_agriculture)
	actions.add_child(confirm)


func _add_agriculture_choice_row(
	label_text: String,
	key: String,
	choices: Array,
	selected: int
) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var label := _make_label(label_text, 12, MUTED)
	label.custom_minimum_size.x = 94
	row.add_child(label)
	var buttons: Array[Button] = []
	for index in range(choices.size()):
		var button := _make_button(String(choices[index]), GOLD)
		button.name = "Agri_%s_%d" % [key, index]
		button.toggle_mode = true
		button.button_pressed = index == selected
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_set_agriculture_choice.bind(key, index))
		row.add_child(button)
		buttons.append(button)
	agriculture_choice_buttons[key] = buttons
	modal_content.add_child(row)


func _set_agriculture_choice(key: String, index: int) -> void:
	match key:
		"size":
			agriculture_size = index
		"execution":
			agriculture_execution = index
		"pledge":
			agriculture_pledge = index
	var buttons: Array = agriculture_choice_buttons[key]
	for button_index in range(buttons.size()):
		buttons[button_index].button_pressed = button_index == index
	_update_agriculture_preview()


func _update_agriculture_preview() -> void:
	var proposal: Dictionary = model.make_agriculture_preview(
		agriculture_size,
		agriculture_execution,
		agriculture_pledge
	)
	agriculture_preview.text = (
		"[color=#ddba70][b]%s[/b][/color]\n" % proposal["stamp"]
		+ "CD [color=#f2ebdc]%d月[/color]  ·  %s\n" % [
			proposal["cd"],
			_effects_text(proposal["effects"]),
		]
		+ "游说票 [color=#78c99d]+%d[/color]  ·  承诺献金 "
		% proposal["lobby"]
		+ "[color=#c190cb]+%d[/color]\n" % proposal["pledge"]
		+ "[color=#9ba9b7]标签：%s[/color]" % " / ".join(proposal["tags"])
	)


func _confirm_agriculture() -> void:
	model.confirm_agriculture_offer(
		agriculture_size,
		agriculture_execution,
		agriculture_pledge
	)
	_close_modal()
	_refresh()
	_show_toast("谈判完成：你定制的农业提案已进入提案库。", GOLD)


func _dismiss_agriculture() -> void:
	model.dismiss_agriculture_visit()
	_close_modal()
	_refresh()
	_show_toast("农业集团离开了。主动来访的谈判机会已经错过。", MUTED)


func _show_vote_result_modal(breakdown: Dictionary) -> void:
	_open_modal("vote")
	var passed: bool = breakdown["passed"]
	_add_modal_eyebrow(
		"议会第 %d 月表决" % model.term_month,
		GREEN if passed else RED
	)
	_add_modal_title("法案通过" if passed else "法案被否决")
	_add_modal_body(
		"[font_size=30][color=%s][b]%d / 60[/b][/color][/font_size]  "
		% [
			(GREEN if passed else RED).to_html(),
			breakdown["yes"],
		]
		+ "[color=#9ba9b7]过半线 31票[/color]\n\n"
		+ "总统党 %d  +  党团 %d  +  游说 %d  +  献金 %d  −  反对 %d"
		% [
			breakdown["player"],
			breakdown["party"],
			breakdown["lobby"],
			breakdown["bribe"],
			breakdown["opposition"],
		]
	)
	_add_modal_response(
		"新法案已替换现行法案。相同提案保留 CD，新增提案从完整 CD 开始。"
		if passed
		else "现行法案保持不变。本月不能再次试票，但可以检查差了哪些票。"
	)
	var actions := _modal_actions()
	var continue_button := _make_button("返回办公室", GREEN if passed else MUTED)
	continue_button.name = "CloseVoteResultButton"
	continue_button.pressed.connect(_close_modal)
	actions.add_child(continue_button)


func _show_newspaper_modal() -> void:
	_open_modal("newspaper")
	_add_modal_eyebrow("报纸头版 · 信息已确认", _deadline_color())
	_add_modal_title("全国乳制品库存创历史新高")
	_add_modal_body(
		"[font_size=24][color=%s][b]只剩 %d 个月[/b][/color][/font_size]\n\n"
		% [_deadline_color().to_html(), model.event_months]
		+ "爆发后：经济崩溃度 +2（当前 8 / 10）\n"
		+ "解决：平均工资 ≥13 或 消费品价格 ≤10\n"
		+ "延缓：平均工资 ≥10 或 消费品价格 ≤12\n\n"
		+ (
			"[color=#78c99d]你曾记录过这项预测，因此拥有更长的政策准备期。[/color]"
			if model.prediction_recorded
			else "[color=#f06b72]你没有提前记录风险；长 CD 政策现在可能来不及。[/color]"
		)
	)
	var actions := _modal_actions()
	var close := _make_button("打开法案夹", _deadline_color())
	close.name = "CloseNewspaperButton"
	close.pressed.connect(_close_modal)
	actions.add_child(close)


func _show_result_modal() -> void:
	_open_modal("result")
	var color := GREEN
	var eyebrow := "危机解除 · 原型路径完成"
	var title := "政策赶在危机前生效"
	if model.result == "strong_delay" or model.result == "weak_delay":
		color = GOLD
		eyebrow = "任期结束 · 危机越过选举线"
		title = "你赢得了时间，但没有解决问题"
	elif model.result == "failed":
		color = RED
		eyebrow = "系统性危机 · 原型路径失败"
		title = "市场在任期末崩溃"
	_add_modal_eyebrow(eyebrow, color)
	_add_modal_title(title)
	var final_stats: Dictionary = model.get_stats()
	_add_modal_body(
		"[font_size=18][color=%s][b]%s[/b][/color][/font_size]\n\n"
		% [color.to_html(), model.result_detail]
		+ "最终数值：工资 %d · 价格 %d · 就业 %d · 企业 %d · 公共 %d · 财政 %d\n"
		% [
			final_stats["wage"],
			final_stats["price"],
			final_stats["jobs"],
			final_stats["business"],
			final_stats["services"],
			final_stats["budget"],
		]
		+ "测试记录：%s预测 · 主动求援%s · 累计损失 CD %d月"
		% [
			"已记录" if model.prediction_recorded else "未记录",
			"是" if model.library.has("interest_finance") else "否",
			model.lost_cd_total,
		]
	)
	_add_modal_response(
		"本切片验证的是信息滞后、政策滞后和任期滞后。"
		+ "重新开始可尝试另一条路线：提前彻底解决、最后三月只延缓，或完全放任。"
	)
	var actions := _modal_actions()
	var inspect := _make_button("查看最终法案", MUTED)
	inspect.name = "InspectResultButton"
	inspect.pressed.connect(_close_modal)
	actions.add_child(inspect)
	var restart := _make_button("重新开始  [R]", color)
	restart.name = "RestartButton"
	restart.pressed.connect(_restart)
	actions.add_child(restart)


func _restart() -> void:
	model.reset()
	bribe_value = 0
	_close_modal()
	_refresh()
	call_deferred("_show_prediction_modal")


func _open_modal(kind: String) -> void:
	_clear_children(modal_content)
	modal_kind = kind
	modal_layer.visible = true
	modal_layer.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(modal_layer, "modulate:a", 1.0, 0.16)


func _close_modal() -> void:
	if modal_kind == "result" and not model.result.is_empty():
		modal_layer.visible = false
		modal_kind = ""
		_refresh_actions()
		return
	modal_layer.visible = false
	modal_kind = ""
	_refresh_actions()


func _add_modal_eyebrow(text: String, color: Color) -> void:
	var label := _make_label(text.to_upper(), 11, color)
	label.add_theme_constant_override("letter_spacing", 2)
	modal_content.add_child(label)


func _add_modal_title(text: String) -> void:
	var label := _make_label(text, 27, TEXT)
	label.add_theme_font_size_override("font_size", 27)
	modal_content.add_child(label)


func _add_modal_body(text: String) -> RichTextLabel:
	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.custom_minimum_size.y = 104
	body.text = text
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("normal_font_size", 14)
	body.add_theme_color_override("default_color", TEXT)
	modal_content.add_child(body)
	return body


func _add_modal_response(text: String) -> RichTextLabel:
	var response := RichTextLabel.new()
	response.name = "DialogResponse"
	response.bbcode_enabled = true
	response.fit_content = true
	response.custom_minimum_size.y = 64
	response.text = text
	response.add_theme_font_size_override("normal_font_size", 13)
	response.add_theme_color_override("default_color", MUTED)
	response.add_theme_stylebox_override(
		"normal",
		_make_style(Color("#101923"), Color("#304251"), 9, 12)
	)
	modal_content.add_child(response)
	return response


func _set_response(response: RichTextLabel, text: String) -> void:
	response.text = text


func _modal_actions() -> HBoxContainer:
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 9)
	modal_content.add_child(actions)
	return actions


func _show_toast(text: String, color: Color = TEAL) -> void:
	toast_label.text = text
	_set_pill_color(toast_label, color)
	toast_label.visible = true
	toast_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(toast_label, "modulate:a", 1.0, 0.12)
	tween.tween_interval(2.5)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.25)
	tween.tween_callback(toast_label.hide)


func _make_panel(
	bg_color: Color,
	border_color: Color,
	radius: int,
	padding: int
) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(
		"panel",
		_make_style(bg_color, border_color, radius, padding)
	)
	return panel


func _make_style(
	bg_color: Color,
	border_color: Color,
	radius: int,
	padding: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _section_heading(title: String, english: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 0)
	box.add_child(_make_label(english, 10, TEAL))
	box.add_child(_make_label(title, 17, TEXT))
	return box


func _status_chip(
	parent: Control,
	label_text: String,
	color: Color,
	width: int = 128
) -> Label:
	var label := _pill_label(label_text, color)
	label.custom_minimum_size = Vector2(width, 48)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


func _pill_label(text: String, color: Color) -> Label:
	var label := _make_label(text, 12, color)
	label.add_theme_stylebox_override(
		"normal",
		_make_style(color.darkened(0.74), color.darkened(0.28), 8, 8)
	)
	return label


func _set_pill_color(label: Label, color: Color) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_stylebox_override(
		"normal",
		_make_style(color.darkened(0.74), color.darkened(0.28), 8, 8)
	)


func _make_button(text: String, accent: Color, min_width: int = 0) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(min_width, 40)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color("#667381"))
	button.add_theme_stylebox_override(
		"normal",
		_make_style(accent.darkened(0.72), accent.darkened(0.34), 8, 10)
	)
	button.add_theme_stylebox_override(
		"hover",
		_make_style(accent.darkened(0.56), accent.darkened(0.12), 8, 10)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_make_style(accent.darkened(0.42), accent, 8, 10)
	)
	button.add_theme_stylebox_override(
		"disabled",
		_make_style(Color("#111923"), Color("#273442"), 8, 10)
	)
	return button


func _style_proposal_button(button: Button, kind: String, selected: bool) -> void:
	var accent := _kind_color(kind)
	var normal := accent.darkened(0.76 if selected else 0.84)
	var border := accent if selected else accent.darkened(0.4)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override(
		"normal",
		_make_style(normal, border, 9, 10)
	)
	button.add_theme_stylebox_override(
		"hover",
		_make_style(accent.darkened(0.67), accent, 9, 10)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_make_style(accent.darkened(0.52), accent, 9, 10)
	)
	button.add_theme_stylebox_override(
		"disabled",
		_make_style(Color("#121b24"), Color("#283542"), 9, 10)
	)


func _kind_color(kind: Variant) -> Color:
	match String(kind):
		"government":
			return BLUE
		"party":
			return PURPLE
		"interest":
			return GOLD
	return MUTED


func _kind_short(kind: Variant) -> String:
	return {
		"government": "政府",
		"party": "政党",
		"interest": "集团",
	}.get(String(kind), "提案")


func _effects_text(effects: Dictionary) -> String:
	var pieces: Array[String] = []
	for stat_key in STAT_LABELS:
		if not effects.has(stat_key):
			continue
		var value := int(effects[stat_key])
		pieces.append("%s %s%d" % [
			STAT_LABELS[stat_key],
			"+" if value > 0 else "",
			value,
		])
	return " · ".join(pieces)


func _empty_state(text: String) -> Label:
	var label := _make_label(text, 12, Color("#65717e"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size.y = 48
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _deadline_color() -> Color:
	if model.event_months <= 1:
		return RED
	if model.event_months == 2:
		return Color("#ff9d5c")
	return Color("#f2cc60")


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE and not modal_kind.is_empty():
		if modal_kind != "result":
			_close_modal()
		return
	if key_event.keycode == KEY_R and not model.result.is_empty():
		_restart()
		return
	if not modal_kind.is_empty():
		return
	match key_event.keycode:
		KEY_N:
			_advance_month()
		KEY_V:
			_submit_vote()
		KEY_F:
			_show_finance_modal()
