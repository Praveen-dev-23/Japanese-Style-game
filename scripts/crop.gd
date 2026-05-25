extends Node2D

@onready var sprite = $Sprite2D

var crop_type: String = "rice_seed"
var growth_stage: int = 0
var cell_coords: Vector2i = Vector2i.ZERO

func _ready():
	update_visuals()
	play_spawn_animation()

func init(type: String, stage: int, cell: Vector2i):
	crop_type = type
	growth_stage = stage
	cell_coords = cell
	if is_inside_tree():
		update_visuals()

func update_visuals():
	if not sprite:
		return
		
	# Retrieve the correct region coordinates
	var rx = 0
	var ry = 0
	
	match crop_type:
		"rice_seed":
			rx = growth_stage * 16
			ry = 0
		"carrot_seed":
			rx = 64 + growth_stage * 16
			ry = 0
		"radish_seed":
			rx = growth_stage * 16
			ry = 16
		"tea_seed":
			rx = 64 + growth_stage * 16
			ry = 16
		"bamboo_seed":
			rx = growth_stage * 16
			ry = 32
			
	sprite.region_rect = Rect2(rx, ry, 16, 16)

func play_spawn_animation():
	if not sprite:
		return
	sprite.scale = Vector2(0.5, 0.5)
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.25)

func play_grow_animation():
	if not sprite:
		return
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
