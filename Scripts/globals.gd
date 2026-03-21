extends Node

var firstPause = true

@warning_ignore("unused_signal")
signal player_ready
var playerRef
var cameraRef
var gridRef:GridMap
var cheatsOn = false
var allPopups = []
var mcToolLevel := "WOOD"
var mcBlocks = 0
const VARS_TO_SAVE = [
	"actionsScanned",
	"availibleTools",
	"availibleShapes",
	"mcToolLevel",
	"mcBlocks",
	"currencies",
	"respawnPoint",
	"archipelagoLocationsFound",
]
var actionsScanned = []:
	set(value):
		for shape in value:
			if isArchipelago: if len(actionsScanned) == len(getActions()): gridRef.finishArchipelago()
			var panel = preload("res://Scenes/grid_panel.tscn").instantiate()
			panel.selectable = false
			panel.get_child(0).text = shape
			panel.custom_minimum_size = Vector2(140,60)
			Globals.cameraRef.get_child(0).get_node("ActionsTab").get_child(0).get_child(0).add_child(panel)
		actionsScanned = value
var currencies = {}
var respawnPoint := Vector3(0,2,0)
var hoveringTool = "NONE"
var hoveringShape = "NONE"
var barLayout = [tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE]
var barIndex = 0
var availibleTools = [tools.NONE]:
	set(value):
		if typeof(value[0]) == TYPE_FLOAT or typeof(value[0]) == TYPE_INT:
			availibleTools = value.map(func(e): return int(e) as tools)
		toolShapes.clear()
		for i in cameraRef.get_child(0).get_node("SetupTab").get_node("ToolsGrid").get_children(): i.queue_free()
		
		for i in availibleTools:
			toolShapes[i] = "NONE"
			var gridPanel = preload("res://Scenes/grid_panel.tscn").instantiate()
			gridPanel.get_child(0).text = tools.keys()[i]
			cameraRef.get_child(0).get_node("SetupTab").get_node("ToolsGrid").add_child(gridPanel)
