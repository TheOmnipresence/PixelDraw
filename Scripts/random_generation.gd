extends GridMap

## Time (in seconds) that popups stay on screen
const popupTime:=2

## The colors that popup text can have, for every item in [enum popupTypes]
const popupColors = {
	popupTypes.TOOL:Color(1.0, 0.0, 0.0, 1.0),
	popupTypes.SHAPE:Color(0.0, 0.0, 1.0, 1.0),
	popupTypes.ACTION:Color(0.0, 1.0, 0.0, 1.0),
	popupTypes.OTHER:Color(0.2,0.2,0.2),
	popupTypes.ARCHIPELAGO_SEND:Color(1,0.735,0,1),
	popupTypes.ARCHIPELAGO_GOAL:Color(0.73,0.535,0,1),
	popupTypes.ARCHIPELAGO_DEATHLINK: Color(1.0, 1.0, 0.0, 1.0),
	popupTypes.STATUS_EFFECT:Color(0.735,0,1,1)
}

## The types of popup you cen recieve
enum popupTypes {
	TOOL, ## When you scan a new tool
	SHAPE, ## When you scan a new shape
	ACTION, ## When you scan a new action
	OTHER, ## Other things, or when you scan an action you have already discovered
	ARCHIPELAGO_SEND, ## When you find an Archipelago item
	ARCHIPELAGO_GOAL, ## When you goal in Archipelago
	ARCHIPELAGO_DEATHLINK, ## When you recieve a deathlink
	STATUS_EFFECT ## Unused
}

## The last pattern scanned, used for [enum Globals.tools].STAMPER
var lastScanned = []

## The cells currently lighted from [enum Globals.tools].BULB
var bulbCells = {}

## The cells currently being mined from [enum Globals.tools].MC_PICK
var pickaxeCells = []

## If currently mining blocks
var miningBlocks := false

## The center point of the plane
var planeOrigin = Vector3i.ZERO


func _ready() -> void:
	var duplicatedShapes = Globals.shapes.duplicate(true)
	
	for i in duplicatedShapes:
		for possibleShape in duplicatedShapes[i]:
			#Rotations
			Globals.shapes[i].append(makeStandard(possibleShape.map(func(e): return Vector2i(-e.y,e.x))))
			Globals.shapes[i].append(makeStandard(possibleShape.map(func(e): return Vector2i(-e.x,-e.y))))
			Globals.shapes[i].append(makeStandard(possibleShape.map(func(e): return Vector2i(e.y,-e.x))))
	
	duplicatedShapes = Globals.shapes.duplicate(true)
	
	for i in duplicatedShapes:
		for possibleShape in duplicatedShapes[i]:
			#Reflections
			Globals.shapes[i].append(makeStandard(possibleShape.map(func(e): return Vector2i(-e.x,e.y))))
			Globals.shapes[i].append(makeStandard(possibleShape.map(func(e): return Vector2i(e.x,-e.y))))
			Globals.shapes[i].append(makeStandard(possibleShape.map(func(e): return Vector2i(-e.x,-e.y))))
	
	Globals.gridRef = self


