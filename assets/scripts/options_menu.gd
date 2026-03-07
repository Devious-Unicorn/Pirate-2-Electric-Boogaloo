extends Control

@export var inputMapPath: String = "user://inputMap.json"

var ctrls: Array = []
var listening := false
var listener = null

func _unhandled_input(event: InputEvent) -> void:
	if not listening: return
	InputMap.action_add_event(listener.get_parent().name, event)
	updateLabels()
	listening = false
	listener = null

func _ready() -> void:
	loadInputMap()
	$Quit.pressed.connect(saveInputMap)
	$Quit.pressed.connect(queue_free)
	
	for node in find_children("*", "Button"):
		if(node is Button and node.name == "ctrl"):
			ctrls.append(node)
			node.pressed.connect(setCtrls.bind(node))
	
	updateLabels()

func updateLabels():
	for ctrl in ctrls:
		var inputMap = InputMap.action_get_events(ctrl.get_parent().name)
		if inputMap.size() > 0:
			ctrl.text = InputMap.action_get_events(ctrl.get_parent().name)[0].as_text().replace(" - Physical", "")
		else: ctrl.text = "Not set"

func setCtrls(button: Button):
	button.text = "Awaiting input..."
	listening = true;
	listener = button
	InputMap.action_erase_events(button.get_parent().name)

func saveInputMap():
	var data = {}
	for action_name in InputMap.get_actions():
		if action_name.begins_with("ui_"): continue
		var events_data = []
		for event in InputMap.action_get_events(action_name):
			var event_data = {"type": event.get_class()}
			
			if event is InputEventKey:
				event_data["keycode"] = event.keycode
			elif event is InputEventJoypadButton:
				event_data["button_index"] = event.button_index
			elif event is InputEventMouseButton: # Add this
				event_data["button_index"] = event.button_index
				
			events_data.append(event_data)
		data[action_name] = events_data
	
	var json_string = JSON.stringify(data, "\t")
	var file = FileAccess.open(inputMapPath, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
	else:
		push_error("Failed to save input map to ", ProjectSettings.globalize_path(inputMapPath))

func loadInputMap():
	if not FileAccess.file_exists(inputMapPath): return

	var file = FileAccess.open(inputMapPath, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()

	if data == null: return

	for action in data.keys():
		InputMap.action_erase_events(action)
		for event_dict in data[action]:
			var new_event = null
			var type = event_dict.get("type")
			
			if type == "InputEventKey":
				new_event = InputEventKey.new()
				new_event.keycode = int(event_dict["keycode"])
			elif type == "InputEventJoypadButton":
				new_event = InputEventJoypadButton.new()
				new_event.button_index = int(event_dict["button_index"])
			elif type == "InputEventMouseButton":
				new_event = InputEventMouseButton.new()
				new_event.button_index = int(event_dict["button_index"])
			
			if new_event:
				InputMap.action_add_event(action, new_event)
