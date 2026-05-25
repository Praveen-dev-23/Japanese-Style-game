extends Node

# Signals
signal coins_changed
signal inventory_changed
signal time_changed(hour, minute, period)
signal save_loaded
signal tool_changed(new_tool)
signal seed_changed(new_seed)

# Crop Metadata
const CROPS = {
	"rice_seed": {
		"name": "Rice",
		"seed_cost": 5,
		"sell_value": 15,
		"grow_days": 3,
		"item_name": "rice",
		"atlas_row": 0
	},
	"carrot_seed": {
		"name": "Carrot",
		"seed_cost": 8,
		"sell_value": 20,
		"grow_days": 2,
		"item_name": "carrot",
		"atlas_row": 1
	},
	"radish_seed": {
		"name": "Radish",
		"seed_cost": 12,
		"sell_value": 35,
		"grow_days": 4,
		"item_name": "radish",
		"atlas_row": 2
	},
	"tea_seed": {
		"name": "Tea Leaves",
		"seed_cost": 18,
		"sell_value": 50,
		"grow_days": 5,
		"item_name": "tea_leaves",
		"atlas_row": 3
	},
	"bamboo_seed": {
		"name": "Bamboo Shoots",
		"seed_cost": 30,
		"sell_value": 80,
		"grow_days": 6,
		"item_name": "bamboo_shoot",
		"atlas_row": 4
	}
}

# Fish Metadata
const FISH = {
	"koi": { "name": "Koi", "sell_value": 25, "atlas_col": 0 },
	"salmon": { "name": "Salmon", "sell_value": 30, "atlas_col": 1 },
	"catfish": { "name": "Catfish", "sell_value": 45, "atlas_col": 2 },
	"tuna": { "name": "Tuna", "sell_value": 75, "atlas_col": 3 },
	"golden_carp": { "name": "Golden Carp", "sell_value": 150, "atlas_col": 4 }
}

# Game State Variables
var coins: int = 100
var day: int = 1

# Time Variables
var game_hour: int = 6
var game_minute: int = 0
var time_period: String = "morning" # "morning", "evening", "night"
var is_time_paused: bool = false
var time_accumulator: float = 0.0
const MINUTE_DURATION: float = 0.15 # seconds per game minute (1 game hour = 9 seconds)

# Inventory
# format: { item_id (string): count (int) }
var inventory: Dictionary = {
	"rice_seed": 5,
	"carrot_seed": 3,
	"radish_seed": 2,
	"tea_seed": 1,
	"bamboo_seed": 1,
	"rice": 0,
	"carrot": 0,
	"radish": 0,
	"tea_leaves": 0,
	"bamboo_shoot": 0,
	"koi": 0,
	"salmon": 0,
	"catfish": 0,
	"tuna": 0,
	"golden_carp": 0
}

# Farming data
# key: "x,y", value: { "type": "rice_seed", "stage": 0, "days": 0 }
var crops_data: Dictionary = {}
# key: "x,y", value: "tilled" or "watered"
var soils_data: Dictionary = {}

# Active Tool/Seed Selection
var active_tool: String = "hoe" # "hoe", "watering_can", "seeds", "fishing_rod"
var active_seed: String = "rice_seed"

func _ready():
	setup_inputs()
	load_game()

func _process(delta):
	if is_time_paused:
		return
		
	time_accumulator += delta
	if time_accumulator >= MINUTE_DURATION:
		time_accumulator -= MINUTE_DURATION
		game_minute += 1
		if game_minute >= 60:
			game_minute = 0
			game_hour += 1
			if game_hour >= 24:
				game_hour = 24 # Lock at midnight, player must sleep
				game_minute = 0
				
		update_time_period()
		time_changed.emit(game_hour, game_minute, time_period)

func update_time_period():
	if game_hour >= 6 and game_hour < 17:
		time_period = "morning"
	elif game_hour >= 17 and game_hour < 20:
		time_period = "evening"
	else:
		time_period = "night"

func add_coins(amount: int):
	coins += amount
	coins_changed.emit()

func remove_coins(amount: int) -> bool:
	if coins >= amount:
		coins -= amount
		coins_changed.emit()
		return true
	return false

func add_item(item_id: String, amount: int = 1):
	if inventory.has(item_id):
		inventory[item_id] += amount
	else:
		inventory[item_id] = amount
	inventory_changed.emit()