func _process(_delta: float) -> void:
	if Input.is_action_just_released("mouse1") or Input.is_action_just_released("mouse3"):
		$"../GridMapOutline".clear()
	if Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z) != planeOrigin or Input.is_action_pressed("mouse3") or Input.is_action_pressed("mouse1"):
		planeOrigin = Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z)
		
		if Input.is_action_pressed("mouse3"):
			$"../GridMapOutline".clear()
			for i in heighestVisibleCells(getShape(planeOrigin,Globals.toolShapes[Globals.currentTool])):
				i.y += 1
				$"../GridMapOutline".set_cell_item(i,Globals.currentTool)
		elif Input.is_action_pressed("mouse1"):
			$"../GridMapOutline".clear()
			for i in heighestVisibleCells(getShape(planeOrigin,Globals.baseShape)):
				i.y += 1
				$"../GridMapOutline".set_cell_item(i,0)
	
	if Input.is_action_just_released("mouse3"):
		var cells = getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool])
		match Globals.currentTool:
			Globals.tools.VOIDER:
				for i in cells:
					set_cell_item(vector2to3(i),0)
			Globals.tools.ERASER:
				for i in cells:
					set_cell_item(vector2to3(i),1)
			Globals.tools.C_GOL:
				var cellValues = {}
				for i in cells:
					var neighborValues = getShape(vector2to3(i),{"type":Globals.types.RECT,"x":3,"y":3})
					neighborValues = neighborValues.filter(func(e): return e != i)
					neighborValues = neighborValues.map(func(e): return get_cell_item(Vector3i(e.x,0,e.y)))
					neighborValues = neighborValues.filter(func(e): return e == 1)
					if len(neighborValues) < 2:
						cellValues[vector2to3(i)] = 0
					elif len(neighborValues) > 3:
						cellValues[vector2to3(i)] = 0
					elif len(neighborValues) == 3:
						cellValues[vector2to3(i)] = 1
				for i in cellValues:
					set_cell_item(i,cellValues[i])
			Globals.tools.RAISER:
				for i in cells:
					if get_cell_item(vector2to3(i)) == 1:
						var coords = Vector3i(i.x,clamp(local_to_map(Vector3(0,floor(Globals.playerRef.position.y-1),0)).y,0,20),i.y)
						if get_cell_item(coords) == -1: set_cell_item(coords,2)
			Globals.tools.LEVELER:
				for i in cells:
					for yLevel in range(1,21):
						if get_cell_item(Vector3i(i.x,yLevel,i.y)) == 2:
							set_cell_item(Vector3i(i.x,yLevel,i.y),-1)
			Globals.tools.DUSTER:
				for i in cells:
					var neighborValues = getShape(vector2to3(i),{"type":Globals.types.SQUIRCLE,"x":3,"y":3})
					neighborValues = neighborValues.map(func(e): return get_cell_item(Vector3i(e.x,0,e.y)))
					neighborValues = neighborValues.filter(func(e): return e == 1)
					if len(neighborValues) < 2:
						set_cell_item(vector2to3(i),0)
			Globals.tools.SHUFFLER:
				var values = []
				for i in cells:
					values.append(get_cell_item(vector2to3(i)))
				values.shuffle()
				for i in range(len(cells)):
					set_cell_item(vector2to3(cells[i]),values[i])
			Globals.tools.STOPPER:
				for i in getShape(Vector3i(local_to_map(Globals.playerRef.position).x + (5 if Globals.playerRef.velocity.x >= 10 else (-5 if Globals.playerRef.velocity.x <= -10 else 0)),0,local_to_map(Globals.playerRef.position).z + (5 if Globals.playerRef.velocity.z >= 10 else (-5 if Globals.playerRef.velocity.z <= -10 else 0))),Globals.toolShapes[Globals.currentTool]):
					if get_cell_item(vector2to3(i)) == 1:
						set_cell_item(Vector3i(i.x,clamp(local_to_map(Vector3(0,ceil(Globals.playerRef.position.y)-1,0)).y,0,Globals.maxHeight),i.y),1)
			Globals.tools.BULB:
				for i in cells:
					bulbCells[vector2to3(i)] = get_cell_item(vector2to3(i))
					set_cell_item(vector2to3(i), 1)
					$BulbTimer.start()
			Globals.tools.MC_PICK:
				cells = cells.filter(func(e): return get_cell_item(Vector3i(e.x,0,e.y)) == 1)
				pickaxeCells += cells
			Globals.tools.HOOK:
				cells = cells.map(func(e): return Vector3i(e.x,2,e.y))
				for enemy:Node3D in get_parent().get_children().filter(func(e): return e.is_in_group("enemy")):
					if cells.has(local_to_map(enemy.position)): 
						enemy.velocity = enemy.position.direction_to(Globals.playerRef.position) * 100
						enemy.position.lerp(Globals.playerRef.position,0.99)
			Globals.tools.BASE_SW:
				hitEnemy(5)
			Globals.tools.PLACER:
				for i in cells:
					if Globals.mcBlocks <= 0:
						break
					elif get_cell_item(vector2to3(i)) == 0:
						Globals.mcBlocks -= 1
						set_cell_item(vector2to3(i),1)
			Globals.tools.STAMPER:
				for i in cells:
					if lastScanned.has(makeStandard(cells)[cells.find(i)]):
						set_cell_item(vector2to3(i),1)
			Globals.tools.GRAVITATE:
				cells = cells.map(func(e): return Vector3i(e.x,2,e.y))
				for enemy:Node3D in get_parent().get_children().filter(func(e): return e.is_in_group("enemy")):
					if cells.has(local_to_map(enemy.position)): 
						enemy.get_node("AntigravityTimer").start()
				multiplyAttribute("gravity",["*",-1],5)
			Globals.tools.SUMMON:
				for enemy:Node3D in get_parent().get_children().filter(func(e): return e.is_in_group("enemy")):
					if cells.has(Vector2i(local_to_map(enemy.position).x,local_to_map(enemy.position).z)): 
						enemy.position.y = 1
			Globals.tools.TERRAIN:
				heightGeneration(cells)
			Globals.tools.PARALYZER:
				for enemy:Node3D in get_parent().get_children().filter(func(e): return e.is_in_group("enemy")):
					if cells.has(Vector2i(local_to_map(enemy.position).x,local_to_map(enemy.position).z)): 
						enemy.paralyze(3)
			Globals.tools.PLATFORM:
				for cell in cells:
					set_cell_item(Vector3i(cell.x,0,cell.y),randi_range(0,1))
			Globals.tools.PLAGUE:
				var cellValues = {}
				for cell in cells:
					var neighborValues = getShape(vector2to3(cell),{"type":Globals.types.RECT,"x":3,"y":3})
					neighborValues = neighborValues.filter(func(e): return e != cell)
					neighborValues = neighborValues.map(func(e): return get_cell_item(Vector3i(e.x,0,e.y)))
					neighborValues = neighborValues.filter(func(e): return e == 0)
					cellValues[vector2to3(cell)] = 0 if len(neighborValues) > 3 else get_cell_item(vector2to3(cell))
				for i in cellValues:
					set_cell_item(i,cellValues[i])
			Globals.tools.MAZER:
				makeMaze(roundi(Globals.allToolShapes[Globals.toolShapes[Globals.currentTool]].x / 2.0),Vector3i(roundi(Globals.playerRef.position.x - 1),0,roundi(Globals.playerRef.position.z - 1)))
	
	if Input.is_action_just_released("mouse1"):
		var result = {}
		for i in getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.baseShape):
			result[i] = (get_cell_item(vector2to3(i)))
		checkForShapes(removeExtras(result))
	
	if Input.is_action_just_pressed("mouse2"):
		for i in Globals.toolsCompatibility:
			runShape(i)
		for i in Globals.allToolShapes:
			runShape(i)
		Globals.mcToolLevel = "NETHERITE"
		if Input.is_action_pressed("plr_shift"):
			for i in Globals.getActions():
				runShape(i)
			giveCurrency("DIAMONDS",100)
	
	if not miningBlocks and not pickaxeCells.is_empty():
		updatePickaxeBlocks()


func updatePickaxeBlocks() -> void:
	miningBlocks = true
	var speed = 0
	match Globals.mcToolLevel:
		"WOOD":
			speed = 1.15
		"STONE":
			speed = 0.6
		"IRON":
			speed = 0.4
		"DIAMOND":
			speed = 0.3
		"NETHERITE":
			speed = 0.25
		"GOLD":
			speed = 0.2
			Globals.mcToolLevel = "WOOD"
	#speed *= len(cells)
	while not pickaxeCells.is_empty():
		var i = pickaxeCells.pick_random()
		$McPickaxe.start(speed)
		await $McPickaxe.timeout
		Globals.mcBlocks += 1
		set_cell_item(vector2to3(i),0)
		pickaxeCells.erase(i)
	miningBlocks = false


## Returns the heighest cells lower than the player at the coords of [param list]
func heighestVisibleCells(list:Array) -> Array:
	list = list.map(func(e): return vector2to3(e,getHeighestCell(e,roundi(Globals.playerRef.position.y -1))))
	return list


