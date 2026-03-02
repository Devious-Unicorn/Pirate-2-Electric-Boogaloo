extends ColorRect # Controls the ocean visual.

@onready var Main = get_parent()
@onready var Boat = get_node("../Boat")

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
	if not wind_noise: # Create a noise generator if one isn't assigned.
		wind_noise = FastNoiseLite.new()
		wind_noise.seed = randi() # Unique seed for every session.

func _process(delta: float) -> void:
	time_passed += delta # Increment our internal timer.
	var mat = material as ShaderMaterial # Access the ocean shader material.
	if not mat: return # Safety check.

	# 1. Calculate Instant Wind Direction (The "Now" Heading)
	var nx = wind_noise.get_noise_1d(time_passed * wind_change_speed) # Noise X (-1 to 1).
	var ny = wind_noise.get_noise_1d((time_passed + 1000.0) * wind_change_speed) # Noise Y (-1 to 1).
	var wind_dir = Vector2(nx, ny) # This is the current wind vector

	# 3. Calculate Flow Speed Surge (Wind Strength)
	var f_noise = wind_noise.get_noise_1d((time_passed + 500.0) * flow_change_speed) # Speed noise.
	var current_flow = remap(f_noise, -1.0, 1.0, flow_min, flow_max) # Scale noise to Min/Max.

	# 4. Update the Sibling Boat Node
	# We check if the boat exists, then pass the current wind direction and strength.
	if Boat:
		# These assume your Boat script has these variables or a function to receive them.
		Boat.set("wind_direction", wind_dir.normalized()) # Pass the direction (0 to 1 length).
		Boat.set("wind_strength", current_flow) # Pass the current speed multiplier.
		#$"../CanvasLayer/Debug".text += "\n" + str(wind_dir) + "\n" + str(current_flow)
	
	# 5. Update Shader Offset (Movement Memory)
	# We multiply direction by strength and delta to get the movement for this frame.
	current_offset += wind_dir * current_flow * delta
	
	# 6. Push Data to Shader
	# The shader uses this to slide the noise across the world-anchored grid.
	mat.set_shader_parameter("wind_direction", current_offset)
