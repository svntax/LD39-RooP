
extends Node2D

var GRID_WIDTH = 19
var GRID_HEIGHT = 20

var SWAP_ANIM_DURATION = 2;
var swapping = false;
var tilesSwapped = false;
var elapsedSwappingTime = 0.0;
var swapBase = null;
var swapTarget = null;
var swapQueue = []

var energy = 4
var selectedTile = null

var sparkScene = load("res://Scenes/spark.tscn")
var gridTileScene = load("res://Scenes/grid_tile.tscn")
var powerMeter
var grid #2D array of tiles represented by their type
var objectGrid #2D array of tile objects

##Tile types:##
#0 = horizontal (left-right)
#1 = vertical (up-down)
#2 = right-down corner
#3 = left-down corner
#4 = up-left corner
#5 = up-right corner
#6 = central generator
var CENTRAL_TILE = 6

#The 4 exits possible for each tile
var UP = 0
var LEFT = 1
var RIGHT = 2
var DOWN = 3

#test function
func testNavigate(startX, startY):
	var startDir = LEFT #spark will enter from the left
	testNavigateHelper(startX, startY, startDir)

func testNavigateHelper(x, y, entryDir):
	#Stay within  bounds
	if(x < 0 or x > GRID_WIDTH - 1 or y < 0 or y > GRID_HEIGHT - 1):
		return
	var tileObj = getTileAt(x, y)
	#Make sure a tile object exists at (x, y)
	if(tileObj == null):
		return
	var exit1 = tileObj.getExit1()
	var exit2 = tileObj.getExit2()
	#Check if spark can enter the tile
	if(entryDir == exit1 or entryDir == exit2):
		#Test - visually mark the tile visited with a spark
		var spark = sparkScene.instance()
		spark.set_pos(tileObj.get_pos() + Vector2(8, 8))
		self.add_child(spark)
		var nextEntryDir = -1
		var currentExit = -1
		#Get the next direction the spark will enter from
		if(entryDir == exit1):
			currentExit = exit2
		elif(entryDir == exit2):
			currentExit = exit1
		#Recursively check the next tile
		if(currentExit == UP):
			testNavigateHelper(x, y - 1, DOWN)
		elif(currentExit == LEFT):
			testNavigateHelper(x - 1, y, RIGHT)
		elif(currentExit == RIGHT):
			testNavigateHelper(x + 1, y, LEFT)
		elif(currentExit == DOWN):
			testNavigateHelper(x, y + 1, UP)
	elif(tileObj.getType() == CENTRAL_TILE):
		var powerBar = powerMeter.find_node("PowerBar")
		var currentEnergy = powerBar.get_val()
		powerBar.set_val(currentEnergy + 5)
	else:
		#Spark fizzles out
		pass

func _ready():
	randomize() #Change the seed for any random operations
	powerMeter = find_node("PowerMeter")
	#Create 2D array for grid
	grid = []
	objectGrid = []
	for x in range(GRID_WIDTH):
		grid.append([])
		for y in range(GRID_HEIGHT):
			grid[x].append(randi() % 6) #Random tiles for now
	#Hard-coded central generator
	for i in range(-1, 2, 1):
		for j in range(-1, 2, 1):
			grid[GRID_WIDTH / 2 + i][GRID_HEIGHT / 2 + j] = CENTRAL_TILE
	#Create a 2D array for the actual tile objects
	for x in range(GRID_WIDTH):
		objectGrid.append([])
		for y in range(GRID_HEIGHT):
			objectGrid[x].append(null)
	createTilesFromGrid(grid)
	set_process_input(true)
	set_process(true);

func _input(event):
	if(event.type == InputEvent.MOUSE_BUTTON):
		var mouseX = event.pos.x
		var mouseY = event.pos.y
		var mouseTileX = floor(mouseX / 32)
		var mouseTileY = floor(mouseY / 32)
		if(event.button_index == BUTTON_LEFT && event.pressed):
			#Left click is tile selection
			if(isValidGridPos(mouseTileX, mouseTileY)):
				if(getTileAt(mouseTileX, mouseTileY).getType() != CENTRAL_TILE):
					selectTileAt(mouseTileX, mouseTileY)
		elif(event.button_index == BUTTON_RIGHT && event.pressed):
			#Test - right click on a tile, then sparks will form on the path
			#starting from the left side of the clicked tile
			if(getTileAt(mouseTileX, mouseTileY).getType() != CENTRAL_TILE):
				testNavigate(mouseTileX, mouseTileY)
	if(event.type == InputEvent.KEY):
		if(event.scancode==KEY_ESCAPE):
			clearOverlay();

#After the 2D array of numbers for the tiles is generated,
#spawn the tile objects
func createTilesFromGrid(grid):
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var tileType = grid[x][y]
			var tileObj = gridTileScene.instance()
			tileObj.set_pos(Vector2(x*16, y*16))
			tileObj.setPosInGrid(Vector2(x, y))
			tileObj.setType(tileType)
			self.add_child(tileObj)
			objectGrid[x][y] = tileObj

