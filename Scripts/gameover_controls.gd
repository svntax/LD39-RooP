
extends VBoxContainer

func _ready():
	pass
	
func _draw():
	draw_rect(Rect2(-2, -2, get_size().x+4, get_size().y+4), Color(255, 255, 255))
	draw_rect(Rect2(-1, -1, get_size().x+2, get_size().y+2), Color(0, 0, 0))

func toggle():
	#Move gameover UI to be drawn on top of everything else
	if(get_index() != get_parent().get_child_count() - 1):
		get_parent().move_child(self, get_parent().get_child_count() - 1)
	show()
	find_node("Button").set_disabled(false)
	var screenWidth = get_viewport().get_rect().size.x / 2
	var screenHeight = get_viewport().get_rect().size.y / 2
	var center = get_viewport().get_rect().size / 2
	var gameoverMenuSize = get_rect().size
	set_global_pos(center - (gameoverMenuSize / 2))

func _on_Button_pressed():
	get_tree().set_pause(false)
	get_tree().change_scene("res://Scenes/main_menu.tscn")
	hide()
	find_node("Button").set_disabled(true)
