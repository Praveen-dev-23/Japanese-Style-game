extends Node2D

@onready var tilemap = $TileMap
@onready var player = $Player
@onready var crops_container = $CropsContainer
@onready var canvas_modulate = $CanvasModulate
@onready var screen_fade = $CanvasLayer/ScreenFade
@onready var shop_ui = $CanvasLayer/ShopUI
@onready var inventory_ui = $CanvasLayer/InventoryUI

# Preloads
const CROP_SCENE = preload("res://scenes/crop.tscn")

# Tilemap layers
const LAYER_GROUND = 0
const LAYER_SOIL = 1
const LAYER_DETAILS = 2

# Tile Coordinates
const TILE_SOURCE_ID = 0
const COORD_GRASS = Vector2i(0, 0)
const COORD_GRASS_ALT = Vector2i(1, 0)
const COORD_SOIL_DRY = Vector2i(2, 0)
const COORD_SOIL_WET = Vector2i(3, 0)
const COORD_PATH = Vector2i(4, 0)
const COORD_WATER = Vector2i(5, 0)
const COORD_WATER_DEEP = Vector2i(6, 0)
const COORD_SHORE = Vector2i(7, 0)

const COORD_WOOD_FLOOR = Vector2i(0, 1)
const COORD_WALL = Vector2i(1, 1)
const COORD_ROOF = Vector2i(2, 1)
const COORD_FENCE = Vector2i(3, 1)
const COORD_LANTERN_OFF = Vector2i(4, 1)
const COORD_LANTERN_ON = Vector2i(5, 1)
const COORD_COUNTER = Vector2i(6, 1)
const COORD_CANOPY = Vector2i(7, 1)

const COORD_TRUNK = Vector2i(0, 2)
const COORD_LEAVES = Vector2i(1, 2)
const COORD_SAKURA = Vector2i(2, 2)
const COORD_BAMBOO = Vector2i(3, 2)
const COORD_BED_PILLOW = Vector2i(4, 2)
const COORD_BED_FRAME = Vector2i(5, 2)
const COORD_RUG = Vector2i(6, 2)

# Map Size
const MAP_WIDTH = 45
const MAP_HEIGHT = 25

# Lantern lights tracking
var lantern_lights = []
var lantern_positions = [
	Vector2i(3, 9),
	Vector2i(13, 9),
	Vector2i(19, 7),
	Vector2i(28, 5),
	Vector2i(28, 15)
]

# Bed coordinate (for sleeping)
const BED_COORDS = Vector2i(6, 4)

func _ready():
	# Configure Screen Fade UI size
	screen_fade.color = Color(0, 0, 0, 0)
	screen_fade.visible = false
	
	# Create map
	generate_default_map()
	
	# Setup lights for lanterns
	setup_lantern_lights()
	
	# Connect signals
	player.interaction_triggered.connect(_on_player_interaction)
	Global.save_loaded.connect(_on_save_loaded)
	Global.time_changed.connect(_on_time_changed)
	
	# Connect shop UI opening
	if not Global.has_signal("shop_opened"):
		Global.add_user_signal("shop_opened")
	if not Global.has_signal("shop_closed"):
		Global.add_user_signal("shop_closed")
	
	Global.connect("shop_opened", func(): shop_ui.open_shop())
	Global.connect("shop_closed", func(): pass)
	
	# Load current state
	load_world_state()
	
	# Initial lighting state
	update_lighting(Global.time_period, true)

