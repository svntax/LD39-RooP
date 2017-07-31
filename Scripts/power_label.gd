
extends Label

func _ready():
	updateValueDisplay(get_parent().get_val())

func updateValueDisplay(newAmount):
	var maxVal = get_parent().get_max()
	self.set_text(str(newAmount) + "/" + str(maxVal))

func _on_PowerBar_value_changed(value):
	updateValueDisplay(value)
