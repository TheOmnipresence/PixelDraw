extends Node

var firstPause = true

var playerRef
var cameraRef
var mcToolLevel := "WOOD"
var mcBlocks = 0
var actionsScanned = []
var respawnPoint := Vector3(0,2,0)
var hoveringTool = "NONE"
var hoveringShape = "NONE"
var barLayout = [tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE]
var barIndex = 0
var availibleTools = [tools.NONE]
enum types {RECT,SQUIRCLE,PLUS,DIAGONAL,LINE,TRIANGLE}
var baseShape = {"type":types.RECT,"x":3,"y":3}
enum tools {NONE,VOIDER,ERASER,C_GOL,RAISER,LEVELER,DUSTER,SHUFFLER,STOPPER,BULB,MC_PICK,HOOK,BASE_SW,PLACER,STAMPER,GRAVITATE,SUMMON,TERRAIN}
var toolsCompatibility = {
	"NONE":[],
	"VOIDER":[],
	"ERASER":[],
	"C_GOL":[		"NONE",		"BASE_RECT",	"5_SQR",	"6_SQR"																																						],
	"RAISER":[		"NONE",												"SM_DIA",	"5_PLUS",													"5_SQC"																	],
	"LEVELER":[		"NONE",		"BASE_RECT",	"5_SQR",																															"5_TRI"								],
	"DUSTER":[		"NONE",		"BASE_RECT",				"6_SQR"																																						],
	"SHUFFLER":[	"NONE",						"5_SQR"																																									],
	"STOPPER":[		"NONE",												"SM_DIA",												"7_LINE"																				],
	"BULB":[		"NONE",															"5_PLUS",		"3_DIAG",	"3_DIAG_IN"																								],
	"MC_PICK":[		"NONE",																										"7_LINE"																				],
	"HOOK":[		"NONE",									"6_SQR",																			"5_SQC"																	],
	"BASE_SW":[		"NONE",																			"3_DIAG",	"3_DIAG_IN",											"5_DIAG"										],
	"PLACER":[		"NONE",																			"3_DIAG",	"3_DIAG_IN"																								],
	"STAMPER":[		"NONE",									"6_SQR"																																						],
	"GRAVITATE":[	"NONE",																																							"5_TRI"								],
	"SUMMON":[		"NONE",						"5_SQR",																									"10_SQR"													],
	"TERRAIN":[		"NONE",						"5_SQR",																																		"50_SQR",	"200_SQR",	],
}
var currentTool = tools.NONE
var enemySpawnShapes = ["RED_PILL","TRI_ENEMY","ZOOM_ENEMY","SMALL_BIRD"]
var toolShapes = {tools.NONE:"BASE_RECT"}
var availibleShapes = ["NONE","BASE_RECT"]
var allToolShapes = {
	"NONE":{},
	"BASE_RECT":{"type":types.RECT,"x":3,"y":3},
	"5_SQR":{"type":types.RECT,"x":5,"y":5},
	"6_SQR":{"type":types.RECT,"x":6,"y":6},
	"SM_DIA":{"type":types.SQUIRCLE,"x":3,"y":3},
	"5_PLUS":{"type":types.PLUS,"x":5,"y":5},
	"3_DIAG":{"type":types.DIAGONAL,"len":3,"tl":true},
	"3_DIAG_IN":{"type":types.DIAGONAL,"len":3,"tl":false},
	"7_LINE":{"type":types.LINE,"len":7 ,"vertical":false},
	"5_SQC":{"type":types.SQUIRCLE,"x":5,"y":5},
	"10_SQR":{"type":types.RECT,"x":10,"y":10},
	"5_DIAG":{"type":types.DIAGONAL,"len":5,"tl":true},
	"16_SQR":{"type":types.RECT,"x":16,"y":16},
	"5_TRI":{"type":types.TRIANGLE,"x":5,"y":5},
	"50_SQR":{"type":types.RECT,"x":50,"y":50},
	"200_SQR":{"type":types.RECT,"x":200,"y":200},
}
var structureShapes = {
	"TOWER":[Vector3i(0,1,0),Vector3i(0,2,0),Vector3i(0,3,0),Vector3i(0,4,0),Vector3i(1,1,0),Vector3i(1,2,0),Vector3i(1,3,0),Vector3i(1,4,0),Vector3i(1,1,1),Vector3i(1,2,1),Vector3i(1,3,1),Vector3i(1,4,1),Vector3i(0,1,1),Vector3i(0,2,1),Vector3i(0,3,1),Vector3i(0,4,1)                ,Vector3i(-1,1,0),Vector3i(-1,2,0),Vector3i(-1,3,0),Vector3i(-1,4,0),Vector3i(-1,1,-1),Vector3i(-1,2,-1),Vector3i(-1,3,-1),Vector3i(-1,4,-1),Vector3i(0,1,-1),Vector3i(0,2,-1),Vector3i(0,3,-1),Vector3i(0,4,-1)],
	"CUBE":[Vector3i(0,1,0),Vector3i(0,2,0),Vector3i(0,3,0)],
	"TORCH":[Vector3i(0,1,0),Vector3i(0,2,0),Vector3i(0,3,0),Vector3i(1,3,0),Vector3i(-1,3,0),Vector3i(0,3,1),Vector3i(0,3,-1),Vector3i(1,4,0),Vector3i(-1,4,0),Vector3i(0,4,1),Vector3i(0,4,-1)],
	"DIA_TOWER":[Vector3i(0,1,0),Vector3i(0,2,0),Vector3i(0,3,0),Vector3i(1,1,0),Vector3i(1,2,0),Vector3i(1,3,0),Vector3i(-1,1,0),Vector3i(-1,2,0),Vector3i(-1,3,0),Vector3i(0,1,1),Vector3i(0,2,1),Vector3i(0,3,1),Vector3i(0,1,-1),Vector3i(0,2,-1),Vector3i(0,3,-1)],
	"TUT_AREA":loadVoxels("res://Scenes/StructureMaps/tut_map.tscn"),
	"TUT_AREA_2":loadVoxels("res://Scenes/StructureMaps/tut_map_2.tscn"),
	"TUT_AREA_3":loadVoxels("res://Scenes/StructureMaps/tut_map_3.tscn"),
	"RANDOM_GENERATION":[]
}
const complexStructures = {
	"TUT_AREA":"res://Scenes/StructureMaps/tut_map.tscn",
	"TUT_AREA_2":"res://Scenes/StructureMaps/tut_map_2.tscn",
	"TUT_AREA_3":"res://Scenes/StructureMaps/tut_map_3.tscn"
}
var colorShapes = {
	"NORMAL_COLOR":[Color.BLACK,Color.WHITE,Color(0.57,0.57,0.57),Color(0.04,0.04,0.04)],
	"C_GOL_COLOR":[Color(0.0, 0.0, 0.0, 1.0),Color(1.0, 1.0, 0.0, 1.0),Color(1,1,1),Color(1,1,1)]
}
var shapes = {
	"NONE":[
		[]
	],
	"ERASER":[
		[]
	],
	"VOIDER":[
		[]
	],
	"C_GOL":[  
		[Vector2i(0, 2), Vector2i(1, 0), Vector2i(1, 2), Vector2i(2, 1), Vector2i(2, 2)],
		[Vector2i(0, 0), Vector2i(0, 2), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 1)]  
	], 
	"5_SQR":[ 
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2)] 
	],
	"6_SQR":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(0,3),Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(1,3),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2),Vector2i(2,3),Vector2i(3,0),Vector2i(3,1),Vector2i(3,2),Vector2i(3,3)] 
	],
	"RAISER":[
		[Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(2,1)]
	],
	"LEVELER":[
		[Vector2i(0,0),Vector2i(0,2),Vector2i(1,1),Vector2i(2,0),Vector2i(2,2)]
	],
	"SM_DIA":[
		[Vector2i(0,2),Vector2i(1,1),Vector2i(1,2),Vector2i(1,3),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2),Vector2i(2,3),Vector2i(2,4),Vector2i(3,1),Vector2i(3,2),Vector2i(3,3),Vector2i(4,2)]
	],
	"DUSTER":[
		[Vector2i(0,0),Vector2i(1,1)],
		[Vector2i(0,1),Vector2i(1,0)]
	],
	"SHUFFLER":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(1,2),Vector2i(2,1)]
	],
	"CREEPER":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(1,3),Vector2i(1,4),Vector2i(1,5),Vector2i(2,2),Vector2i(2,3),Vector2i(2,4),Vector2i(3,2),Vector2i(3,3),Vector2i(3,4),Vector2i(4,0),Vector2i(4,1),Vector2i(4,3),Vector2i(4,4),Vector2i(4,5),Vector2i(5,0),Vector2i(5,1)]
	],
	"RESPAWN":[
		[Vector2i(0,2),Vector2i(0,3),Vector2i(1,1),Vector2i(1,4),Vector2i(2,0),Vector2i(2,2),Vector2i(2,3),Vector2i(2,5),Vector2i(3,0),Vector2i(3,2),Vector2i(3,3),Vector2i(3,5),Vector2i(4,1),Vector2i(4,4),Vector2i(5,2),Vector2i(5,3)]
	],
	"RED_PILL":[
		[Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(1,3),Vector2i(2,1),Vector2i(2,2)]
	],
	"STOPPER":[
		[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)]
	],
	"TOWER":[
		[Vector2i(0,0),Vector2i(0,2),Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(2,0),Vector2i(2,2)]
	],
	"5_PLUS":[
		[Vector2i(0,2),Vector2i(1,2),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2),Vector2i(2,3),Vector2i(2,4),Vector2i(3,2),Vector2i(4,2)]
	],
	"3_DIAG":[
		[Vector2i(0,0),Vector2i(1,1),Vector2i(2,2)]
	],
	"3_DIAG_IN":[
		[Vector2i(0,2),Vector2i(1,1),Vector2i(2,0)]
	],
	"BULB":[
		[Vector2i(0,1),Vector2i(0,3),Vector2i(1,0),Vector2i(1,1),Vector2i(1,3),Vector2i(1,4),Vector2i(2,2),Vector2i(3,0),Vector2i(3,1),Vector2i(3,3),Vector2i(3,4),Vector2i(4,1),Vector2i(4,3)]
	],
	"MC_PICK":[
		[Vector2i(0,0),Vector2i(0,3),Vector2i(1,0),Vector2i(1,2),Vector2i(2,0),Vector2i(2,1),Vector2i(3,1),Vector2i(3,2),Vector2i(3,3)]
	],
	"7_LINE":[
		[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0)]
	],
	"W":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(1,2),Vector2i(2,2)],
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(1,2),Vector2i(2,0),Vector2i(2,2)]
	],
	"L":[
		[Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2)]
	],
	"ZIG":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(1,2)]
	],
	"ZAG":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(2,2)]
	],
	"HOOK":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(2,0),Vector2i(2,1)],
		[Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(2,0),Vector2i(2,1)],
		[Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(2,1)]
	],
	"5_SQC":[
		[Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(1,3),Vector2i(2,0),Vector2i(2,3),Vector2i(3,1),Vector2i(3,2)]
	],
	"10_SQR":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(0,3),Vector2i(0,4),Vector2i(0,5),Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(1,3),Vector2i(1,4),Vector2i(1,5),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2),Vector2i(2,3),Vector2i(2,4),Vector2i(2,5),Vector2i(3,0),Vector2i(3,1),Vector2i(3,2),Vector2i(3,3),Vector2i(3,4),Vector2i(3,5),Vector2i(4,0),Vector2i(4,1),Vector2i(4,2),Vector2i(4,3),Vector2i(4,4),Vector2i(4,5),Vector2i(5,0),Vector2i(5,1),Vector2i(5,2),Vector2i(5,3),Vector2i(5,4),Vector2i(5,5)] 
	],
	"COMPASS":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(1,2),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2)]
	],
	"SENDER":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(2,0),Vector2i(2,1)],
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(2,0),Vector2i(2,2)]
	],
	"UNSENDER":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,0),Vector2i(2,1)]
	],
	"GROUNDER":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(1,2),Vector2i(2,0),Vector2i(2,1)]
	],
	"BASE_SW":[
		[Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(2,0)]
	],
	"CUBE":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1)]
	],
	"TRI_ENEMY":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,0)]
	],
	"TORCH":[
		[Vector2i(0,0),Vector2i(1,1),Vector2i(1,2),Vector2i(2,1)]
	],
	"5_DIAG":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,2),Vector2i(2,1),Vector2i(2,2)]
	],
	"ZOOM_ENEMY":[
		[Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(1,1),Vector2i(2,1),Vector2i(2,2)]
	],
	"16_SQR":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(0,3),Vector2i(0,4),Vector2i(0,5),Vector2i(0,6),Vector2i(0,7),Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(1,3),Vector2i(1,4),Vector2i(1,5),Vector2i(1,6),Vector2i(1,7),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2),Vector2i(2,3),Vector2i(2,4),Vector2i(2,5),Vector2i(2,6),Vector2i(2,7),Vector2i(3,0),Vector2i(3,1),Vector2i(3,2),Vector2i(3,3),Vector2i(3,4),Vector2i(3,5),Vector2i(3,6),Vector2i(3,7),Vector2i(4,0),Vector2i(4,1),Vector2i(4,2),Vector2i(4,3),Vector2i(4,4),Vector2i(4,5),Vector2i(4,6),Vector2i(4,7),Vector2i(5,0),Vector2i(5,1),Vector2i(5,2),Vector2i(5,3),Vector2i(5,4),Vector2i(5,5),Vector2i(5,6),Vector2i(5,7),Vector2i(6,0),Vector2i(6,1),Vector2i(6,2),Vector2i(6,3),Vector2i(6,4),Vector2i(6,5),Vector2i(6,6),Vector2i(6,7),Vector2i(7,0),Vector2i(7,1),Vector2i(7,2),Vector2i(7,3),Vector2i(7,4),Vector2i(7,5),Vector2i(7,6),Vector2i(7,7)] 
	],
	"STONE":[
		loadPixels("res://Sprites/cobble.png")
	],
	"IRON":[
		loadPixels("res://Sprites/iron.png")
	],
	"GOLD":[
		loadPixels("res://Sprites/gold.png")
	],
	"DIAMOND":[
		loadPixels("res://Sprites/diamond.png")
	],
	"NETHERITE":[
		loadPixels("res://Sprites/netherite.png")
	],
	"PLACER":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(2,1),Vector2i(2,2)]
	],
	"STAMPER":[
		loadPixels("res://Sprites/spamp.png")
	],
	"GRAVITATE":[
		[Vector2i(0,1),Vector2i(0,2),Vector2i(0,3),Vector2i(1,0),Vector2i(1,1),Vector2i(1,3),Vector2i(2,1),Vector2i(2,2),Vector2i(2,3)]
	],
	"SMALL_SPEED":[
		[Vector2i(0,0),Vector2i(0,1)]
	],
	"5_TRI":[
		[Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2)]
	],
	"NO":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(2,1),Vector2i(2,2)],
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(2,0),Vector2i(2,1)],
		[Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(2,1),Vector2i(2,2)]
	],
	"THUMB":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,1),Vector2i(1,2)]
	],
	"DOT":[
		[Vector2(0,0)]
	],
	"L_HA":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,2)]
	],
	"CHAIR":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,1),Vector2i(2,1),Vector2i(2,2)]
	],
	"CROWN":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,0),Vector2i(2,1),Vector2i(3,1),Vector2i(4,0),Vector2i(4,1)]
	],
	"6_PACK":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(1,1),Vector2i(1,2)]
	],
	"SMALL_BIRD":[
		[Vector2i(0,0),Vector2i(1,0),Vector2i(2,1),Vector2i(2,2)],
		[Vector2i(0,0),Vector2i(1,1),Vector2i(2,0)]
	],
	"SUMMON_BIRDS":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,2)]
	],
	"SUMMON":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(2,1),Vector2i(2,2)]
	],
	"DIA_TOWER":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,2),Vector2i(2,1)]
	],
	"WALKING_PERSON":[
		[Vector2i(0,0),Vector2i(0,2),Vector2i(1,0),Vector2i(1,1),Vector2i(2,0),Vector2i(2,2)]
	],
	"TEA":[
		[Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(2,0)]
	],
	"FLOAT":[
		[Vector2i(0,0),Vector2i(1,1),Vector2i(2,1),Vector2i(2,2)],
		[Vector2i(0,1),Vector2i(1,0),Vector2i(2,0),Vector2i(2,1)]
	],
	"TUT_AREA":[
		[Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(2,0),Vector2i(2,1)]
	],
	"TUT_AREA_2":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,1),Vector2i(1,2),Vector2i(2,1),Vector2i(2,3),Vector2i(3,2),Vector2i(3,3),Vector2i(4,2),Vector2i(4,3),Vector2i(4,4)]
	],
	"TUT_AREA_3":[
		[Vector2i(0,1),Vector2i(1,0),Vector2i(1,2),Vector2i(2,0),Vector2i(2,3),Vector2i(3,1),Vector2i(3,3),Vector2i(4,2)]
	],
	"RANDOM_GENERATION":[
		[Vector2i(0,0),Vector2i(1,1),Vector2i(1,2),Vector2i(2,0),Vector2i(2,2)]
	],
	"TERRAIN":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(2,1)]
	],
	"50_SQR":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(0,3),Vector2i(0,4),Vector2i(1,0),Vector2i(1,2),Vector2i(1,4),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2),Vector2i(2,3),Vector2i(2,4),Vector2i(3,0),Vector2i(3,2),Vector2i(3,4),Vector2i(4,0),Vector2i(4,1),Vector2i(4,2),Vector2i(4,3),Vector2i(4,4)]
	],
	"NORMAL_COLOR":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2)]
	],
	"C_GOL_COLOR":[
		[Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(1,2),Vector2i(2,1),Vector2i(2,2)]
	],
}
static func loadPixels(imagePath:String):
	var image:Image = load(imagePath).get_image()
	var result = []
	for x in range(image.get_size().x):
		for y in range(image.get_size().y):
			if image.get_pixel(x,y) == Color(0,0,0,1):
				result.append(Vector2i(x,y))
	return result

