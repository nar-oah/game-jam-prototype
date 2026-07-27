@tool
class_name PrototypeModel
extends RefCounted

const START_TERM_MONTH := 35
const TERM_END_MONTH := 48
const VOTE_THRESHOLD := 31
const TOTAL_SEATS := 60

const BASE_STATS := {
	"wage": 8,
	"price": 14,
	"jobs": 9,
	"business": 10,
	"services": 7,
	"budget": 8,
}

var term_month := START_TERM_MONTH
var event_months := 13
var collapse := 8
var donation := 0
var prediction_handled := false
var prediction_recorded := false
var newspaper_confirmed := false
var action_used := false
var vote_used := false
var agriculture_visit_available := false
var agriculture_negotiated := false
var result := ""
var result_detail := ""
var last_vote: Dictionary = {}
var lost_cd_total := 0

var definitions: Dictionary = {}
var library: Dictionary = {}
var current_bill: Array[Dictionary] = []
var draft: Array[String] = []
var claimed_pledges: Dictionary = {}
var history: Array[String] = []


func _init() -> void:
	reset()


func reset() -> void:
	term_month = START_TERM_MONTH
	event_months = 13
	collapse = 8
	donation = 0
	prediction_handled = false
	prediction_recorded = false
	newspaper_confirmed = false
	action_used = false
	vote_used = false
	agriculture_visit_available = false
	agriculture_negotiated = false
	result = ""
	result_detail = ""
	last_vote = {}
	lost_cd_total = 0
	claimed_pledges.clear()
	current_bill.clear()
	draft.clear()
	history = ["第35月：农业研究员带着一份尚未证实的预测来访。"]
	definitions = _make_definitions()
	library.clear()
	for proposal_id in [
		"gov_min_wage",
		"gov_essentials",
		"gov_public_jobs",
		"gov_progressive_tax",
		"party_labor",
		"interest_pharma",
	]:
		library[proposal_id] = definitions[proposal_id]


func _make_definitions() -> Dictionary:
	var proposals := {}
	proposals["gov_min_wage"] = _proposal(
		"gov_min_wage", "最低工资提高", "government", 6,
		{"wage": 4, "business": -2},
		["劳动", "收入", "消费"], 0, 0, 5
	)
	proposals["gov_essentials"] = _proposal(
		"gov_essentials", "生活必需品补贴", "government", 3,
		{"price": -3, "budget": -3},
		["补贴", "消费", "公共服务"], 0, 0, 4
	)
	proposals["gov_public_jobs"] = _proposal(
		"gov_public_jobs", "公共就业计划", "government", 8,
		{"jobs": 5, "budget": -4},
		["劳动", "公共服务", "补贴"], 0, 0, 6
	)
	proposals["gov_progressive_tax"] = _proposal(
		"gov_progressive_tax", "累进税改革", "government", 5,
		{"budget": 4, "business": -2},
		["税收", "监管"], 0, 0, 8
	)
	proposals["party_labor"] = _proposal(
		"party_labor", "全民失业补助", "party", 3,
		{"services": 2, "budget": -4, "business": -1},
		["劳动", "公共服务", "补贴"], 0, 0, 0, "工党"
	)
	proposals["interest_pharma"] = _proposal(
		"interest_pharma", "药品企业减税", "interest", 4,
		{"budget": -3, "services": 1, "price": 1},
		["医疗", "企业", "减税"], 6, 3, 0
	)
	proposals["interest_finance"] = _proposal(
		"interest_finance", "消费信贷扩张", "interest", 2,
		{"wage": 1, "price": -2, "budget": -2},
		["金融", "消费", "延缓"], 7, 3, 0
	)
	return proposals


func _proposal(
	proposal_id: String,
	title: String,
	kind: String,
	cd: int,
	effects: Dictionary,
	tags: Array,
	lobby: int,
	pledge: int,
	opposition: int,
	party: String = "",
	stamp: String = ""
) -> Dictionary:
	return {
		"id": proposal_id,
		"title": title,
		"kind": kind,
		"cd": cd,
		"effects": effects,
		"tags": tags,
		"lobby": lobby,
		"pledge": pledge,
		"opposition": opposition,
		"party": party,
		"stamp": stamp,
	}


