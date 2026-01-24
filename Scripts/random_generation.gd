extends GridMap

var lastScanned = []

enum scanTypes {TOOL,SHAPE,ACTION,OTHER}

const maxHeight = 70

func _ready() -> void:
	for x in range(-100,100):
		for z in range(-100,100):
			set_cell_item(Vector3i(x,0,z),randi_range(0,1))
	for x in range(-200,200):
		for z in range(-200,200):
			if abs(x) > 130 or abs(z) > 130:
				set_cell_item(Vector3i(x,0,z),randi_range(0,1))
	for dist in range(-130,130):
		set_cell_item(Vector3i(dist,0,130),1)
		set_cell_item(Vector3i(dist,0,-130),1)
		set_cell_item(Vector3i(130,0,dist),1)
		set_cell_item(Vector3i(-130,0,dist),1)
	var index = 0
	for dist in range(-131,131):
		set_cell_item(Vector3i(dist,0,131),index)
		set_cell_item(Vector3i(dist,0,-131),index)
		set_cell_item(Vector3i(131,0,dist),index)
		set_cell_item(Vector3i(-131,0,dist),index)
		if index == 0: index = 1
		else: index = 0
	for dist in range(-132,132):
		set_cell_item(Vector3i(dist,0,132),1)
		set_cell_item(Vector3i(dist,0,-132),1)
		set_cell_item(Vector3i(132,0,dist),1)
		set_cell_item(Vector3i(-132,0,dist),1)
	for dirMultiplier in [[1,true],[-1,true],[-1,false],[1,false]]:
		for x in range(-100,100):
			for z in range(200,300):
				set_cell_item(Vector3i(x if dirMultiplier[1] else z * dirMultiplier[0],0,z * dirMultiplier[0] if dirMultiplier[1] else x),randi_range(0,1))
	
	
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

var bulbCells = {}