## Builds the starting cells
func startCells():
	var grid := GridMap.new()
	grid.mesh_library = preload("res://Sprites/MeshLibraries/MeshLibrary.tres")
	for x in range(-100,100):
		for z in range(-100,100):
			grid.set_cell_item(Vector3i(x,0,z),randi_range(0,1))
	
	buildCells(grid.get_used_cells(),Vector3.ZERO,true,grid)
	if Globals.isMultiplayer: rpc("buildCells",Vector3.ZERO,true,grid)


## Finds the groups of cells from [param input]
func removeExtras(input:Dictionary) -> Dictionary:
	lastScanned = []
	var map := AStar2D.new()
	for coords in input:
		if input[coords] == 1:
			map.add_point(input.keys().find(coords),coords)
	for coords in input:
		if input[coords] == 1:
			lastScanned.append(coords)
			for i in getShape(Vector3(coords.x,0,coords.y),{"type":Globals.types.RECT,"x":3,"y":3}):
				if i == coords: continue
				if not input.has(i): continue
				if input[i] == 0: continue
				if map.has_point(input.keys().find(coords)) and map.has_point(input.keys().find(i)):
					map.connect_points(input.keys().find(coords),input.keys().find(i))
	
	lastScanned = makeStandard(lastScanned)
	
	var groups = {}
	for i in input:
		if input[i] == 0: continue
		var connections = getAllConnections(map,[],input,i)
		var add = true
		for group in groups.values():
			if sorted(group) == sorted(connections):
				add = false
		if add and not connections.is_empty(): groups[Vector2i(connections.map(func(e): return e.x).min(),connections.map(func(e): return e.y).min()) + Vector2i(1,1)] = (makeStandard(sorted(connections)))
	
	return groups


## Runs [method scanShape] on each identifiable group in [param groups]. Also handles completion shape and extra patterns for archipelago.
func checkForShapes(groups:Dictionary) -> Array:
	var result = []
	var hasShape = []
	for group in groups.values().duplicate_deep():
		if group.is_empty(): continue
		for shape in Globals.shapes:
			if Globals.shapes[shape].has(group) and groups.values().has(group):
				scanShape(groups.find_key(group),shape,group)
				hasShape.append(group)
				result.append(shape)
		if hasShape.has(group): groups.erase(groups.find_key(group))
		if Globals.isArchipelago:
			if Archipelago.conn.slot_data["completion_shape"] != "":
				if Globals.Shape.allTransformations(Globals.Shape.fromBooleanList(Globals.Shape.binaryOrHexToBooleanList(Archipelago.conn.slot_data["completion_shape"]))).has(group): tryFinish(true)
			
			for pattern in Globals.allExtraPatterns:
				if pattern.has(group):
					Globals.extraPatternsFound.append(Globals.allExtraPatterns.find(pattern))
					tryFinish()
	
	if not groups.values().is_empty():
		for i in groups.values():
			result.append(i)
		printerr(groups.values())
	return result


## Converts a [Vector2] to a [Vector3]
static func vector2to3(vector,yPos=0):
	if typeof(vector) == TYPE_VECTOR2:
		return Vector3(vector.x,float(yPos),vector.y)
	else:
		return Vector3i(vector.x,yPos,vector.y)


## Runs [method runShape] on a shape
func scanShape(pos:Vector2i,shape:String,group:Array) -> void:
	group = group.map(func(e): return vector2to3(e + pos,0))
	await lightShape(group,0,false)
	runShape(shape,pos)
	await get_tree().create_timer(0.2).timeout
	await lightShape(group,-1,false)


## Highlights the [param cells] on the gridmap
func lightShape(cells,value:int,wait:=true) -> void:
	if wait: await get_tree().create_timer(randf_range(0.3,0.9)).timeout
	
	for i in cells:
		$"../ActivationGridMap".set_cell_item(i,value)