func generate_default_map():
	# 1. Fill ground layer with grass
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			# Add random details
			var coord = COORD_GRASS
			if randf() < 0.05:
				coord = COORD_GRASS_ALT
			tilemap.set_cell(LAYER_GROUND, Vector2i(x, y), TILE_SOURCE_ID, coord)
			
	# 2. Draw gravel path
	for x in range(10, 20):
		tilemap.set_cell(LAYER_GROUND, Vector2i(x, 14), TILE_SOURCE_ID, COORD_PATH)
	for y in range(9, 15):
		tilemap.set_cell(LAYER_GROUND, Vector2i(13, y), TILE_SOURCE_ID, COORD_PATH)

	# 3. Draw lake (water and shores)
	for y in range(3, 21):
		# Shoreline
		tilemap.set_cell(LAYER_GROUND, Vector2i(29, y), TILE_SOURCE_ID, COORD_SHORE)
		# Water body
		for x in range(30, MAP_WIDTH):
			var water_coord = COORD_WATER
			if x > 33:
				water_coord = COORD_WATER_DEEP
			tilemap.set_cell(LAYER_GROUND, Vector2i(x, y), TILE_SOURCE_ID, water_coord)

	# 4. Draw farmhouse
	# Interior wood floor (Ground layer override)
	for x in range(5, 12):
		for y in range(4, 8):
			tilemap.set_cell(LAYER_GROUND, Vector2i(x, y), TILE_SOURCE_ID, COORD_WOOD_FLOOR)
	
	# Rug inside house
	tilemap.set_cell(LAYER_GROUND, Vector2i(8, 6), TILE_SOURCE_ID, COORD_RUG)
	tilemap.set_cell(LAYER_GROUND, Vector2i(9, 6), TILE_SOURCE_ID, COORD_RUG)

	# Walls (Details Layer)
	# Top wall
	for x in range(4, 13):
		tilemap.set_cell(LAYER_DETAILS, Vector2i(x, 3), TILE_SOURCE_ID, COORD_WALL)
	# Side walls
	for y in range(4, 9):
		tilemap.set_cell(LAYER_DETAILS, Vector2i(4, y), TILE_SOURCE_ID, COORD_WALL)
		tilemap.set_cell(LAYER_DETAILS, Vector2i(12, y), TILE_SOURCE_ID, COORD_WALL)
	# Front walls (with door opening at 8)
	tilemap.set_cell(LAYER_DETAILS, Vector2i(5, 8), TILE_SOURCE_ID, COORD_WALL)
	tilemap.set_cell(LAYER_DETAILS, Vector2i(6, 8), TILE_SOURCE_ID, COORD_WALL)
	tilemap.set_cell(LAYER_DETAILS, Vector2i(7, 8), TILE_SOURCE_ID, COORD_WALL)
	tilemap.set_cell(LAYER_DETAILS, Vector2i(9, 8), TILE_SOURCE_ID, COORD_WALL)
	tilemap.set_cell(LAYER_DETAILS, Vector2i(10, 8), TILE_SOURCE_ID, COORD_WALL)
	tilemap.set_cell(LAYER_DETAILS, Vector2i(11, 8), TILE_SOURCE_ID, COORD_WALL)
	
	# House Roof (visual layered styling)
	for x in range(4, 13):
		tilemap.set_cell(LAYER_DETAILS, Vector2i(x, 2), TILE_SOURCE_ID, COORD_ROOF)
		tilemap.set_cell(LAYER_DETAILS, Vector2i(x, 3), TILE_SOURCE_ID, COORD_ROOF)

	# Futon/Bed
	tilemap.set_cell(LAYER_DETAILS, Vector2i(6, 4), TILE_SOURCE_ID, COORD_BED_PILLOW)
	tilemap.set_cell(LAYER_DETAILS, Vector2i(6, 5), TILE_SOURCE_ID, COORD_BED_FRAME)

	# 5. Draw Shop
	# Wooden shop counters
	for x in range(21, 26):
		tilemap.set_cell(LAYER_DETAILS, Vector2i(x, 6), TILE_SOURCE_ID, COORD_COUNTER)
	# Shop canopy roof
	for x in range(21, 26):
		tilemap.set_cell(LAYER_DETAILS, Vector2i(x, 5), TILE_SOURCE_ID, COORD_CANOPY)

	# 6. Draw lanterns at preset locations
	for pos in lantern_positions:
		tilemap.set_cell(LAYER_DETAILS, pos, TILE_SOURCE_ID, COORD_LANTERN_OFF)

	# 7. Draw decorative trees
	var trees = [
		{"pos": Vector2i(2, 2), "type": "sakura"},
		{"pos": Vector2i(15, 2), "type": "sakura"},
		{"pos": Vector2i(17, 20), "type": "sakura"},
		{"pos": Vector2i(3, 19), "type": "green"},
		{"pos": Vector2i(11, 22), "type": "green"}
	]
	for tree in trees:
		var p = tree["pos"]
		# Trunk base
		tilemap.set_cell(LAYER_DETAILS, p + Vector2i(0, 1), TILE_SOURCE_ID, COORD_TRUNK)
		# Foliage
		var foliage = COORD_SAKURA if tree["type"] == "sakura" else COORD_LEAVES
		tilemap.set_cell(LAYER_DETAILS, p, TILE_SOURCE_ID, foliage)
		tilemap.set_cell(LAYER_DETAILS, p + Vector2i(-1, 0), TILE_SOURCE_ID, foliage)
		tilemap.set_cell(LAYER_DETAILS, p + Vector2i(1, 0), TILE_SOURCE_ID, foliage)

	# 8. Draw bamboo grove (obstacle grid decoration)
	var bamboo_spots = [
		Vector2i(21, 20), Vector2i(22, 20), Vector2i(23, 20),
		Vector2i(20, 21), Vector2i(21, 21), Vector2i(22, 21),
		Vector2i(20, 22), Vector2i(21, 22), Vector2i(22, 22)
	]
	for b in bamboo_spots:
		tilemap.set_cell(LAYER_DETAILS, b, TILE_SOURCE_ID, COORD_BAMBOO)

	# 9. Draw Fences around farming plot
	# Plot is roughly x from 7 to 15, y from 10 to 16.
	# Top fences
	for x in range(7, 16):
		if x != 11: # leave gap for gate
			tilemap.set_cell(LAYER_DETAILS, Vector2i(x, 9), TILE_SOURCE_ID, COORD_FENCE)
	# Left/Right fences
	for y in range(10, 16):
		tilemap.set_cell(LAYER_DETAILS, Vector2i(6, y), TILE_SOURCE_ID, COORD_FENCE)
		tilemap.set_cell(LAYER_DETAILS, Vector2i(16, y), TILE_SOURCE_ID, COORD_FENCE)

	# Set default player start location
	player.position = Vector2(130, 200) # Right in front of the house path

