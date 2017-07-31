
extends VBoxContainer

func _ready():
	pass
	
func _draw():
	draw_rect(Rect2(-2, -2, get_size().x+4, get_size().y+4), Color(255, 255, 255))
	draw_rect(Rect2(-1, -1, get_size().x+2, get_size().y+2), Color(0, 0, 0))

func enableButtons():
	find_node("YesButton").set_disabled(false)
	find_node("NoButton").set_disabled(false)

func disableButtons():
	find_node("YesButton").set_disabled(true)
	find_node("NoButton").set_disabled(true)

func toggle():
	#Move pause menu node so it draws on top of everything else
	if(get_index() != get_parent().get_child_count() - 1):
		get_parent().move_child(self, get_parent().get_child_count() - 1)
	show()
	enableButtons()
	var screenWidth = get_viewport().get_rect().size.x / 2
	var screenHeight = get_viewport().get_rect().size.y / 2
	var center = get_viewport().get_rect().size / 2
	var menuSize = get_rect().size
	set_global_pos(center - (menuSize / 2))

func _on_YesButton_pressed():
	get_tree().set_pause(false)
	disableButtons()
	get_tree().change_scene("res://Scenes/main_menu.tscn")
	hide()
	disableButtons()

func _on_NoButton_pressed():
	get_tree().set_pause(false)
	disableButtons()
	set_global_pos(Vector2(-640, -480))
	hide()
