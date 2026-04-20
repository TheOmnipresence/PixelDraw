extends Node

## If multiplayer is active
var isMultiplayer = false

## If archipelago is active
var isArchipelago = false

## The archipelago locations found
var archipelagoLocationsFound = []

## The needed patterns found for archipelago
var extraPatternsFound = []

## All the needed patterns for archipelago
var allExtraPatterns = []

## Set to true the first successful scan after connection to archipelago
var startedArchipelago = false:
	set(value):
		if not (value and startedArchipelago):
			startedArchipelago = value
			if value:
				Archipelago.set_client_status(Archipelago.ClientStatus.CLIENT_PLAYING)

## The deathlink messages for archipelago
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

var finished_archipelago := false

var scanned_all_extra_patterns := false

var scanned_all_actions := false

var bounds_velocity := 100

@warning_ignore("unused_signal")
## Emits once the player finishes its ready function
signal player_ready

## A refrence to the player
var playerRef:CharacterBody3D

## A refrence to the camera
var cameraRef:Camera3D

## A refrence to the grid
var gridRef:GridMap

## If you can use commands in the command line
var cheatsOn = false

## All the popups recieved
var allPopups:Array[String] = []

## The level for the minecraft tools (MC_PICK)
var mcToolLevel := "WOOD"

## The amount of minecraft blocks you currently have stored
var mcBlocks := 0:
	set(value):
		mcBlocks = clampi(value,0,mcInventoryLevel * 64)

## The level of inventory for minecraft
var mcInventoryLevel := 1

## The current save slot
var currentSlot := 0

## The variables that are saved to file
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

## A list of all actions scanned, used predominantly for Archipelago stuff
var actionsScanned = []:
	set(value):
		for shape in value:
			if isArchipelago: if len(actionsScanned) == int(Archipelago.conn.slot_data["actions_needed"]): gridRef.finishArchipelago()
			var panel = preload("res://Scenes/grid_panel.tscn").instantiate()
			panel.selectable = false
			panel.get_child(0).text = shape
			panel.custom_minimum_size = Vector2(140,60)
			Globals.cameraRef.get_child(0).get_node("ActionsTab").get_child(0).get_child(0).add_child(panel)
		actionsScanned = []
		actionsScanned.assign(value)

## The currencies and how much of them
var currencies := {}

## The reset point of the player
var respawnPoint := Vector3(0,2,0)

## The tool that is being hovered over in the ui
var hoveringTool := "NONE":
	set(value):
		hoveringTool = value
		cameraRef.updateDescriptionWindows("Tool",value)

## The shape that is being hovered over in the ui
var hoveringShape := "NONE":
	set(value):
		hoveringShape = value
		cameraRef.updateDescriptionWindows("Shape",value)

## The action that is being hovered over in the ui
var hoveringAction := "NONE":
	set(value):
		hoveringAction = value
		cameraRef.updateDescriptionWindows("Action",value)

## The tools currently on the toolbar
var barLayout:Array[tools] = [tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE,tools.NONE]

## The currently selected index of the toolbar
var barIndex := 0

## All unlocked tools
var availibleTools := [tools.NONE]:
	set(value):
		if typeof(value[0]) == TYPE_FLOAT or typeof(value[0]) == TYPE_INT:
			availibleTools = []
			availibleTools.assign(value.map(func(e): return int(e) as tools))
		toolShapes.clear()
		for i in cameraRef.get_child(0).get_node("SetupTab").get_node("ToolsGrid").get_children(): i.queue_free()
		
		for i in availibleTools:
			toolShapes[i] = "NONE"
			var gridPanel = preload("res://Scenes/grid_panel.tscn").instantiate()
			gridPanel.get_child(0).text = tools.keys()[i]
			cameraRef.get_child(0).get_node("SetupTab").get_node("ToolsGrid").add_child(gridPanel)

## The types of shape
enum types {
	RECT, ## A rectangle, perameters "x" and "y" for lengths in both axis
	SQUIRCLE, ## Rectangle with the corners gone, perameters "x" and "y" for lengths in both axis
	PLUS, ## A plus shape, two perpendicular lines meeting in the middle, perameters "x" and "y" for lengths in both axis
	DIAGONAL, ## A diagonal line, perameter "len" for length and "tl" for inversion
	LINE, ## A line, perameter "len" for length and "vertical" for axis
	TRIANGLE, ## A right triangle, perameters "x" and "y" for lengths in both axis
	LOOP, ## A square loop, perameters "x" and "y" for lengths in both axis and "w" for width of the loop
	CIRCLE, ## A circle, perameter "d" for diameter
	DIAMOND, ## A square rhombus, perameter "len" for lengths of opposite corners
}

## The shape the scanner uses
var baseShape := allToolShapes.BASE_RECT

## All status effects
enum allStatuses {NONE,SPEED}

## The maximum height that the grid map can place cells
const maxHeight = 300

## All tools
enum tools {
	NONE, ## A blank tool
	VOIDER, ## 
	ERASER,
	C_GOL,
	RAISER,
	LEVELER,
	DUSTER,
	SHUFFLER,
	STOPPER,
	BULB,
	MC_PICK,
	HOOK,
	BASE_SW,
	PLACER,
	STAMPER,
	GRAVITATE,
	SUMMON,
	TERRAIN,
	PARALYZER,
	PLATFORM,
	PLAGUE,
	MAZER,
} # TODO: HOLE

