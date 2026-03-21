extends PanelContainer

@onready var boat = preload("res://assets/scenes/boat.tscn")
@export var Game: Node2D
@export var Throbber: TextureRect
@export var Status: Label

func _ready() -> void:
	Game.generation_complete.connect(startGame)

func _physics_process(delta: float) -> void:
	Throbber.rotation += PI / 45

func startGame():
	Game.add_child(boat.instantiate())
	queue_free()

func setStatus(txt: String):
	Status.set_deferred("text", txt)
