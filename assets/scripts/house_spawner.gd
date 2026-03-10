extends Node2D

@export var houseDistance: float = 150 # how close together each house is allowed to be

@onready var Islands = get_node("../Islands")
@onready var Game = get_node("../")
@onready var House = preload("res://assets/scenes/house.tscn")
@onready var Guy = preload("res://assets/scenes/guy.tscn")

var houses: Array
var guys: Array

func _ready():
	await Islands.generationComplete
	var islands = Islands.find_children("*", "CollisionPolygon2D")
	
	for island in islands:
		var num = randi_range(1, 10)
		var spawned_on_island = 0
		var attempts = 0
		
		while spawned_on_island < num and attempts < 100:
			var point = pickPointInPolygon(island.polygon)
			
			# Check distance against ALL existing houses
			var too_close = false
			for h in houses:
				if point.distance_to(h.global_position) < houseDistance:
					too_close = true
					break
			
			if not too_close:
				var new_house = House.instantiate()
				new_house.global_position = point
				add_child(new_house)
				houses.append(new_house)
				spawned_on_island += 1
			
			attempts += 1
	
	for h in houses:
		var num = randi_range(1, 4)
		for i in range(num):
			guys.append(Guy.instantiate())
			guys[-1].homePosition = h.global_position
			guys[-1].global_position = guys[-1].homePosition + Vector2.ONE * randf_range(-10, 10)
			add_child(guys[-1])

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
