extends CharacterBody2D

signal interaction_triggered(cell_coords, tool_used)

@export var speed: float = 100.0

@onready var sprite = $Sprite2D
@onready var alert_bubble = $AlertBubble

var facing_dir: Vector2 = Vector2.DOWN
var is_locked: bool = false
var is_fishing: bool = false
var anim_time: float = 0.0

# Active tool tracker
var active_tool_index: int = 0
const TOOLS = ["hoe", "watering_can", "seeds", "fishing_rod"]

func _ready():
	alert_bubble.visible = false
	# Connect to global selections
	Global.tool_changed.connect(_on_global_tool_changed)
	_on_global_tool_changed(Global.active_tool)

func _physics_process(delta):
	if is_locked or is_fishing:
		velocity = Vector2.ZERO
		move_and_slide()
		# Keep idle frame
		update_sprite_animation(Vector2.ZERO, delta)
		return

	# Get input direction
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_up"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_down"):
		input_dir.y += 1

	input_dir = input_dir.normalized()
	velocity = input_dir * speed
	move_and_slide()

	# Keep track of last non-zero direction
	if input_dir != Vector2.ZERO:
		facing_dir = input_dir
		# Snap to primary axis for tile-based interaction
		if abs(input_dir.x) > abs(input_dir.y):
			facing_dir = Vector2(sign(input_dir.x), 0)
		else:
			facing_dir = Vector2(0, sign(input_dir.y))

	update_sprite_animation(input_dir, delta)

func _unhandled_input(event):
	if is_locked:
		return

	# Handle hotkey tool selection
	if event.is_action_pressed("tool_1"):
		Global.select_tool("hoe")
	elif event.is_action_pressed("tool_2"):
		Global.select_tool("watering_can")
	elif event.is_action_pressed("tool_3"):
		# Switch to seeds (uses active seed)
		Global.select_tool("seeds")
	elif event.is_action_pressed("tool_4"):
		Global.select_tool("fishing_rod")

	# Interact trigger
	if event.is_action_pressed("interact"):
		if is_fishing:
			# Pressing interact while fishing is a bite reaction
			# Will be handled by the Fishing Area / minigame
			return
			
		# Normal interaction: tilling, planting, harvesting, talking
		var target_cell_offset = facing_dir * 14.0 # Distance in pixels
		emit_signal("interaction_triggered", target_cell_offset, Global.active_tool)

func update_sprite_animation(input_dir: Vector2, delta: float):
	var dir_str = "down"
	if facing_dir.y < 0:
		dir_str = "up"
	elif facing_dir.x < 0:
		dir_str = "left"
	elif facing_dir.x > 0:
		dir_str = "right"

	var base_row_offset = 0
	match dir_str:
		"down": base_row_offset = 0
		"up": base_row_offset = 8
		"left": base_row_offset = 16
		"right": base_row_offset = 24

	if input_dir == Vector2.ZERO:
		# Idle frame is the first col of each row
		sprite.frame = base_row_offset
		anim_time = 0.0
	else:
		anim_time += delta
		# walk cycle frames sequence: Idle (0), Left Foot (1), Idle (0), Right Foot (2)
		var walk_sequence = [0, 1, 0, 2]
		var step = walk_sequence[int(anim_time * 6.0) % 4]
		sprite.frame = base_row_offset + step

func _on_global_tool_changed(new_tool: String):
	# Optional: show visual feedback for active tool
	pass

func show_alert(show: bool):
	alert_bubble.visible = show
