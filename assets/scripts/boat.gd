extends CharacterBody2D

# the maximum speed the boat is allowed to move
@export var defaultMaxSpeed : float = 50
# how fast the boat accelerates
@export var acceleration: float = 10
# how much the boat slows every frame
@export_range(0, 100, 0.001) var friction: float = 5
# how much the wind from the ocean scene pushes the boat
@export var wind_push_factor: float = 0.5

@onready var Main := get_parent()
@onready var Ocean := Main.get_node_or_null("Ocean")
@onready var Islands := Main.get_node_or_null("Islands")
@onready var islandSize: Vector2 = Islands.gameSize * Islands.scale_factor
# direction and strength of wind (sent from Ocean every frame)
var wind_direction: Vector2 = Vector2.ZERO
var wind_strength: float = 0.0
var endl := "\n"

func _ready() -> void:
	position = islandSize / 2

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed("zoom in"): $Camera2D.zoom += Vector2.ONE * 0.1
	if Input.is_action_pressed("zoom out"): $Camera2D.zoom -= Vector2.ONE * 0.1
	

func _physics_process(delta: float) -> void:
	# get forces that would cause a change in velocity
	var driveForce := _drive() * acceleration
	var windForce := -wind_direction * (wind_strength * wind_push_factor)
	# add to velocity instead of setting directly to make the boat accelerate instead of moving instantly
	velocity += (driveForce + windForce) * delta
	
	# if the boat is moving apply friction and rotation
	if velocity.length() > 0: 
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		rotation = lerp_angle(rotation, velocity.angle(), 0.01)
	
	#reduce max speed or increase max speed depending on velocity angle and wind direction
	var maxSpeed = defaultMaxSpeed - ((abs(velocity.angle_to(wind_direction.rotated(deg_to_rad(-180)))) - PI / 2) * wind_strength * 3)
	
	# limit speed to maxSpeed
	velocity = velocity.limit_length(maxSpeed)
	
	# limit camera zoom
	$Camera2D.zoom = $Camera2D.zoom.clamp(Vector2.ONE * 0.25, Vector2.ONE * 10)
	
	move_and_slide()
	
	# if the boat travels off of the side of the map then loop it around to the other side
	if position.x > islandSize.x: position.x = 0; Ocean.current_offset.x += islandSize.x / 2
	if position.y > islandSize.y: position.y = 0; Ocean.current_offset.y += islandSize.y / 2
	if position.x < 0: position.x = islandSize.x; Ocean.current_offset.x -= islandSize.x / 2
	if position.y < 0: position.y = islandSize.y; Ocean.current_offset.y -= islandSize.y / 2
	$CanvasLayer/Label.text = str(position)

func _drive() -> Vector2:
	var input = Input.get_vector("left", "right", "up", "down")
	return input
