extends Node2D

@onready var islandScene = preload("res://assets/scenes/islands.tscn")
@onready var oceanScene = preload("res://assets/scenes/ocean.tscn")
@onready var Islands = $Islands
@onready var Ocean = $Ocean

var islands: Array
var genFin := false

func _on_islands_generation_complete() -> void:
	var island_node = Islands if Islands else get_node("Islands")
	if genFin or not island_node: return 
	
	var islandSize: Vector2 = island_node.gameSize * island_node.scale_factor
	
	# Setup Ocean
	Ocean.size = islandSize * 2
	Ocean.global_position = islandSize / 2 - Ocean.size / 2
	
	for i in range(8):
		# Create a "blank" island (don't call _buildMesh)
		var new_island = islandScene.instantiate()
		new_island.is_clone = true # tell the instantaited island to not run _ready()
		
		# Transfer the data from the original generated island
		Islands.duplicate_data_to(new_island)
		
		# Position it based on your match logic
		new_island.global_position = _get_island_pos(i, islandSize)
		
		add_child(new_island)
		islands.append(new_island)
		
	genFin = true

# Helper to clean up that long match statement
func _get_island_pos(i: int, size: Vector2) -> Vector2:
	var offsets = [
		Vector2(-size.x, -size.y), Vector2(0, -size.y), Vector2(size.x, -size.y),
		Vector2(-size.x, 0),                            Vector2(size.x, 0),
		Vector2(-size.x, size.y),  Vector2(0, size.y),  Vector2(size.x, size.y)
	]
	return offsets[i]