static func loadVoxels(scenePath:String):
	var gridmap:GridMap = load(scenePath).instantiate()
	return gridmap.get_used_cells()

func getUnusedValues(width:int,height:int) -> Array:
	for x in range(width):
		for y in range(height):
			pass
	return []

var descriptions = {
	"NONE":{"name":"Nothing","text":"Really. Nothing."},
	# Tools
	"VOIDER":{"name":"Voider","text":"Calls the void to the tiles","type":"tool"},
	"ERASER":{"name":"Eraser","text":"Erases the void from the tiles","type":"tool"},
	"C_GOL":{"name":"Conway's Game of Life","text":"Embewed with the power of generations, of over and under population, and of growth. Applies one generation of Conway's Game of Life on the area.","type":"tool"},
	"RAISER":{"name":"Raiser","text":"It allows the creation of parkor to go much faster. Raises the ground to under you in the area.","type":"tool"},
	"LEVELER":{"name":"Leveler","text":"Everything needs to be perfect. Flat. If it could, it would make everything grey. But it can't. How sad. Levels the area to ground level.","type":"tool"},
	"DUSTER":{"name":"Duster","text":"Sort of an adaptable broom that cleans up the dust. Removes lone tiles.","type":"tool"},
	"SHUFFLER":{"name":"Shuffler","text":"The power of chaos this tool has is unmatched. Have fun using this 20 times in a row to get what you want. Shuffles all the tiles in the area randomly.","type":"tool"},
	"STOPPER":{"name":"Stopper","text":"Does not like to go fast. Will stop you by raising the ground in front of you.","type":"tool"},
	"BULB":{"name":"Copper Bulb","text":"Shines light for you, and, when activated, lights more for a short time. Gives you a light passively and fills in all tiles temporarily when activated","type":"tool"},
	"MC_PICK":{"name":"Minecraft Pickaxe","text":"Pickaxe crafted, somehow, without a crafting table. Will auto craft into better a better pickaxe when getting the correct materials.","type":"tool","other":["MC_TOOL"]},
	"HOOK":{"name":"Hook","text":"Not really of the captian variety, more as a grapple. Brings enemies in the area closer.","type":"tool"},
	"BASE_SW":{"name":"Base Sword","text":"A really basic sword. Don't really know what else to say. Knocks enemies back a small amount in the area.","type":"tool"},
	"PLACER":{"name":"Placer","text":"Does what your fist should really be doing instead, but, considering you don't have one, this places your minecraft blocks. Places collected minecraft blocks in the area.","type":"tool","other":["MC_BLOCK"]},
	"STAMPER":{"name":"Stamper","text":"Not stampy. Sadly, not that cool. Stamps the last scanned shape onto the area.","type":"tool"},
	"GRAVITATE":{"name":"Antigravity Tool","text":"Don't know how this works, but it does. Makes everyone in the area have reversed gravity.","type":"tool"},
	"SUMMON":{"name":"Summoner","text":"Bring them down! USE ME!!! I WILL BRING YOUR ENEMIES DOWN IF YOU WON'T!!!","type":"tool"},
	"TERRAIN":{"name":"Terrain","text":"The power of creationism. Create terrain in the area.","type":"tool"},
	
	# "":{"name":"","text":"","type":"tool"},
	
	# Shapes
	"BASE_RECT":{"name":"Base Rectangle","text":"Yes I know, it's a square, but this sounds better.","type":"shape"},
	"5_SQR":{"name":"5 - Square","text":"A square that's 5 by 5. Quite boring.","type":"shape"},
	"6_SQR":{"name":"6 - Square","text":"Still boring, just 6 by 6.","type":"shape"},
	"SM_DIA":{"name":"Small Diamond","text":"This is lying, the game just treats it like a Squircle.","type":"shape"},
	"5_PLUS":{"name":"5 - Plus","text":"Reminds you of Switzerland, doesen't it?","type":"shape"},
	"3_DIAG":{"name":"3 - Diagonal","text":"A diagonal line with a length of 3.","type":"shape"},
	"3_DIAG_IN":{"name":"3 - Diagonal (Inverted)","text":"Just read the other one.","type":"shape"},
	"7_LINE":{"name":"7 - Horizontal","text":"A line with a length of 7. Line. With 7 length. Really not that complicated. You can stop reading this now. Please stop. How long will I have to keep going? Do I have to show off to get you to stop? I can spell hippopotomonstrosesquippedaliophobia. I was hoping that would be longer so you would lose interest (haha reference) but it seems to not have worked so I'm just going to make this a really long run-on sentance (did I spell that right?) you problably won't see the compatibilities, so they're: " + ", ".join(toolsCompatibility.keys().filter(func(e): return toolsCompatibility[e].has("7_LINE"))) + " just in case you needed that. This is problably where you'll not be able to read any further, so goodbye to you if so. This is a reminder that this is a line that is 7 tiles long, in case you forgot. The end. \n\n\n\n\n /j lol get trolled and rickrolled never gonna give you up never gonna let you down, that's all. [INSERT SECRET HERE] blah blah bl blah blah, blah bl blah bl blah, blah blah bl blah, blah blah bl blah","type":"shape"},
	"5_SQC":{"name":"5 - Squircle","text":"Hey look a squircle, that sounds fun.","type":"shape"},
	"10_SQR":{"name":"10 - Square","text":"Wow that's a big square.","type":"shape"},
	"5_DIAG":{"name":"5 - Diagonal","text":"Spiky","type":"shape"},
	"16_SQR":{"name":"16 - Square","text":"That's a really big square, too bad it only works with the scanner lol.","type":"shape"},
	"5_TRI":{"name":"5 - Triangle","text":"It's a triangle yay, we love triangles here","type":"shape"},
	
	# "":{"name":"","text":"","type":"shape"},
	
	# Actions
	"CREEPER":{"name":"","text":"","type":"action"},
	"RESPAWN":{"name":"Respawn Point","text":"Makes a futuristic sound. Sets the point you return to.","type":"action"},
	"W":{"name":"W","text":"A huge W. Launches you high into the air.","type":"action"},
	"L":{"name":"L","text":"Not a W. Sends you down.","type":"action"},
	"ZIG":{"name":"Zig","text":"Shocking. Multiplies your speed.","type":"action"},
	"ZAG":{"name":"Zag","text":"Electrifying. Multiplies your speed.","type":"action"},
	"COMPASS":{"name":"Compass","text":"An interesting artifact, Perhaps constructed from iron, but has hints of red along with yellow. Along with this, it seems to require a great deal of effort to use. Anyway, points the way twords the center.","type":"action"},
	"SENDER":{"name":"Sender","text":"Redirects you to the center.","type":"action"},
	"UNSENDER":{"name":"Unsender","text":"Redirects you away from the center.","type":"action"},
	"GROUNDER":{"name":"Grounder","text":"Very halting. Stops you in your tracks.","type":"action"},
	"STONE":{"name":"Stone","text":"A rather cubic resource, even for here. Upgrades tools to stone.","type":"action"},
	"IRON":{"name":"Iron","text":"A rather cubic resource, even for here. Upgrades tools to iron.","type":"action"},
	"GOLD":{"name":"Gold","text":"A rather cubic (and fragile) resource, even for here. Upgrades tools to gold.","type":"action"},
	"DIAMOND":{"name":"Diamond","text":"A rather cubic resource, even for here. Upgrades tools to diamond.","type":"action"},
	"NETHERITE":{"name":"Netherite","text":"A rather cubic resource, even for here. Upgrades tools to netherite.","type":"action"},
	"SMALL_SPEED":{"name":"Small Speed Boost","text":"Is it a drug? Whatever, we go faster now.","type":"action"},
	"NO":{"name":"No","text":"Passive agressive. Sends you underground.","type":"action"},
	"THUMB":{"name":"Thumb","text":"Basically flipping a coin. Changes your movement, either in a good way or bad.","type":"action"},
	"DOT":{"name":"Dot","text":"Very simplistic. Gives you slightly more elevation.","type":"action"},
	"L_HA":{"name":"L... Ha","text":"Imagine falling for this. Movement reduced.","type":"action"},
	"CHAIR":{"name":"Chair","text":"Freezes you in place for your comfort.","type":"action"},
	"CROWN":{"name":"Crown","text":"Assert dominance. Hit all enemies in a large area.","type":"action"},
	"6_PACK":{"name":"Six Pack","text":"Steroids? Increases strength.","type":"action"},
	"SUMMON_BIRDS":{"name":"Summon Birds","text":"Bring everything down to your level.","type":"action"},
	"WALKING_PERSON":{"name":"Walking Person","text":"Gives you strength and speed, just like a person that would walk places and touch grass!!!","type":"action"},
	"TEA":{"name":"Tea","text":"Pinkies out. BRITISH POWER.","type":"action"},
	"FLOAT":{"name":"Float","text":"Defy gravitational force.","type":"action"},
	
	# "":{"name":"","text":"","type":"action"},
}