#INFO very important
## Gives you a tool or shape or runs an action 
func runShape(shape:String,center:Vector2i=Vector2i.ZERO,calledFromArchipelago:=false,archipelagoInfo:NetworkItem=NetworkItem.new()):
	print(shape)
	
	if Globals.isArchipelago and not Globals.startedArchipelago and not calledFromArchipelago:
		Globals.startedArchipelago = true
	
	if Globals.tools.keys().has(shape):
		if Globals.isArchipelago and not calledFromArchipelago:
			sendArchipelagoItem(Globals.toolsCompatibility.keys().find(shape),shape)
		else:
			if not Globals.availibleTools.has(Globals.tools.keys().find(shape) as Globals.tools):
				Globals.availibleTools.append(Globals.tools.keys().find(shape) as Globals.tools)
				Globals.toolShapes[(Globals.tools.keys().find(shape) as Globals.tools)] = "NONE"
				var gridPanel = preload("res://Scenes/grid_panel.tscn").instantiate()
				gridPanel.get_child(0).text = shape
				Globals.cameraRef.get_child(0).get_node("SetupTab").get_node("ToolsGrid").add_child(gridPanel)
				
				trigger_popup("New Tool: " + shape + ("" if not Globals.isArchipelago else " From: " + Archipelago.conn.get_player_name(archipelagoInfo.src_player_id)),popupTypes.TOOL)
	elif Globals.allToolShapes.has(shape):
		if Globals.isArchipelago and not calledFromArchipelago:
			sendArchipelagoItem(Globals.allToolShapes.keys().find(shape) + 1000,shape)
		else:
			if not Globals.availibleShapes.has(shape):
				Globals.availibleShapes.append(shape)
				trigger_popup("New Shape: " + shape + ("" if not Globals.isArchipelago else " From: " + Archipelago.conn.get_player_name(archipelagoInfo.src_player_id)),popupTypes.SHAPE)
	elif Globals.UPGRADES.has(shape):
		match shape:
			"MC_INVENTORY":
				Globals.mcInventoryLevel += 1
	elif Globals.enemySpawnShapes.has(shape):
		if not Globals.actionsScanned.has(shape):
			add_action(shape)
			trigger_popup("New Action Triggered: SPAWNED_" + shape,popupTypes.ACTION)
		
		var pos = map_to_local(local_to_map(Globals.playerRef.position))
		summonEnemy(pos,shape)
		if Globals.isMultiplayer:
			rpc("summonEnemy",pos,shape)
	elif Globals.structureShapes.keys().has(shape):
		
		match shape:
			"RANDOM_GENERATION":
				var cells = await heightGeneration(getShape(Vector3i.ZERO,"200_SQR"))
				buildCells(cells,Vector3(0,0,0),false,null,true)
				if Globals.isMultiplayer:
					rpc("buildCells",cells,Vector3(0,0,0),false,null,true)
			"START":
				startCells()
			_:
				var cells = Globals.structureShapes[shape].duplicate()
				var playerPos = map_to_local(Vector3i(center.x,0,center.y))
				var isComplexStructure = Globals.complexStructures.has(shape)
				var structureGrid = null
				
				if isComplexStructure:
					structureGrid = load(Globals.complexStructures[shape]).instantiate()
					
					playerPos += structureGrid.position
					
					for i in structureGrid.get_children():
						structureGrid.remove_child(i)
						get_parent().get_node("StructureParent").add_child(i)
						var pos = local_to_map(playerPos)
						pos.y = 0
						pos = map_to_local(pos)
						i.position += pos
				
				buildCells(cells,playerPos,isComplexStructure,shape)
				if Globals.isMultiplayer:
					rpc("buildCells",cells,playerPos,isComplexStructure,shape)
		
		if not Globals.actionsScanned.has(shape):
			add_action(shape)
			trigger_popup("New Action Triggered: BUILT_" + shape,popupTypes.ACTION)
	elif Globals.colorShapes.has(shape):
		setColor(shape)
		if not Globals.actionsScanned.has(shape):
			add_action(shape)
			trigger_popup("New Action Triggered: COLORED_" + shape,popupTypes.ACTION)
	elif shape.contains("DEFEAT_"):
		if Globals.isArchipelago and not calledFromArchipelago and Globals.enemySpawnShapes.has(shape.replace("DEFEAT_","")):
			if Archipelago.conn.slot_data["randomize_enemy_deaths"]: sendArchipelagoItem(Globals.enemySpawnShapes.find(shape.replace("DEFEAT_","")) + 2000,shape)
	elif Globals.SALESMEN.has(shape):
		if not Globals.actionsScanned.has(shape):
			add_action(shape)
		trigger_popup("New Action Triggered: SUMMONED_" + shape,popupTypes.ACTION)
		for i in Globals.cameraRef.get_node("%Salesmen").get_children():
			if i.summoner == shape:
				i.setup()
				break
	else:
		if not Globals.actionsScanned.has(shape) and not (shape == "RANDOM_ACTION" or shape == "RANDOM_ENEMY"):
			add_action(shape)
			trigger_popup("New Action Triggered: " + shape,popupTypes.ACTION)
		else:
			trigger_popup("Action Triggered: " + shape,popupTypes.OTHER)
		match shape:
			var x when x.left(10) == "CHIP_PACK_":
				if not Globals.isArchipelago:
					Globals.compatibilityChips += Globals.chipPackAmounts[int(x.right(-10)) - 1]
					Globals.chipPackAmounts[int(x.right(-10)) - 1] = 0
				elif calledFromArchipelago:
					Globals.compatibilityChips += 1
				else:
					var chipsBefore := 0
					for i in Globals.chipPackAmounts.slice(0, int(x.right(-10)) - 1):
						chipsBefore += i
					
					for i in range(Globals.chipPackAmounts[int(x.right(-10)) - 1]):
						sendArchipelagoItem(i + chipsBefore + 3000, shape + "-" + str(i + 1))
			"COMPATIBILITY_CHIP":
				if Globals.isArchipelago and calledFromArchipelago:
					Globals.compatibilityChips += 1
			"CREEPER":
				for i:SpotLight3D in $"../Biomes".get_children():
					i.light_color = Color(randf_range(0.0,1.0),randf_range(0.0,1.0),randf_range(0.0,1.0))
					i.visible = true
			"RESPAWN":
				Globals.respawnPoint = Globals.playerRef.position
			"W":
				Globals.playerRef.velocity.y += 20
			"L":
				Globals.playerRef.velocity.y -= 20
			"ZIG":
				Globals.playerRef.velocity *= 10
			"ZAG":
				Globals.playerRef.velocity *= 20
			"COMPASS":
				var cells = getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),"BASE_RECT")
				
				var chosenCell = cells[0]
				for i:Vector2i in cells:
					if vectorMin(i,chosenCell) == i:
						chosenCell = i
				
				for i in cells:
					set_cell_item(vector2to3(i),1)
				
				set_cell_item(Vector3i(chosenCell.x,0,chosenCell.y),0)
			"SENDER":
				Globals.playerRef.savedVelocity = - ((Globals.playerRef.position - (Globals.respawnPoint)).normalized() * 20)
			"UNSENDER":
				Globals.playerRef.savedVelocity = ((Globals.playerRef.position - (Globals.respawnPoint)).normalized() * 20)
			"GROUNDER":
				Globals.playerRef.velocity = Vector3(0,0,0)
			"STONE":
				if Globals.mcToolLevel == "WOOD":
					Globals.mcToolLevel = "STONE"
			"IRON":
				if Globals.mcToolLevel == "STONE":
					Globals.mcToolLevel = "IRON"
			"GOLD":
				if Globals.mcToolLevel == "IRON":
					Globals.mcToolLevel = "GOLD"
			"DIAMOND":
				if Globals.mcToolLevel == "GOLD" or Globals.mcToolLevel == "IRON":
					Globals.mcToolLevel = "DIAMOND"
				newCurrency("DIAMONDS",8.0)
			"NETHERITE":
				if Globals.mcToolLevel == "DIAMOND":
					Globals.mcToolLevel = "NETHERITE"
			"SMALL_SPEED":
				multiplyAttribute("speed",["+",2],10)
			"NO":
				Globals.playerRef.position.y = -1
			"THUMB":
				if randi_range(0,1) == 0:
					multiplyAttribute("speed",["/",3],4)
				else:
					multiplyAttribute("speed",["*",3],4)
			"DOT":
				if not Globals.playerRef.get_node("CeilRay").is_colliding(): Globals.playerRef.position.y += 1
			"L_HA":
				multiplyAttribute("speed",["/",4],6)
			"CHAIR":
				Globals.playerRef.sitting = not Globals.playerRef.sitting
			"CROWN":
				hitEnemy(3,"16_SQR")
			"6_PACK":
				Globals.playerRef.strength += 0.5
			"SUMMON_BIRDS":
				for i in get_parent().get_children().filter(func(e): return e.is_in_group("enemy")):
					i.position.y = 1
			"WALKING_PERSON":
				Globals.playerRef.strength += 0.25
				multiplyAttribute("speed",["*",1.5],8)
			"TEA":
				Globals.playerRef.strength += 5
			"FLOAT":
				multiplyAttribute("gravity",["/",4],10)
			"BOUNCE":
				Globals.playerRef.velocity *= -1
			"UNDERSIDE":
				Globals.playerRef.position.y *= -1
				multiplyAttribute("gravity",["*",-1],12)
			"MULTIGRAVITY":
				multiplyAttribute("gravity",["*",2],9)
			"SCALE_UP":
				multiplyAttribute("scale",["*",2],12)
			"SCALE_DOWN":
				multiplyAttribute("scale",["/",2],12)
			"MED_SPEED":
				multiplyAttribute("speed",["+",5],10)
			"RANDOM_ACTION":
				while true:
					var action = Globals.shapes.keys().pick_random()
					if not (Globals.tools.keys().has(shape) or Globals.allToolShapes.has(shape)):
						runShape(action,Vector2i.ZERO,true)
						break
			"RANDOM_ENEMY":
				var pos = map_to_local(local_to_map(Globals.playerRef.position))
				for i in range(randi_range(0,10)):
					var enemyShape = Globals.enemySpawnShapes.pick_random()
					summonEnemy(pos,enemyShape)
					if Globals.isMultiplayer:
						rpc("summonEnemy",pos,enemyShape)
			"CURRENCY_CUBICS":
				newCurrency("CUBICS",1)
			"CURRENCY_AGNI": 
				newCurrency("AGNI",20)
			"BLOCK":
				Globals.mcBlocks += 64
			"MAZE":
				makeMaze(20,Vector3i(center.x,0,center.y))
			"STRENGTHEN_BOUNDS":
				Globals.bounds_velocity += 20
				await get_tree().create_timer(90).timeout
				Globals.bounds_velocity -= 20