func _process(_delta: float) -> void:
	if Input.is_action_just_released("mouse1") or Input.is_action_just_released("mouse3"):
		$"../GridMapOutline".clear()
	if Input.is_action_pressed("mouse3"):
		$"../GridMapOutline".clear()
		for i in getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool]):
			$"../GridMapOutline".set_cell_item(Vector3i(i.x,0,i.y),0)
	elif Input.is_action_pressed("mouse1"):
		$"../GridMapOutline".clear()
		for i in getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.baseShape):
			$"../GridMapOutline".set_cell_item(Vector3i(i.x,0,i.y),0)
	
	if $BulbTimer.is_stopped():
		for cell in bulbCells:
			set_cell_item(cell,bulbCells[cell])
	
	
	#(get_cell_item())
	#(Vector3(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z))
	if Input.is_action_just_released("mouse3"):
		match Globals.currentTool:
			Globals.tools.VOIDER:
				for i in getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool]):
					set_cell_item(Vector3i(i.x,0,i.y),0)
			Globals.tools.ERASER:
				for i in getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool]):
					set_cell_item(Vector3i(i.x,0,i.y),1)
			Globals.tools.C_GOL:
				for i in getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool]):
					var neighborValues = getShape(Vector3i(i.x,0,i.y),{"type":Globals.types.RECT,"x":3,"y":3})
					neighborValues = neighborValues.filter(func(e): return e != i)
					neighborValues = neighborValues.map(func(e): return get_cell_item(Vector3i(e.x,0,e.y)))
					neighborValues = neighborValues.filter(func(e): return e == 1)
					if len(neighborValues) < 2:
						set_cell_item(Vector3i(i.x,0,i.y),0)
					elif len(neighborValues) > 3:
						set_cell_item(Vector3i(i.x,0,i.y),0)
					elif len(neighborValues) == 3:
						set_cell_item(Vector3i(i.x,0,i.y),1)
			Globals.tools.RAISER:
				for i in getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool]):
					if get_cell_item(Vector3i(i.x,0,i.y)) == 1:
						var coords = Vector3i(i.x,clamp(local_to_map(Vector3(0,floor(Globals.playerRef.position.y-1),0)).y,0,20),i.y)
						if get_cell_item(coords) == -1: set_cell_item(coords,2)
			Globals.tools.LEVELER:
				for i in getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool]):
					for yLevel in range(1,21):
						if get_cell_item(Vector3i(i.x,yLevel,i.y)) == 2:
							set_cell_item(Vector3i(i.x,yLevel,i.y),-1)
			Globals.tools.DUSTER:
				for i in getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool]):
					var neighborValues = getShape(Vector3i(i.x,0,i.y),{"type":Globals.types.SQUIRCLE,"x":3,"y":3})
					#neighborValues = neighborValues.filter(func(e): return e != i)
					neighborValues = neighborValues.map(func(e): return get_cell_item(Vector3i(e.x,0,e.y)))
					neighborValues = neighborValues.filter(func(e): return e == 1)
					#print(neighborValues)
					if len(neighborValues) < 2:
						set_cell_item(Vector3i(i.x,0,i.y),0)
			Globals.tools.SHUFFLER:
				var values = []
				for i in getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool]):
					values.append(get_cell_item(Vector3i(i.x,0,i.y)))
				values.shuffle()
				var index = 0
				for i in getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool]):
					set_cell_item(Vector3i(i.x,0,i.y),values[index])
					index += 1
			Globals.tools.STOPPER:
				for i in getShape(Vector3i(local_to_map(Globals.playerRef.position).x + (5 if Globals.playerRef.velocity.x >= 10 else (-5 if Globals.playerRef.velocity.x <= -10 else 0)),0,local_to_map(Globals.playerRef.position).z + (5 if Globals.playerRef.velocity.z >= 10 else (-5 if Globals.playerRef.velocity.z <= -10 else 0))),Globals.toolShapes[Globals.currentTool]):
					if get_cell_item(Vector3i(i.x,0,i.y)) == 1:
						set_cell_item(Vector3i(i.x,clamp(local_to_map(Vector3(0,ceil(Globals.playerRef.position.y)-1,0)).y,0,maxHeight),i.y),1)
			Globals.tools.BULB:
				for i in getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool]):
					bulbCells[Vector3i(i.x,0,i.y)] = get_cell_item(Vector3i(i.x,0,i.y))
					set_cell_item(Vector3i(i.x,0,i.y), 1)
					$BulbTimer.start()
			Globals.tools.MC_PICK:
				var cells = getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool])
				cells = cells.filter(func(e): return get_cell_item(Vector3i(e.x,0,e.y)) == 1)
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
				speed *= len(cells)
				$McPickaxe.start(speed + $McPickaxe.time_left)
				await $McPickaxe.timeout
				for i in cells:
					Globals.mcBlocks += 1
					set_cell_item(Vector3i(i.x,0,i.y),0)
			Globals.tools.HOOK:
				var cells = getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool])
				cells = cells.map(func(e): return Vector3i(e.x,2,e.y))
				for enemy:Node3D in get_parent().get_children().filter(func(e): return e.is_in_group("enemy")):
					if cells.has(local_to_map(enemy.position)): 
						enemy.velocity = enemy.position.direction_to(Globals.playerRef.position) * 100
						enemy.position.lerp(Globals.playerRef.position,0.99)
			Globals.tools.BASE_SW:
				hitEnemy(0.5)
			Globals.tools.PLACER:
				for i in getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool]):
					if Globals.mcBlocks <= 0:
						break
					else:
						Globals.mcBlocks -= 1
						set_cell_item(Vector3i(i.x,0,i.y),1)
			Globals.tools.STAMPER:
				var cells = getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool])
				for i in cells:
					if lastScanned.has(makeStandard(cells)[cells.find(i)]):
						set_cell_item(Vector3i(i.x,0,i.y),1)
			Globals.tools.GRAVITATE:
				var cells = getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool])
				cells = cells.map(func(e): return Vector3i(e.x,2,e.y))
				for enemy:Node3D in get_parent().get_children().filter(func(e): return e.is_in_group("enemy")):
					if cells.has(local_to_map(enemy.position)): 
						enemy.get_node("AntigravityTimer").start()
				Globals.playerRef.get_node("AntigravityTimer").start()
			Globals.tools.SUMMON:
				var cells = getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool])
				#cells = cells.map(func(e): return Vector3i(e.x,2,e.y))
				for enemy:Node3D in get_parent().get_children().filter(func(e): return e.is_in_group("enemy")):
					if cells.has(Vector2i(local_to_map(enemy.position).x,local_to_map(enemy.position).z)): 
						enemy.position.y = 1
			Globals.tools.TERRAIN:
				var cells = getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.toolShapes[Globals.currentTool])
				heightGeneration(cells)
	
	if Input.is_action_just_released("mouse1"):
		var result = {}
		for i in getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),Globals.baseShape):
			result[i] = (get_cell_item(Vector3i(i.x,0,i.y)))
		checkForShapes(removeExtras(result))
	
	if Input.is_action_just_pressed("mouse2"):
		for i in Globals.toolsCompatibility:
			runShape(i,Vector2i(0,0))
		for i in Globals.allToolShapes:
			runShape(i,Vector2i(0,0))
		Globals.mcToolLevel = "NETHERITE"
		#print(getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),"3_DIAG"))

