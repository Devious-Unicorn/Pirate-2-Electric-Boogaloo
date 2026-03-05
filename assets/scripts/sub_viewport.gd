extends SubViewport

@onready var Boat := get_node("../../../")

func _ready():
	world_2d = get_tree().root.world_2d
	$"Minimap camera".global_position = Boat.global_position
	$"Minimap camera".zoom = Vector2.ONE * 0.1666
