extends ColorRect

var noise = FastNoiseLite.new()
@export_range(0, 1, 0.01) var sandThreshold = 0.3;
@export var gameSize := Vector2(3840, 2160)

func _ready() -> void:
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05

func _buildMesh():
	
	for x in range(gameSize.x):
		for y in range(gameSize.y):
			pass

func get_noise_color(v: float) -> Color:
	if v < sandThreshold:
		return Color(0.94, 0.82, 0.6) # Sand
	# Normalize green range to 0.0 - 1.0 for lerping
	var green_factor = (v - sandThreshold) / (1.0 - sandThreshold)
	return Color(0.5, 0.9, 0.2).lerp(Color(0.05, 0.3, 0.05), green_factor)