#Returns the tile type at (x, y) or -1 if invalid position
func getTileTypeAt(x, y):
	if(isValidGridPos(x, y)):
		return grid[x][y]
	else:
		return -1

#Returns the tile object at (x, y) or null if invalid position
func getTileAt(x, y):
	if(isValidGridPos(x, y)):
		return objectGrid[x][y]
	else:
		return null

#Checks if the given position is within the bounds of the grid
func isValidGridPos(x, y):
	return (x >= 0 and x < GRID_WIDTH and y >= 0 and y < GRID_HEIGHT)


#Debug function - used to print an exit direction as a string
func exitAsString(exit):
	if(exit == LEFT):
		return "LEFT"
	elif(exit == RIGHT):
		return "RIGHT"
	elif(exit == UP):
		return "UP"
	elif(exit == DOWN):
		return "DOWN"

#Selects a tile at the given valid position
func selectTileAt(x, y):
	#Do nothing if trying to select central generator
	#if(getTileAt(x, y).getType() == CENTRAL_TILE):
		#return
	#If no selected tile, select the clicked tile
	if(selectedTile == null):
		selectedTile = getTileAt(x, y)
		showOverlayAt(x, y)
	else:
		var clickedTile = getTileAt(x, y)
		#If clicked on the same tile, de-select it
		if(selectedTile == clickedTile):
			selectedTile = null
		else:
			beginSwap(clickedTile, selectedTile)
			selectedTile = null
		clearOverlay()

func clearOverlay():
	for x1 in range(GRID_WIDTH):
		for y1 in range(GRID_HEIGHT):
			var targetTile = getTileAt(x1,y1);
			targetTile.find_node("DistanceSprite_Black").hide();
			targetTile.find_node("DistanceSprite_Green").hide();
			targetTile.find_node("DistanceSprite_Blue").hide();

func showOverlayAt(x, y):
	clearOverlay();
	for x1 in range(GRID_WIDTH):
		for y1 in range(GRID_HEIGHT):
			var targetTile = getTileAt(x1,y1);
			if(x1 == x and y1 == y):
				pass
			elif(max(abs(x1-x),abs(y1-y))>energy):
				targetTile.find_node("DistanceSprite_Black").show();
			elif(int(max(abs(x1-x),abs(y1-y)))%2==0):
				targetTile.find_node("DistanceSprite_Green").show();
			else:
				targetTile.find_node("DistanceSprite_Blue").show();
				
func _process(delta):
	handleSwapping(delta);
	
# The first function in the swap operation. Kicks off the process.
func beginSwap(tileA, tileB):
	swapping = true;
	elapsedSwappingTime = 0.0;
	swapBase = tileA;
	swapTarget = tileB;
	swapQueue.push_back(tileA)
	swapQueue.push_back(tileB)

# Handles swapping once it has been initiated by beginSwapping.
# Delegates to swapTiles and updateSwapColors
func handleSwapping(delta):
	if(swapping):
		elapsedSwappingTime+=delta;
		if(elapsedSwappingTime>=SWAP_ANIM_DURATION/2 and !tilesSwapped):
			swapTiles(swapBase, swapTarget);
			tilesSwapped = true;
		if(elapsedSwappingTime>=SWAP_ANIM_DURATION):
			swapping = false;
			elapsedSwappingTime = 0.0;
			tilesSwapped=false;
		updateSwapColors();
		
#Swap two tiles' positions
#Both tiles should not be null
# This gets called HALFWAY through the swap process.
func swapTiles(tileA, tileB):
	var posA = tileA.getPosInGrid()
	var posB = tileB.getPosInGrid()
	#Swap the types in the grid
	var tempA = grid[posA.x][posA.y]
	grid[posA.x][posA.y] = grid[posB.x][posB.y]
	grid[posB.x][posB.y] = tempA
	#Swap the object references
	var tempObjA = tileA
	objectGrid[posA.x][posA.y] = tileB
	objectGrid[posB.x][posB.y] = tileA
	#Swap the actual positions of the tiles
	var tempPosA = Vector2(posA.x, posA.y)
	tileA.setPosInGrid(posB)
	tileA.set_pos(Vector2(posB.x*16, posB.y*16))
	tileB.setPosInGrid(tempPosA)
	tileB.set_pos(Vector2(tempPosA.x*16, tempPosA.y*16))
	
			
# Updates the colors of the two swapping tiles
func updateSwapColors():
	var opacity = max(1-2*abs(elapsedSwappingTime-SWAP_ANIM_DURATION/2),0);
	if(opacity>0 and swapping):
		swapBase.find_node("DistanceSprite_Grey").show();
		swapBase.find_node("DistanceSprite_Grey").set_opacity(opacity);
		swapTarget.find_node("DistanceSprite_Grey").show();
		swapTarget.find_node("DistanceSprite_Grey").set_opacity(opacity);
	else:
		swapBase.find_node("DistanceSprite_Grey").hide();
		swapTarget.find_node("DistanceSprite_Grey").hide();