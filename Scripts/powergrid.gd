
extends Node2D

var GRID_WIDTH = 19
var GRID_HEIGHT = 20

var GENERATOR_DENSITY = 0.012;
var GENERATOR_COUNT = ceil(GENERATOR_DENSITY*GRID_WIDTH*GRID_HEIGHT);

var DIAMOND_DENSITY = 0.012;
var DIAMOND_COUNT = ceil(GENERATOR_DENSITY*GRID_WIDTH*GRID_HEIGHT);

var SPARK_INTERVAL = 5;
var spark_elapsed = 0.0;

var DIAMOND_SPARK_INTERVAL = 2
var diamond_spark_elapsed = 0.0

var powerDrainRate = 1.0;

var SWAP_ANIM_DURATION = 0.5;
var swapping = false;
var tilesSwapped = false;
var elapsedSwappingTime = 0.0;
var swapBase = null;
var swapTarget = null;
var swapQueue = []

var energy = 4
var selectedTile = null

var uniqueCounter = 0;
var sparkCounts = [];
var generatorCharges = [];
var GENERATOR_STARTING_CHARGE_COUNT = 1;

var sparkScene = load("res://Scenes/spark.tscn")
var diamondSparkScene = load("res://Scenes/diamond_spark.tscn")
var gridTileScene = load("res://Scenes/grid_tile.tscn")
var powerMeter
var diamondMeter
var grid #2D array of tiles represented by their type
var objectGrid #2D array of tile objects
var uidGrid = []

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
var CENTRAL_TILE = 6
var GENERATOR_TILE = 7
var DIAMOND_TILE = 8

#The 4 exits possible for each tile
var UP = 0
var LEFT = 1
var RIGHT = 2
var DOWN = 3

#test function
func testNavigate(startX, startY):
	var startDir = LEFT #spark will enter from the left
	#testNavigateHelper(startX, startY, startDir)

		
func testNavigateHelper(x, y, entryDir, sparkCreatorUid):
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
			testNavigateHelper(x, y - 1, DOWN, sparkCreatorUid)
		elif(currentExit == LEFT):
			testNavigateHelper(x - 1, y, RIGHT, sparkCreatorUid)
		elif(currentExit == RIGHT):
			testNavigateHelper(x + 1, y, LEFT, sparkCreatorUid)
		elif(currentExit == DOWN):
			testNavigateHelper(x, y + 1, UP, sparkCreatorUid)
	#Spark reached the central generator
	elif(tileObj.getType() == CENTRAL_TILE):
		var powerBar = powerMeter.find_node("PowerBar")
		sparkCounts[sparkCreatorUid] += 1;
		#var currentEnergy = powerBar.get_val()
		#powerBar.set_val(currentEnergy + 5)
	else:
		#Spark fizzles out
		pass

#Returns true if the diamond successfully connected with a central tile
func diamondNavigate(x, y, entryDir):
	#Stay within  bounds
	if(x < 0 or x > GRID_WIDTH - 1 or y < 0 or y > GRID_HEIGHT - 1):
		return false
	var tileObj = getTileAt(x, y)
	#Make sure a tile object exists at (x, y)
	if(tileObj == null):
		return false
	var exit1 = tileObj.getExit1()
	var exit2 = tileObj.getExit2()
	#Check if spark can enter the tile
	if(entryDir == exit1 or entryDir == exit2):
		#Test - visually mark the tile visited with a spark
		var spark = diamondSparkScene.instance()
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
			return diamondNavigate(x, y - 1, DOWN)
		elif(currentExit == LEFT):
			return diamondNavigate(x - 1, y, RIGHT)
		elif(currentExit == RIGHT):
			return diamondNavigate(x + 1, y, LEFT)
		elif(currentExit == DOWN):
			return diamondNavigate(x, y + 1, UP)
	#Spark reached the central generator
	elif(tileObj.getType() == CENTRAL_TILE):
		var diamondBar = diamondMeter.find_node("DiamondBar")
		var diamondsCollected = diamondBar.get_val()
		diamondBar.set_val(diamondsCollected + 1)
		return true
	else:
		#Spark fizzles out
		return false

