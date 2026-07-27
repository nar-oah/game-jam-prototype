@tool
extends McpTestSuite

const ModelScript = preload("res://scripts/prototype_model.gd")


func suite_name() -> String:
	return "prototype_rules"


func test_early_information_route_can_solve_the_crisis() -> void:
	var model = ModelScript.new()
	model.resolve_prediction(true)
	model.accept_finance_offer()
	_add_to_draft(model, [
		"gov_min_wage",
		"party_labor",
		"interest_pharma",
		"interest_finance",
	])
	var preview: Dictionary = model.get_vote_breakdown(4)
	assert_eq(preview["yes"], 31, "early bill should reach the threshold with 4 pledge votes")
	assert_true(preview["passed"])
	model.submit_vote(4)
	for _month in range(13):
		model.advance_month()
	assert_eq(model.result, "solved")
	assert_gt(model.get_stats()["wage"], 12)


func test_late_confirmed_route_can_only_delay() -> void:
	var model = ModelScript.new()
	model.resolve_prediction(false)
	for _month in range(8):
		model.advance_month()
	assert_eq(model.term_month, 43)
	assert_true(model.agriculture_visit_available)
	model.confirm_agriculture_offer(1, 0, 1)
	for _month in range(2):
		model.advance_month()
	assert_true(model.newspaper_confirmed)
	model.accept_finance_offer()
	_add_to_draft(model, [
		"party_labor",
		"interest_agriculture",
		"interest_finance",
	])
	var preview: Dictionary = model.get_vote_breakdown(0)
	assert_eq(preview["yes"], 31)
	model.submit_vote(0)
	for _month in range(3):
		model.advance_month()
	assert_eq(model.result, "strong_delay")
	assert_eq(model.event_months, 13)


func test_ignoring_the_crisis_reaches_collapse_limit() -> void:
	var model = ModelScript.new()
	model.resolve_prediction(false)
	for _month in range(13):
		model.advance_month()
	assert_eq(model.result, "failed")
	assert_eq(model.collapse, 10)


func test_same_proposal_keeps_cd_and_readding_resets_it() -> void:
	var model = ModelScript.new()
	model.resolve_prediction(true)
	model.accept_finance_offer()
	_add_to_draft(model, [
		"party_labor",
		"interest_pharma",
		"interest_finance",
	])
	model.submit_vote(0)
	model.advance_month()
	assert_eq(model.get_current_entry("interest_finance")["remaining_cd"], 1)
	model.set_draft_from_current()
	model.submit_vote(0)
	assert_eq(model.get_current_entry("interest_finance")["remaining_cd"], 1)
	model.advance_month()
	model.draft.erase("interest_finance")
	model.submit_vote(6)
	assert_eq(model.lost_cd_total, 2)
	model.advance_month()
	model.draft.append("interest_finance")
	model.submit_vote(0)
	assert_eq(model.get_current_entry("interest_finance")["remaining_cd"], 2)


func test_labor_synergy_changes_projected_threshold() -> void:
	var model = ModelScript.new()
	_add_to_draft(model, ["gov_min_wage", "party_labor"])
	var stats: Dictionary = model.get_projected_stats()
	assert_eq(stats["wage"], 13)
	assert_contains(model.get_projected_synergies(), "劳动 2：平均工资额外 +1")


func _add_to_draft(model, proposal_ids: Array) -> void:
	for proposal_id in proposal_ids:
		model.draft.append(String(proposal_id))
