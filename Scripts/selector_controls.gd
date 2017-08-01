
extends Node2D

func _ready():
	set_process(true)

func _process(delta):
	#Move selector to be drawn above everything else
	if(get_index() != get_parent().get_child_count() - 1):
		get_parent().move_child(self, get_parent().get_child_count() - 1)

	var mousePos = get_viewport().get_mouse_pos()
	var mouseTileX = floor(mousePos.x / 32)
	var mouseTileY = floor(mousePos.y / 32)
	if(get_parent().isValidGridPos(mouseTileX, mouseTileY)):
		self.set_pos(Vector2(mouseTileX * 16, mouseTileY * 16))