## The compatible shapes for each tool
var toolsCompatibility = {
	"NONE":[],
	"VOIDER":[],
	"ERASER":[],
	"C_GOL":[		"NONE",		"BASE_RECT",	"5_SQR",	"6_SQR"																																																					],
	"RAISER":[		"NONE",												"SM_DIA",	"5_PLUS",													"5_SQC"																																],
	"LEVELER":[		"NONE",		"BASE_RECT",	"5_SQR",																															"5_TRI",																			"6/4_RECT",	],
	"DUSTER":[		"NONE",		"BASE_RECT",				"6_SQR",																																								"8_CIR",										],
	"SHUFFLER":[	"NONE",						"5_SQR"																																																								],
	"STOPPER":[		"NONE",												"SM_DIA",												"7_LINE"																																			],
	"BULB":[		"NONE",															"5_PLUS",		"3_DIAG",	"3_DIAG_IN",																																"11_DIA",				],
	"MC_PICK":[		"NONE",																										"7_LINE"																																			],
	"HOOK":[		"NONE",									"6_SQR",																			"5_SQC",																						"10_TRI",							],
	"BASE_SW":[		"NONE",																			"3_DIAG",	"3_DIAG_IN",											"5_DIAG"																									],
	"PLACER":[		"NONE",																			"3_DIAG",	"3_DIAG_IN",																																						],
	"STAMPER":[		"NONE",									"6_SQR",																																																				],
	"GRAVITATE":[	"NONE",																																							"5_TRI",													"10_TRI",							],
	"SUMMON":[		"NONE",						"5_SQR",																									"10_SQR",																						"11_DIA",				],
	"TERRAIN":[		"NONE",						"5_SQR",																																		"50_SQR",	"200_SQR",																],
	"PARALYZER":[	"NONE",																																																"7_SQC",							"11_DIA",	"6/4_RECT",	],
	"PLATFORM":[	"NONE",																																										"50_SQR",				"7_SQC",	"8_CIR",										],
	"PLAGUE":[		"NONE",																																	"10_SQR",																			"10_TRI",							],
	"MAZER":[		"NONE",									"6_SQR",																						"10_SQR",							"50_SQR",																			],
}

const additionalCompatibilities = {
	"NONE":[],
	"VOIDER":[],
	"ERASER":[],
	"C_GOL":["10_SQR","50_SQR"],
	"RAISER":["11_DIA"],
	"LEVELER":["11_DIA"],
	"DUSTER":["7_SQC"],
	"SHUFFLER":["7_LINE"],
	"STOPPER":["3_DIAG"],
	"BULB":["SM_DIA"],
	"MC_PICK":["6_SQR"],
	"HOOK":["7_SQC"],
	"BASE_SW":["7_LOOP"],
	"PLACER":["BASE_RECT"],
	"STAMPER":["6/4_RECT"],
	"GRAVITATE":["8_CIR"],
	"SUMMON":["10_TRI"],
	"TERRAIN":["10_SQR"],
	"PARALYZER":["5_PLUS"],
	"PLATFORM":["BASE_RECT"],
	"PLAGUE":["6/4_RECT"],
	"MAZER":["5_SQR"],
}

## All tool compatibilities currently unlocked
var unlockedCompatibilities = {}

## The amount of compatibility chips
var compatibilityChips := 0:
	set(value):
		compatibilityChips = value
		cameraRef.get_child(0).get_node("ToolsTab").get_node("ChipAmount").text = "Compatibility Chips: " + str(value)

## The current tool selected in the toolbar
var currentTool:tools = tools.NONE

## The patterns that spawn enemies
const enemySpawnShapes = ["RED_PILL","TRI_ENEMY","ZOOM_ENEMY","SMALL_BIRD"]

## The associated shapes for tools in the toolbar
var toolShapes:Dictionary[tools,String] = {tools.NONE:"BASE_RECT"}

## All unlocked shapes
var availibleShapes: = ["NONE","BASE_RECT"]:
	set(value):
		availibleShapes = []
		availibleShapes.assign(value)

## The data for every shape
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
	"10_TRI":{"type":types.TRIANGLE,"x":10,"y":10},
	"11_DIA":{"type":types.DIAMOND,"len":12},
	"6/4_RECT":{"type":types.RECT,"x":6,"y":4}
}