enum types {RECT,SQUIRCLE,PLUS,DIAGONAL,LINE,TRIANGLE,LOOP,CIRCLE}
var baseShape = {"type":types.RECT,"x":3,"y":3}
enum allStatuses {NONE,SPEED}
const maxHeight = 300
enum tools {NONE,VOIDER,ERASER,C_GOL,RAISER,LEVELER,DUSTER,SHUFFLER,STOPPER,BULB,MC_PICK,HOOK,BASE_SW,PLACER,STAMPER,GRAVITATE,SUMMON,TERRAIN,PARALYZER,PLATFORMS}
const toolsCompatibility = {
	"NONE":[],
	"VOIDER":[],
	"ERASER":[],
	"C_GOL":[		"NONE",		"BASE_RECT",	"5_SQR",	"6_SQR"																																									],
	"RAISER":[		"NONE",												"SM_DIA",	"5_PLUS",													"5_SQC"																				],
	"LEVELER":[		"NONE",		"BASE_RECT",	"5_SQR",																															"5_TRI"											],
	"DUSTER":[		"NONE",		"BASE_RECT",				"6_SQR"																																									],
	"SHUFFLER":[	"NONE",						"5_SQR"																																												],
	"STOPPER":[		"NONE",												"SM_DIA",												"7_LINE"																							],
	"BULB":[		"NONE",															"5_PLUS",		"3_DIAG",	"3_DIAG_IN"																											],
	"MC_PICK":[		"NONE",																										"7_LINE"																							],
	"HOOK":[		"NONE",									"6_SQR",																			"5_SQC"																				],
	"BASE_SW":[		"NONE",																			"3_DIAG",	"3_DIAG_IN",											"5_DIAG"													],
	"PLACER":[		"NONE",																			"3_DIAG",	"3_DIAG_IN"																											],
	"STAMPER":[		"NONE",									"6_SQR"																																									],
	"GRAVITATE":[	"NONE",																																							"5_TRI"											],
	"SUMMON":[		"NONE",						"5_SQR",																									"10_SQR"																],
	"TERRAIN":[		"NONE",						"5_SQR",																																		"50_SQR",	"200_SQR",				],
	"PARALYZER":[	"NONE",																																																"7_SQC",	],
	"PLATFORMS":[	"NONE",																																										"50_SQR",				"7_SQC",	],
}
var currentTool = tools.NONE
const enemySpawnShapes = ["RED_PILL","TRI_ENEMY","ZOOM_ENEMY","SMALL_BIRD"]
var toolShapes = {tools.NONE:"BASE_RECT"}
var availibleShapes = ["NONE","BASE_RECT"]
const allToolShapes = {
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
	"7_LOOP":{"type":types.LOOP,"x":7,"y":7,"w":1},
	"7_SQC":{"type":types.SQUIRCLE,"x":7,"y":7},
	"8_CIR":{"type":types.CIRCLE,"d":8},
}
var structureShapes = {
	"TOWER":[Vector3i(0,1,0),Vector3i(0,2,0),Vector3i(0,3,0),Vector3i(0,4,0),Vector3i(1,1,0),Vector3i(1,2,0),Vector3i(1,3,0),Vector3i(1,4,0),Vector3i(1,1,1),Vector3i(1,2,1),Vector3i(1,3,1),Vector3i(1,4,1),Vector3i(0,1,1),Vector3i(0,2,1),Vector3i(0,3,1),Vector3i(0,4,1)                ,Vector3i(-1,1,0),Vector3i(-1,2,0),Vector3i(-1,3,0),Vector3i(-1,4,0),Vector3i(-1,1,-1),Vector3i(-1,2,-1),Vector3i(-1,3,-1),Vector3i(-1,4,-1),Vector3i(0,1,-1),Vector3i(0,2,-1),Vector3i(0,3,-1),Vector3i(0,4,-1)],
	"CUBE":[Vector3i(0,1,0),Vector3i(0,2,0),Vector3i(0,3,0)],
	"TORCH":[Vector3i(0,1,0),Vector3i(0,2,0),Vector3i(0,3,0),Vector3i(1,3,0),Vector3i(-1,3,0),Vector3i(0,3,1),Vector3i(0,3,-1),Vector3i(1,4,0),Vector3i(-1,4,0),Vector3i(0,4,1),Vector3i(0,4,-1)],
	"DIA_TOWER":[Vector3i(0,1,0),Vector3i(0,2,0),Vector3i(0,3,0),Vector3i(1,1,0),Vector3i(1,2,0),Vector3i(1,3,0),Vector3i(-1,1,0),Vector3i(-1,2,0),Vector3i(-1,3,0),Vector3i(0,1,1),Vector3i(0,2,1),Vector3i(0,3,1),Vector3i(0,1,-1),Vector3i(0,2,-1),Vector3i(0,3,-1)],
	"TUT_AREA":loadVoxels("res://Scenes/StructureMaps/tut_map.tscn"),
	"TUT_AREA_2":loadVoxels("res://Scenes/StructureMaps/tut_map_2.tscn"),
	"TUT_AREA_3":loadVoxels("res://Scenes/StructureMaps/tut_map_3.tscn"),
	"RANDOM_GENERATION":[],
	"START":[]
}
const complexStructures = {
	"TUT_AREA":"res://Scenes/StructureMaps/tut_map.tscn",
	"TUT_AREA_2":"res://Scenes/StructureMaps/tut_map_2.tscn",
	"TUT_AREA_3":"res://Scenes/StructureMaps/tut_map_3.tscn"
}
const colorShapes = {
	"NORMAL_COLOR":[Color.BLACK,Color.WHITE,Color(0.57,0.57,0.57),Color(0.04,0.04,0.04)],
	"C_GOL_COLOR":[Color(0.0, 0.0, 0.0, 1.0),Color(1.0, 1.0, 0.0, 1.0),Color(1,1,1),Color(1,1,1)]
}
var currencyExchangeRates = { # To cubics
	"CUBICS":1.0,
	"USD":100.0,
	"DIAMONDS":(6.7027791 * pow(10,-8)),
	"GEO":(100.0/0.225),
	"ROSARIES":(100.0/0.45),
	"AGNI":(100.0/0.225)*(1.0/35)
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
		[Vector2i(0,0),Vector2i(1,1)]
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
	"START":[
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
	"CAR":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(1,1),Vector2i(2,1),Vector2i(2,2)]
	],
	"7_LOOP":[
		loadShape({"type":types.LOOP,"x":5,"y":5,"w":1})
	],
	"BOUNCE":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,1),Vector2i(1,2),Vector2i(2,0)]
	],
	"UNDERSIDE":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,2),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2)]
	],
	"MULTIGRAVITY":[
		[Vector2i(0,0),Vector2i(1,1),Vector2i(1,2),Vector2i(2,1),Vector2i(2,2)]
	],
	"SCALE_UP":[
		[Vector2i(0,2),Vector2i(1,1),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2)]
	],
	"SCALE_DOWN":[
		[Vector2i(0,0),Vector2i(1,1),Vector2i(2,0),Vector2i(2,2)]
	],
	"MED_SPEED":[
		[Vector2i(0,0),Vector2i(0,2),Vector2i(1,1),Vector2i(2,1)]
	],
	"PARALYZER":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(1,1),Vector2i(2,0),Vector2i(2,2)]
	],
	"7_SQC":[
		[Vector2i(0,1),Vector2i(1,0),Vector2i(1,2),Vector2i(2,1)]
	],
	"PLATFORMS":[
		[Vector2i(0,0),Vector2i(1,1),Vector2i(1,2),Vector2i(2,0),Vector2i(2,2),Vector2i(2,4),Vector2i(3,2),Vector2i(3,3),Vector2i(4,4)]
	],
	"200_SQR":[
		loadShape(allToolShapes["50_SQR"])
	],
	"8_CIR":[
		[Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(0,3),Vector2i(1,1),Vector2i(1,2),Vector2i(1,3),Vector2i(2,1),Vector2i(2,2),Vector2i(2,3),Vector2i(3,3)]
	],
	"CURRENCY_CUBICS":[
		[Vector2i(0,2),Vector2i(1,1),Vector2i(1,2),Vector2i(2,1),Vector2i(3,0),Vector2i(3,1),Vector2i(4,1)]
	],
	"CURRENCY_AGNI":[
		loadPixels("res://Sprites/agni.png")
	]
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

