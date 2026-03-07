extends Control

var ctrls: Array = []
var listening := false
var listener = null

func _unhandled_input(event: InputEvent) -> void:
	if not listening: return
	InputMap.action_add_event(listener.get_parent().name, event)
	updateLabels()

func _ready() -> void:
	$Quit.pressed.connect(queue_free)
	for node in find_children("*", "Button"):
		if(node is Button and node.name == "ctrl"):
			ctrls.append(node)
			node.pressed.connect(setCtrls.bind(node))
	
	updateLabels()

func updateLabels():
	for ctrl in ctrls:
		InputMap.action_get_events(ctrl.get_parent().name)
		ctrl.text = InputMap.action_get_events(ctrl.get_parent().name)[0].as_text().replace(" - Physical", "")

func setCtrls(button: Button):
	button.text = "Awaiting input..."
	listening = true;
	listener = button
	InputMap.action_erase_events(button.get_parent().name)