func resolve_prediction(recorded: bool) -> void:
	prediction_handled = true
	prediction_recorded = recorded
	history.append(
		"已将乳制品过剩预测记入时间轴。"
		if recorded
		else "选择不记录未经证实的乳制品过剩预测。"
	)


func accept_finance_offer() -> void:
	if action_used or library.has("interest_finance"):
		return
	library["interest_finance"] = definitions["interest_finance"]
	action_used = true
	history.append("主动求援：接受金融集团不可谈判的最终报价。")


func decline_finance_offer() -> void:
	if action_used:
		return
	action_used = true
	history.append("拒绝金融集团最终报价，本月主动行动已使用。")


func make_agriculture_preview(
	size_choice: int,
	execution_choice: int,
	pledge_choice: int
) -> Dictionary:
	var size_data: Array[Dictionary] = [
		{"budget": -2, "lobby": 3, "name": "小规模"},
		{"budget": -3, "lobby": 5, "name": "中规模"},
		{"budget": -5, "lobby": 7, "name": "大规模"},
	]
	var execution_data: Array[Dictionary] = [
		{
			"cd": 1,
			"effects": {"price": -1},
			"tags": ["农业", "延缓", "补贴"],
			"name": "直接收储",
		},
		{
			"cd": 3,
			"effects": {"services": 1},
			"tags": ["农业", "公共服务", "补贴"],
			"name": "学校采购",
		},
		{
			"cd": 2,
			"effects": {"business": 1, "budget": -1},
			"tags": ["农业", "企业", "补贴"],
			"name": "出口补贴",
		},
	]
	var pledge_data: Array[Dictionary] = [
		{"pledge": 1, "effects": {"price": -1}, "name": "低献金"},
		{"pledge": 2, "effects": {}, "name": "中献金"},
		{"pledge": 4, "effects": {"budget": -1}, "name": "高献金"},
	]
	var selected_size: Dictionary = size_data[clampi(size_choice, 0, 2)]
	var selected_execution: Dictionary = execution_data[clampi(execution_choice, 0, 2)]
	var selected_pledge: Dictionary = pledge_data[clampi(pledge_choice, 0, 2)]
	var effects := {"budget": int(selected_size["budget"])}
	_merge_effects(effects, selected_execution["effects"])
	_merge_effects(effects, selected_pledge["effects"])
	return _proposal(
		"interest_agriculture",
		"政府乳制品收储",
		"interest",
		int(selected_execution["cd"]),
		effects,
		selected_execution["tags"],
		int(selected_size["lobby"]),
		int(selected_pledge["pledge"]),
		0,
		"",
		"%s · %s · %s" % [
			selected_size["name"],
			selected_execution["name"],
			selected_pledge["name"],
		]
	)


func confirm_agriculture_offer(
	size_choice: int,
	execution_choice: int,
	pledge_choice: int
) -> void:
	if agriculture_negotiated:
		return
	var proposal := make_agriculture_preview(
		size_choice, execution_choice, pledge_choice
	)
	definitions["interest_agriculture"] = proposal
	library["interest_agriculture"] = proposal
	agriculture_negotiated = true
	agriculture_visit_available = false
	history.append("谈判完成：农业集团《%s》进入提案库。" % proposal["stamp"])


func dismiss_agriculture_visit() -> void:
	agriculture_visit_available = false
	history.append("本月没有接待农业集团，主动来访提案暂时错过。")


func toggle_draft(proposal_id: String) -> void:
	if not library.has(proposal_id) or vote_used:
		return
	if draft.has(proposal_id):
		draft.erase(proposal_id)
	else:
		draft.append(proposal_id)


func set_draft_from_current() -> void:
	draft.clear()
	for entry in current_bill:
		draft.append(String(entry["id"]))


func get_definition(proposal_id: String) -> Dictionary:
	var definition: Dictionary = definitions.get(proposal_id, {})
	return definition


func get_current_entry(proposal_id: String) -> Dictionary:
	for entry in current_bill:
		if entry["id"] == proposal_id:
			return entry
	return {}


func get_stats() -> Dictionary:
	var active_definitions: Array[Dictionary] = []
	for entry in current_bill:
		if bool(entry["active"]):
			active_definitions.append(get_definition(String(entry["id"])))
	return _calculate_stats(active_definitions)


