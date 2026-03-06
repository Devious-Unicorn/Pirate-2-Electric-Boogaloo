extends SubViewport

@export var Boat: CharacterBody2D
@export var MinimapIcon: Sprite2D

func _ready():
	world_2d = get_tree().root.get_viewport().world_2d
	get_tree().root.canvas_cull_mask = 1
	$"Minimap camera".zoom = Vector2.ONE / 15
	MinimapIcon.scale = Vector2.ONE * 5

func _process(delta: float) -> void:
	$"Minimap camera".global_position = Boat.global_position