## Logs an action
func add_action(shape:String) -> void:
	Globals.actionsScanned.append(shape)
	tryFinish()
	var panel = preload("res://Scenes/grid_panel.tscn").instantiate()
	panel.selectable = false
	panel.get_child(0).text = shape
	panel.custom_minimum_size = Vector2(155,60)
	Globals.cameraRef.get_child(0).get_node("ActionsTab").get_child(0).get_child(0).add_child(panel)


## Spawns an enemy at position [param pos], enemy kind is specified with [param shape]
@rpc("any_peer","call_remote")
func summonEnemy(pos:Vector3,shape:String):
	var enemy = load("res://Scenes/"+shape+".tscn").instantiate()
	enemy.position = pos
	await get_tree().create_timer(2).timeout
	get_parent().add_child(enemy)


## Places all of the [param cells]
@rpc("any_peer","call_remote")
func buildCells(cells:Array,onPosition:Vector3,isComplexStructure:=false,structureGrid=null,matchGround:=false) -> void:
	if typeof(structureGrid) == TYPE_STRING and isComplexStructure: structureGrid = load(Globals.complexStructures[structureGrid]).instantiate()
	var structureSize = len(cells)
	
	var repeatAmount = ceil(structureSize / 100.0) if structureSize < 5000 else 200
	
	while not cells.is_empty():
		for i in range(repeatAmount):
			if cells.is_empty(): continue
			var currentCell = cells.pick_random()
			var actualCell = local_to_map(Vector3(onPosition.x,0,onPosition.z)) + currentCell
			cells.erase(currentCell)
			if isComplexStructure:
				set_cell_item(actualCell,structureGrid.get_cell_item(currentCell))
			elif matchGround:
				set_cell_item(actualCell,get_cell_item(Vector3i(actualCell.x,0,actualCell.z)))
			else:
				set_cell_item(actualCell,1)
		
		if structureSize < 5000: await get_tree().create_timer(0.001 / structureSize).timeout
		else: await get_tree().process_frame

## Makes a maze with [param width]
func makeMaze(width:int,center:Vector3i) -> void:
	var currentCell = Vector2i.ZERO
	var triedCells = null
	var pastCells = []
	while len(pastCells) < ((width + 1) ** 2) and triedCells != []:
		if not pastCells.has(currentCell):
			for neighbor in getNeighboringCells(Vector3i(currentCell.x,0,currentCell.y)):
				if not pastCells.has(Vector2i(neighbor.x,neighbor.z)):
					set_cell_item(neighbor+center,0)
			set_cell_item(Vector3i(currentCell.x,0,currentCell.y)+center,1)
			if not pastCells.is_empty():
				var middleCell = (currentCell + pastCells[-1]) / 2
				set_cell_item(Vector3i(middleCell.x,0,middleCell.y)+center,1)
			
			await get_tree().process_frame
		
		pastCells.erase(currentCell)
		pastCells.append(currentCell)
		var nextCells = [currentCell + Vector2i(2,0), currentCell + Vector2i(-2,0), currentCell + Vector2i(0,2), currentCell + Vector2i(0,-2)].filter(func(e): return not (pastCells.has(e) or (abs(e.x) > width) or (abs(e.y) > width)))
		if nextCells.is_empty():
			if triedCells == null: triedCells = pastCells.duplicate_deep()
			triedCells.erase(currentCell)
			if not triedCells.is_empty(): currentCell = triedCells.pick_random()
		else:
			currentCell = nextCells.pick_random()
			triedCells = null


