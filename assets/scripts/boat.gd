extends CharacterBody2D

# the maximum speed the boat is allowed to move
@export var defaultMaxSpeed : float = 50
# how fast the boat accelerates
@export var acceleration: float = 10
# how much the boat slows every frame
@export_range(0, 100, 0.001) var friction: float = 5
@export_range(0, 100, 0.001) var beachedFriction: float = 25
# how much the wind from the ocean scene pushes the boat
@export var wind_push_factor: float = 0.5

@onready var Game: Node2D = get_node("../")
@onready var Main := get_parent()
@onready var Ocean := Main.get_node_or_null("Ocean")
@onready var Islands := Main.get_node_or_null("Islands")
@onready var islandSize: Vector2 = Islands.gameSize * Islands.scale_factor
@onready var guy := preload("res://assets/scenes/guy.tscn")

# direction and strength of wind (sent from Ocean every frame)
var wind_direction: Vector2 = Vector2.ZERO
var wind_strength: float = 0.0
var endl := "\n"
# stores how many crew members the boat has
var crewSize: int = 1
var crew: Array[Node]
var beached := false
var crewOut := false

func _ready() -> void:
	global_position = islandSize / 2
	await get_parent().generation_complete
	
	while(isStuck()):
		global_position += Vector2(
			randf_range(-20, 20),
			randf_range(-20, 20)
		)
		force_update_transform()

func isStuck() -> bool:
	for dir in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		if test_move(global_transform, dir * 20): return true;
	return false

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed("zoom in"): $Camera2D.zoom += Vector2.ONE * 0.1
	if Input.is_action_pressed("zoom out"): $Camera2D.zoom -= Vector2.ONE * 0.1
	$Camera2D.zoom = $Camera2D.zoom.clamp(Vector2.ONE * 0.4, Vector2.ONE * 10)
	
	# check if beached OR crew out becuase otherwise checking for beached is inconsistant and doesn't always work
	if Input.is_action_just_pressed("disembark crew") and (beached or crewOut):
		crewOut = not crewOut
		_handleCrew()

func _physics_process(delta: float) -> void:
	# get forces that would cause a change in velocity
	var driveForce := _drive() * acceleration
	var windForce := -wind_direction * (wind_strength * wind_push_factor)
	# add to velocity instead of setting directly to make the boat accelerate instead of moving instantly
	velocity += (driveForce + windForce) * delta
	
	# if the boat is moving apply friction and rotation
	if velocity.length() > 0: 
		var realFriction
		rotation = lerp_angle(rotation, velocity.angle(), 0.01)
		if(!get_last_slide_collision() == null and "Islands" in get_last_slide_collision().get_collider().name):
			realFriction = beachedFriction
			beached = true
		else: 
			beached = false
			realFriction = friction
		velocity = velocity.move_toward(Vector2.ZERO, realFriction * delta)
	
	#reduce max speed or increase max speed depending on velocity angle and wind direction
	var maxSpeed = defaultMaxSpeed - (abs(velocity.angle_to(wind_direction.rotated(5 * PI / 4)) - PI / 2) * wind_strength * 3)
	
	# limit speed to maxSpeed
	velocity = velocity.limit_length(maxSpeed)
	
	$CanvasLayer/Label.text = str(beached) + endl + str(crewOut) + endl + str(position) + endl + str(velocity) + endl + str(velocity.length())
	
	$"CanvasLayer/Speedometer needle".rotation = remap(velocity.length(), 0, 50, 0, PI / 2)
	
	if crewOut: velocity = Vector2.ZERO
	
	move_and_slide()
	
	# if the boat travels off of the side of the map then loop it around to the other side
	if position.x > islandSize.x: 
		global_position.x -= islandSize.x
		Ocean.current_offset.x += islandSize.x / 2
	if position.x < 0: 
		global_position.x += islandSize.x
		Ocean.current_offset.x -= islandSize.x / 2
	if position.y > islandSize.y: 
		global_position.y -= islandSize.y
		Ocean.current_offset.y += islandSize.y / 2
	if position.y < 0: 
		global_position.y += islandSize.y
		Ocean.current_offset.y -= islandSize.y / 2

func _drive() -> Vector2:
	var input = Input.get_vector("left", "right", "up", "down")
	return input

func _handleCrew():
	if not crewOut:
		for c in crew:
			c.get_node("NavigationAgent2D").target_position = global_position
		crew = []
	else:
		for i in range(crewSize):
			# create a new guy
			crew.append(guy.instantiate())
			# name him something easy to keep track of
			crew[-1].name = "CrewMember" + str(i)
			# set him just in front of the boat with a little spread
			crew[-1].global_position = global_position + ((Vector2.ONE * 32).rotated(rotation + randf_range(-PI / 12, PI / 12) - PI / 4))
			Game.add_child(crew[-1])
