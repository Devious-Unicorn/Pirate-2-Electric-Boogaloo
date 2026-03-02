extends Control

@onready var play = $MarginContainer/VBoxContainer/Play
@onready var options = $MarginContainer/VBoxContainer/Options
@onready var credits = $MarginContainer/VBoxContainer/Credits
@onready var quit = $MarginContainer/VBoxContainer/Quit
@onready var Main = get_parent()

var optionsScene
var creditsScene

func _ready() -> void:
	quit.pressed.connect(get_tree().quit)
	options.pressed.connect(optionsMenu)
	credits.pressed.connect(creditsMenu)

func optionsMenu():
	optionsScene = preload("res://assets/scenes/options_menu.tscn").instantiate()
	add_child(optionsScene)

func creditsMenu():
	creditsScene = preload("res://assets/scenes/credits.tscn").instantiate()
	add_child(creditsScene)
