
extends Node2D

var DELETION_DELAY = 1

func _ready():
	pass

func _on_Timer_timeout():
	self.find_node("Particles2D").set_emitting(false)
	var timer = Timer.new()
	timer.connect("timeout", self, "deleteSpark")
	timer.set_wait_time(DELETION_DELAY)

func deleteSpark():
	self.queue_free()