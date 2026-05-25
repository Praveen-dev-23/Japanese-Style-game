extends Area2D

var player_in_area: CharacterBody2D = null
var is_fishing: bool = false
var is_bite_active: bool = false
var bite_timer: Timer = null
var reaction_timer: Timer = null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Create timer nodes
	bite_timer = Timer.new()
	bite_timer.one_shot = true
	bite_timer.timeout.connect(_on_bite_timeout)
	add_child(bite_timer)
	
	reaction_timer = Timer.new()
	reaction_timer.one_shot = true
	reaction_timer.timeout.connect(_on_reaction_timeout)
	add_child(reaction_timer)

func _on_body_entered(body):
	if body.name == "Player":
		player_in_area = body

func _on_body_exited(body):
	if body == player_in_area:
		if is_fishing:
			cancel_fishing()
		player_in_area = null

func _unhandled_input(event):
	if not player_in_area or player_in_area.is_locked:
		return
		
	if event.is_action_pressed("interact"):
		if Global.active_tool == "fishing_rod":
			if not is_fishing:
				start_fishing()
			elif is_bite_active:
				catch_fish()

func start_fishing():
	is_fishing = true
	is_bite_active = false
	player_in_area.is_fishing = true
	
	spawn_floating_text("Casting line...", player_in_area.global_position + Vector2(0, -32))
	
	# Wait for a random time (1.5 to 3.5 seconds) for a bite
	var wait_time = randf_range(1.5, 3.5)
	bite_timer.start(wait_time)

func _on_bite_timeout():
	is_bite_active = true
	player_in_area.show_alert(true)
	
	# Play a simple synthetic beep using AudioServer or just rely on visual
	# 0.6 seconds reaction window
	reaction_timer.start(0.6)

func _on_reaction_timeout():
	# Player was too slow!
	player_in_area.show_alert(false)
	spawn_floating_text("The fish escaped...", player_in_area.global_position + Vector2(0, -32))
	end_fishing()

func catch_fish():
	reaction_timer.stop()
	player_in_area.show_alert(false)
	
	# Determine fish based on probability
	var roll = randf() * 100.0
	var fish_id = "koi"
	
	if roll < 2.0:
		fish_id = "golden_carp" # 2%
	elif roll < 12.0:
		fish_id = "tuna" # 10%
	elif roll < 30.0:
		fish_id = "catfish" # 18%
	elif roll < 60.0:
		fish_id = "salmon" # 30%
	else:
		fish_id = "koi" # 40%
		
	var fish_name = Global.FISH[fish_id]["name"]
	Global.add_item(fish_id, 1)
	
	spawn_floating_text("Caught a " + fish_name + "!", player_in_area.global_position + Vector2(0, -32))
	end_fishing()

func cancel_fishing():
	bite_timer.stop()
	reaction_timer.stop()
	if player_in_area:
		player_in_area.show_alert(false)
		player_in_area.is_fishing = false
	is_fishing = false
	is_bite_active = false

func end_fishing():
	is_fishing = false
	is_bite_active = false
	# Wait brief delay before letting player move again (for animation/juice)
	get_tree().create_timer(0.4).timeout.connect(func():
		if player_in_area:
			player_in_area.is_fishing = false
	)

# Juicy floating text effect
func spawn_floating_text(text: String, start_pos: Vector2):
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Simple theme styling
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(1.0, 0.98, 0.9))
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.1, 0.15))
	label.add_theme_constant_override("outline_size", 3)
	
	label.position = start_pos - Vector2(50, 0) # center offset
	label.size = Vector2(100, 20)
	
	# Add to main world, not the area, so it stays in world coordinates
	get_tree().current_scene.add_child(label)
	
	# Animate float and fade
	var tween = create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", start_pos.y - 20, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	tween.chain().tween_callback(label.queue_free)