## The structure data for every structure pattern
var structureShapes:Dictionary[String,Array] = {
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

## The structures that pull cell data
const complexStructures = {
	"TUT_AREA":"res://Scenes/StructureMaps/tut_map.tscn",
	"TUT_AREA_2":"res://Scenes/StructureMaps/tut_map_2.tscn",
	"TUT_AREA_3":"res://Scenes/StructureMaps/tut_map_3.tscn"
}

## The unlockable color schemes
const colorShapes = {
	"NORMAL_COLOR":[Color.BLACK,Color.WHITE,Color(0.57,0.57,0.57),Color(0.04,0.04,0.04)],
	"C_GOL_COLOR":[Color(0.0, 0.0, 0.0, 1.0),Color(1.0, 1.0, 0.0, 1.0),Color(1,1,1),Color(1,1,1)],
	"GODOT_COLOR":[Color("242424"),Color(0.24, 0.59, 0.83),Color.WHITE,Color.WHITE],
}

## The amount of compatibility chips you get for every pack
var chipPackAmounts = [
	1,
	2,
]

## The exchange rates for the currencies, in however many you would get from 1 cubic
var currencyExchangeRates:Dictionary[String,float] = { # To cubics
	"CUBICS":1.0,
	"USD":100.0,
	"DIAMONDS":(1/75.0),
	"GEO":(100.0/0.225),
	"ROSARIES":(100.0/0.45),
	"AGNI":(100.0/0.225)*(1.0/35)
}

## All salesmen
const SALESMEN: Array[String] = [
	"CUBIC_SALESMAN",
	"MINECRAFT_USER",
]


const ALL_SHOP_ITEMS: Array[String] = [
	"CUBIC_SALESMAN_ITEM_1",
	"CUBIC_SALESMAN_ITEM_2",
	"CUBIC_SALESMAN_ITEM_3",
	"MINECRAFT_USER_ITEM_1",
	"MINECRAFT_USER_ITEM_2",
	"MINECRAFT_USER_ITEM_3-1",
	"MINECRAFT_USER_ITEM_3-2",
	"MINECRAFT_USER_ITEM_3-3",
	"MINECRAFT_USER_ITEM_3-4",
	"MINECRAFT_USER_ITEM_3-5",
	"MINECRAFT_USER_ITEM_3-6",
	"MINECRAFT_USER_ITEM_3-7",
]


const UPGRADES:Array[String] = [
	"MC_INVENTORY"
]

## All patterns
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
	"PLATFORM":[
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
	],
	"GODOT_COLOR":[
		loadPixels("res://Sprites/godot.png")
	],
	"TUT_AREA":[
		[Vector2i(0,2),Vector2i(0,3),Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(1,3),Vector2i(1,4),Vector2i(2,1),Vector2i(2,2)]
	],
	"10_TRI":[
		[Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2),Vector2i(3,0),Vector2i(3,1),Vector2i(4,0)]
	],
	"11_DIA":[
		[Vector2i(0,0),Vector2i(0,2),Vector2i(0,4),Vector2i(1,1),Vector2i(1,2),Vector2i(1,3),Vector2i(2,0),Vector2i(2,1),Vector2i(2,2),Vector2i(2,3),Vector2i(2,4),Vector2i(3,1),Vector2i(3,2),Vector2i(3,3),Vector2i(4,0),Vector2i(4,2),Vector2i(4,4)]
	],
	"PLAGUE":[
		[Vector2i(0,2),Vector2i(1,1),Vector2i(1,3),Vector2i(2,0),Vector2i(2,2),Vector2i(2,4),Vector2i(3,1),Vector2i(3,3),Vector2i(4,2)]
	],
	"BLOCK":[
		loadPixels("res://Sprites/block.png")
	],
	"MAZE":[
		loadPixels("res://Sprites/maze.png")
	],
	"MAZER":[
		loadPixels("res://Sprites/mazer.png")
	],
	"CHIP_PACK_1":[
		[Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(1,3),Vector2i(2,1),Vector2i(2,2)]
	],
	"6/4_RECT":[
		loadShape({"type":types.RECT,"x":4,"y":2})
	],
	"CHIP_PACK_2":[
		[Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(1,3),Vector2i(2,1),Vector2i(2,2),Vector2i(3,0),Vector2i(3,3),Vector2i(4,1),Vector2i(4,2)]
	],
	#"LOAF":[
		#[Vector2i(0,1),Vector2i(0,2),Vector2i(1,0),Vector2i(1,3),Vector2i(2,0),Vector2i(2,2),Vector2i(3,1)]
	#],
	#"BARGE":[
		#[Vector2i(0,1),Vector2i(1,0),Vector2i(1,2),Vector2i(2,1),Vector2i(2,3),Vector2i(3,2)]
	#],
	#"LONG_BOAT":[
		#[Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,2),Vector2i(2,1),Vector2i(2,3),Vector2i(3,2)]
	#],
	#"LONG_SHIP":[
		#[Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,2),Vector2i(2,1),Vector2i(2,3),Vector2i(3,2),Vector2i(3,3)]
	#],
	"CUBIC_SALESMAN":[
		loadPixels("res://Sprites/cubic_salesman.png")
	],
	"MINECRAFT_USER":[
		loadPixels("res://Sprites/minecraft_user.png")
	],
	"STRENGTHEN_BOUNDS":[
		[Vector2i(0,0),Vector2i(0,2),Vector2i(1,1),Vector2i(1,2),Vector2i(1,3),Vector2i(2,0),Vector2i(2,2)]
	],
}

