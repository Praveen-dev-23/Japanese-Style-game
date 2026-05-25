extends Control

@onready var buy_tab = $NinePatchRect/Tabs/BuyTab
@onready var sell_tab = $NinePatchRect/Tabs/SellTab
@onready var buy_list = $NinePatchRect/BuyListContainer/BuyScroll/BuyList
@onready var sell_list = $NinePatchRect/SellListContainer/SellScroll/SellList
@onready var coins_label = $NinePatchRect/CoinsDisplay/CoinsLabel

# Active tab: "buy" or "sell"
var current_tab: String = "buy"

# Region mapping for items.png icons
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
	# Connect to Global events
	Global.coins_changed.connect(update_coins_display)
	Global.inventory_changed.connect(update_lists)
	
	# Connect to Global shop signal
	if not Global.is_connected("shop_opened", open_shop):
		Global.add_user_signal("shop_opened")
		Global.add_user_signal("shop_closed")
	
	Global.connect("shop_opened", open_shop)
	
	visible = false
	
	# Wire up tab buttons
	$NinePatchRect/Tabs/BuyBtn.pressed.connect(func(): switch_tab("buy"))
	$NinePatchRect/Tabs/SellBtn.pressed.connect(func(): switch_tab("sell"))
	$NinePatchRect/CloseButton.pressed.connect(close_shop)
	$NinePatchRect/SellListContainer/SellAllBtn.pressed.connect(sell_all_goods)
	
	switch_tab("buy")

func open_shop():
	visible = true
	update_coins_display()
	update_lists()
	
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player:
		player.is_locked = true

func close_shop():
	visible = false
	var player = get_tree().current_scene.get_node_or_null("Player")
	if player:
		player.is_locked = false
	Global.emit_signal("shop_closed")

func update_coins_display():
	coins_label.text = str(Global.coins)

func switch_tab(tab_name: String):
	current_tab = tab_name
	if tab_name == "buy":
		buy_tab.visible = true
		sell_tab.visible = false
		$NinePatchRect/Tabs/BuyBtn.disabled = true
		$NinePatchRect/Tabs/SellBtn.disabled = false
	else:
		buy_tab.visible = false
		sell_tab.visible = true
		$NinePatchRect/Tabs/BuyBtn.disabled = false
		$NinePatchRect/Tabs/SellBtn.disabled = true
	update_lists()

func update_lists():
	# Clear list nodes
	for child in buy_list.get_children():
		child.queue_free()
	for child in sell_list.get_children():
		child.queue_free()
		
	# Populate Buy List
	for seed_id in Global.CROPS:
		var crop = Global.CROPS[seed_id]
		var row = create_shop_row(
			seed_id, 
			crop["name"] + " Seeds", 
			crop["seed_cost"], 
			Global.inventory.get(seed_id, 0),
			true
		)
		buy_list.add_child(row)
		
	# Populate Sell List
	# Sell Crops
	for seed_id in Global.CROPS:
		var crop = Global.CROPS[seed_id]
		var crop_id = crop["item_name"]
		var count = Global.inventory.get(crop_id, 0)
		if count >= 0: # Show everything even if count 0
			var row = create_shop_row(
				crop_id, 
				crop["name"], 
				crop["sell_value"], 
				count, 
				false
			)
			sell_list.add_child(row)
			
	# Sell Fish
	for fish_id in Global.FISH:
		var fish = Global.FISH[fish_id]
		var count = Global.inventory.get(fish_id, 0)
		var row = create_shop_row(
			fish_id, 
			fish["name"], 
			fish["sell_value"], 
			count, 
			false
		)
		sell_list.add_child(row)

func create_shop_row(item_id: String, item_name: String, price: int, qty: int, is_buy: bool) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.custom_minimum_size = Vector2(280, 26)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Icon
	var icon = TextureRect.new()
	icon.texture = load("res://assets/items.png")
	icon.custom_minimum_size = Vector2(16, 16)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
x	icon.region_enabled = true
	icon.region_rect = ITEM_REGIONS.get(item_id, Rect2(0,0,16,16))
	row.add_child(icon)
	
	# Name
	var name_label = Label.new()
	name_label.text = item_name
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.custom_minimum_size = Vector2(100, 16)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.clip_text = true
	row.add_child(name_label)
	
	# Price Info
	var price_label = Label.new()
	price_label.text = str(price) + " c"
	price_label.add_theme_font_size_override("font_size", 9)
	price_label.custom_minimum_size = Vector2(40, 16)
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(price_label)
	
	# Owned Qty Info
	var qty_label = Label.new()
	qty_label.text = "(" + str(qty) + ")"
	qty_label.add_theme_font_size_override("font_size", 8)
	qty_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4))
	qty_label.custom_minimum_size = Vector2(30, 16)
	qty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(qty_label)
	
	# Action Button
	var btn = Button.new()
	btn.add_theme_font_size_override("font_size", 8)
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(36, 16)
	
	if is_buy:
		btn.text = "Buy"
		btn.disabled = (Global.coins < price)
		btn.pressed.connect(func():
			if Global.remove_coins(price):
				Global.add_item(item_id, 1)
		)
	else:
		btn.text = "Sell"
		btn.disabled = (qty <= 0)
		btn.pressed.connect(func():
			if Global.remove_item(item_id, 1):
				Global.add_coins(price)
		)
		
	row.add_child(btn)
	return row

func sell_all_goods():
	var total_earned = 0
	var items_sold = 0
	
	# Sell Crops
	for seed_id in Global.CROPS:
		var crop = Global.CROPS[seed_id]
		var crop_id = crop["item_name"]
		var count = Global.inventory.get(crop_id, 0)
		if count > 0:
			var value = crop["sell_value"] * count
			total_earned += value
			items_sold += count
			Global.remove_item(crop_id, count)
			
	# Sell Fish
	for fish_id in Global.FISH:
		var fish = Global.FISH[fish_id]
		var count = Global.inventory.get(fish_id, 0)
		if count > 0:
			var value = fish["sell_value"] * count
			total_earned += value
			items_sold += count
			Global.remove_item(fish_id, count)
			
	if items_sold > 0:
		Global.add_coins(total_earned)
		# Spawn flying text
		var player = get_tree().current_scene.get_node_or_null("Player")
		if player:
			var txt = Label.new()
			txt.text = "+ " + str(total_earned) + " Coins!"
			txt.add_theme_font_size_override("font_size", 9)
			txt.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
			txt.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.1))
			txt.add_theme_constant_override("outline_size", 3)
			txt.position = player.global_position + Vector2(-50, -40)
			txt.size = Vector2(100, 20)
			txt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			get_tree().current_scene.add_child(txt)
			
			var tween = create_tween().set_parallel(true)
			tween.tween_property(txt, "position:y", player.global_position.y - 60, 1.2)
			tween.tween_property(txt, "modulate:a", 0.0, 1.2)
			tween.chain().tween_callback(txt.queue_free)
	else:
		# Alert nothing to sell
		pass