func removeExtras(input:Dictionary):
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

func checkForShapes(groups:Dictionary):
	for group in groups.values().duplicate_deep():
		if group.is_empty(): continue
		for shape in Globals.shapes:
			if Globals.shapes[shape].has(group):
				scanShape(groups.find_key(group),shape,group)
				groups.erase(groups.find_key(group))

func scanShape(pos:Vector2i,shape:String,group:Array) -> void:
	await lightShape(group.map(func(e): return e + pos),0)
	runShape(shape,pos)
	await get_tree().create_timer(0.2).timeout
	await lightShape(group.map(func(e): return e + pos),-1,false)

func lightShape(cells,value:int,wait:=true) -> void:
	if wait: await get_tree().create_timer(randf_range(0.3,0.9)).timeout
	
	for i in cells:
		$"../ActivationGridMap".set_cell_item(Vector3i(i.x,0,i.y),value)

func runShape(shape:String,center:Vector2i):
	print(shape)
	if Globals.tools.keys().has(shape):
		if not Globals.availibleTools.has(Globals.tools.keys().find(shape) as Globals.tools):
			Globals.availibleTools.append(Globals.tools.keys().find(shape) as Globals.tools)
			Globals.toolShapes[(Globals.tools.keys().find(shape) as Globals.tools)] = "NONE"
			var gridPanel = preload("res://Scenes/grid_panel.tscn").instantiate()
			gridPanel.get_child(0).text = shape
			Globals.cameraRef.get_child(0).get_node("SetupTab").get_node("ToolsGrid").add_child(gridPanel)
			
			triggerPopup("New Tool: " + shape,scanTypes.TOOL)
	elif Globals.allToolShapes.has(shape):
		if not Globals.availibleShapes.has(shape):
			Globals.availibleShapes.append(shape)
			triggerPopup("New Shape: " + shape,scanTypes.SHAPE)
	elif Globals.enemySpawnShapes.has(shape):
		if not Globals.actionsScanned.has(shape):
			Globals.actionsScanned.append(shape)
			triggerPopup("New Action Triggered: SPAWNED_" + shape,scanTypes.ACTION)
		var enemy = load("res://Scenes/"+shape+".tscn").instantiate()
		enemy.position = map_to_local(local_to_map(Globals.playerRef.position))
		await get_tree().create_timer(2).timeout
		get_parent().add_child(enemy)
	elif Globals.structureShapes.keys().has(shape):
		
		match shape:
			"RANDOM_GENERATION":
				heightGeneration(getShape(Vector3i.ZERO,"200_SQR"))
			_:
				var cells = Globals.structureShapes[shape].duplicate()
				
				#for i in cells:
					#set_cell_item(local_to_map(Vector3(Globals.playerRef.position.x,0,Globals.playerRef.position.z)) + i,1)
				
				var playerPos = map_to_local(Vector3i(center.x,0,center.y))
				
				var isComplexStructure = Globals.complexStructures.has(shape)
				var structureGrid = null
				
				if isComplexStructure:
					structureGrid = load(Globals.complexStructures[shape]).instantiate()
					
					playerPos += structureGrid.position
					
					for i in structureGrid.get_children():
						structureGrid.remove_child(i)
						get_parent().add_child(i)
						var pos = local_to_map(playerPos)
						pos.y = 0
						pos = map_to_local(pos)
						i.position += pos
				
				buildCells(cells,playerPos,isComplexStructure,structureGrid)
		
		if not Globals.actionsScanned.has(shape):
			Globals.actionsScanned.append(shape)
			triggerPopup("New Action Triggered: BUILT_" + shape,scanTypes.ACTION)
	elif Globals.colorShapes.has(shape):
		setColor(shape)
		triggerPopup("New Action Triggered: COLORED_" + shape,scanTypes.ACTION)
	else:
		if not Globals.actionsScanned.has(shape):
			Globals.actionsScanned.append(shape)
			var panel = preload("res://Scenes/grid_panel.tscn").instantiate()
			panel.selectable = false
			panel.get_child(0).text = shape
			panel.custom_minimum_size = Vector2(140,60)
			Globals.cameraRef.get_child(0).get_node("ActionsTab").get_child(0).add_child(panel)
			triggerPopup("New Action Triggered: " + shape,scanTypes.ACTION)
		else:
			triggerPopup("Action Triggered: " + shape,scanTypes.OTHER)
		match shape:
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
					set_cell_item(Vector3i(i.x,0,i.y),1)
				
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
			"NETHERITE":
				if Globals.mcToolLevel == "DIAMOND":
					Globals.mcToolLevel = "NETHERITE"
			"SMALL_SPEED":
				Globals.playerRef.speedMultipliers.append(["+",2])
				$SmallSpeed.start()
				await $SmallSpeed.timeout
				Globals.playerRef.speedMultipliers.erase(["+",2])
			"NO":
				Globals.playerRef.position.y = -1
			"THUMB":
				if randi_range(0,1) == 0:
					Globals.playerRef.speedMultipliers.append(["/",3])
					await get_tree().create_timer(4).timeout
					Globals.playerRef.speedMultipliers.erase(["/",3])
				else:
					Globals.playerRef.speedMultipliers.append(["*",3])
					await get_tree().create_timer(4).timeout
					Globals.playerRef.speedMultipliers.erase(["*",3])
			"DOT":
				if not Globals.playerRef.get_node("CeilRay").is_colliding(): Globals.playerRef.position.y += 1
			"L_HA":
				Globals.playerRef.speedMultipliers.append(["/",4])
				await get_tree().create_timer(6).timeout
				Globals.playerRef.speedMultipliers.erase(["/",4])
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
				Globals.playerRef.speedMultipliers.append(["*",1.5])
				await get_tree().create_timer(8).timeout
				Globals.playerRef.speedMultipliers.erase(["*",1.5])
			"TEA":
				Globals.playerRef.strength += 5
			"FLOAT":
				Globals.playerRef.floating = true
				await get_tree().create_timer(10).timeout
				Globals.playerRef.floating = false