func _ready():
	randomize() #Change the seed for any random operations
	powerMeter = find_node("PowerMeter")
	diamondMeter = find_node("DiamondMeter")
	#Set the max number of diamonds needed
	diamondMeter.find_node("DiamondBar").set_max(DIAMOND_COUNT)
	#Set the current diamond count of the diamond bar to 0
	diamondMeter.find_node("DiamondBar").set_val(0)
	#print(diamondMeter.find_node("DiamondBar").get_val())
	#Create 2D array for grid
	grid = []
	objectGrid = []
	uidGrid = []
	for x in range(GRID_WIDTH):
		grid.append([])
		uidGrid.append([]);
		for y in range(GRID_HEIGHT):
			grid[x].append(randi() % 6) #Random tiles for now
			uidGrid[x].append(-1);
	#Hard-coded central generator
	for i in range(-1, 2, 1):
		for j in range(-1, 2, 1):
			grid[GRID_WIDTH / 2 + i][GRID_HEIGHT / 2 + j] = CENTRAL_TILE

	addGenerators();
	addDiamonds();
	
	for i in range(uniqueCounter):
		sparkCounts.append(0);
		generatorCharges.append(GENERATOR_STARTING_CHARGE_COUNT);
	
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
				if(getTileAt(mouseTileX, mouseTileY).getType() <= 5):
					selectTileAt(mouseTileX, mouseTileY)
#		elif(event.button_index == BUTTON_RIGHT && event.pressed):
#			#Test - right click on a tile, then sparks will form on the path
#			#starting from the left side of the clicked tile
#			if(getTileAt(mouseTileX, mouseTileY).getType() <= 5):
#				testNavigate(mouseTileX, mouseTileY)
#	if(event.type == InputEvent.KEY):
#		if(event.scancode==KEY_ESCAPE):
#			clearOverlay();

func isOverlapping(generatorX, generatorY):
	var overlap = false;
	overlap = overlap or grid[generatorX][generatorY] == GENERATOR_TILE;
	overlap = overlap or grid[generatorX+1][generatorY] == GENERATOR_TILE;
	overlap = overlap or grid[generatorX][generatorY+1] == GENERATOR_TILE;
	overlap = overlap or grid[generatorX+1][generatorY+1] == GENERATOR_TILE;
	overlap = overlap or grid[generatorX][generatorY] == CENTRAL_TILE;
	overlap = overlap or grid[generatorX+1][generatorY] == CENTRAL_TILE;
	overlap = overlap or grid[generatorX][generatorY+1] == CENTRAL_TILE;
	overlap = overlap or grid[generatorX+1][generatorY+1] == CENTRAL_TILE;
	overlap = overlap or grid[generatorX][generatorY] == DIAMOND_TILE;
	overlap = overlap or grid[generatorX+1][generatorY] == DIAMOND_TILE;
	overlap = overlap or grid[generatorX][generatorY+1] == DIAMOND_TILE;
	overlap = overlap or grid[generatorX+1][generatorY+1] == DIAMOND_TILE;

	return(overlap);

func isOccupied(x,y):
	var tile=grid[x][y];
	return(tile==GENERATOR_TILE or tile==CENTRAL_TILE or tile==DIAMOND_TILE);

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

func addGenerators():
	for i in range(GENERATOR_COUNT):
		var generatorX=-1;
		var generatorY=-1;
		while(generatorX == -1 or generatorY == -1 or isOverlapping(generatorX, generatorY)):
			generatorX=(randi() % GRID_WIDTH-1);
			generatorY=(randi() % GRID_HEIGHT-1);
		
		grid[generatorX][generatorY] = GENERATOR_TILE;
		grid[generatorX+1][generatorY] = GENERATOR_TILE;
		grid[generatorX][generatorY+1] = GENERATOR_TILE;
		grid[generatorX+1][generatorY+1] = GENERATOR_TILE;
		
		uidGrid[generatorX][generatorY] = uniqueCounter;
		uidGrid[generatorX+1][generatorY] = uniqueCounter;
		uidGrid[generatorX][generatorY+1] = uniqueCounter;
		uidGrid[generatorX+1][generatorY+1] = uniqueCounter;
		
		uniqueCounter+=1;

