extends Node2D

@onready var islandScene = preload("res://assets/scenes/islands.tscn")
@onready var Islands = $Islands
@onready var Ocean = $Ocean
@export var LoadingScreen: PanelContainer

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
	
	LoadingScreen.setStatus.call_deferred("Create navigation regions for NPC random movement")
	var thread = Thread.new(); thread.start(createNavAreas)
	await nav_areas_ready
	thread.wait_to_finish()
	LoadingScreen.setStatus.call_deferred("Randomly place houses on each island")
	get_node("House spawner").spawnHouses()
	get_node("House spawner").spawnGuys()
	call_deferred("emit_signal", "generation_complete")

func createNavAreas():
	LoadingScreen.setStatus.call_deferred("Initialize NavigationRegion and NavigationPolygon for generating from the islands' hitboxes")
	var navArea: NavigationRegion2D = NavigationRegion2D.new()
	var navPoly: NavigationPolygon = NavigationPolygon.new()
	
	navPoly.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	navPoly.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	
	var sourceData = NavigationMeshSourceGeometryData2D.new()
	(func(): 
		LoadingScreen.setStatus("Parse the geometry of the hitboxes of the islands to create the navigation polygon")
		NavigationServer2D.parse_source_geometry_data(navPoly, sourceData, $Islands)
		LoadingScreen.setStatus("Bake the parsed source geometry of the islands into the navigation polygon")
		NavigationServer2D.bake_from_source_geometry_data(navPoly, sourceData)
	).call_deferred()
	
	LoadingScreen.setStatus.call_deferred("Set the navigation polygon of the NavigationRegion to the navigation polygon generated from the parsed source geometry of the islands")
	navArea.navigation_polygon = navPoly
	LoadingScreen.setStatus.call_deferred("Add the completed NavigationRegion to the scene tree")
	add_child.call_deferred(navArea)
	print("navigation region added to scene tree")
	nav_areas_ready.emit.call_deferred()

func _get_island_pos(i: int, size: Vector2) -> Vector2:
	var offsets = [
		Vector2(-size.x, -size.y), Vector2(0, -size.y), Vector2(size.x, -size.y),
		Vector2(-size.x, 0),                            Vector2(size.x, 0),
		Vector2(-size.x, size.y),  Vector2(0, size.y),  Vector2(size.x, size.y)
	]
	return offsets[i]
