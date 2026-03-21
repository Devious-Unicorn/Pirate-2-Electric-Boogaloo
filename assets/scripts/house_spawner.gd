extends Node2D

@export var houseDistance: float = 150 # how close together each house is allowed to be
@export var LoadingScreen: PanelContainer
@export var Islands: StaticBody2D
@export var Game = Node2D

@onready var Guy = preload("res://assets/scenes/guy.tscn")
@onready var islandCols: Array[CollisionPolygon2D] = Islands.cols

var houses: Array
var guys: Array

signal houseSpawnComplete;
signal guySpawnComplete;

func polygonArea(polygon: PackedVector2Array) -> float:
	# https://www.mathopenref.com/coordpolygonarea2.html // CAUTION this website is in light mode
	var area = 0
	var j: int = polygon.size() - 1
	
	for i in range(polygon.size()):
		area += (polygon[j].x + polygon[i].x) * (polygon[j].y - polygon[i].y)
		j = i
	
	return area / 2

func spawnHouses():
	LoadingScreen.setStatus("Place houses randomly on islands")
	
	for island in islandCols:
		# reverse direction of polygon if it is clockwise because in down is y+ coordinate systems it calculates the area wrong
		var area: float
		if Geometry2D.is_polygon_clockwise(island.polygon): 
			island.polygon.reverse()
			area = polygonArea(island.polygon)
			# put polygon winding back
			island.polygon.reverse()
		else:
			# polygon is already ccw so it can be left alone
			area = polygonArea(island.polygon)
		var maxHouses: int = floor(
			# makes a graph where an island with less than 100 area will have 0 houses and the biggest island i've seen so far (area of ~1106000) will only have 50
			(100 * (area - 100)) / (area + 1.1058e6)
		)
		var num: int = randi_range(1, maxHouses) if area > 100 else 0
		var spawned_on_island = 0
		var attempts = 0
		while spawned_on_island < num and attempts < 100:
			var point = pickPointInPolygon(island.polygon)
			# Check distance against ALL existing houses
			var too_close = false
			for h in houses:
				if point.distance_squared_to(h.global_position) < (houseDistance ** 2):
					too_close = true
					break
			
			if not too_close:
				var new_house = Sprite2D.new()
				new_house.texture = preload("res://assets/sprites/house.png")
				new_house.scale = Vector2.ONE * 3
				new_house.global_position = point
				add_child.call_deferred(new_house)
				houses.append(new_house)
				spawned_on_island += 1
			
			attempts += 1
	spawnGuys()

func spawnGuys():
	LoadingScreen.setStatus.call_deferred("Spawn people")
	for h in houses:
		var num = randi_range(1, 4)
		for i in range(num):
			guys.append(Guy.instantiate())
			guys[-1].home = h.global_position
			guys[-1].global_position = guys[-1].home + Vector2.ONE * randf_range(-10, 10)
			add_child.call_deferred(guys[-1])

func pickPointInPolygon(polygon) -> Vector2:
	var triPoints = Geometry2D.triangulate_polygon(polygon)
	
	# make array of the triangles that makes up the polygon
	var tris: Array[PackedVector2Array]
	for i in range(0, triPoints.size(), 3):
		# create an array of each triangle
		tris.append([polygon[triPoints[i]], polygon[triPoints[i + 1]], polygon[triPoints[i + 2]]])
	# create array of the area of each triangle
	var area: Array
	for tri in tris:
		# area of a triangle can be found by finding the cross product of two adjacent edges
		# the magnitude of the result of the cross product is equal to a paralelogram with the same two edges used in the cross product
		# halving the result of the cross product gives the area of the triangle
		# subtract the positions to create a vector in the mathematical sense (dx, dy)
		area.append(abs((tri[1] - tri[0]).cross(tri[2] - tri[0])) * 0.5)
	
	var selectedTri = tris[area.find(selectRandomWeighted(area))]
	var num = Vector2(randf(), randf())
	
	return (1 - sqrt(num.x)) * selectedTri[0] + (sqrt(num.x) * (1 - num.y)) * selectedTri[1] + (sqrt(num.x) * num.y) * selectedTri[2]

func distance(a: Vector2, b: Vector2) -> float:
	return sqrt((b.x - a.x) ** 2 + (b.y - a.y) ** 2)

func selectRandomWeighted(list):
	var totalWeight := 0.0
	for i in list:
		totalWeight += i
	
	var num = randf_range(0, totalWeight)
	for i in list:
		num -= i
		if num <= 0: return i
