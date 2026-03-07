extends Control

@onready var newGame = $"MarginContainer/VBoxContainer/New game"
@onready var quit = $MarginContainer/VBoxContainer/Quit
@onready var Main = get_parent()

func _ready() -> void:
	newGame.pressed.connect(Callable(Main, "newGame"))
	newGame.pressed.connect(queue_free)
	quit.pressed.connect(Callable(Main, "_ready"))
	quit.pressed.connect(queue_free)
