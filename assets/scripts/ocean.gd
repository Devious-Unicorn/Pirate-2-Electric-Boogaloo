extends ColorRect # Controls the ocean visual.

@onready var Main = get_parent()
@onready var Boat = get_node_or_null("../Boat")
@onready var Islands = get_node_or_null("../Islands")

@export_group("Resources")
@export var wind_noise: FastNoiseLite

@export_group("Wind Movement")
@export var wind_change_speed: float = 0.5   # How often the wind direction shifts.

@export_group("Flow Intensity Range")
@export var flow_change_speed: float = 1.0   # How often the flow speed surges or slows.
@export var flow_min: float = 0.5          # Slowest flow multiplier.
@export var flow_max: float = 1.8          # Fastest flow multiplier.

var current_offset: Vector2 = Vector2.ZERO # Total movement "memory" passed to the shader.
var time_passed: float = 0.0               # Clock to track noise sampling over time.

func _ready() -> void:
	if Islands: pass
	else: set_deferred("size", Vector2(640, 360))
	
	if not wind_noise: # Create a noise generator if one isn't assigned.
		wind_noise = FastNoiseLite.new()
		wind_noise.seed = randi() # Unique seed for every session.

func _process(delta: float) -> void:
	time_passed += delta # Increment our internal timer.
	var mat = material as ShaderMaterial # Access the ocean shader material.
	if not mat: return

	# calculate current wind direction
	var nx = wind_noise.get_noise_1d(time_passed * wind_change_speed)
	var ny = wind_noise.get_noise_1d((time_passed + 1000.0) * wind_change_speed) # add offset so it is less uniform
	var wind_dir = Vector2(nx, ny)

	# calculate current wind speed
	var f_noise = wind_noise.get_noise_1d((time_passed + 500.0) * flow_change_speed)
	var current_flow = remap(f_noise, -1.0, 1.0, flow_min, flow_max) # Scale noise to [min, max]

	# send wind to boat so it can be pushed by it
	if Boat:
		Boat.set("wind_direction", wind_dir.normalized()) # Pass the direction (0 to 1 length).
		Boat.set("wind_strength", current_flow) # Pass the current speed multiplier.
	
	# We multiply direction by strength and delta to get the movement for this frame.
	current_offset += wind_dir * current_flow * delta
	
	mat.set_shader_parameter("wind_direction", current_offset)
