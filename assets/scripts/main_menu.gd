extends Control

@onready var play = $MarginContainer/VBoxContainer/Play
@onready var options = $MarginContainer/VBoxContainer/Options
@onready var credits = $MarginContainer/VBoxContainer/Credits
@onready var quit = $MarginContainer/VBoxContainer/Quit

func _ready() -> void:
	quit.pressed.connect(get_tree().quit)
	options.pressed.connect(optionsMenu)
	credits.pressed.connect(creditsMenu)

func optionsMenu():
	pass

func creditsMenu():
	pass
