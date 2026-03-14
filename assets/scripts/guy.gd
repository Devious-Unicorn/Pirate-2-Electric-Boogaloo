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
	pass

func _process(delta: float) -> void:
	if currentState == state.moving or currentState == state.walking:
		if nav.is_navigation_finished():
			if randi() % 10 < 4:
				currentState += [1, -1].pick_random()
				clamp(currentState, 0, 3)
			else:
				for region in get_node("../../").find_children("*", "NavigationRegion2D"):
					var global_vertices: Array[Vector2]
					for v in region.navigation_polygon.get_vertices():
						global_vertices.append(region.to_global(v))
					if(Geometry2D.is_point_in_polygon(global_position, global_vertices)):
						nav.target_position = NavigationServer2D.region_get_random_point(region.get_region_rid(), 1, false)
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
		currentState = state.walking