func remove_item(item_id: String, amount: int = 1) -> bool:
	if inventory.has(item_id) and inventory[item_id] >= amount:
		inventory[item_id] -= amount
		inventory_changed.emit()
		return true
	return false

func select_tool(tool_name: String):
	active_tool = tool_name
	tool_changed.emit(active_tool)

func select_seed(seed_name: String):
	active_seed = seed_name
	active_tool = "seeds"
	seed_changed.emit(active_seed)
	tool_changed.emit(active_tool)

func advance_day():
	# Advance day number
	day += 1
	game_hour = 6
	game_minute = 0
	time_accumulator = 0.0
	update_time_period()
	
	# Crop growth phase
	# Grow all crops planted on watered soil
	var next_crops_data = {}
	for cell_str in crops_data:
		var crop = crops_data[cell_str]
		var is_watered = soils_data.get(cell_str, "") == "watered"
		
		var new_stage = crop["stage"]
		var new_days = crop["days"]
		
		if is_watered:
			new_days += 1
			var grow_days = CROPS[crop["type"]]["grow_days"]
			var stage_threshold = float(grow_days) / 3.0
			new_stage = int(min(3, floor(float(new_days) / stage_threshold)))
			
		next_crops_data[cell_str] = {
			"type": crop["type"],
			"stage": new_stage,
			"days": new_days
		}
	crops_data = next_crops_data
	
	# Dry out all soil tiles
	for cell_str in soils_data:
		if soils_data[cell_str] == "watered":
			soils_data[cell_str] = "tilled"
			
	save_game()
	save_loaded.emit() # Triggers world visual updates
	time_changed.emit(game_hour, game_minute, time_period)

# Save/Load System
func save_game():
	var save_dict = {
		"coins": coins,
		"day": day,
		"inventory": inventory,
		"crops_data": crops_data,
		"soils_data": soils_data,
		"active_tool": active_tool,
		"active_seed": active_seed
	}
	var file = FileAccess.open("user://save_game.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_dict))
		print("Game Saved Successfully!")

func load_game():
	if not FileAccess.file_exists("user://save_game.json"):
		return
		
	var file = FileAccess.open("user://save_game.json", FileAccess.READ)
	if file:
		var text = file.get_as_text()
		var json = JSON.new()
		if json.parse(text) == OK:
			var data = json.get_data()
			coins = int(data.get("coins", coins))
			day = int(data.get("day", day))
			
			var loaded_inv = data.get("inventory", {})
			for key in loaded_inv:
				inventory[key] = int(loaded_inv[key])
				
			crops_data = data.get("crops_data", {})
			
			var loaded_soils = data.get("soils_data", {})
			soils_data = {}
			for key in loaded_soils:
				soils_data[key] = str(loaded_soils[key])
				
			active_tool = str(data.get("active_tool", active_tool))
			active_seed = str(data.get("active_seed", active_seed))
			
			print("Game Loaded Successfully!")
			save_loaded.emit()

func reset_game():
	coins = 100
	day = 1
	game_hour = 6
	game_minute = 0
	time_period = "morning"
	time_accumulator = 0.0
	
	# Reset inventory
	for key in inventory:
		if key.ends_with("_seed"):
			if key == "rice_seed": inventory[key] = 5
			elif key == "carrot_seed": inventory[key] = 3
			elif key == "radish_seed": inventory[key] = 2
			else: inventory[key] = 1
		else:
			inventory[key] = 0
			
	crops_data = {}
	soils_data = {}
	active_tool = "hoe"
	active_seed = "rice_seed"
	
	# Delete save file if exists
	if FileAccess.file_exists("user://save_game.json"):
		var dir = DirAccess.open("user://")
		dir.remove("save_game.json")
		
	save_loaded.emit()
	time_changed.emit(game_hour, game_minute, time_period)

# Setup inputs programmatically
func setup_inputs():
	var inputs = {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E, KEY_SPACE],
		"inventory": [KEY_I, KEY_TAB],
		"cancel": [KEY_ESCAPE],
		"tool_1": [KEY_1],
		"tool_2": [KEY_2],
		"tool_3": [KEY_3],
		"tool_4": [KEY_4]
	}
	for action in inputs:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		else:
			InputMap.action_erase_events(action)
			
		for key in inputs[action]:
			var event = InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