## Gives you a popup with [param text] and colored by the [param type]
func trigger_popup(text:String,type:popupTypes) -> void:
	var amountSame = 1
	for i in Globals.cameraRef.get_child(0).get_node("PopupBox").get_children():
		var panelText = i.get_child(0).text
		
		if panelText == "":
			continue
		elif panelText.right(2) == "x)": 
			panelText = panelText.left(panelText.rfind("(") - 1)
			if panelText == text:
				amountSame += int(i.get_child(0).text.replace(panelText,"").left(-2).right(-2))
				i.queue_free()
				i.get_child(0).text = ""
		elif panelText == text:
			amountSame += 1
			i.queue_free()
			i.get_child(0).text = ""
	if amountSame > 1: text += " (" + str(amountSame) + "x)"
	
	var label = Label.new()
	label.label_settings = LabelSettings.new()
	label.label_settings.font_size = 30
	label.text = text
	var panel = PanelContainer.new()
	panel.modulate = popupColors[type]
	panel.add_child(label)
	panel.name = text
	Globals.cameraRef.get_child(0).get_node("PopupBox").add_child(panel)
	
	Globals.allPopups.append(text)
	print_rich("[color="+popupColors[type].to_html(false)+"]"+text+"[/color]")
	
	await get_tree().create_timer(popupTime).timeout
	if is_instance_valid(panel):
		panel.queue_free()


## Something
static func getAllConnections(map:AStar2D,notInclude:Array,input:Dictionary,coords:Vector2i) -> Array:
	var checked = []
	
	if input[coords] == 1:
		if not (notInclude+checked).has(coords):
			checked.append(coords)
			for i in map.get_point_connections(input.keys().find(coords)):
				if not (notInclude+checked).has(input.keys()[i]):
					var iResult = getAllConnections(map,notInclude+checked,input,input.keys()[i])
					checked.append_array(iResult)
	return checked


## Sets the color scheme of the gridmap from [param colorName]
func setColor(colorName:String) -> void:
	for meshIndex:int in Array(mesh_library.get_item_list()):
		mesh_library.get_item_mesh(meshIndex).material.albedo_color = Globals.colorShapes[colorName][meshIndex]


## Gets all the cells from [param shape]'s data
static func getShape(center:Vector3i,shape) -> Array:
	if typeof(shape) == TYPE_STRING:
		shape = Globals.allToolShapes[shape]
	if shape == {}: return []
	var result = []
	match shape.type:
		Globals.types.RECT:
			result = fullPointsForRect(shape,center)
		Globals.types.SQUIRCLE:
			result = fullPointsForRect(shape,center)
			result.erase(Vector2i(topLeftPoint(center,Vector2i(shape.x,shape.y))))
			var floored = Vector2i(floori(shape.x/2),floori(shape.y/2))
			result.erase(Vector2i(center.x + floored.x, center.z - floored.y))
			result.erase(Vector2i(center.x + floored.x, center.z + floored.y))
			result.erase(Vector2i(center.x - floored.x, center.z + floored.y))
		Globals.types.PLUS:
			for x in range(-floor(shape.x/2.0),ceil(shape.x/2.0)):
				if not result.has(Vector2i(x + center.x,center.z)):
					result.append(Vector2i(x + center.x,center.z))
			for y in range(-floor(shape.y/2.0),ceil(shape.y/2.0)):
				if not result.has(Vector2i(center.x,y + center.z)):
					result.append(Vector2i(center.x,y + center.z))
		Globals.types.DIAGONAL:
			for dist in range(shape.len):
				result.append(Vector2i(center.x + ((dist - floor(shape.len/2.0))) * (1 if shape.tl else -1),center.z + (dist - floor(shape.len/2.0))))
		Globals.types.LINE:
			for dist in range(-floor(shape.len/2.0),ceil(shape.len/2.0)):
				result.append(Vector2i(center.x + (0 if shape.vertical else dist), center.z + (dist if shape.vertical else 0)))
		Globals.types.TRIANGLE:
			for x in range(-floor(shape.x/2.0),ceil(shape.x/2.0)):
				for y in range(-floor(shape.y/2.0),ceil(shape.y/2.0)):
					if x > y: continue
					if not result.has(Vector2i(x + center.x,y + center.z)):
						result.append(Vector2i(x + center.x,y + center.z))
		Globals.types.LOOP:
			result = fullPointsForRect(shape,center)
			for i in rectPoints(shape.x-2,shape.y-2,Vector2(center.x-(floor(shape.x/2))+shape.w,center.z-(floor(shape.y/2))+shape.w)): result.erase(i)
		Globals.types.CIRCLE:
			result = rectPoints(shape.d+1,shape.d+1,topLeftPoint(center,Vector2i(shape.d,shape.d)))
			for i in (result.duplicate_deep()):
				if abs((((i.x - center.x + floor(shape.d/2.0)) - floor(shape.d/2)) ** 2) + (((i.y - center.z - floor(shape.d/2.0)) + floor(shape.d/2)) ** 2)) > floor(shape.d/2) ** 2:
					result.erase(i)
		Globals.types.DIAMOND:
			result = rectPoints(shape.len,shape.len,topLeftPoint(center,Vector2i(shape.len,shape.len)))
			result = result.filter(func(e): return abs(e.x-center.x)+abs(e.y-center.z) <= (shape.len/2 - 1))
	return result


## Gets [method rectPoints] with regular dimensions
static func fullPointsForRect(shape:Dictionary,center:Vector3i) -> Array:
	return rectPoints(shape.x,shape.y,topLeftPoint(center,Vector2i(shape.x,shape.y)))


## Gets the top left point with the given [param dimensions] and the [param center]
static func topLeftPoint(center:Vector3i,dimensions:Vector2i) -> Vector2i:
	@warning_ignore("integer_division")
	return Vector2i(center.x-(floor(dimensions.x/2)),center.z-(floor(dimensions.y/2)))


## Returns rectangle points
static func rectPoints(x:int,y:int,tl:Vector2i) -> Array[Vector2i]:
	var result:Array[Vector2i] = []
	for xRan in range(0,x):
		for yRan in range(0,y):
			result.append(Vector2i(xRan,yRan) + tl)
	return result


## Returns the [param array] sorted
static func sorted(array:Array) -> Array:
	array.sort()
	return array


