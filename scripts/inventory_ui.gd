extends Control

@onready var day_label = $HUD/TimePanel/VBox/DayLabel
@onready var time_label = $HUD/TimePanel/VBox/TimeLabel
@onready var period_label = $HUD/TimePanel/VBox/PeriodLabel
@onready var coins_label = $HUD/CoinsPanel/HBox/CoinsLabel

@onready var hotbar_slots = [
	$HUD/Hotbar/Slot1,
	$HUD/Hotbar/Slot2,
	$HUD/Hotbar/Slot3,
	$HUD/Hotbar/Slot4
]

@onready var inventory_panel = $InventoryPanel
@onready var grid_container = $InventoryPanel/NinePatchRect/MarginContainer/ScrollContainer/GridContainer
@onready var dialogue_panel = $DialoguePanel
@onready var dialogue_text = $DialoguePanel/NinePatchRect/MarginContainer/DialogueText

# Slot atlas mappings
const ITEM_REGIONS = {
	"rice_seed": Rect2(0, 0, 16, 16),
	"carrot_seed": Rect2(64, 0, 16, 16),
	"radish_seed": Rect2(0, 16, 16, 16),
	"tea_seed": Rect2(64, 16, 16, 16),
	"bamboo_seed": Rect2(0, 32, 16, 16),
	
	"rice": Rect2(48, 0, 16, 16),
	"carrot": Rect2(112, 0, 16, 16),
	"radish": Rect2(48, 16, 16, 16),
	"tea_leaves": Rect2(112, 16, 16, 16),
	"bamboo_shoot": Rect2(48, 32, 16, 16),
	
	"koi": Rect2(0, 48, 16, 16),
	"salmon": Rect2(16, 48, 16, 16),
	"catfish": Rect2(32, 48, 16, 16),
	"tuna": Rect2(48, 48, 16, 16),
	"golden_carp": Rect2(64, 48, 16, 16)
}

func _ready():
	# Connect global signals
	Global.coins_changed.connect(update_hud)
	Global.inventory_changed.connect(populate_inventory)
	Global.time_changed.connect(update_time_hud)
	Global.tool_changed.connect(update_hotbar_selection)
	Global.seed_changed.connect(update_hotbar_seed_icon)
	Global.dialogue_shown.connect(show_dialogue)
	
	# Initial draw
	update_hud()
	update_time_hud(Global.game_hour, Global.game_minute, Global.time_period)
	populate_inventory()
	update_hotbar_selection(Global.active_tool)
	update_hotbar_seed_icon(Global.active_seed)
	
	inventory_panel.visible = false
	dialogue_panel.visible = false
	
	# Connect buttons programmatically
	$InventoryPanel/NinePatchRect/CloseButton.pressed.connect(toggle_inventory)
	$DialoguePanel/NinePatchRect/NextButton.pressed.connect(advance_dialogue)

func _unhandled_input(event):
	if event.is_action_pressed("inventory"):
		toggle_inventory()
	elif event.is_action_pressed("cancel"):
		if inventory_panel.visible:
			toggle_inventory()
		elif dialogue_panel.visible:
			advance_dialogue()

func toggle_inventory():
	if dialogue_panel.visible:
		return # block inventory while talking
	
	inventory_panel.visible = not inventory_panel.visible
	var player = get_tree().current_scene.get_node_or_null("Player")
	
	if inventory_panel.visible:
		populate_inventory()
		if player:
			player.is_locked = true
	else:
		if player:
			player.is_locked = false

func update_hud():
	coins_label.text = str(Global.coins)

func update_time_hud(hour: int, minute: int, period: String):
	day_label.text = "Day " + str(Global.day)
	time_label.text = "%02d:%02d" % [hour, minute]
	period_label.text = period.capitalize()

func update_hotbar_selection(active_tool: String):
	var active_idx = 0
	match active_tool:
		"hoe": active_idx = 0
		"watering_can": active_idx = 1
		"seeds": active_idx = 2
		"fishing_rod": active_idx = 3
		
	# Update active panel borders
	for i in range(4):
		var slot_panel = hotbar_slots[i]
		var frame = slot_panel.get_node("SelectedFrame")
		frame.visible = (i == active_idx)

func update_hotbar_seed_icon(seed_name: String):
	var seed_icon_rect = hotbar_slots[2].get_node("Icon")
	if ITEM_REGIONS.has(seed_name):
		seed_icon_rect.region_rect = ITEM_REGIONS[seed_name]

func populate_inventory():
	# Clear previous slots
	for child in grid_container.get_children():
		child.queue_free()
		
	# Re-create slots for items in ITEM_REGIONS
	for item_id in ITEM_REGIONS:
		var slot = create_slot_node(item_id)
		grid_container.add_child(slot)

func create_slot_node(item_id: String) -> Control:
	var slot_panel = Panel.new()
	slot_panel.custom_minimum_size = Vector2(36, 36)
	
	# Add background panel styling
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.9, 0.82)
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.72, 0.58, 0.43)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	slot_panel.add_theme_stylebox_override("panel", style)

	# Icon
	var icon = TextureRect.new()
	icon.texture = load("res://assets/items.png")
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(24, 24)
	icon.position = Vector2(6, 6)
	icon.region_enabled = true
	icon.region_rect = ITEM_REGIONS[item_id]
	slot_panel.add_child(icon)
	
	# Quantity Label
	var count = Global.inventory.get(item_id, 0)
	var label = Label.new()
	label.text = str(count)
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color.BLACK)
	label.position = Vector2(18, 22)
	label.size = Vector2(16, 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	slot_panel.add_child(label)
	
	# Add Selection highlight if it's the active seed and we are looking at seeds
	if item_id.ends_with("_seed") and count > 0:
		var btn = Button.new()
		btn.size = Vector2(36, 36)
		btn.flat = true
		btn.focus_mode = Control.FOCUS_NONE
		btn.pressed.connect(func():
			Global.select_seed(item_id)
			populate_inventory() # redraw highlights
		)
		slot_panel.add_child(btn)
		
		# Show selector highlight if active
		if item_id == Global.active_seed:
			var active_style = style.duplicate()
			active_style.border_color = Color(0.2, 0.6, 0.3)
			active_style.bg_color = Color(0.85, 0.95, 0.88)
			slot_panel.add_theme_stylebox_override("panel", active_style)
			
	return slot_panel

# Dialogue system callbacks
func show_dialogue(text: String):
	dialogue_text.text = text
	dialogue_panel.visible = true
	
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player:
		player.is_locked = true

func advance_dialogue():
	dialogue_panel.visible = false
	
	if Global.open_shop_after_dialogue:
		# Proceed to open shop UI
		Global.open_shop_after_dialogue = false
		Global.open_shop()
	else:
		# Unlock player
		var player = get_tree().current_scene.get_node_or_null("Player")
		if player:
			player.is_locked = false

# Hotbar click handlers (allows mouse clicks on hotbar)
func _on_hotbar_slot_clicked(tool_name: String):
	if dialogue_panel.visible or inventory_panel.visible:
		return
	Global.select_tool(tool_name)