func buildCells(cells:Array,onPosition:Vector3,isComplexStructure:=false,structureGrid=null,matchGround:=false) -> void:
	var structureSize = len(cells)
	var floatingCells = []
	var usedFloatingCells = false
	var repeatAmount = ceil(structureSize / 100.0) if structureSize < 5000 else 200
	
	while not cells.is_empty():
		for i in range(repeatAmount):
			if cells.is_empty() and usedFloatingCells: continue
			var currentCell = cells.pick_random()
			var actualCell = local_to_map(Vector3(onPosition.x,0,onPosition.z)) + currentCell
			if (not getNeighboringCells(actualCell).is_empty()) or usedFloatingCells:
				cells.erase(currentCell)
				if isComplexStructure:
					set_cell_item(actualCell,structureGrid.get_cell_item(currentCell))
				elif matchGround:
					set_cell_item(actualCell,get_cell_item(Vector3i(actualCell.x,0,actualCell.z)))
				else:
					set_cell_item(actualCell,1)
			else:
				cells.erase(currentCell)
				floatingCells.append(currentCell)
			if cells.is_empty():
				cells = floatingCells.duplicate(true)
				usedFloatingCells = true
				floatingCells = []
		
		if structureSize < 5000: await get_tree().create_timer(0.001 / structureSize).timeout
		else: await get_tree().process_frame

