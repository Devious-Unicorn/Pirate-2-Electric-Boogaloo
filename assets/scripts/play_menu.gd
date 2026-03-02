extends Control

@onready var newGame = $"MarginContainer/VBoxContainer/New game"
@onready var Main = get_parent()

func _ready() -> void:
	newGame.pressed.connect(Callable(Main, "newGame"))
	newGame.pressed.connect(queue_free)
