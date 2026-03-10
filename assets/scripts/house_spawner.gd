extends Node2D

@onready var Islands = get_node("../Islands")
@onready var Game = get_node("../")
@onready var House = preload("res://assets/scenes/house.tscn")

var houses: Array

func _ready():
	await Islands.generationComplete
	# get all colliders
	var islands = Islands.find_children("*", "CollisionPolygon2D")
	for island in islands:
		for i in range(randi_range(1, 10)):
			var point := pickPointInPolygon(island.polygon)
			houses.append(House.instantiate())
			houses[-1].global_position = point
			add_child(houses[-1])

func pickPointInPolygon(polygon) -> Vector2:
	# convert the polygon to triangles
	var triPoints = Geometry2D.triangulate_polygon(polygon)
	
	var tris: Array[PackedVector2Array]
	for i in range(0, triPoints.size(), 3):
		# create an array of each triangle
		tris.append([polygon[triPoints[i]], polygon[triPoints[i + 1]], polygon[triPoints[i + 2]]])
	# create array of the area of each triangle
	var area: Array
	for tri in tris:
		var p1 = tri[0]
		var p2 = tri[1]
		var p3 = tri[2]
		area.append(0.5 * abs(p1.x * (p2.y - p3.y) + p2.x * (p3.y - p1.y) + p3.x * (p1.y - p2.y)))
	
	var selectedTri = tris[area.find(selectRandomWeighted(area))]
	var num = Vector2(randf(), randf())
	return ((1 - sqrt(num.x)) * selectedTri[0] + (sqrt(num.x) * (1 - num.y)) * selectedTri[1] + (sqrt(num.x) * num.y) * selectedTri[2])

func selectRandomWeighted(list):
	var totalWeight := 0.0
	for i in list:
		totalWeight += i
	
	var num = randf()
	for i in range(list.size()):
		num  -= list[i]
		if(num <= 0): return list[i]