func triggerPopup(text:String,type:scanTypes) -> void:
	var amountSame = 1
	for i in Globals.cameraRef.get_child(0).get_node("PopupBox").get_children():
		var panelText = i.get_child(0).text
		if panelText.right(2) == "x)": 
			panelText = panelText.left(panelText.rfind("(") - 1)
			if panelText == text:
				amountSame += int(i.get_child(0).text.replace(panelText,"").left(-2).right(-2))
				i.queue_free()
		elif panelText == text:
			amountSame += 1
			i.queue_free()
	if amountSame > 1: text += " (" + str(amountSame) + "x)"
	
	var label = Label.new()
	label.label_settings = LabelSettings.new()
	label.label_settings.font_size = 30
	label.text = text
	var panel = PanelContainer.new()
	panel.modulate = {scanTypes.TOOL:Color(1.0, 0.0, 0.0, 1.0),scanTypes.SHAPE:Color(0.0, 0.0, 1.0, 1.0),scanTypes.ACTION:Color(0.0, 1.0, 0.0, 1.0),scanTypes.OTHER:Color(0.2,0.2,0.2)}[type]
	panel.add_child(label)
	panel.name = text
	Globals.cameraRef.get_child(0).get_node("PopupBox").add_child(panel)
	await get_tree().create_timer(2).timeout
	if is_instance_valid(panel):
		panel.queue_free()

func getAllConnections(map:AStar2D,notInclude:Array,input:Dictionary,coords:Vector2i):
	var checked = []
	
	if input[coords] == 1:
		if not (notInclude+checked).has(coords):
			checked.append(coords)
			for i in map.get_point_connections(input.keys().find(coords)):
				if not (notInclude+checked).has(input.keys()[i]):
					var iResult = getAllConnections(map,notInclude+checked,input,input.keys()[i])
					checked.append_array(iResult)
	return checked

func setColor(colorName:String) -> void:
	for meshIndex:int in Array(mesh_library.get_item_list()):
		mesh_library.get_item_mesh(meshIndex).material.albedo_color = Globals.colorShapes[colorName][meshIndex]

func getShape(center:Vector3i,shape) -> Array:
	if typeof(shape) == TYPE_STRING:
		shape = Globals.allToolShapes[shape]
	if shape == {}: return []
	var result = []
	match shape.type:
		Globals.types.RECT:
			result = rectPoints(shape.x,shape.y,Vector2(center.x-(floor(shape.x/2)),center.z-(floor(shape.y/2))))
		Globals.types.SQUIRCLE:
			result = rectPoints(shape.x,shape.y,Vector2(center.x-(floor(shape.x/2)),center.z-(floor(shape.y/2))))
			result.erase(Vector2i(center.x-(floor(shape.x/2)),center.z-(floor(shape.y/2))))
			result.erase(Vector2i(center.x+(floor(shape.x/2)),center.z-(floor(shape.y/2))))
			result.erase(Vector2i(center.x+(floor(shape.x/2)),center.z+(floor(shape.y/2))))
			result.erase(Vector2i(center.x-(floor(shape.x/2)),center.z+(floor(shape.y/2))))
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
	return result

func rectPoints(x:int,y:int,tl:Vector2i):
	var result = []
	for xRan in range(0,x):
		for yRan in range(0,y):
			result.append(Vector2i(xRan,yRan) + tl)
	return result

