
extends Node2D

func _ready():
	pass

func _on_Timer_timeout():
	self.queue_free()

func setText(text):
	find_node("Label1").set_text(text)
	find_node("Label2").set_text(text)