## Descriptions for all tools, shapes, and actions
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
	"MC_PICK":{"name":"Minecraft Pickaxe","text":"Pickaxe crafted, somehow, without a crafting table. Will auto craft into better a better pickaxe when getting the correct materials.","type":"tool","other":["MC_TOOL","MC_BLOCK"]},
	"HOOK":{"name":"Hook","text":"Not really of the captian variety, more as a grapple. Brings enemies in the area closer.","type":"tool"},
	"BASE_SW":{"name":"Base Sword","text":"A really basic sword. Don't really know what else to say. Knocks enemies back a small amount in the area.","type":"tool"},
	"PLACER":{"name":"Placer","text":"Does what your fist should really be doing instead, but, considering you don't have one, this places your minecraft blocks. Places collected minecraft blocks in the area.","type":"tool","other":["MC_BLOCK"]},
	"STAMPER":{"name":"Stamper","text":"Not stampy. Sadly, not that cool. Stamps the last scanned shape onto the area.","type":"tool"},
	"GRAVITATE":{"name":"Antigravity Tool","text":"Don't know how this works, but it does. Makes everyone in the area have reversed gravity.","type":"tool"},
	"SUMMON":{"name":"Summoner","text":"Bring them down! USE ME!!! I WILL BRING YOUR ENEMIES DOWN IF YOU WON'T!!!","type":"tool"},
	"TERRAIN":{"name":"Terrain","text":"The power of creationism. Create terrain in the area.","type":"tool"},
	"PARALYZER":{"name":"Paralyzer","text":"I don't know if that's spelled right. Freezes enemies in place.","type":"tool"},
	"PLATFORM":{"name":"Platform","text":"More land!! Yay!","type":"tool"},
	"PLAGUE":{"name":"Plague","text":"A sickness spreads, bringing death in it's path. If some spaces around a tile are empty, it becomes empty as well.","type":"tool"},
	"MAZER":{"name":"Mazer","text":"Solve these","type":"tool"},
	
	#"":{"name":"","text":"","type":"tool"},
	
	# Shapes
	"BASE_RECT":{"name":"Base Rectangle","text":"Yes I know, it's a square, but this sounds better.","type":"shape"},
	"5_SQR":{"name":"5 - Square","text":"A square that's 5 by 5. Quite boring.","type":"shape"},
	"6_SQR":{"name":"6 - Square","text":"Still boring, just 6 by 6.","type":"shape"},
	"SM_DIA":{"name":"Small Diamond","text":"This is lying, the game just treats it like a Squircle.","type":"shape"},
	"5_PLUS":{"name":"5 - Plus","text":"Reminds you of Switzerland, doesen't it?","type":"shape"},
	"3_DIAG":{"name":"3 - Diagonal","text":"A diagonal line with a length of 3.","type":"shape"},
	"3_DIAG_IN":{"name":"3 - Diagonal (Inverted)","text":"Just read the other one.","type":"shape"},
	"7_LINE":{"name":"7 - Horizontal","text":"A line with a length of 7. Line. With 7 length. Really not that complicated. You can stop reading this now. Please stop. How long will I have to keep going? Do I have to show off to get you to stop? I can spell hippopotomonstrosesquippedaliophobia. I was hoping that would be longer so you would lose interest (haha reference) but it seems to not have worked so I'm just going to make this a really long run-on sentance (did I spell that right?) you problably won't see the compatibilities, so they're: " + ", ".join(toolsCompatibility.keys().filter(func(e): return toolsCompatibility[e].has("7_LINE"))) + " just in case you needed that. This is problably where you'll not be able to read any further, so goodbye to you if so. This is a reminder that this is a line that is 7 tiles long, in case you forgot. The end. \n\n\n\n\n\n\n\n /j lol get trolled and rickrolled never gonna give you up never gonna let you down, that's all. [INSERT SECRET HERE] blah blah bl blah blah, blah bl blah bl blah, blah blah bl blah, blah blah bl blah","type":"shape"},
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
	"10_TRI":{"name":"10 - Triangle","text":"Yknow that theorem isn't actually pythagoras's","type":"shape"},
	"11_DIA":{"name":"11 - Diamond","text":"Now this is actually a diamond shape.","type":"shape"},
	"6/4_RECT":{"name":"6 by 4 - Rectangle","text":"This is actually a rectangle","type":"shape"},
	
	#"":{"name":"","text":"","type":"shape"},
	
	# Actions
	"CREEPER":{"name":"Creeper","text":"","type":"action"},
	"RESPAWN":{"name":"Respawn Point","text":"Makes a futuristic sound. Sets the point you return to.","type":"action"},
	"W":{"name":"W","text":"A huge W. Launches you high into the air.","type":"action"},
	"L":{"name":"L","text":"Not a W. Sends you down.","type":"action"},
	"ZIG":{"name":"Zig","text":"Shocking. Multiplies your speed.","type":"action"},
	"ZAG":{"name":"Zag","text":"Electrifying. Multiplies your speed.","type":"action"},
	"COMPASS":{"name":"Compass","text":"An interesting artifact, Perhaps constructed from iron, but has hints of red along with yellow. Along with this, it seems to require a great deal of effort to use. Anyway, points the way towards the center.","type":"action"},
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
	"CURRENCY_CUBICS":{"name":"Cubics","text":"Suspiciously expensive cubes","type":"action","other":["CURRENCY"]},
	"CURRENCY_AGNI":{"name":"Agni","text":"Firey stones from a fallen kingdom.","type":"action","other":["CURRENCY"]},
	"CURRENCY_DIAMONDS":{"name":"Diamonds","text":"Shiny","type":"action","other":["CURRENCY"]},
	"GODOT_COLOR":{"name":"Godot Color Scheme","text":"This is a bit familiar","type":"action"},
	"RED_PILL":{"name":"Spawned Red Pill","text":"A very basic enemy","type":"action"},
	"TRI_ENEMY":{"name":"Spawned Triangle Enemy","text":"Actually, a triangular prism...","type":"action"},
	"ZOOM_ENEMY":{"name":"Spawned Zoom Enemy","text":"It jumps much","type":"action"},
	"SMALL_BIRD":{"name":"Spawned Small Bird","text":"It flies much","type":"action"},
	"TOWER":{"name":"Tower","text":"Not very formidable","type":"action"},
	"CUBE":{"name":"Cube","text":"It's cubey","type":"action"},
	"TORCH":{"name":"Torch","text":"There is no light coming from this","type":"action"},
	"DIA_TOWER":{"name":"Diamond Tower","text":"Still not formidable","type":"action"},
	"TUT_AREA":{"name":"Tutorial Area","text":"","type":"action"},
	"TUT_AREA_2":{"name":"Tutorial Area Two","text":"","type":"action"},
	"TUT_AREA_3":{"name":"Tutorial Area Three","text":"","type":"action"},
	"RANDOM_GENERATION":{"name":"Random Generation","text":"Cool mountains","type":"action"},
	"START":{"name":"Start","text":"The start of a journey","type":"action"},
	"BLOCK":{"name":"Block","text":"That's a big block. Gives a stack of mc blocks.","type":"action","other":["MC_BLOCK"]},
	"MAZE":{"name":"Maze","text":"Solve this","type":"action"},
	"CHIP_PACK_1":{"name":"Chip Pack 1","text":"The first of many packs. Gives you 1 compatibility chip to upgrade your tools.","type":"action","other":["CHIP_PACK"]},
	"CHIP_PACK_2":{"name":"Chip Pack 2","text":"Another chip pack. Gives you 2 compatibility chips to upgrade your tools.","type":"action","other":["CHIP_PACK"]},
	"CUBIC_SALESMAN":{"name":"Cubic Salesman","text":"Barters with rather expensive cubes","type":"action"},
	"MINECRAFT_USER":{"name":"Minecraft User","text":"Gimme those shiny rocks","type":"action"},
	"STRENGTHEN_BOUNDS":{"name":"Strengthen Bounds","text":"Reinforce the walls that hold you in","type":"action"},
	
	#"":{"name":"","text":"","type":"action"},
}


