extends StaticBody2D

@onready var sprite = $Sprite2D
@onready var interact_label = $InteractLabel
@onready var interact_area = $InteractArea

var player_in_range: CharacterBody2D = null

func _ready():
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	interact_label.visible = false
	sprite.frame = 3 # Sora's frame index in characters.png

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = body
		interact_label.visible = true

func _on_body_exited(body):
	if body == player_in_range:
		player_in_range = null
		interact_label.visible = false

func _unhandled_input(event):
	if not player_in_range or player_in_range.is_locked:
		return
		
	if event.is_action_pressed("interact"):
		start_dialogue()

func start_dialogue():
	player_in_range.is_locked = true
	interact_label.visible = false
	
	# Show dialogue first, then open shop
	Global.show_dialogue("Konnichiwa! Welcome to my shop. I have seeds to sell, and I can buy your fresh crops and fish!")