static func loadShape(shape:Dictionary) -> Array:
	var loader = preload("res://Scripts/random_generation.gd")
	return loader.makeStandard(loader.getShape(Vector3i.ZERO,shape))

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
	"PARALYZER":{"name":"Paralyzer","text":"I don't know if that's spelled right. Freezes enemies in place.","type":"tool"},
	"PLATFORMS":{"name":"Platforms","text":"More land!! Yay!","type":"tool"},
	
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
	"50_SQR":{"name":"50 - Square","text":"The penultimate shape.","type":"shape"},
	"7_LOOP":{"name":"7 - Loop","text":"Not a round loop, that would be a ring.","type":"shape"},
	"7_SQC":{"name":"7 - Squircle","text":"A bigger squircle! What are these anyways...","type":"shape"},
	"200_SQR":{"name":"200 - Square","text":"The ultimate shape.","type":"shape"},
	"8_CIR":{"name":"8 - Circle","text":"A circle in a square world.","type":"shape"},
	
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
	"SMALL_SPEED":{"name":"Small Speed Boost","text":"We go faster now.","type":"action"},
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
	"NORMAL_COLOR":{"name":"Normal Color Scheme","text":"A very boring palette, just use something else lol","type":"action"},
	"C_GOL_COLOR":{"name":"Conway's Game of Life Color Scheme","text":"Now this looks cool.","type":"action"},
	"CAR":{},
	"BOUNCE":{"name":"Bounce","text":"*bouncy noises*","type":"action"},
	"UNDERSIDE":{"name":"Underside","text":"Flips your world upside down, kinda","type":"action"},
	"MULTIGRAVITY":{"name":"Multigravity","text":"Increases your gravity. So helpful.","type":"action"},
	"SCALE_UP":{"name":"Scale Up","text":"Bigger","type":"action"},
	"SCALE_DOWN":{"name":"Scale Down","text":"Smaller","type":"action"},
	"MED_SPEED":{"name":"Medium Speed","text":"We go even faster now.","type":"action"},
	"CURRENCY_CUBICS":{"name":"Cubics","text":"Suspiciously expensive cubes","type":"action"},
	"CURRENCY_AGNI":{"name":"Agni","text":"Firey stones from a fallen kingdom.","type":"action"},
	
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
var isArchipelago = false
var archipelagoLocationsFound = []
const deathlinkMessages = [
	"\"boop\" - %s",
	"%s couldn't think of a pop culture refrence to put here",
	"%s poked at the wrong guy",
	"%s fought for Aiur",
	"That's the wrong action, %s",
	"Oh no, %s lost all their [insert currency here]",
	"%s's home bed was missing or obstructed",
	"*sad giraffe noises* - %s",
	"\"%s has been cubified, sir\"",
	"%s broke through the shiny wall",
	"%s's world is looking a little too pixelated",
	"baba is not %s",
	"%s fell off of the space platform",
	"%s walked past elderbug",
	"The zombies ate %s's brains",
	"GLaDOS is dissapointed in %s",
	"%s IS a potato",
	"%s really wants to turn keep inventory on right now",
	"%s needs Shakra to help for this fight (apperently)",
	"What's the point of this wall being here if %s is just gonna breeze right through??",
	"%s was bonked by an apricot-flavored popsicle",
	"\"death.fell.accident.water\" - %s",
	"%s died? Interesting... very Interesting",
	"%s didn't think that mantis shrimps are cool",
	"%s didn't think that would do two masks",
	"%s overreacted",
]

func testShapes() -> void:
	var amounts = {}
	var bitGrid = getBits(16)
	bitGrid = bitGrid.map(toCells)
	
	for i in bitGrid:
		for shape in gridRef.checkForShapes(gridRef.removeExtras(i)):
			if amounts.has(shape):
				amounts[shape] += 1
			else:
				amounts[shape] = 1
	
	print(amounts)
	print(len(amounts))

func getBits(length:int) -> Array:
	if length <= 1: return [[false],[true]]
	
	var result = []
	for i in getBits(length - 1):
		result.append(i + [false])
		result.append(i + [true])
	return result