func addDiamonds():
	for i in range(DIAMOND_COUNT):
		var diamondX=-1;
		var diamondY=-1;
		while(diamondX == -1 or diamondY == -1 or isOccupied(diamondX, diamondY)):
			diamondX=(randi() % GRID_WIDTH-1);
			diamondY=(randi() % GRID_HEIGHT-1);
		grid[diamondX][diamondY] = DIAMOND_TILE;

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
	#Cannot swap if there is a swapping animation
	if(swapping):
		return
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
	powerDrain(delta);
	generatorSpark(delta);
	diamondSpark(delta)

func generatorSpark(delta):
	spark_elapsed += delta;

	if(spark_elapsed >= SPARK_INTERVAL):
		spark_elapsed = 0;
		for i in range(uniqueCounter):
			sparkCounts[i]=0;
		for x1 in range(GRID_WIDTH):
			for y1 in range(GRID_HEIGHT):
				if(grid[x1][y1] == GENERATOR_TILE):
					if(not getTileAt(x1, y1).isDrained()):
						if(isValidGridPos(x1-1, y1)):
							testNavigateHelper(x1-1, y1, RIGHT, uidGrid[x1][y1]);
						if(isValidGridPos(x1+1, y1)):
							testNavigateHelper(x1+1, y1, LEFT, uidGrid[x1][y1]);
						if(isValidGridPos(x1, y1-1)):
							testNavigateHelper(x1, y1-1, DOWN, uidGrid[x1][y1]);
						if(isValidGridPos(x1, y1+1)):
							testNavigateHelper(x1, y1+1, UP, uidGrid[x1][y1]);
		var energyGain = 0;
		for i in range(uniqueCounter):
			if(sparkCounts[i]==0):
				pass;
			elif(generatorCharges[i]>0):
				generatorCharges[i]-=1;
				if(generatorCharges[i]==0):
					#Visual deactivation
					for x2 in range(GRID_WIDTH):
						for y2 in range(GRID_HEIGHT):
							if(uidGrid[x2][y2] == i):
								if(!getTileAt(x2, y2).isDrained()):
									getTileAt(x2, y2).drainGenerator()
				if(sparkCounts[i]==1):
					energyGain+=10;
				elif(sparkCounts[i]==2):
					energyGain+=15;
				elif(sparkCounts[i]>=3):
					energyGain+=20;

		var powerBar = powerMeter.find_node("PowerBar")
		powerBar.set_val(powerBar.get_val()+energyGain);

func diamondSpark(delta):
	diamond_spark_elapsed += delta;
	if(diamond_spark_elapsed >= DIAMOND_SPARK_INTERVAL):
		diamond_spark_elapsed = 0;
		for x1 in range(GRID_WIDTH):
			for y1 in range(GRID_HEIGHT):
				if(getTileTypeAt(x1, y1) == DIAMOND_TILE):
					#print("mining at ", x1, y1)
					if(getTileAt(x1, y1).isDrained()):
						continue
					if(isValidGridPos(x1-1, y1)):
						if(diamondNavigate(x1-1, y1, RIGHT)):
							getTileAt(x1, y1).drainDiamond()
					#Check again if diamond is drained or not
					if(getTileAt(x1, y1).isDrained()):
						continue
					if(isValidGridPos(x1+1, y1)):
						if(diamondNavigate(x1+1, y1, LEFT)):
							getTileAt(x1, y1).drainDiamond()
					#Check again if diamond is drained or not
					if(getTileAt(x1, y1).isDrained()):
						continue
					if(isValidGridPos(x1, y1-1)):
						if(diamondNavigate(x1, y1-1, DOWN)):
							getTileAt(x1, y1).drainDiamond()
					#Check again if diamond is drained or not
					if(getTileAt(x1, y1).isDrained()):
						continue
					if(isValidGridPos(x1, y1+1)):
						if(diamondNavigate(x1, y1+1, UP)):
							getTileAt(x1, y1).drainDiamond()

func powerDrain(delta):
	var powerBar = powerMeter.find_node("PowerBar")
	powerBar.set_val(powerBar.get_val()-delta*powerDrainRate);

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