## Standardizes the [param list]
static func makeStandard(list:Array) -> Array:
	if list.is_empty(): return []
	var mins = list[0]
	for i in list:
		if i.x < mins.x:
			mins.x = i.x
		if i.y < mins.y:
			mins.y = i.y
	
	list = list.map(func(e): return e - mins)
	return sorted(list)


## Returns the minimum vector
static func vectorMin(vect1:Vector2i,vect2:Vector2i) -> Vector2i:
	if abs(vect1.x) + abs(vect1.y) < abs(vect2.x) + abs(vect2.y):
		return vect1
	else:
		return vect2


## Hits enemies in the shape [param shape]
func hitEnemy(dist:float,shape:String = Globals.toolShapes[Globals.currentTool]) -> void:
	var cells = getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),shape)
	cells = cells.map(func(e): return Vector3i(e.x,2,e.y))
	for enemy:Node3D in get_parent().get_children().filter(func(e): return e.is_in_group("enemy")):
		if cells.has(local_to_map(enemy.position)): 
			enemy.savedVelocity = ((enemy.position - (Globals.respawnPoint)).normalized() * 20 * (dist + Globals.playerRef.strength))


## Gets the surrounding cells of [param coords]
func getNeighboringCells(coords:Vector3i) -> Array:
	var result = []
	
	for x in range(coords.x - 1,coords.x + 2):
		#for y in range(coords.y - 1,coords.y + 2):
		for z in range(coords.z - 1,coords.z + 2):
			#if get_cell_item(Vector3i(x,y,z)) != -1:
			result.append(Vector3i(x,coords.y,z))
	
	return result


## Finds the mode of the [param array]
static func mode(array:Array) -> Variant:
	var result = {}
	for i in array:
		if result.has(i):
			result[i] += 1
		else:
			result[i] = 1
	return result.find_key(result.values().max())


## Randomly generates terrain
func heightGeneration(shapeCells:Array) -> Array:
	var cells = []
	var cellsToYVals = {}
	
	for i in shapeCells:
		cells.append(vector2to3(i))
		cellsToYVals[i] = 0
	
	var grid = GridMap.new()
	grid.mesh_library = load("res://Sprites/MeshLibraries/MeshLibrary.tres")
	grid.cell_size = Vector3(1,1,1)
	
	var leftCells = cellsToYVals.keys().duplicate(true)
	
	var nextCell = null
	const ogHeightMap = [-1,0,0,0,0,0,1,1,1,1,1,1]
	var heightMap = [-1,0,0,0,0,0,1,1,1,1,1,1]
	
	while not leftCells.is_empty():
		var currentCell
		if nextCell == null:
			currentCell = leftCells.pick_random()
			heightMap = ogHeightMap.duplicate(true)
		else:
			currentCell = nextCell
		
		var surroundingYVals = []
		for x in range(currentCell.x - 1,currentCell.x + 2):
			for y in range(currentCell.y - 1,currentCell.y + 2):
				if Vector2i(x,y) != currentCell:
					if cellsToYVals.has(Vector2i(x,y)):
						var value = cellsToYVals[Vector2i(x,y)]
						if value != 0:
							surroundingYVals.append(value)
					else:
						var value = getHeighestCell(Vector2i(x,y))
						if value != 0: surroundingYVals.append(value)
		
		@warning_ignore("integer_division")
		var yVal = 0
		if not surroundingYVals.is_empty():
			yVal = surroundingYVals.reduce(func(a,n): return a + n) / len(surroundingYVals)
			yVal += heightMap.pick_random()
			if surroundingYVals.count(mode(surroundingYVals)) > 5:
				yVal = mode(surroundingYVals)
		else:
			yVal += heightMap.pick_random()
		yVal = clamp(yVal,1,Globals.maxHeight)
		
		cellsToYVals[currentCell] = yVal
		
		leftCells.erase(currentCell)
		
		if randi_range(0,(40 - abs(len(ogHeightMap) - len(heightMap)))) == 0:
			heightMap = ogHeightMap.duplicate(true)
		else:
			if randi_range(0,1) == 0:
				if randi_range(0,25) == 0:
					heightMap.erase(heightMap.pick_random())
			else:
				for i in range(randi_range(1,3)):
					match randi_range(-1,15):
						-1:
							heightMap.append(0)
						0:
							heightMap.append(0)
						1:
							heightMap.append(0)
						2:
							heightMap.append(2)
						3:
							heightMap.append(2)
		
		nextCell = pickNextCell(currentCell,leftCells)
		
		if len(leftCells) % 20 == 0:
			await get_tree().process_frame
	
	leftCells = cellsToYVals.keys().duplicate(true)
	while not leftCells.is_empty():
		var currentCell = leftCells.pick_random()
		
		var surroundingYVals = []
		for x in range(currentCell.x - 1,currentCell.x + 2):
			for y in range(currentCell.y - 1,currentCell.y + 2):
				if Vector2i(x,y) != currentCell:
					if cellsToYVals.has(Vector2i(x,y)):
						var value = cellsToYVals[Vector2i(x,y)]
						if value != 0:
							surroundingYVals.append(value)
		
		var yVal = cellsToYVals[currentCell]
		if not surroundingYVals.is_empty():
			if surroundingYVals.count(mode(surroundingYVals)) > 4:
				yVal = mode(surroundingYVals)
			elif len(surroundingYVals.filter(func(e): return e > yVal)) > 6:
				yVal += 1
		yVal = clamp(yVal,1,Globals.maxHeight)
		
		cellsToYVals[currentCell] = yVal
		
		leftCells.erase(currentCell)
		
		if len(leftCells) % 10 == 0:
			await get_tree().process_frame
	
	for i in cellsToYVals:
		cells.erase(vector2to3(i))
		cells.append(Vector3i(i.x,cellsToYVals[i],i.y))
	
	for i in cells.duplicate(true):
		var surroundingYVals = []
		for x in range(i.x - 1, i.x + 2):
			for y in range(i.z - 1, i.z + 2):
				if cellsToYVals.has(Vector2i(x,y)):
					surroundingYVals.append(cellsToYVals[Vector2i(x,y)])
				else:
					var value = getHeighestCell(Vector2i(x,y))
					if value != 0: surroundingYVals.append(value)
		
		for y in range(surroundingYVals.min(), i.y - 1):
			cells.append(Vector3i(i.x,clamp(y + 1,1,Globals.maxHeight),i.z))
	
	return addStructures(cells)


