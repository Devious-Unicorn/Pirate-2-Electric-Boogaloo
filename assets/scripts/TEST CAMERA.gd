extends CharacterBody2D

@export var speed: float = 5
@onready var Islands = get_parent().get_node("Islands")

func _ready() -> void:
	position = Islands.gameSize * Islands.scale_factor / 2
	$Camera2D.zoom = Vector2.ONE * (640 / (Islands.gameSize.x * Islands.scale_factor))
	#$Camera2D.zoom = Vector2.ONE

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_pressed("zoom in"): $Camera2D.zoom += Vector2(0.1, 0.1)
	if Input.is_action_pressed("zoom out"): $Camera2D.zoom -= Vector2(0.1, 0.1)
	if Input.is_key_label_pressed(KEY_SPACE): $Camera2D.zoom = Vector2.ONE
	if Input.is_key_label_pressed(KEY_I): speed += 1
	if Input.is_key_label_pressed(KEY_K): speed -= 1
	speed = clamp(speed, 0.001, 1000000)
	$Camera2D.zoom = $Camera2D.zoom.clamp(Vector2.ONE * (640 / (Islands.gameSize.x * Islands.scale_factor)), Vector2.ONE * 10)

func _process(delta: float) -> void:
	
	velocity = Input.get_vector("left","right","up","down") * speed
	$CanvasLayer/Label.text = str(velocity.length()) + "\n" + str(speed)
	move_and_slide()
