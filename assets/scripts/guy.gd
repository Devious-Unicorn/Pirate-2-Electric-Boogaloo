extends CharacterBody2D

@export var home: Vector2
@export var speed: float = 100
@onready var Islands = get_node("../../Islands")
@onready var thread: Thread
@onready var nav = $NavigationAgent2D
enum state {
	moving, # walking around a lot with minimal pausing. at each pause has a chance to bump down to walking
	walking, # walking to the target position and then has a chance to move to resting
	resting, # stopped walking for a few seconds. has a chance to move down to stopped
	stopped # not moving for a while. after the timer runs out moves to walking
}
var currentState = state.walking
var is_map_ready = false
var state_timer: float = 0.0  # Controls how long the guy stay in a state

func _ready() -> void:
	thread = Thread.new()
	# Connect to the map_changed signal so we know exactly when the nav mesh is loaded
	NavigationServer2D.map_changed.connect(_on_map_changed)

func _on_map_changed(_map_rid):
	is_map_ready = true
	# Disconnect after first sync so we don't trigger this constantly
	NavigationServer2D.map_changed.disconnect(_on_map_changed)
	# Set the first target now that we know the map exists
	pick_new_target()

func _physics_process(delta: float) -> void:
	global_rotation = 0
	
	thread.start(stateMachine)
	thread.wait_to_finish.call_deferred()
	
	move_and_slide()

func stateMachine():
	if not is_map_ready: return
	
	if state_timer > 0:
		state_timer -= get_process_delta_time()
		velocity = Vector2.ZERO
		return 
	
	match currentState:
		state.moving, state.walking:
			if nav.is_navigation_finished():
				# 40% chance to change state, 60% to just pick a new spot
				if randi() % 10 < 4:
					currentState = (clampi(currentState + [1, -1].pick_random(), 0, state.size() - 1)) as state
				else:
					pick_new_target.call_deferred()
			else:
				var next_pos = nav.call_deferred("get_next_path_position")
				set_deferred("velocity", global_position.direction_to(next_pos) * speed)
		
		state.resting:
			state_timer = randf_range(0.5, 2.0)
			currentState = state.walking if randi() % 2 == 0 else state.stopped

		state.stopped:
			state_timer = randf_range(3.0, 5.0)
			currentState = state.walking
	
	(func(): $Label.text = 'State: %s\nTarget: %s\nVelocity: %s' % [state.keys()[currentState], nav.target_position, velocity]).call_deferred()

func pick_new_target():
	var map = get_world_2d().get_navigation_map()
	var region = NavigationServer2D.map_get_closest_point_owner(map, global_position)
	
	if region.is_valid():
		var target = NavigationServer2D.region_get_random_point(region, 1, false)
		nav.target_position = target
