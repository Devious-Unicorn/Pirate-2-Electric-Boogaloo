extends Node2D

@onready var islandScene = preload("res://assets/scenes/islands.tscn")
@onready var Islands = $Islands
@onready var Ocean = $Ocean

var islands: Array
var genFin := false
signal nav_areas_ready

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
		new_island.is_clone = true
		Islands.duplicate_data_to(new_island)
		new_island.global_position = _get_island_pos(i, islandSize)
		add_child(new_island)
		islands.append(new_island)
		
	genFin = true
	
	createNavAreas()
	await get_tree().process_frame
	NavigationServer2D.bake_from_source_geometry_data(
		get_world_2d().get_navigation_map(),
		NavigationMeshSourceGeometryData2D.new()
	)
	
	get_node("House spawner").spawnGuys()

func createNavAreas():
	for island in find_children("*", "CollisionPolygon2D"):
		var navArea = NavigationRegion2D.new()
		var navPoly = NavigationPolygon.new()
		navPoly.add_outline(Geometry2D.offset_polygon(island.polygon, -32))
		navArea.navigation_polygon = navPoly
		add_child(navArea)
		navArea.bake_navigation_polygon()
	
	# Signal that nav areas are ready
	call_deferred("emit_signal", "nav_areas_ready")

func _get_island_pos(i: int, size: Vector2) -> Vector2:
	var offsets = [
		Vector2(-size.x, -size.y), Vector2(0, -size.y), Vector2(size.x, -size.y),
		Vector2(-size.x, 0),                            Vector2(size.x, 0),
		Vector2(-size.x, size.y),  Vector2(0, size.y),  Vector2(size.x, size.y)
	]
	return offsets[i]
