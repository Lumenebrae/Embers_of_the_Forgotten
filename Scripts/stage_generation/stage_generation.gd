extends TileMap


# Grid Variables
var grid_size_x = 25
var grid_size_y = 25
var final_grid_x_size = grid_size_x

# Verticle Slice Variables
var heightBase = 6
var heightMin = 6
var heightMax = 12
var height = 8
var heightAdjust = 0
var heightAdjustCounter = 3

var basePointBase = 12
var basePointMin = 3
var basePointMax = 40
var basePoint = 12
var basePointAdjust = 0
var basePointAdjustCounter = 3

var VSlice1
var VSlice2
var VSlice3

var isRoom = true
var roomLength = 18
var roomLengthMin = 15
var roomLengthMax = 30
var roomHeightBoost = 5
var roomHeightBoostMin = 3 
var roomHeightBoostMax = 8

var platforms = []
var platformYIndexing = []
var enemyIndexing = []

var test 
var Tiles = {
	"C": 0,			#Center Tile
	"C_TL": 12,		#Ceiling Top Left
	"C_TR": 11,		#Ceiling Top Right
	"C_BL": 6,		#Ceiling Bottom Left
	"C_BR": 4,		#Ceiling Bottom Right
	"C_M": 5,		#Ceiling Middle
	"G_BL": 10,		#Ground Bottom Left
	"G_BR": 9,		#Ground Bottom Right
	"G_TL": 8,		#Ground Top Left
	"G_TR": 2,		#Ground Top Right
	"G_M": 1,		#Ground Middle
	"S_R": 3,		#Side Right
	"S_L": 7 		#Side Left
}

var loaded
# Generate and evaluate the appropriate amount of Vertical Slices
func _ready():
	# do not proceed if stage is boss
	if GameData.current_level % 4 == 0:
		
		#will cause trouble, remember to migrate
		#GameData.roomEnemyCount = 0
		
		
		return
	
	# for a consistent, testable seed, comment the below line
	randomize()
	
	GameData.interactablePos = []
	
	_V_setup()
	var iterator = 1
	while iterator < grid_size_x:
		_v_slice_generate()
		_v_slice_evaluate(iterator)
		# room logic
		if isRoom:
			isRoom = false
			VSlice1 = VSlice2
			VSlice2 = VSlice3
			VSlice3.y += 5
			_v_slice_evaluate(iterator + 1)
			VSlice1 = VSlice2
			VSlice2 = VSlice3
			_v_slice_evaluate(iterator + 2)
			VSlice1 = VSlice2
			for val in range(roomLength):
				_add_interactable(iterator + val + 3)
				_v_slice_evaluate(iterator + val + 3)
				_platform_evaluate(iterator + val + 3, val)
				_enemy_indexing(iterator + val + 3, val)
			#print("found room on iteration: " + str(iterator))
			iterator += roomLength + 1
		iterator += 1
	
	_V_finalize(iterator)

	var rand = RandomNumberGenerator.new()
	
	var enemy1 = preload("res://Scenes/Enemies/EnemyVariant1.tscn")
	var enemy2 = preload("res://Scenes/Enemies/EnemyVariant2.tscn")
	var enemy3 = preload("res://Scenes/Enemies/EnemyVariant3.tscn")
	var enemy4 = preload("res://Scenes/Enemies/EnemyVariant4.tscn")
	
	var enemyScenes = [enemy1, enemy2]
	#adding more diffcult enemies as the game progresses 
	if GameData.current_level > 3:
		enemyScenes.append(enemy3)
	if GameData.current_level > 5:
		 enemyScenes.append(enemy4)
	GameData.roomEnemyCount = enemyIndexing.size()
	
	for index in enemyIndexing:
		var x = randi() % enemyScenes.size() - 1
		var en = enemyScenes[x].instance()
		en.position.x = GameData.tile_size * index.x
		en.position.y = GameData.tile_size * index.y
		add_child(en)

# Initialize with the first three Vertical Slices
func _V_setup():
	#get data of first three slices
	_v_slice_generate()
	VSlice1 = VSlice3
	VSlice2 = VSlice3

	#set left corner
	set_cell(0, basePointBase - VSlice1.x, Tiles.G_BL)
	for x in VSlice1.y - 1:
		set_cell(0, basePointBase - VSlice1.x - x - 1, Tiles.S_R)
	set_cell(0, basePointBase - VSlice1.x - VSlice1.y, Tiles.C_TL)

