extends Node2D

@onready var islandScene = preload("res://assets/scenes/islands.tscn")
@onready var Islands = $Islands
@onready var Ocean = $Ocean

var islands: Array
var genFin := false
signal nav_areas_ready
signal generation_complete

func _ready() -> void:
	var thread = Thread.new(); thread.start($Islands.call.bind("generate"))
	await $Islands.generationComplete
	thread.wait_to_finish()
	thread.start(_on_islands_generation_complete)
	await generation_complete
	thread.wait_to_finish()

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
	
	var thread = Thread.new(); thread.start(createNavAreas)
	await get_tree().process_frame
	await nav_areas_ready
	thread.wait_to_finish()
	get_node("House spawner").spawnGuys()
	call_deferred("emit_signal", "generation_complete")

func createNavAreas():
	#for island in $Islands.find_children("*", "CollisionPolygon2D"):
	var navArea: NavigationRegion2D = NavigationRegion2D.new()
	var navPoly: NavigationPolygon = NavigationPolygon.new()
	
	navPoly.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	navPoly.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	
	var sourceData = NavigationMeshSourceGeometryData2D.new()
	(func(): NavigationServer2D.parse_source_geometry_data(navPoly, sourceData, $Islands)).call_deferred()
	(func(): NavigationServer2D.bake_from_source_geometry_data(navPoly, sourceData)).call_deferred()
	
	navArea.navigation_polygon = navPoly
	add_child.call_deferred(navArea)
	
	call_deferred("emit_signal", "nav_areas_ready")

func _get_island_pos(i: int, size: Vector2) -> Vector2:
	var offsets = [
		Vector2(-size.x, -size.y), Vector2(0, -size.y), Vector2(size.x, -size.y),
		Vector2(-size.x, 0),                            Vector2(size.x, 0),
		Vector2(-size.x, size.y),  Vector2(0, size.y),  Vector2(size.x, size.y)
	]
	return offsets[i]
