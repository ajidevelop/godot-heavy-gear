extends "ContextBase.gd"

const Constants = preload("res://scripts/Constants.gd")
const HexUtils = preload("res://scripts/HexUtils.gd")
const DirectionArc = preload("res://scripts/GUI/DirectionArc.tscn")

onready var direction_marker
onready var done_button = $MarginContainer/HBoxContainer/DoneButton
onready var label = $MarginContainer/HBoxContainer/Label

var rotate_unit
var allowed_dirs #if set, limit rotation to the specified dirs

var last_clicked

func _ready():
	var world_map = get_tree().get_root().find_node("WorldMap", true, false)
	
	direction_marker = DirectionArc.instance()
	direction_marker.z_as_relative = false
	direction_marker.z_index = Constants.HUD_ZLAYER
	world_map.add_child(direction_marker)

func activated(args):
	.activated(args)
	label.text = "Select direction to rotate unit."
	
	rotate_unit = args.rotate_unit
	if rotate_unit.has_facing() && args.max_turns && args.max_turns < HexUtils.DIR_WRAP/2:
		var min_turn = rotate_unit.facing - args.max_turns
		var max_turn = rotate_unit.facing + args.max_turns
		allowed_dirs = HexUtils.arc_dirs(min_turn, max_turn)
		
		direction_marker.global_position = rotate_unit.map_marker.global_position
		direction_marker.clear()
		for dir in allowed_dirs:
			direction_marker.set_dir(dir, true)
		direction_marker.show()

func deactivated():
	.deactivated()
	rotate_unit = null
	allowed_dirs = null
	
	last_clicked = null
	direction_marker.hide()
	add_child(direction_marker)

func unit_cell_input(world_map, cell_pos, event):
	if event.is_action_pressed("click_select"):
		if cell_pos == last_clicked:
			_done_button_pressed()
		elif cell_pos != rotate_unit.cell_position:
			var arm = world_map.get_grid_pos(cell_pos) - world_map.get_grid_pos(rotate_unit.cell_position)
			var dir = HexUtils.nearest_dir(arm.angle())
			
			if allowed_dirs && !allowed_dirs.has(dir):
				dir = _get_closest_dir(dir) ## get the closest allowed dir
			
			rotate_unit.facing = dir
			last_clicked = cell_pos
			label.text = "Select direction to rotate unit (or click again to confirm)."

func _get_closest_dir(dir):
	var best_dir
	var best_dist
	
	for adir in allowed_dirs:
		var dist = abs(HexUtils.get_shortest_turn(dir, adir))
		if !best_dist || dist < best_dist:
			best_dir = adir
			best_dist = dist
	
	return best_dir

func _done_button_pressed():
	context_manager.deactivate()