# Obtain the data for a new Vertical Slice
func _v_slice_generate():
	VSlice1 = VSlice2
	VSlice2 = VSlice3
	_set_random_vars()
	
func _add_interactable(iterator):
	var x = randi() % 8
	if x > 0:
		return
	#will fall to rest on whatever is nearest to the ceiling
	GameData.interactablePos.append(Vector2(32*iterator,32*(basePointBase - VSlice2.x - VSlice2.y + 3)))

func _platform_evaluate(xVal, roomLengthIteration):
	#stop evaluations
	if roomLengthIteration > (roomLength - 2):
		while platforms.size():
			var platform = platforms.pop_front()
			set_cell(xVal, basePointBase - VSlice2.x - platform.y, Tiles.C_BR)
			set_cell(xVal, basePointBase - VSlice2.x - platform.y - 1, Tiles.G_TR)
		platformYIndexing = []
		return

	#add platform Vector3(starting_x, y, length)
	var x = randi() % 3
	if (x == 0) and (roomLengthIteration < roomLength - 4):
		x = randi() % 5
		var y = randi() % (height - heightMin + 1)
		if (platformYIndexing.find(y) == -1) and (platformYIndexing.find(y-1) == -1):
			platforms.append(Vector3(xVal, y + 3, x + 3))
			platformYIndexing.append(y)

	#evaluate platforms at VSlice
	var saveSize = platforms.size()
	for v in range(saveSize):
		var val = platforms.pop_front()
		#start of platform
		if val.x == xVal:
			set_cell(xVal, basePointBase - VSlice2.x - val.y, Tiles.C_BL)
			set_cell(xVal, basePointBase - VSlice2.x - val.y - 1, Tiles.G_TL)
		#end of platform
		elif xVal >= val.x + val.z:
			set_cell(xVal, basePointBase - VSlice2.x - val.y, Tiles.C_BR)
			set_cell(xVal, basePointBase - VSlice2.x - val.y - 1, Tiles.G_TR)
		#middle of platform
		else:
			set_cell(xVal, basePointBase - VSlice2.x - val.y, Tiles.C_M)
			set_cell(xVal, basePointBase - VSlice2.x - val.y - 1, Tiles.G_M)
		if !(xVal >= val.x + val.z):
			platforms.push_back(val)
		else:
			if (platformYIndexing.find(val.y) != -1):
				platformYIndexing.remove(platformYIndexing.find(val.y))

func _enemy_indexing(iterator, roomLengthIteration):
	var x = randi() % 8
	if (x == 0) and (roomLengthIteration < roomLength - 4):
		enemyIndexing.append(Vector2(iterator, basePointBase - VSlice2.y - VSlice2.x + 4))

func _v_slice_evaluate_test(iterator): 
	for val in range(0, height):
		set_cell(iterator, basePoint + val, 6)