func _ready() -> void:
	Archipelago.connect("connected",(func(_arg,_arg2):
		isArchipelago = true
		Archipelago.conn.deathlink.connect(recieveDeathlink)
		Archipelago.conn.connect("obtained_item",(func(e):gridRef.runShape((e.get_name()),Vector2i.ZERO,true,e)))
		Archipelago.conn.force_scout_all()
		Archipelago.set_deathlink(is_equal_approx(Archipelago.conn.slot_data["death_link"],1.0))
		allExtraPatterns = Archipelago.conn.slot_data["needed_patterns"].map(func(e): return Shape.makeStandard(Shape.fromBooleanList(Shape.binaryOrHexToBooleanList(e)))).map(Shape.allTransformations)
		))
	Archipelago.connect("disconnected",(func():isArchipelago = false))
	
	checkForErrors()
	#await get_tree().create_timer(1).timeout
	#var result = allScanningShapes(true)
	#for i in result:
		#if not result[i].has("BASE_RECT"):
			#print(i, ": ", result[i])


## A method to get the description for the pattern [param key]
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
							var regCompatibility = toolsCompatibility[key].filter(func(e): return e != "NONE")
							if not regCompatibility.is_empty():
								result += "\n\nCompatibility: " + ", ".join(regCompatibility)
							var moreCompatibility = additionalCompatibilities[key].filter(func(e): return not safeGet(unlockedCompatibilities,key,[]).has(e))
							if not moreCompatibility.is_empty():
								result += "\n\nLocked Compatibility: " + ", ".join(moreCompatibility)
						"shape":
							var regCompatibility = toolsCompatibility.keys().filter(func(e): return toolsCompatibility[e].has(key))
							if not regCompatibility.is_empty():
								result += "\n\nCompatibility: " + ", ".join(toolsCompatibility.keys().filter(func(e): return toolsCompatibility[e].has(key)))
							var moreCompatibility = additionalCompatibilities.keys().filter(func(e): return not safeGet(unlockedCompatibilities,e,[]).has(key) and additionalCompatibilities[e].has(key))
							if not moreCompatibility.is_empty():
								result += "\n\nLocked Compatibility: " + ", ".join(moreCompatibility)
						"action":
							pass
							#if shapes.has(key):
								#result += "\n\nPattern:\n" + visualize(shapes[key].pick_random())
				"other":
					for otherVal in descriptions[key][query]:
						match otherVal:
							"MC_TOOL":
								result += "\n\nMaterial: " + Globals.mcToolLevel.capitalize()
							"MC_BLOCK":
								result += "\n\nBlocks: " + str(Globals.mcBlocks) + " / " + str(64 * mcInventoryLevel)
							"CURRENCY":
								result += "\n\nAmount: " + str(currencies[key.replace("CURRENCY_","")])
							"CHIP_PACK":
								result += "\n\nCompatibility Chips: " + str(compatibilityChips)
	result = result.right(-2)
	return result


## A method to get nodes as descriptions for the pattern [param key]
func getComplexDescription(key:String) -> Array[Control]:
	var result : Array[Control] = []
	if descriptions.has(key):
		for query in descriptions[key]:
			match query:
				"type":
					match descriptions[key][query]:
						"action":
							if shapes.has(key):
								var shape = Shape.new([])
								shape.universal_format.assign(shapes[key].pick_random())
								
								var container = HBoxContainer.new()
								container.name = "PatternContainer"
								container.alignment = BoxContainer.ALIGNMENT_CENTER
								container.mouse_filter = Control.MOUSE_FILTER_IGNORE
								
								var copyButton = Button.new()
								copyButton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
								copyButton.name = "CopyButton"
								copyButton.text = "Copy\n(Ctrl C)"
								copyButton.pressed.connect(func(): cameraRef.copyShape(shape.binary_format))
								container.add_child(copyButton)
								
								var pinButton = Button.new()
								pinButton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
								pinButton.name = "PinButton"
								pinButton.text = "Pin\n(Ctrl P)"
								pinButton.pressed.connect(func(): cameraRef.pinShape(shape.binary_format))
								container.add_child(pinButton)
								
								result.append(container)
								
								var textureRect = TextureRect.new()
								textureRect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
								textureRect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
								textureRect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
								textureRect.custom_minimum_size = Vector2(100,100)
								textureRect.texture = shape.image_format
								
								result.append(textureRect)
	
	return result