func setup_lantern_lights():
	# Procedurally generate radial glow texture
	var light_texture = GradientTexture2D.new()
	light_texture.fill = GradientTexture2D.FILL_RADIAL
	light_texture.width = 64
	light_texture.height = 64
	
	var gradient = Gradient.new()
	gradient.colors = PackedColorArray([Color(1.0, 0.88, 0.5, 0.9), Color(1.0, 0.88, 0.5, 0.0)])
	gradient.offsets = PackedFloat32Array([0.0, 1.0])
	light_texture.gradient = gradient
	
	# Spawn light nodes
	for pos in lantern_positions:
		var light = PointLight2D.new()
		light.texture = light_texture
		light.texture_scale = 1.8
		light.energy = 1.0
		# Center on the tile coordinate
		light.position = tilemap.map_to_local(pos)
		light.visible = false
		add_child(light)
		lantern_lights.append(light)

func load_world_state():
	# 1. Redraw Soils layer based on Global data
	# First clear any soil layer tiles
	for x in range(MAP_WIDTH):
		for y in range(MAP_HEIGHT):
			tilemap.set_cell(LAYER_SOIL, Vector2i(x, y), -1, Vector2i(-1,-1))
			
	for cell_str in Global.soils_data:
		var cell = parse_cell_string(cell_str)
		var state = Global.soils_data[cell_str]
		if state == "tilled":
			tilemap.set_cell(LAYER_SOIL, cell, TILE_SOURCE_ID, COORD_SOIL_DRY)
		elif state == "watered":
			tilemap.set_cell(LAYER_SOIL, cell, TILE_SOURCE_ID, COORD_SOIL_WET)

	# 2. Spawn crop nodes
	# Clear previous crops
	for child in crops_container.get_children():
		child.queue_free()
		
	for cell_str in Global.crops_data:
		var cell = parse_cell_string(cell_str)
		var crop_info = Global.crops_data[cell_str]
		
		var crop_node = CROP_SCENE.instantiate()
		crop_node.position = tilemap.map_to_local(cell)
		crops_container.add_child(crop_node)
		crop_node.init(crop_info["type"], crop_info["stage"], cell)

func _on_save_loaded():
	load_world_state()

func _on_player_interaction(target_offset: Vector2, tool_used: String):
	# Calculate target cell
	var target_world_pos = player.position + target_offset
	var cell = tilemap.local_to_map(target_world_pos)
	var cell_str = "%d,%d" % [cell.x, cell.y]
	
	# First, check if interacting with Bed
	if cell == BED_COORDS:
		trigger_sleep_cycle()
		return

	# Retrieve tile information at target
	var ground_tile = tilemap.get_cell_atlas_coords(LAYER_GROUND, cell)
	var soil_tile = tilemap.get_cell_atlas_coords(LAYER_SOIL, cell)
	var detail_tile = tilemap.get_cell_atlas_coords(LAYER_DETAILS, cell)
	
	# 1. Tilling (Hoe)
	if tool_used == "hoe":
		# Can only till green grass tiles with no obstacles
		if ground_tile == COORD_GRASS or ground_tile == COORD_GRASS_ALT:
			if detail_tile == Vector2i(-1, -1):
				tilemap.set_cell(LAYER_SOIL, cell, TILE_SOURCE_ID, COORD_SOIL_DRY)
				Global.soils_data[cell_str] = "tilled"
				Global.save_game()
				play_visual_effect(tilemap.map_to_local(cell), Color(0.48, 0.35, 0.22))
				
	# 2. Watering (Watering Can)
	elif tool_used == "watering_can":
		if Global.soils_data.has(cell_str):
			tilemap.set_cell(LAYER_SOIL, cell, TILE_SOURCE_ID, COORD_SOIL_WET)
			Global.soils_data[cell_str] = "watered"
			Global.save_game()
			play_visual_effect(tilemap.map_to_local(cell), Color(0.3, 0.6, 0.9, 0.7))
			
	# 3. Planting (Seeds)
	elif tool_used == "seeds":
		# Must stand on tilled/watered soil
		if Global.soils_data.has(cell_str):
			# Cannot plant if crop already exists
			if not Global.crops_data.has(cell_str):
				# Check inventory
				if Global.remove_item(Global.active_seed, 1):
					Global.crops_data[cell_str] = {
						"type": Global.active_seed,
						"stage": 0,
						"days": 0
					}
					Global.save_game()
					
					# Spawn crop scene
					var crop_node = CROP_SCENE.instantiate()
					crop_node.position = tilemap.map_to_local(cell)
					crops_container.add_child(crop_node)
					crop_node.init(Global.active_seed, 0, cell)
					
	# 4. Harvesting / Empty hand interact
	else:
		# Check if there is a crop node
		if Global.crops_data.has(cell_str):
			var crop_info = Global.crops_data[cell_str]
			if crop_info["stage"] == 3: # Mature
				var crop_meta = Global.CROPS[crop_info["type"]]
				var harvest_item = crop_meta["item_name"]
				
				# Harvest crop
				Global.add_item(harvest_item, 1)
				Global.crops_data.erase(cell_str)
				Global.save_game()
				
				# Play visual puff and free node
				var crop_node = find_crop_node_at(cell)
				if crop_node:
					play_visual_effect(crop_node.position, Color(1.0, 0.9, 0.5))
					crop_node.queue_free()
					
				# Spawn rising label
				spawn_harvest_label(crop_meta["name"], tilemap.map_to_local(cell))