func getDescriptionText(key:String) -> String:
	var result = ""
	if descriptions.has(key):
		for query in descriptions[key]:
			match query:
				"name":
					result += "\n\n" + descriptions[key][query]
				"text":
					result += "\n\n" + descriptions[key][query]
				"type":
					match descriptions[key][query]:
						"tool":
							if not toolsCompatibility[key].filter(func(e): return e != "NONE").is_empty():
								result += "\n\nCompatibility: " + ", ".join(toolsCompatibility[key].filter(func(e): return e != "NONE"))
						"shape":
							if not toolsCompatibility.keys().filter(func(e): return toolsCompatibility[e].has(key)).is_empty():
								result += "\n\nCompatibility: " + ", ".join(toolsCompatibility.keys().filter(func(e): return toolsCompatibility[e].has(key)))
						"action":
							result += "\n\nPattern:\n" + visualize(shapes[key].pick_random())
				"other":
					for otherVal in descriptions[key][query]:
						match otherVal:
							"MC_TOOL":
								result += "\n\nMaterial: " + Globals.mcToolLevel.capitalize()
							"MC_BLOCK":
								result += "\n\nBlocks: " + str(Globals.mcBlocks)
	result = result.right(-2)
	return result

func visualize(pattern:Array) -> String:
	var result = ""
	var length = pattern.map(func(e): return e.x).max()
	var height = pattern.map(func(e): return e.y).max()
	for i in range(height + 1):
		var strip = ""
		for x in range(length + 1):strip += "#"
		for point in pattern.filter(func(e): return e.y == i):
			var tempStrip = strip.split("")
			tempStrip[point.x] = "%"
			strip = "".join(tempStrip)
		result += strip + "\n"
	
	return result

var isMultiplayer = false
