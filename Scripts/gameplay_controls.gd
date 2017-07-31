
extends Node2D

func _ready():
	set_process(true)

func _process(delta):
	if(Input.is_action_pressed("UI_PAUSE")):
		if(!get_tree().is_paused()):
			var pauseMenu = self.find_node("PauseMenuPopup")
			pauseMenu.toggle()
			get_tree().set_pause(true)
