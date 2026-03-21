extends Node2D

@onready var islandScene = preload("res://assets/scenes/islands.tscn")
@onready var Islands = $Islands
@onready var Ocean = $Ocean
@export var LoadingScreen: PanelContainer
@export var HouseSpawner: Node2D

var islands: Array
var genFin := false
signal nav_areas_ready
signal generation_complete

func _ready() -> void:
	var thread = Thread.new(); thread.start($Islands.generate)
	await $Islands.generationComplete
	thread.wait_to_finish()

func _on_islands_generation_complete() -> void:
	var island_node = Islands if Islands else get_node("Islands")
	if genFin or not island_node: return 
	
	var islandSize: Vector2 = island_node.gameSize * island_node.scale_factor
	
	LoadingScreen.setStatus.call_deferred("Initialize ocean size and position")
	(func():
		# Setup Ocean
		Ocean.size = islandSize * 2
		Ocean.global_position = islandSize / 2 - Ocean.size / 2
	).call_deferred()
	
	for i in range(8):
		LoadingScreen.setStatus.call_deferred("Duplicate islands to create infinite world (%d/8)" % (i + 1))
		# Create a "blank" island (don't call _buildMesh)
		var new_island = islandScene.instantiate()
		new_island.is_clone = true
		Islands.duplicate_data_to.call_deferred(new_island)
		new_island.global_position = _get_island_pos(i, islandSize)
		add_child.call_deferred(new_island)
		islands.append(new_island)
		
	genFin = true
	
	LoadingScreen.setStatus.call_deferred("Randomly place houses on each island")
	HouseSpawner.spawnHouses()
	generation_complete.emit.call_deferred()

func createNavAreas():
	# This must run on the Main Thread
	if not Thread.is_main_thread():
		createNavAreas.call_deferred()
		return

	var navArea = NavigationRegion2D.new()
	var navPoly = NavigationPolygon.new()
	
	# IMPORTANT: Change to 'Root Node Children' and 'Visible Geometry'
	# This treats your island polygons as the WALKABLE area, not obstacles.
	navPoly.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_MESH_INSTANCES
	navPoly.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	
	var sourceData = NavigationMeshSourceGeometryData2D.new()
	
	# Parse the $Islands node. It will look for the visual shapes of your islands.
	NavigationServer2D.parse_source_geometry_data(navPoly, sourceData, $Islands)
	NavigationServer2D.bake_from_source_geometry_data(navPoly, sourceData)
	
	navArea.navigation_polygon = navPoly
	add_child(navArea)
	
	# Give the server a moment to register the new regions
	await get_tree().physics_frame
	nav_areas_ready.emit()

func _get_island_pos(i: int, size: Vector2) -> Vector2:
	var offsets = [
		Vector2(-size.x, -size.y), Vector2(0, -size.y), Vector2(size.x, -size.y),
		Vector2(-size.x, 0),                            Vector2(size.x, 0),
		Vector2(-size.x, size.y),  Vector2(0, size.y),  Vector2(size.x, size.y)
	]
	return offsets[i]
