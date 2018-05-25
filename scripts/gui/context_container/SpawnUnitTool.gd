extends "ContextBase.gd"

const Unit = preload("res://scripts/units/Unit.tscn")
const Crew = preload("res://scripts/units/Crew.gd")

onready var player_button = $HBoxContainer/PlayerButton
onready var faction_button = $HBoxContainer/FactionButton
onready var unit_model_button = $HBoxContainer/UnitModelButton

var players = {}
var factions = {}
var unit_models = {}

func _ready():
	call_deferred("_ready_deferred")

func _ready_deferred():
	var root = get_tree().get_root().get_node("Main")
	var all_players = root.game_state.get_all_players()
	for i in range(all_players.size()):
		var player = all_players[i]
		player_button.add_item(player.display_name, i)
		players[i] = player
	
	var faction_ids = Factions.all_factions()
	for i in range(faction_ids.size()):
		var faction_id = faction_ids[i]
		var faction = Factions.get_info(faction_id)
		faction_button.add_item(faction.name, i)
		factions[i] = faction
		
		var models = {}
		for j in range(faction.unit_models.size()):
			var model_id = faction.unit_models[j]
			models[j] = UnitModels.get_info(model_id)
		unit_models[i] = models
	
	_update_model_list(faction_button.get_selected_id())

func _faction_button_item_selected(i):
	_update_model_list(i)

func _update_model_list(i):
	unit_model_button.clear()
	for j in unit_models[i]:
		var unit_info = unit_models[i][j]
		unit_model_button.add_item(unit_info.desc.name, j)

func cell_input(world_map, cell_pos, event):
	if event.is_action_pressed("click_select"):
		var spawn_unit = Unit.instance()
		
		var player_idx = player_button.get_selected_id()
		var player = players[player_idx]
		
		var faction_idx = faction_button.get_selected_id()
		var faction = factions[faction_idx]
		
		var model_idx = unit_model_button.get_selected_id()
		var unit_info = unit_models[faction_idx][model_idx]

		spawn_unit.set_player_owner(player)
		spawn_unit.set_faction(faction)
		spawn_unit.set_unit_info(unit_info)
		
		if world_map.unit_can_place(spawn_unit, cell_pos):
			var crew = Crew.new(faction, unit_info.get_default_crew())
			spawn_unit.set_crew_info(crew)
			
			spawn_unit.cell_position = cell_pos
			world_map.add_unit(spawn_unit)
			
			if spawn_unit.has_facing():
				context_manager.activate("select_facing", { unit = spawn_unit, forced = true })
			
		else:
			spawn_unit.queue_free()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		context_manager.deactivate()

func _done_button_pressed():
	context_manager.deactivate()

