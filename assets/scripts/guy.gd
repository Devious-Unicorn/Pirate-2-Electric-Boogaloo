extends CharacterBody2D

@export var speed: float = 100
@export var home: Vector2
@onready var nav: NavigationAgent2D = $NavigationAgent2D

enum State { MOVING, WALKING, RESTING, STOPPED }
var current_state = State.WALKING
var state_timer: float = 0.0
var is_map_ready = false

func _ready() -> void:
	if "Crew" in name: speed = 15; is_map_ready = true; $CollisionShape2D.set_deferred("disabled", true); nav.avoidance_enabled = false
	else: NavigationServer2D.map_changed.connect(_on_map_changed)

func _on_map_changed(_map_rid):
	# Crucial: The server needs a physics frame to register the new RIDs
	await get_tree().physics_frame 
	is_map_ready = true
	pick_new_target()

func _physics_process(delta: float) -> void:
	$Label.text = name
	# if the map isn't ready or not visible then don't do anything this frame to save resources
	if not is_map_ready or not $VisibleOnScreenNotifier2D.is_on_screen(): return
	
	if state_timer > 0:
		state_timer -= delta
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	if current_state in [State.MOVING, State.WALKING] and not "Crew" in name:
		if not nav.is_navigation_finished():
			var next_pos = nav.get_next_path_position()
			var local_dir = to_local(next_pos).normalized()
			velocity = local_dir * speed
		else:
			velocity = Vector2.ZERO
			decide_next_state()
	
	if "Crew" in name:
		$Label.text += "\n" + str(nav.target_position) + "\n" + str(position) + "\n" + str(velocity.length())
		if not nav.is_navigation_finished():
			var next_pos = nav.get_next_path_position()
			var local_dir = to_local(next_pos).normalized()
			velocity = local_dir * speed
		else:
			velocity = Vector2.ZERO
			if nav.target_position == $"../Boat".global_position:
				queue_free()
				return
			for i in get_parent().find_children("*", "CharacterBody2D"):
				if "Crew" in i.name: continue
				var inRange: Array[Node]
				if global_position.distance_squared_to(i.global_position) < (50 ** 2):
					inRange.append(i)
				
				nav.target_position = inRange.pick_random().global_position
	
	move_and_slide()

func decide_next_state():
	var chance = randf()
	
	if chance < 0.2:
		current_state = State.RESTING
		state_timer = randf_range(0.5, 2.0)
	elif chance < 0.4:
		current_state = State.STOPPED
		state_timer = randf_range(3.0, 5.0)
	else:
		current_state = State.WALKING
		pick_new_target()

func pick_new_target():
	var map = get_world_2d().get_navigation_map()
	
	# Try to find the region under the agent
	var region_rid = NavigationServer2D.map_get_closest_point_owner(map, global_position)
	
	if region_rid.is_valid():
		var random_point = NavigationServer2D.region_get_random_point(region_rid, 1, false)
		if random_point != Vector2.ZERO:
			nav.target_position = random_point
			return
	
	# If we failed, wait and try again (prevents the flood of errors)
	state_timer = 2.0 
