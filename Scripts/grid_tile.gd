
extends Node2D

##Tile types:##
#0 = horizontal (left-right)
#1 = vertical (up-down)
#2 = right-down corner
#3 = left-down corner
#4 = up-left corner
#5 = up-right corner
#6 = central generator
#7 = external generator
#8 = diamond tile

#The points where a spark can enter or exit from
var UP = 0
var LEFT = 1
var RIGHT = 2
var DOWN = 3

var type
var gridPos
var exit1
var exit2
var sparkInTile #If there is currently a spark in this tile
var drained

func _ready():
	sparkInTile = false
	drained = false

func getPosInGrid():
	return gridPos

func setPosInGrid(newPos):
	gridPos = newPos

func getType():
	return type

func setType(type):
	self.type = type
	var tileSprite = self.find_node("Sprite")
	#First 6 basic tiles are in the first row of the tileset
	if(type >= 0 and type <= 5):
		tileSprite.set_region_rect(Rect2(type*16, 0, 16, 16))
	elif(type == 6): #central tile
		tileSprite.set_region_rect(Rect2(0, 16, 16, 16))
	elif(type == 7): #generator tile
		tileSprite.set_region_rect(Rect2(16, 16, 16, 16))
	elif(type == 8): #diamond tile
		tileSprite.set_region_rect(Rect2(32, 16, 16, 16))
	if(type == 0): #left-right horizontal tile
		exit1 = LEFT
		exit2 = RIGHT
	elif(type == 1): #up-down vertical tile
		exit1 = UP
		exit2 = DOWN
	elif(type == 2): #right-down corner tile
		exit1 = RIGHT
		exit2 = DOWN
	elif(type == 3): #left-down corner tile
		exit1 = LEFT
		exit2 = DOWN
	elif(type == 4): #up-left corner tile
		exit1 = UP
		exit2 = LEFT
	elif(type == 5): #up-right corner tile
		exit1 = UP
		exit2 = RIGHT

func getExit1():
	return exit1

func getExit2():
	return exit2

func isSparkInTile():
	return sparkInTile

func drainDiamond():
	self.find_node("DrainedDiamond").show()
	drained = true

#For diamond tiles, check if drained or not
func isDrained():
	return drained