## A pattern loader, loads pixels from an image given with the path [param imagePath]
static func loadPixels(imagePath:String):
	var image:Image = load(imagePath).get_image()
	if image.is_compressed(): image.decompress()
	var result = []
	for x in range(image.get_size().x):
		for y in range(image.get_size().y):
			if image.get_pixel(x,y) == Color(0,0,0,1):
				result.append(Vector2i(x,y))
	return result


## A structure loader, loads cells from a gridmap scene given with the path [param scenePath]
static func loadVoxels(scenePath:String):
	var gridmap:GridMap = load(scenePath).instantiate()
	return gridmap.get_used_cells()


## A shape loader, takes them from the shape data [param shape]
static func loadShape(shape:Dictionary) -> Array:
	var loader = preload("res://Scripts/random_generation.gd")
	return loader.makeStandard(loader.getShape(Vector3i.ZERO,shape))


## Returns the pattern as text visualization
static func visualize(pattern:Array) -> String:
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


## Tests all possible patterns
func testShapes(length:int) -> void:
	var amounts = {}
	var bitGrid = getBits(roundi(length ** 2))
	bitGrid = bitGrid.map(Shape.toCells)
	
	for i in bitGrid:
		for shape in gridRef.checkForShapes(gridRef.removeExtras(i)):
			if amounts.has(shape):
				amounts[shape] += 1
			else:
				amounts[shape] = 1
	
	print(amounts)
	print(len(amounts))


## Gets possible bit arrays
static func getBits(length:int) -> Array:
	if length <= 1: return [[false],[true]]
	
	var result = []
	for i in getBits(length - 1):
		result.append(i + [false])
		result.append(i + [true])
	return result


## Gets the max length for the shape, as in it'll return 3 if it fits in a 3 by 3 grid
func size(shape:Array) -> int:
	return [shape.map(func(e): return e.x).max(),shape.map(func(e): return e.y).max()].max() + 1


## Checks for the existance of decriptions on patterns
func checkForErrors() -> void:
	for i in shapes:
		if not descriptions.has(i) and not structureShapes.has(i) and not enemySpawnShapes.has(i):
			printerr("No description for " + i)


## Returns all action names
func getActions() -> Array:
	return descriptions.keys().filter(
		func(e): 
			if descriptions[e].has("type"): return descriptions[e].type == "action"
			else: return e == "CAR")


## Gets your name in archipelago
func archipelagoName() -> String:
	return Archipelago.conn.get_player().get_name() if Globals.isArchipelago else ""


## Resets the grid when you fall off
func reset(trueDeath:bool=(not playerRef.get_parent().get_node("Bounds").get_overlapping_bodies().has(playerRef)),fromDeathlink:=false) -> void:
	if trueDeath:
		var deathCause = deathlinkMessages.pick_random() % archipelagoName()
		for i in playerRef.get_parent().get_node("StructureParent").get_children():
			i.queue_free()
		respawnPoint = Vector3(0,2,0)
		gridRef.clear()
		for x in range(3):
			for y in range(3):
				gridRef.set_cell_item(Vector3i(x-1,0,y-1),0)
		for i in shapes["START"][0]:
			gridRef.set_cell_item(Vector3i(i.x-1,0,i.y-1),1)
		if isArchipelago and not fromDeathlink and Archipelago.is_deathlink(): Archipelago.conn.send_deathlink(deathCause)
	playerRef.position = Globals.respawnPoint
	playerRef.velocity = Vector3(0,0,0)
	playerRef.strength = 0.0


## Recieves the deathlink and resets the player
func recieveDeathlink(_source:String,cause:String,_json:Dictionary) -> void:
	reset(true,true)
	gridRef.trigger_popup("Archipelago Deathlink: " + cause,gridRef.scanTypes.ARCHIPELAGO_DEATHLINK)


## Returns the max size of the pattern
func maxLength(list:Array) -> int:
	var result = list[0].x
	for i in list:
		if i.x > result: result = i.x
		if i.y > result: result = i.y
	return result


## Saves the game to a [param slot]
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


