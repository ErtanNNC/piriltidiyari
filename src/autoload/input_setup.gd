extends Node
## Registers the input actions in code so they stay readable in review.

const ACTIONS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"jump": [KEY_SPACE],
	"attack": [KEY_J],
	"interact": [KEY_E, KEY_ENTER],
	"roll": [KEY_K, KEY_SHIFT],
	"skill": [KEY_L],
	"potion_1": [KEY_1],
	"potion_2": [KEY_2],
	"potion_3": [KEY_3],
	"potion_4": [KEY_4],
}

const PAD_BUTTONS := {
	"jump": JOY_BUTTON_A,
	"attack": JOY_BUTTON_X,
	"interact": JOY_BUTTON_Y,
	"roll": JOY_BUTTON_B,
	"skill": JOY_BUTTON_RIGHT_SHOULDER,
	"potion_1": JOY_BUTTON_LEFT_SHOULDER,
}


func _init() -> void:
	for action: String in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for key: int in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
	for action: String in PAD_BUTTONS:
		var jb := InputEventJoypadButton.new()
		jb.button_index = PAD_BUTTONS[action]
		InputMap.action_add_event(action, jb)
	var axes := {"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_forward": [JOY_AXIS_LEFT_Y, -1.0], "move_back": [JOY_AXIS_LEFT_Y, 1.0]}
	for action: String in axes:
		var jm := InputEventJoypadMotion.new()
		jm.axis = axes[action][0]
		jm.axis_value = axes[action][1]
		InputMap.action_add_event(action, jm)
