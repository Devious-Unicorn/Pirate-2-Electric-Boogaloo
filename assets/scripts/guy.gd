extends CharacterBody2D

@export var homePosition: Vector2

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	wander()
	
	move_and_slide()

func wander():
	pass