func get_projected_stats() -> Dictionary:
	var proposal_definitions: Array[Dictionary] = []
	for proposal_id in draft:
		proposal_definitions.append(get_definition(proposal_id))
	return _calculate_stats(proposal_definitions)


func _calculate_stats(proposal_definitions: Array[Dictionary]) -> Dictionary:
	var stats: Dictionary = BASE_STATS.duplicate(true)
	for proposal in proposal_definitions:
		_merge_effects(stats, proposal["effects"])
	var tag_counts := _count_tags(proposal_definitions)
	if int(tag_counts.get("劳动", 0)) >= 2:
		stats["wage"] = int(stats["wage"]) + 1
	if (
		int(tag_counts.get("消费", 0)) >= 1
		and int(tag_counts.get("企业", 0)) >= 1
	):
		var price_reduction: int = maxi(0, int(BASE_STATS["price"]) - int(stats["price"]))
		stats["business"] = int(stats["business"]) + price_reduction / 2
	return stats


func _merge_effects(target: Dictionary, effects: Dictionary) -> void:
	for stat_key in effects:
		target[stat_key] = int(target.get(stat_key, 0)) + int(effects[stat_key])


func _count_tags(proposal_definitions: Array[Dictionary]) -> Dictionary:
	var counts := {}
	for proposal in proposal_definitions:
		for tag in proposal["tags"]:
			counts[tag] = int(counts.get(tag, 0)) + 1
	return counts


func get_projected_synergies() -> Array[String]:
	var proposal_definitions: Array[Dictionary] = []
	for proposal_id in draft:
		proposal_definitions.append(get_definition(proposal_id))
	var counts := _count_tags(proposal_definitions)
	var synergies: Array[String] = []
	if int(counts.get("劳动", 0)) >= 2:
		synergies.append("劳动 2：平均工资额外 +1")
	if (
		int(counts.get("消费", 0)) >= 1
		and int(counts.get("企业", 0)) >= 1
	):
		synergies.append("消费 + 企业：每降低 2 点价格，企业活力 +1")
	return synergies


func get_event_assessment(stats: Dictionary) -> String:
	if int(stats["wage"]) >= 13 or int(stats["price"]) <= 10:
		return "solved"
	if int(stats["wage"]) >= 10 or int(stats["price"]) <= 12:
		return "strong_delay"
	if int(stats["wage"]) >= 9 or int(stats["price"]) <= 13:
		return "weak_delay"
	return "failed"


func get_vote_breakdown(bribe: int) -> Dictionary:
	var player_votes := 1
	var parties: Array[String] = []
	var lobby_votes := 0
	var opposition_votes := 0
	for proposal_id in draft:
		var proposal := get_definition(proposal_id)
		var party := String(proposal["party"])
		if not party.is_empty() and not parties.has(party):
			parties.append(party)
		lobby_votes += int(proposal["lobby"])
		opposition_votes += int(proposal["opposition"])
	var party_votes := 18 if parties.size() == 1 and parties[0] == "工党" else 0
	var promises := get_unclaimed_promises()
	var available := donation + promises
	var used_bribe := clampi(bribe, 0, available)
	var yes_votes := clampi(
		player_votes + party_votes + lobby_votes + used_bribe - opposition_votes,
		0,
		TOTAL_SEATS
	)
	return {
		"player": player_votes,
		"party": party_votes,
		"lobby": lobby_votes,
		"bribe": used_bribe,
		"opposition": opposition_votes,
		"promises": promises,
		"available": available,
		"yes": yes_votes,
		"passed": yes_votes >= VOTE_THRESHOLD,
	}


func get_unclaimed_promises() -> int:
	var total := 0
	for proposal_id in draft:
		if claimed_pledges.has(proposal_id):
			continue
		total += int(get_definition(proposal_id)["pledge"])
	return total


func submit_vote(bribe: int) -> Dictionary:
	if vote_used or draft.is_empty() or not result.is_empty():
		return {}
	var breakdown := get_vote_breakdown(bribe)
	vote_used = true
	last_vote = breakdown.duplicate(true)
	if bool(breakdown["passed"]):
		_enact_draft()
		donation = int(breakdown["available"]) - int(breakdown["bribe"])
		for proposal_id in draft:
			if int(get_definition(proposal_id)["pledge"]) > 0:
				claimed_pledges[proposal_id] = true
		history.append(
			"表决通过：%d / 60 票，新法案开始等待各自 CD。"
			% int(breakdown["yes"])
		)
	else:
		var stock_spent: int = maxi(
			0, int(breakdown["bribe"]) - int(breakdown["promises"])
		)
		donation = maxi(0, donation - stock_spent)
		history.append(
			"表决否决：%d / 60 票，现行法案保持不变。"
			% int(breakdown["yes"])
		)
	return breakdown