func sorted(array:Array) -> Array:
	array.sort()
	return array

func makeStandard(list:Array) -> Array:
	if list.is_empty(): return []
	var mins = list[0]
	for i in list:
		if i.x < mins.x:
			mins.x = i.x
		if i.y < mins.y:
			mins.y = i.y
	
	list = list.map(func(e): return e - mins)
	return sorted(list)

func vectorMin(vect1:Vector2i,vect2:Vector2i):
	if abs(vect1.x) + abs(vect1.y) < abs(vect2.x) + abs(vect2.y):
		return vect1
	else:
		return vect2

func hitEnemy(dist:float,shape:String = Globals.toolShapes[Globals.currentTool]):
	var cells = getShape(Vector3i(local_to_map(Globals.playerRef.position).x,0,local_to_map(Globals.playerRef.position).z),shape)
	cells = cells.map(func(e): return Vector3i(e.x,2,e.y))
	for enemy:Node3D in get_parent().get_children().filter(func(e): return e.is_in_group("enemy")):
		if cells.has(local_to_map(enemy.position)): 
			enemy.savedVelocity = ((enemy.position - (Globals.respawnPoint)).normalized() * 20 * (dist + Globals.playerRef.strength))

func getNeighboringCells(coords:Vector3i) -> Array:
	var result = []
	
	for x in range(coords.x - 1,coords.x + 2):
		for y in range(coords.y - 1,coords.y + 2):
			for z in range(coords.z - 1,coords.z + 2):
				if get_cell_item(Vector3i(x,y,z)) != -1:
					result.append(Vector3i(x,y,z))
	
	return result

func mode(array:Array):
	var result = {}
	for i in array:
		if result.has(i):
			result[i] += 1
		else:
			result[i] = 1
	return result.find_key(result.values().max())

func heightGeneration(shapeCells:Array):
	var cells = []
	var cellsToYVals = {}
	
	for i in shapeCells:
		cells.append(Vector3i(i.x,0,i.y))
		cellsToYVals[i] = 0
	
	var grid = GridMap.new()
	grid.mesh_library = load("res://MeshLibrary.tres")
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
		yVal = clamp(yVal,1,maxHeight)
		
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
		
		var possibleNextCells = []
		for x in range(currentCell.x - 1,currentCell.x + 2):
			for y in range(currentCell.y - 1,currentCell.y + 2):
				possibleNextCells.append(Vector2i(x,y))
		possibleNextCells = possibleNextCells.filter(func(e): return leftCells.has(e))
		if not possibleNextCells.is_empty():
			nextCell = possibleNextCells.pick_random()
		else:
			nextCell = null
		
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
		yVal = clamp(yVal,1,maxHeight)
		
		cellsToYVals[currentCell] = yVal
		
		leftCells.erase(currentCell)
		
		if len(leftCells) % 10 == 0:
			await get_tree().process_frame
	
	for i in cellsToYVals:
		cells.erase(Vector3i(i.x,0,i.y))
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
			cells.append(Vector3i(i.x,clamp(y + 1,1,maxHeight),i.z))
	
	buildCells(addStructures(cells),Vector3(0,0,0),false,null,true)

func addStructures(cells:Array) -> Array:
	var structureOrigins = []
	@warning_ignore("static_called_on_instance")
	var structures = {"FOUNTAIN":Globals.loadVoxels("res://Scenes/StructureMaps/tut_map.tscn")}
	for i in range(randi_range(2,30)):
		var origin = cells.pick_random()
		if structureOrigins.filter(func(e:Vector3i): return e.distance_to(origin) < 20).is_empty():
			structureOrigins.append(origin)
			
			cells += structures.values().pick_random()
	
	return cells

func getHeighestCell(pos:Vector2i) -> int:
	var result = 0
	var currentIndex = maxHeight
	while result == 0 and currentIndex > 0:
		if get_cell_item(Vector3i(pos.x,currentIndex,pos.y)) != -1:
			result = currentIndex
		else:
			currentIndex -= 1
	
	return result
