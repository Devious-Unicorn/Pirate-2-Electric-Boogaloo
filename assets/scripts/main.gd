extends Control

var packedScenes := {
	"mainMenu" = preload("res://assets/scenes/main_menu.tscn"),
	"playMenu" = preload("res://assets/scenes/play_manu.tscn"),
	"optionsMenu" = preload("res://assets/scenes/options_menu.tscn"),
	"credits" = preload("res://assets/scenes/credits.tscn"),
	"game" = preload("res://assets/scenes/game.tscn")
}
var scenes := {
	"mainMenu" = null,
	"playMenu" = null,
	"optionsMenu" = null,
	"credits" = null,
	"game" = null
}

func _ready() -> void:
	scenes.mainMenu = packedScenes.mainMenu.instantiate()
	add_child(scenes.mainMenu)
