extends CharacterBody2D

@export var home: Vector2
@export var speed: float = 5
@onready var nav = $NavigationAgent2D
@onready var Islands = get_node("../../Islands")
enum state {
	moving, # walking around a lot with minimal pausing. at each pause has a chance to bump down to walking
	walking, # walking to the target position and then has a chance to move to resting
	resting, # stopped walking for a few seconds. has a chance to move down to stopped
	stopped # not moving for a while. after the timer runs out moves to walking
}
var currentState

func _ready() -> void:
	wander()

func _process(delta: float) -> void:
	if currentState == state.moving or currentState == state.walking:
		if nav.is_navigation_finished():
			if randi() % 10 < 4:
				currentState += [1, -1].pick_random()
				clamp(currentState, 0, 3)
			else:
				nav.target_position = Vector2(randf_range(0, Islands.gameSize.x * Islands.scale_factor), randf_range(0, Islands.gameSize.y * Islands.scale_factor))
				if !nav.is_target_reachable(): nav.target_position = nav.get_final_position()
		else:
			velocity = global_position.direction_to(nav.get_next_path_position()) * speed
			move_and_slide()
	elif currentState == state.resting:
		velocity = Vector2.ZERO
		await get_tree().create_timer(randf_range(0.1, 1)).timeout
		if randi() % 10 < 4:
			currentState += [1, -1].pick_random()
	elif currentState == state.stopped:
		velocity = Vector2.ZERO
		await get_tree().create_timer(randf_range(3, 5)).timeout
		currentState = state.walking
	else:
		velocity = Vector2.ZERO
		match randi() % state.size():
			0: currentState = state.moving
			1: currentState = state.walking
			2: currentState = state.resting
			3: currentState = state.stopped

func wander():
	match state:
		state.moving:
			pass
		state.walking:
			pass
		state.resting:
			pass
		state.stopped:
			pass