## Loads the game from a [param slot]
func loadSlot(slot:int) -> void:
	if not DirAccess.dir_exists_absolute("user://Data/"): DirAccess.make_dir_absolute("user://Data/")
	if not FileAccess.file_exists("user://Data/save"+str(slot)+".dat"): FileAccess.open("user://Data/save"+str(slot)+".dat",FileAccess.WRITE)
	var file = FileAccess.open("user://Data/save"+str(slot)+".dat",FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	for i in data:
		if i in self:
			#print(data[i])
			set(i,data[i])
			#print(get(i))
	currentSlot = slot
	cameraRef.updateSaves()


## Converts the [param list] to a [Dictionary] using the [param function] on each key
func toDictionary(function:Callable,list:Array) -> Dictionary:
	var result = {}
	for i in list:
		result[i] = function.call(i)
	return result


## Safely gets the value of [param key] in the [param dictionary]
static func safeGet(dictionary:Dictionary,key,fallback,setValue:=false):
	if not dictionary.has(key):
		if setValue:
			dictionary[key] = fallback
		else:
			return fallback
	return dictionary[key]


## Returns true if [param array] has all of the values in [param all]
static func arrayHasAll(array:Array,all:Array) -> bool:
	for i in all:
		if not array.has(i): return false
	return true


## Checks if the given [param pattern] can fit (in any transformation) inside of [param shape].
func canPatternFit(shape:Array,pattern:Array) -> bool:
	if shape.is_empty(): return false
	if pattern.is_empty(): return false
	
	var typedShape: Array[Vector2i] = []
	typedShape.assign(shape)
	shape = Shape.makeStandard(typedShape)
	var shapeSize = Vector2i(shape.map(func(e): return e.x).max(),shape.map(func(e): return e.x).min()) + Vector2i.ONE
	
	for i in Shape.allTransformations(pattern, true, shapeSize):
		if arrayHasAll(shape,i):
			return true
	return false


## Gets all the [member allToolShapes] that [param pattern] can fit into.
func getScanningShapes(pattern:Array) -> Array:
	return allToolShapes.keys().filter(func(e): return canPatternFit(gridRef.getShape(Vector3i.ZERO,allToolShapes[e]), pattern))


## Returns all shapes that each pattern in [member shapes] can fit into.
func allScanningShapes(noActions := false) -> Dictionary:
	var result = {}
	var actions = getActions()
	for pattern in shapes.keys().filter(func(e): return not noActions or not actions.has(e)):
		result[pattern] = getScanningShapes(shapes[pattern][0])
	return result


class Shape extends Resource: ## Class for pattern format changes and manipulation
	
	## Data in universal format (the base that the game uses most), an array of 2d coordinates that are filled
	var universal_format:Array[Vector2i]:
		set(value):
			pattern_name_format = ""
			universal_format = value
	
	## Data as a binary string, going from top to bottom then left to right
	var binary_format:String:
		set(value):
			universal_format = []
			universal_format.assign(fromBooleanList(binaryOrHexToBooleanList(value)))
		get():
			return shapeToBinary(universal_format)
	
	## Data as a hexadecimal string (starting with 0x) and is a compressed version of [member binary_format]
	var hexadecimal_format:String:
		set(value):
			universal_format = []
			universal_format.assign(fromBooleanList(binaryOrHexToBooleanList(value)))
		get():
			return binaryToHex(shapeToBinary(universal_format))
	
	## Data as an image
	var image_format:ImageTexture:
		set(value):
			universal_format = []
			universal_format.assign(decodeImage(value))
		get():
			return getImageFromList(universal_format)
	
	## Data as the pattern name in [member Globals.shapes]
	var pattern_name_format:String:
		set(value):
			if value != "":
				universal_format = []
				if Globals.shapes.has(value):
					var typedValue : Array[Vector2i]
					typedValue.assign(Globals.shapes[value][0])
					universal_format = makeStandard(typedValue)
			pattern_name_format = value
		get():
			if pattern_name_format == "":
				for shape in Globals.shapes:
					if Globals.shapes[shape].has(makeStandard(universal_format)):
						pattern_name_format = shape
						break
			return pattern_name_format
	
	## Data as an icon image
	var icon_format:ImageTexture:
		set(value):
			universal_format = []
			universal_format.assign(decodeImage(value,false,Color.WHITE,value.get_image().get_pixel(0,0),Color.DARK_GRAY,1))
		get():
			var backgroundColor := Color(0.08,0.08,0.08)
			if pattern_name_format != "":
				if Globals.tools.has(pattern_name_format):
					var library:MeshLibrary = preload("res://Sprites/MeshLibraries/OutlinerMeshLibrary.tres")
					backgroundColor = (library.get_item_mesh(Globals.tools[pattern_name_format]).surface_get_material(0).albedo_color)
					backgroundColor.a = 1
					backgroundColor.v -= 0.2
			return getImageFromList(universal_format,false,Color.WHITE,backgroundColor,Color.DARK_GRAY,1)
	
	
	func _init(value:Array[Vector2i]) -> void:
		universal_format = value
	
	
	## Rotates the points (in [member universal_format]), with [param clockwise] defining the direction
	static func rotatePoints(points:Array[Vector2i],clockwise:=true) -> Array[Vector2i]:
		var result:Array[Vector2i] = []
		
		for i in points:
			result.append(Vector2i(i.y,-i.x) if clockwise else Vector2i(-i.y,i.x))
		
		return makeStandard(result)
	
	
	## Standardizes the [param list] (in [member universal_format]) to make sure it can be recognised
	static func makeStandard(list:Array) -> Array[Vector2i]:
		if list.is_empty(): return []
		var mins = list[0]
		for i in list:
			if i.x < mins.x:
				mins.x = i.x
			if i.y < mins.y:
				mins.y = i.y
		
		var modified:Array[Vector2i] = []
		modified.assign(list.map(func(e): return e - mins))
		modified.sort()
		return modified
	
	
	## Encodes the [param shape] (in [member universal_format]) to [member binary_format]
	static func shapeToBinary(shape:Array) -> String:
		if shape.is_empty(): return ""
		var result = ""
		
		shape = makeStandard(shape)
		
		var maxVector = Vector2i(
			shape.map(func(e): return e.x).max() + 1,
			shape.map(func(e): return e.y).max() + 1
		)
		
		for x in range([maxVector.x,maxVector.y].max()):
			for y in range([maxVector.x,maxVector.y].max()):
				result += "1" if shape.has(Vector2i(x,y)) else "0"
		
		return result
	
	
	## Converts the [param binary] to hexadecimal
	static func binaryToHex(binary:String) -> String:
		return "0x" + String.num_int64(binary.bin_to_int(),16)
	
	
	## Converts the [param string] (in either [member binary_format] or [member hexadecimal_format]) to a binary list
	static func binaryOrHexToBooleanList(string:String) -> Array[bool]:
		var result:Array[bool] = []
		
		if string.left(2) == "0x":
			string = String.num_int64(string.hex_to_int(),2)
		
		if string.left(2) == "0b":
			string = string.right(-2)
		
		if Array(string.split("")).filter(func(e): return e != "1" and e != "0").is_empty():
			for i in string.split(""):
				result.append(i == "1")
		#else:
			#string.to_utf8_buffer()
		
		return result
	
	
	## Converts a binary [param list] to [member universal_format].
	static func fromBooleanList(list:Array[bool]) -> Array[Vector2i]:
		var cellsResult = toCells(list)
		var result:Array[Vector2i]
		result.assign(cellsResult.keys().filter(func(e): return cellsResult[e] == 1))
		return result
	
	
	## Converts a binary [param list] to a [Dictionary] of the coords to the value
	static func toCells(list:Array[bool]) -> Dictionary:
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
	
	
	## Converts [member universal_format] to [member image_format], [member icon_format], or a custom other image format
	static func getImageFromList(shapePoints:Array[Vector2i], addOutlines:=true, baseColor:=Color.WHITE, backgroundColor:=Color.TRANSPARENT, outlineColor:=Color.DARK_GRAY, iconRingSize:=0) -> ImageTexture:
		if shapePoints.is_empty(): return ImageTexture.new()
		
		var maxVector = Vector2i(shapePoints.map(func(e): return e.x).max() + 1,shapePoints.map(func(e): return e.y).max() + 1)
		if addOutlines: maxVector *= 10
		
		var image := Image.create_empty(maxVector.x,maxVector.y,false,Image.Format.FORMAT_RGBA8)
		
		if addOutlines:
			for i in shapePoints:
				for x in range(10):
					for y in range(10):
						image.set_pixelv(Vector2i(i*10)+Vector2i(x,y),baseColor if (x < 9) and (y < 9) else outlineColor)
		else:
			for i in shapePoints:
				image.set_pixelv(Vector2i(i),baseColor)
		
		if backgroundColor != Color.TRANSPARENT:
			var backgroundImage := Image.create_empty(maxVector.x+(iconRingSize*2),maxVector.y+(iconRingSize*2),false,Image.Format.FORMAT_RGBA8)
			backgroundImage.fill(backgroundColor)
			var foregroundImage = image.duplicate_deep()
			backgroundImage.blend_rect(foregroundImage,Rect2i(Vector2i.ZERO,foregroundImage.get_size()),Vector2i(iconRingSize,iconRingSize))
			image = backgroundImage.duplicate_deep()
		
		return ImageTexture.create_from_image(image)
	
	
	## Decodes an [member image_format] or [member icon_format] to [member universal_format]
	static func decodeImage(imageTexture:ImageTexture, usingOutlines:=true, baseColor:=Color.WHITE, _backgroundColor:=Color.TRANSPARENT, _outlineColor:=Color.DARK_GRAY, iconRingSize:=0) -> Array[Vector2i]:
		var image:Image = imageTexture.get_image()
		var outlineMultiplier = 10 if usingOutlines else 1
		if image.is_compressed(): image.decompress()
		var result:Array[Vector2i] = []
		@warning_ignore("integer_division")
		for x in range(image.get_size().x / outlineMultiplier):
			@warning_ignore("integer_division")
			for y in range(image.get_size().y / outlineMultiplier):
				if image.get_pixel(x * outlineMultiplier + iconRingSize, y * outlineMultiplier + iconRingSize) == baseColor:
					result.append(Vector2i(x,y))
		return result
	
	
	## Returns all rotations and reflections of [param shape]
	static func allTransformations(shape:Array, translate := false, maxes := Vector2i.ZERO) -> Array[Array]:
		var possibleShapes:Array[Array] = [shape]
		
		#Rotations
		possibleShapes.append(makeStandard(shape.map(func(e): return Vector2i(-e.y,e.x))))
		possibleShapes.append(makeStandard(shape.map(func(e): return Vector2i(-e.x,-e.y))))
		possibleShapes.append(makeStandard(shape.map(func(e): return Vector2i(e.y,-e.x))))
		
		for reflectedShape in possibleShapes.duplicate(true):
			#Reflections
			possibleShapes.append(makeStandard(reflectedShape.map(func(e): return Vector2i(-e.x,e.y))))
			possibleShapes.append(makeStandard(reflectedShape.map(func(e): return Vector2i(e.x,-e.y))))
			possibleShapes.append(makeStandard(reflectedShape.map(func(e): return Vector2i(-e.x,-e.y))))
		
		if translate:
			for currentShape in possibleShapes.duplicate(true):
				possibleShapes.append_array(allTranslations(currentShape,maxes))
		
		return possibleShapes
	
	static func allTranslations(shape: Array, maxes: Vector2i) -> Array[Array]:
		if maxes == Vector2i.ZERO: return [shape]
		if shape.is_empty(): return [[]]
		
		var result: Array[Array] = []
		var typedShape: Array[Vector2i] = []
		typedShape.assign(shape)
		#shape = makeStandard(typedShape)
		var shapeSize = Vector2i(shape.map(func(e): return e.x).max(),shape.map(func(e): return e.x).min()) + Vector2i.ONE
		
		for x in range(maxes.x - shapeSize.x):
			for y in range(maxes.y - shapeSize.y):
				result.append(shape.map(func(e): return e + Vector2i(x,y)))
		
		return result