# Obtain tile data for VSlice2
func _v_slice_evaluate(iterator):
	var parseTemp
	var parseGoal
	
	# top tiles
	if (VSlice2.x + VSlice2.y) > (VSlice1.x + VSlice1.y):
		set_cell(iterator, basePointBase - VSlice2.y - VSlice2.x, Tiles.C_TL)
		parseGoal = basePointBase - VSlice1.y - VSlice1.x
		parseTemp = basePointBase - VSlice2.y - VSlice2.x + 1
		while parseTemp <= parseGoal:
			if parseTemp == parseGoal:
				set_cell(iterator, parseTemp, Tiles.C_BR)
			else:
				set_cell(iterator, parseTemp, Tiles.S_R)
			parseTemp += 1
	elif (VSlice2.x + VSlice2.y) > (VSlice3.x + VSlice3.y):
		set_cell(iterator, basePointBase - VSlice2.y - VSlice2.x, Tiles.C_TR)
		parseGoal = basePointBase - VSlice3.y - VSlice3.x
		parseTemp = basePointBase - VSlice2.y - VSlice2.x + 1
		while parseTemp <= parseGoal:
			if parseTemp == parseGoal:
				set_cell(iterator, parseTemp, Tiles.C_BL)
			else:
				set_cell(iterator, parseTemp, Tiles.S_L)
			parseTemp += 1
	else:
		set_cell(iterator, basePointBase - VSlice2.y - VSlice2.x, Tiles.C_M)
	
	# bottom tile
	if VSlice2.x < VSlice3.x:
		set_cell(iterator, basePointBase - VSlice2.x, Tiles.G_BR)
		parseGoal = basePointBase - VSlice3.x
		parseTemp = basePointBase - VSlice2.x - 1
		while parseTemp >= parseGoal:
			if parseTemp == parseGoal:
				set_cell(iterator, parseTemp, Tiles.G_TL)
			else:
				set_cell(iterator, parseTemp, Tiles.S_R)
			parseTemp -= 1
	elif VSlice2.x < VSlice1.x:
		set_cell(iterator, basePointBase - VSlice2.x, Tiles.G_BL)
		parseGoal = basePointBase - VSlice1.x
		parseTemp = basePointBase - VSlice2.x - 1
		while parseTemp >= parseGoal:
			if parseTemp == parseGoal:
				set_cell(iterator, parseTemp, Tiles.G_TR)
			else:
				set_cell(iterator, parseTemp, Tiles.S_L)
			parseTemp -= 1
	else:
		set_cell(iterator, basePointBase - VSlice2.x, Tiles.G_M)
	
	# middle tiles
	#set_cell(xInt, basePoint - yIntTop, 6)
	

# Compute random vals to determine VSlice behavior
func _set_random_vars():
	# get new height
	var x = randi() % 5
	# random var leading to a smaller height
	if x == 0 && height > heightMin && heightAdjust != 1 && basePointAdjust == 0:
		height -= 1
		heightAdjust = -1
		heightAdjustCounter = 3
	# random var leading to a larger height
	elif x == 1 && height < heightMax && heightAdjust != -1 && basePointAdjust == 0:
		height += 1
		heightAdjust = 1
		heightAdjustCounter = 3
	else:
		heightAdjustCounter -= 1
		if heightAdjustCounter <= 0:
			heightAdjust = 0
	
	# get new midpoint
	x = randi() % 5
	# random var leading to a lower midpoint
	if x == 0 && basePoint > basePointMin && basePointAdjust != 1 && heightAdjust == 0:
		basePoint -= 1
		basePointAdjust = -1
		basePointAdjustCounter = 3
	# random var leading to a higher midpoint
	if x == 1 && basePoint < basePointMax && basePointAdjust != -1 && heightAdjust == 0:
		basePoint += 1
		basePointAdjust = 1
		basePointAdjustCounter = 3
	else:
		basePointAdjustCounter -= 1
		if basePointAdjustCounter <= 0:
			basePointAdjust = 0
	
	# random var leading to a room being generated
	x = randi() % 100
	if x == 1:
		isRoom = true
		x = randi() % (roomLengthMax - roomLengthMin)
		roomLength = x + roomLengthMin
		x = randi() % (roomHeightBoostMax - roomHeightBoostMin)
		roomHeightBoost = x + roomHeightBoostMin
	
	# commit data to evaluatedSlice
	VSlice3 = Vector2(basePointBase - basePoint, height)

func _V_finalize(iterator):
	#finalize data for last three slices
	VSlice1 = VSlice2
	VSlice2 = VSlice3
	_v_slice_evaluate(iterator)
	VSlice1 = VSlice2
	_v_slice_evaluate(iterator + 1)

	#set right corner
	set_cell(iterator + 2, basePointBase - VSlice2.x, Tiles.G_BR)
	for x in VSlice1.y - 1:
		set_cell(iterator + 2, basePointBase - VSlice2.x - x - 1, Tiles.S_L)
	set_cell(iterator + 2, basePointBase - VSlice2.x - VSlice2.y, Tiles.C_TR)
	
	final_grid_x_size = iterator + 2
	GameData.final_grid_size_x = final_grid_x_size
	
	var items = get_node_or_null("../../Item_Generation")
	if items != null:
		items._place_interactables()
		
#	GameData.stage_tile_set = inst2dict(self)
	#GameData.stage_parent = get_parent().get_path()


