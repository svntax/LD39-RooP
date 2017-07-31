
extends VBoxContainer

func _ready():
	pass

func _on_StartButton_pressed():
	get_tree().change_scene("res://Scenes/gameplay.tscn")

func _on_QuitButton_pressed():
	get_tree().quit()