## Chooses a new cell for terrain generation
func pickNextCell(currentCell:Vector2i,leftCells:Array) -> Variant:
	var result = null
	var distance = 1
	
	while result == null:
		var possibleNextCells = []
		for x in range(currentCell.x - distance,currentCell.x + distance + 1):
			for y in range(currentCell.y - distance,currentCell.y + distance + 1):
				possibleNextCells.append(Vector2i(x,y))
		possibleNextCells = possibleNextCells.filter(func(e): return leftCells.has(e))
		if not possibleNextCells.is_empty():
			result = possibleNextCells.pick_random()
		elif randi_range(0,53) == 0:
			return null
		distance += 1
	
	return result


## Does nothing
func addStructures(cells:Array) -> Array:
	return cells
	#var structureOrigins = []
	#@warning_ignore("static_called_on_instance")
	#var structures = {"FOUNTAIN":Globals.loadVoxels("res://Scenes/StructureMaps/tut_map.tscn")}
	#for i in range(randi_range(2,30)):
		#var origin = cells.pick_random()
		#if structureOrigins.filter(func(e:Vector3i): return e.distance_to(origin) < 20).is_empty():
			#structureOrigins.append(origin)
			#
			#cells += structures.values().pick_random()
	#
	#return cells


## Gets the heighest cell at the [param pos]
func getHeighestCell(pos:Vector2i,maxHeight:int=Globals.maxHeight) -> int:
	var result = 0
	var currentIndex = maxHeight
	while result == 0 and currentIndex > 0:
		if get_cell_item(Vector3i(pos.x,currentIndex,pos.y)) != -1:
			result = currentIndex
		else:
			currentIndex -= 1
	
	return result


## Sends the gridmap's data to peers
@rpc("any_peer","call_remote")
func sendMap() -> void:
	var result = {}
	for i in get_used_cells():
		result[i] = get_cell_item(i)
	rpc_id(multiplayer.get_remote_sender_id(),"resetMap",result)


## Resets the gridmap
@rpc("authority","call_remote")
func resetMap(mapInfo:Dictionary) -> void:
	clear()
	for i in mapInfo:
		set_cell_item(i,mapInfo[i])


## Multiplies the [param attribute]
func multiplyAttribute(attribute:String,value:Array,time:float) -> void:
	Globals.playerRef.multipliers[attribute].changes.append(value)
	Globals.playerRef.updateMultipliers()
	await get_tree().create_timer(time).timeout
	Globals.playerRef.multipliers[attribute].changes.erase(value)
	Globals.playerRef.updateMultipliers()


## Gives you a new currency of [param type]
func newCurrency(type:String,amount:float) -> void:
	if not Globals.currencies.has(type): giveCurrency(type,amount)


## Increases the amount of currency of [param type] if you already have discovered it
func moreCurrency(type:String,amount:float) -> void:
	if Globals.currencies.has(type): giveCurrency(type,amount)


## Increases the amount of currency of [param type]
func giveCurrency(type:String,amount:float) -> void:
	if Globals.currencies.has(type):
		Globals.currencies[type] += amount
	else:
		Globals.currencies[type] = amount
	
	if Globals.cameraRef.get_child(0).get_node("MoneyTab").get_node("CurrencyContainer").get_children().filter(func(e): return e.get_child(0).text == "CURRENCY_" + type).is_empty():
		
		var panel = preload("res://Scenes/grid_panel.tscn").instantiate()
		panel.selectable = false
		panel.get_child(0).text = "CURRENCY_" + type
		panel.custom_minimum_size = Vector2(140,60)
		
		Globals.cameraRef.get_child(0).get_node("MoneyTab").get_node("CurrencyContainer").add_child(panel)


## Sends the notification that you found the location
func sendArchipelagoItem(id:int,shape:String) -> void:
	if not Globals.archipelagoLocationsFound.has(shape):
		Globals.archipelagoLocationsFound.append(shape)
		Archipelago.collect_location(id)
		Archipelago.conn.scout(id,0,archipelagoPopup)


## Gives you a popup when you recieve an item from Archipelago
func archipelagoPopup(info:NetworkItem) -> void:
	var playerName = Archipelago.conn.get_player_name(info.dest_player_id)
	var itemName = info.get_name()
	trigger_popup("Archipelago Item: " + playerName + "'s " + itemName, popupTypes.ARCHIPELAGO_SEND)


## Checks if you can finish Archipelago
func tryFinish(fromFinishShape:=false) -> void:
	if Globals.isArchipelago: 
		if len(Globals.actionsScanned) >= int(Archipelago.conn.slot_data["actions_needed"]):
			if not Globals.scanned_all_actions and int(Archipelago.conn.slot_data["actions_needed"]) > 0:
				trigger_popup("Scanned All Actions", popupTypes.ARCHIPELAGO_GOAL)
				Globals.scanned_all_actions = true
			@warning_ignore("static_called_on_instance")
			if Globals.arrayHasAll(Globals.extraPatternsFound,range(len(Archipelago.conn.slot_data["needed_patterns"]))): 
				if not Globals.scanned_all_extra_patterns and len(Archipelago.conn.slot_data["needed_patterns"]) > 0:
					trigger_popup("Scanned All Needed Patterns", popupTypes.ARCHIPELAGO_GOAL)
					Globals.scanned_all_extra_patterns = true
				if (Archipelago.conn.slot_data["completion_shape"] == "" or fromFinishShape):
					finishArchipelago() #TODO maybe add amount of extra shapes needed?


## Sends the Archipelago goal signal
func finishArchipelago() -> void:
	Archipelago.set_client_status(AP.ClientStatus.CLIENT_GOAL)
	
	if not Globals.finished_archipelago:
		trigger_popup("Finished Archipelago", popupTypes.ARCHIPELAGO_GOAL)
		Globals.finished_archipelago = true


func _on_bulb_timer_timeout() -> void:
	for cell in bulbCells:
		set_cell_item(cell,bulbCells[cell])