func toCells(list:Array) -> Dictionary:
	var result = []
	var gridSize := ceili(sqrt(len(list)))
	
	for x in range(gridSize):
		if len(list) == len(result): break
		for y in range(gridSize):
			if len(list) == len(result): break
			result.append(Vector2i(x,y))
	
	var dictionaryResult = {}
	for i in result:
		dictionaryResult[i] = 1 if list[result.find(i)] else 0
	
	return dictionaryResult

func checkForErrors() -> void:
	for i in shapes:
		if not descriptions.has(i) and not structureShapes.has(i) and not enemySpawnShapes.has(i):
			printerr("No description for " + i)

func getActions() -> Array:
	return shapes.keys().filter(func(e): return not allToolShapes.has(e) and not toolsCompatibility.has(e))

func _ready() -> void:
	Archipelago.connect("connected",(func(_arg,_arg2):
		isArchipelago = true
		Archipelago.conn.deathlink.connect(recieveDeathlink)
		Archipelago.conn.connect("obtained_item",(func(e):gridRef.runShape((e.get_name()),Vector2i.ZERO,true,e)))
		Archipelago.conn.force_scout_all()
		#print(Archipelago.conn.slot_data)
		Archipelago.set_deathlink(is_equal_approx(Archipelago.conn.slot_data["death_link"],1.0))
		))
	Archipelago.connect("disconnected",(func():isArchipelago = true))
	
	checkForErrors()

func archipelagoName() -> String:
	return Archipelago.conn.get_player().get_name()

func reset(trueDeath:bool=(not playerRef.get_parent().get_node("Bounds").get_overlapping_bodies().has(playerRef)),fromDeathlink:=false) -> void:
	if trueDeath:
		var deathCause = deathlinkMessages.pick_random() % archipelagoName()
		gridRef.clear()
		for x in range(3):
			for y in range(3):
				gridRef.set_cell_item(Vector3i(x,0,y),0)
		for i in shapes["START"][0]:
			gridRef.set_cell_item(Vector3i(i.x,0,i.y),1)
		if isArchipelago and not fromDeathlink and Archipelago.is_deathlink(): Archipelago.conn.send_deathlink(deathCause)
	playerRef.position = Globals.respawnPoint
	playerRef.velocity = Vector3(0,0,0)
	playerRef.strength = 0.0

func recieveDeathlink(source:String,cause:String,json:Dictionary) -> void:
	reset(true,true)
	#await player_ready
	gridRef.triggerPopup("Archipelago Deathlink: " + cause,gridRef.scanTypes.ARCHIPELAGO_DEATHLINK)
	print(source)
	print(cause)
	print(json)

func maxLength(list:Array) -> int:
	var result = list[0].x
	for i in list:
		if i.x > result: result = i.x
		if i.y > result: result = i.y
	return result

var currentSlot := 0

func saveSlot(slot:int=currentSlot) -> void:
	if slot == -1:
		slot = Array(DirAccess.open("user://Data/").get_files()).filter(func(e): return str(e).contains("save")).map(func(e): return int(str(e).replace("save","").replace(".dat",""))).max() + 1
	
	if not DirAccess.dir_exists_absolute("user://Data/"): DirAccess.make_dir_absolute("user://Data/")
	if not FileAccess.file_exists("user://Data/save"+str(slot)+".dat"): FileAccess.open("user://Data/save"+str(slot)+".dat",FileAccess.WRITE)
	
	var file = FileAccess.open("user://Data/save"+str(slot)+".dat",FileAccess.WRITE)
	var data = {
		"actionsScanned":actionsScanned,
		"availibleTools":availibleTools,
		"availibleShapes":availibleShapes,
		"mcToolLevel":mcToolLevel,
		"mcBlocks":mcBlocks,
		"currencies":currencies,
		"respawnPoint":respawnPoint,
		"archipelagoLocationsFound":archipelagoLocationsFound,
	}
	data = toDictionary((func(e): return get(e)),VARS_TO_SAVE)
	file.store_line(JSON.stringify(data))
	
	cameraRef.updateSaves()

func loadSlot(slot:int) -> void:
	if not DirAccess.dir_exists_absolute("user://Data/"): DirAccess.make_dir_absolute("user://Data/")
	if not FileAccess.file_exists("user://Data/save"+str(slot)+".dat"): FileAccess.open("user://Data/save"+str(slot)+".dat",FileAccess.WRITE)
	var file = FileAccess.open("user://Data/save"+str(slot)+".dat",FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	for i in data:
		if i in self:
			set(i,data[i])
	currentSlot = slot
	
	cameraRef.updateSaves()

func toDictionary(function:Callable,list:Array) -> Dictionary:
	var result = {}
	for i in list:
		result[i] = function.call(i)
	return result