func find_crop_node_at(cell: Vector2i) -> Node2D:
	for child in crops_container.get_children():
		if child.get("cell_coords") == cell:
			return child
	return null

func trigger_sleep_cycle():
	player.is_locked = true
	screen_fade.visible = true
	
	# Smooth fade out
	var tween = create_tween()
	tween.tween_property(screen_fade, "color:a", 1.0, 0.8)
	
	# Advance day & save
	tween.tween_callback(func():
		Global.advance_day()
		# Simple slept text popup
		var sleep_label = Label.new()
		sleep_label.text = "Morning of Day " + str(Global.day)
		sleep_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sleep_label.size = Vector2(200, 20)
		sleep_label.position = Vector2(220, 160)
		sleep_label.add_theme_font_size_override("font_size", 14)
		sleep_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
		screen_fade.add_child(sleep_label)
		
		# Wait 1.0 second on black screen
		get_tree().create_timer(1.0).timeout.connect(func():
			sleep_label.queue_free()
			# Fade back in
			var fade_in_tween = create_tween()
			fade_in_tween.tween_property(screen_fade, "color:a", 0.0, 0.8)
			fade_in_tween.chain().tween_callback(func():
				screen_fade.visible = false
				player.is_locked = false
			)
		)
	)

func _on_time_changed(hour: int, minute: int, period: String):
	update_lighting(period, false)

func update_lighting(period: String, immediate: bool):
	var target_color = Color(1.0, 0.98, 0.95)
	var lanterns_visible = false
	
	match period:
		"morning":
			target_color = Color(1.0, 0.98, 0.95)
			lanterns_visible = false
		"evening":
			target_color = Color(0.85, 0.58, 0.6)
			lanterns_visible = true
		"night":
			target_color = Color(0.25, 0.28, 0.48)
			lanterns_visible = true
			
	# Update tilemap lantern frames (ON / OFF)
	var source_lantern = COORD_LANTERN_ON if lanterns_visible else COORD_LANTERN_OFF
	for pos in lantern_positions:
		tilemap.set_cell(LAYER_DETAILS, pos, TILE_SOURCE_ID, source_lantern)

	# Update light node visibility
	for light in lantern_lights:
		light.visible = lanterns_visible

	# Smoothly tint CanvasModulate
	if immediate:
		canvas_modulate.color = target_color
	else:
		var tween = create_tween()
		tween.tween_property(canvas_modulate, "color", target_color, 2.5)

# Visual puff particle effect
func play_visual_effect(pos: Vector2, color: Color):
	var particles = CPUParticles2D.new()
	particles.position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 8
	particles.lifetime = 0.4
	particles.explosiveness = 0.8
	particles.spread = 180.0
	particles.gravity = Vector2(0, 0)
	particles.initial_velocity_min = 15.0
	particles.initial_velocity_max = 30.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = color
	add_child(particles)
	particles.finished.connect(particles.queue_free)

func spawn_harvest_label(item_name: String, pos: Vector2):
	var label = Label.new()
	label.text = "+1 " + item_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.1))
	label.add_theme_constant_override("outline_size", 2)
	label.position = pos + Vector2(-50, -16)
	label.size = Vector2(100, 20)
	add_child(label)
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", pos.y - 32, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.chain().tween_callback(label.queue_free)

# Helper to parse coord string
func parse_cell_string(s: String) -> Vector2i:
	var parts = s.split(",")
	return Vector2i(int(parts[0]), int(parts[1]))