func _enact_draft() -> void:
	var enacted: Array[Dictionary] = []
	for proposal_id in draft:
		var old_entry := get_current_entry(proposal_id)
		if not old_entry.is_empty():
			enacted.append(old_entry.duplicate(true))
			continue
		var proposal := get_definition(proposal_id)
		var cd := int(proposal["cd"])
		enacted.append({
			"id": proposal_id,
			"remaining_cd": cd,
			"active": cd <= 0,
		})
	for old_entry in current_bill:
		var old_id := String(old_entry["id"])
		if draft.has(old_id):
			continue
		var original_cd := int(get_definition(old_id)["cd"])
		var remaining_cd := int(old_entry["remaining_cd"])
		lost_cd_total += original_cd if bool(old_entry["active"]) else original_cd - remaining_cd
	current_bill = enacted


func get_pending_cd_loss() -> int:
	var total := 0
	for entry in current_bill:
		if draft.has(String(entry["id"])):
			continue
		var original_cd := int(get_definition(String(entry["id"]))["cd"])
		var remaining_cd := int(entry["remaining_cd"])
		total += original_cd if bool(entry["active"]) else original_cd - remaining_cd
	return total


func advance_month() -> Dictionary:
	if not prediction_handled or not result.is_empty():
		return {}
	var activated: Array[String] = []
	for entry in current_bill:
		if bool(entry["active"]):
			continue
		entry["remaining_cd"] = maxi(0, int(entry["remaining_cd"]) - 1)
		if int(entry["remaining_cd"]) <= 0:
			entry["active"] = true
			activated.append(String(get_definition(String(entry["id"]))["title"]))
	event_months = maxi(0, event_months - 1)
	term_month += 1
	action_used = false
	vote_used = false
	last_vote.clear()
	if not activated.is_empty():
		history.append("政策生效：%s。" % "、".join(activated))
	if term_month == 43 and not agriculture_negotiated:
		agriculture_visit_available = true
		history.append("第43月：农业集团主动来访，可谈判乳制品收储条款。")
	var just_confirmed := false
	if event_months <= 3 and not newspaper_confirmed:
		newspaper_confirmed = true
		just_confirmed = true
		history.append("报纸确认：全国乳制品库存创历史新高。")
	if event_months <= 0:
		_resolve_due_event()
	return {
		"activated": activated,
		"visitor": agriculture_visit_available,
		"newspaper": just_confirmed,
		"result": result,
	}


func _resolve_due_event() -> void:
	var stats := get_stats()
	var assessment := get_event_assessment(stats)
	match assessment:
		"solved":
			result = "solved"
			result_detail = "危机被彻底解决。政策在倒计时归零前完成生效。"
			history.append("任期第48月：乳制品过剩危机被彻底解决。")
		"strong_delay":
			event_months = 13
			result = "strong_delay"
			result_detail = "危机被强力延缓 13 个月，已推至本届任期之后。"
			history.append("任期第48月：危机被延缓13个月，但问题并未根治。")
		"weak_delay":
			event_months = 6
			result = "weak_delay"
			result_detail = "危机被勉强延缓 6 个月，已越过本届任期线。"
			history.append("任期第48月：危机被勉强延缓6个月。")
		_:
			collapse = mini(10, collapse + 2)
			result = "failed"
			result_detail = "危机爆发，经济崩溃度从 8 上升到 %d。" % collapse
			history.append("任期第48月：危机爆发，经济崩溃度达到%d。" % collapse)


func can_contact_finance() -> bool:
	return (
		prediction_handled
		and not action_used
		and not library.has("interest_finance")
		and result.is_empty()
	)


func get_month_phase_text() -> String:
	if not prediction_handled:
		return "来访者简报"
	if newspaper_confirmed:
		return "危机已确认"
	if prediction_recorded:
		return "追踪早期预测"
	return "等待可靠信息"
