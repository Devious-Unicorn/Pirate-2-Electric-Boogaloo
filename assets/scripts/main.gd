extends Control

var packedScenes := {
	"mainMenu" = preload("res://assets/scenes/main_menu.tscn"),
	"playMenu" = preload("res://assets/scenes/play_menu.tscn"),
	"game" = preload("res://assets/scenes/game.tscn")
}
var scenes := {
	"mainMenu" = null,
	"playMenu" = null,
	"game" = null
}

func _ready() -> void:
	scenes.mainMenu = packedScenes.mainMenu.instantiate()
	add_child(scenes.mainMenu)

func playMenu():
	scenes.playMenu = packedScenes.playMenu.instantiate()
	add_child(scenes.playMenu)

func newGame():
	$Ocean.queue_free()
	scenes.game = packedScenes.game.instantiate()
	add_child(scenes.game)
