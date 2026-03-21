## A class for running commands.
class_name CommandLine
extends Control

#region Exported Variables
@export_file var STORED_COMMANDS_FILE_PATH := "user://Data/CommandHistory.dat" ## The file path in the user's file system for the command history. If it is an empty string, commands will not be stored or retrieved.
@export_file var CLASS_PROPS_FILE_PATH := "user://Data/ClassProps.dat" ## The file path for the stored class props
@export var PRINTING := true ## Wether or not it should print the values given by returning functions or getting variables.
@export var USE_HELP_LABEL := true ## Controls if the help label is given a text value. The method [method processLine] will still need a [param helpLabel] parameter.
@export var USE_STORED_COMMANDS := true ## This directly stops the variable [member currentCommandIndex] from being used without having to erase the value of [member STORED_COMMANDS_FILE_PATH]. It also checks at a different place, only affecting [method processLine], leaving the other functions free to call without issues.
@export var ALLOW_SUBMISSION := true ## If you can submit commands through [method processLine]. If this is set to false, submission will only un-focus the line edit.
@export var ALLOW_AUTOCOMPLETE := true ## If pressing the autocomplete button fills out the current part of the command.
@export_group("Use Cheats On")
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "") var USE_CHEATS_ON := true ## If checking for cheats to be on is necessary.
@export var PERMISSION_TO_SET := true ## Checks for [member cheatsOn] for setting variables. If [member USE_CHEATS_ON] is false, this variable is overriden.
@export var PERMISSION_TO_GET := false ## Checks for [member cheatsOn] for getting variables. If [member USE_CHEATS_ON] is false, this variable is overriden.
@export var PERMISSIOM_TO_RUN := true ## Checks for [member cheatsOn] for running functions. If [member USE_CHEATS_ON] is false, this variable is overriden.
@export_group("")
#endregion

var currentCommandIndex := 0 ## The current index of the command in the stored commands list, counting from the most recent as 1.
var currentlySelectedFunc := "" ## The currently selected function or variable, only used in [method getFuncSearchText].
var oldText := "" ## The variable to check if the text in the line edit is the same as when previously called.
var classToScript := {} ## The class name key as a [String] to the refrence of the class needed.
var classProps := {} ## The class name key as a [String] to an [Array] of the methods in the class.
var classArgs := {} ## The class name key as a [String] to a [Dictionary] of the method name to the arguments, as a specially formatted [String]. (Dictionary[String,Dictionary[String,String]])
var cheatsOn := false ## If commands not included in [member passableVars] should go through.
var passableVars : Dictionary[Variant,Array] = {} ## The variables and functions that override the permissions, even if [member cheatsOn] is false. This variable is the type Dictionary[Variant,Array[lb]String[rb]], with the variant being the class reference and the string being the name of the variable or function.
var unreplacableFunctions : Dictionary[Variant,Array] = {} ## The functions that the parameters should not be replaced for. This variable is the type Dictionary[Variant,Array[lb]String[rb]], with the variant being the class reference and the string being the name of the function.

signal commandRun(classRef,methodOrVar:bool,constructor:String,paramsOrValue:String) ## Emits when a [b]single[/b] command is run (so not counting commands seperated by ";" as a single command. ex, when "Globals.cheatsOn = true; Player.speed = 200" is run, this will emit twice).
signal textSubmitted(text:String) ## Emits when text is submitted through [method processLine], before it is entered with [method enterText].
signal textEntered(text:String) ## Emits when text is submitted through [method processLine], after it is entered with [method enterText].
signal storedTextUsed(text:String,index:int) ## Emits when [method updateLineForOldText] is called.
signal helpLabelUpdated(text:String) ## Emits when the help label's text is changed.

## Gets inputs to run the text and change the [member currentCommandIndex], along with updating the [param helpLabel]'s text. Uses [param inputEnter] for submitting the line and parameters [param inputUp] and [param inputDown] for changing the [member currentCommandIndex]. The [param fallbackNode] is focused when [param inputEnter] is pressed and either [param lineEdit]'s text is empty or [member ALLOW_SUBMISSION] is false.
func processLine(inputEnter:String,inputUp:String,inputDown:String,inputAutocomplete:String,lineEdit:LineEdit,helpLabel:Label,fallbackNode:Control) -> void:
	if Input.is_action_just_pressed(inputEnter):
		if lineEdit.text != "" and ALLOW_SUBMISSION:
			textSubmitted.emit(lineEdit.text)
			enterText(lineEdit.text)
			textEntered.emit(lineEdit.text)
			lineEdit.text = ""
		elif lineEdit.has_focus():
			fallbackNode.grab_focus()
	
	if lineEdit.has_focus() and USE_STORED_COMMANDS:
		if Input.is_action_just_pressed(inputUp):
			currentCommandIndex += 1
			updateLineForOldText(lineEdit)
		if Input.is_action_just_pressed(inputDown):
			currentCommandIndex -= 1
			updateLineForOldText(lineEdit)
	
	if USE_HELP_LABEL: helpLabel.text = getFuncSearchText(lineEdit.text,helpLabel.text)
	
	if ALLOW_AUTOCOMPLETE and Input.is_action_just_pressed(inputAutocomplete):
		var searchText = getFuncSearchText(lineEdit.text,helpLabel.text,false,false)
		lineEdit.text = (getAutocompleteText(searchText.split("\n")[0],lineEdit.text))
		lineEdit.grab_focus()
		lineEdit.caret_column = lineEdit.text.length()

## Sets [member classProps] and [member classArgs] to the appropriate values for the classes in [param cts].
func setupClassData(cts:Dictionary,propVersionCheck:=true,propVersion:={}):
	var setupNode:ClassSetup = ClassSetup.new()
	setupNode.CLASS_PROPS_FILE_PATH = CLASS_PROPS_FILE_PATH
	setupNode.classToScript = cts
	classProps = setupNode.getAllPropsForClasses(propVersionCheck,propVersion)
	classArgs = setupNode.getAllArgsForClasses(classProps.duplicate(true))

## Returns the autocomplete text from the top help label text [param fromText] and modifying the text [param onText].
func getAutocompleteText(fromText:String,onText:String) -> String:
	var currentCommand = onText.split("; ")[-1]
	var pastCommands = onText.split("; ")
	pastCommands.resize(pastCommands.find(currentCommand))
	pastCommands = Array(pastCommands).map(func(e): return e + "; ")
	if currentCommand.split("")[-1] == ";": currentCommand = currentCommand.left(-1)
	
	var edited = false
	
	if currentCommand != currentCommand.replace(currentCommand.split(".")[-1],fromText): edited = true
	currentCommand = currentCommand.replace(currentCommand.split(".")[-1],fromText)
	
	if currentCommand == "":
		currentCommand = fromText
		edited = true
	if currentCommand.split(".")[-1] == "":
		currentCommand += fromText
		edited = true
	
	if currentCommand.split(".")[-1] == fromText and not edited:
		if classToScript.has(currentCommand): currentCommand += "."
		else: currentCommand += "; "
	
	return "".join(pastCommands) + currentCommand

## Sets the [param lineEdit]'s text to the retrived command from the [member currentCommandIndex]. Also sets the caret to the end of the line and focuses the node.
func updateLineForOldText(lineEdit:LineEdit) -> void:
	lineEdit.text = retriveCommand(currentCommandIndex)
	lineEdit.caret_column = lineEdit.text.length()
	lineEdit.grab_focus()
	storedTextUsed.emit(lineEdit.text,currentCommandIndex)

## Runs ([method runCommandLine]) and stores ([method storeCommand]) the command. Also resets the [member currentCommandIndex].
func enterText(text:String) -> void:
	runCommandLine(text)
	storeCommand(text)
	currentCommandIndex = 0

## Gets the text for the help label based on the current [param text].
func getFuncSearchText(text:String, previousSearchText:String, checkOldText := true, getArgs := true) -> String:
	if checkOldText:
		if text == oldText: return previousSearchText
		else: oldText = text
	
	if text.contains("; "):
		return getFuncSearchText(((text).right(-(text.find("; ") + 2))),previousSearchText,false,getArgs)
	
	var arrayResult : Array = []
	var result = ""
	
	if not text.contains("."):
		arrayResult = classToScript.keys()
	elif classToScript.has((text).split(".")[0]):
		arrayResult = classProps[(text).split(".")[0]].map(func(e): return e.keys()[0] if e[e.keys()[0]] == "var" else e.keys()[0] + "()")
	else:
		arrayResult = [""]
	
	if text.contains("."):
		if ((text).right(-(text.find(".") + 1))) != "":
			arrayResult = arrayResult.filter(func(e): return e.containsn((text).right(-(text.find(".") + 1))))
	else:
		if text != "":
			arrayResult = arrayResult.filter(func(e): return e.containsn(text))
	
	if len(arrayResult) == 1 and text.contains("."): currentlySelectedFunc = arrayResult[0]
	else: currentlySelectedFunc = ""
	
	if arrayResult.is_empty(): arrayResult = [""]
	
	arrayResult.sort()
	result = "\n".join(PackedStringArray(getFirst(arrayResult,10)))
	if currentlySelectedFunc != "":
		if classArgs.has(text.split(".")[0]) and getArgs: if classArgs[text.split(".")[0]].has(currentlySelectedFunc):
			result = convertToFuncArgs(classArgs[text.split(".")[0]][currentlySelectedFunc])
		else:
			result = currentlySelectedFunc
	
	helpLabelUpdated.emit(result)
	return result

## Converts the [param funcArgsString] into a more readable format for the help label.
func convertToFuncArgs(funcArgsString:String) -> String:
	var prefix = funcArgsString.left((funcArgsString.find("(") + 1))
	var result = funcArgsString.right(-(funcArgsString.find("(") + 1)).left(-1).split(", ")
	if len(result) == 1 and result[0] == "": return funcArgsString
	return prefix + "\n" + ",\n".join(PackedStringArray(Array(result).map(func(e): return "    "+e))) + "\n)"

## Gets the first [param amount] entries of the [param array].
func getFirst(array:Array,amount:int) -> Array:
	var result = []
	if len(array) < amount: return array
	for i in range(0,amount-1):
		result.append(array[i])
	return result

## Stores the [param command] into the user's file system.
func storeCommand(command:String) -> void:
	if STORED_COMMANDS_FILE_PATH == "": return
	
	if not FileAccess.file_exists(STORED_COMMANDS_FILE_PATH):
		FileAccess.open(STORED_COMMANDS_FILE_PATH, FileAccess.WRITE)
	var file = FileAccess.open(STORED_COMMANDS_FILE_PATH, FileAccess.READ_WRITE)
	var fileLine = file.get_line()
	var newLine = str(fileLine + " - " + command)
	if fileLine == "": 
		file.store_line(command)
		return
	var newFile = FileAccess.open(STORED_COMMANDS_FILE_PATH, FileAccess.WRITE)
	newFile.store_line(newLine)

## Retrives the command at the specified [param index] from the user's file system.
func retriveCommand(index:int) -> String:
	if index == 0: return ""
	if index < 0:
		currentCommandIndex = 0
		return ""
	
	if STORED_COMMANDS_FILE_PATH == "": return ""
	
	if not FileAccess.file_exists(STORED_COMMANDS_FILE_PATH):
		FileAccess.open(STORED_COMMANDS_FILE_PATH, FileAccess.WRITE)
	var file = FileAccess.open(STORED_COMMANDS_FILE_PATH, FileAccess.READ)
	var fileCommands = file.get_line().split(" - "); fileCommands.reverse()
	if index == len(fileCommands) + 1: 
		currentCommandIndex -= 1
		return fileCommands[index-2]
	return fileCommands[index-1]

## The replacable values for the command line. Defaults to returning an empty [Dictionary] and is meant to be overriden. The key should always be in (')s (ex. 'waterlevel'). 
func replacableValues() -> Dictionary[String,Variant]:
	return {}

## Splits the command if it has multiple sections, then runs the functions and gets/sets the variables. Emits [signal commandRun] for each seperate command.
func runCommandLine(line:String):
	if line.contains("; "):
		for i in line.split("; "):
			runCommandLine(i)
	elif line.split(" ")[0].contains("("):
		var currentClass = classToScript[line.left(line.find("(")).split(".")[0]]
		if unreplacableFunctions.has(currentClass):
			if not unreplacableFunctions[currentClass].has(line.left(line.find("(")).split(".")[1]):
				for key in replacableValues():
					line = line.replace(key,replacableValues()[key])
		
		var funcName = line.left(line.find("("))
		var params = splitParameters(line.right(line.reverse().rfind("(")).left(-1))
		
		if len(params) == 1 and typeof(params[0]) == TYPE_STRING: if params[0] == "": params = []
		executeFunction(funcName,params)
		
		var fName = funcName.right(-(funcName.find(".")+1))
		var cName = funcName.replace(funcName.right(-(funcName.find(".")+1)),"")
		
		commandRun.emit(cName,fName,"",params)
	else:
		for key in replacableValues():
			line = line.replace(key,replacableValues()[key])
		
		var className = line.left(line.find("."))
		var varName = line.right(-(line.find(".")+1))
		
		if varName.contains(" "):
			varName = varName.left(varName.find(" "))
			var constructor = "="
			var value = line.right(-(line.find("=")+2))
			useVariable(className,varName,constructor,value)
			commandRun.emit(className,varName,constructor,value)
		else:
			useVariable(className,varName)
			commandRun.emit(className,varName,"","")

## Parses the [param params] and returns an [Array] of them.
func splitParameters(params) -> Array:
	params = replaceVector2s(params)
	params = JSON.parse_string("["+params+"]")
	params = params.map(func(e): return e if typeof(e) != TYPE_STRING else (e if e.left(1) != "(" else load("res://Scripts/data_loader.gd").new().strToVector2(e)))
	return params

## Finds and parses all the [Vector2]s in [param perams] into something [JSON] can recognize.
func replaceVector2s(perams:String) -> String:
	var peramList = perams.split("")
	for i in range(len(peramList)):
		if peramList[i] == "(":
			if ((peramList[i-1] == " ") if i > 0 else true):
				var Vector = [[],[]]
				var currentChar = i+1
				while str(int(peramList[currentChar])) == peramList[currentChar] or peramList[currentChar] == "-" or peramList[currentChar] == "." or peramList[currentChar] == " ":
					Vector[0].append(peramList[currentChar])
					currentChar += 1
				currentChar += 1
				while str(int(peramList[currentChar])) == peramList[currentChar] or peramList[currentChar] == "-" or peramList[currentChar] == "." or peramList[currentChar] == " ":
					Vector[1].append(peramList[currentChar])
					currentChar += 1
				if Vector[0].is_empty() or Vector[1].is_empty(): continue
				Vector = "(" + "".join(Vector[0]) + "," + "".join(Vector[1]) + ")"
				perams = perams.replace(Vector,"\""+Vector+"\"")
			else:
				var startIndex = i
				while peramList[startIndex] != " " and startIndex != -1: startIndex -= 1
				startIndex += 1
				var endIndex = i
				while peramList[endIndex] != ")" and endIndex != len(peramList): endIndex += 1
				
				perams = "\"" + "".join(peramList.slice(startIndex,endIndex + 1)) + "\""
	return perams

## Abbreviates the [param string] by joining the capital letters.
func abbreveation(string:String) -> String:
	var result := ""
	for i in string.split(""):
		if i.to_upper() == i:
			result += i
	return result

## Runs the function [param funcName] with parameters [param params]. If it returns a value, it will be printed (unless [member PRINTING] is false).
func executeFunction(funcName:String,params:Array):
	if not funcName.contains("."):
		if funcName == "help":
			var returns = classToScript.keys()
			if returns != null and PRINTING: print_rich("[b]"+str(returns)+"[/b]")
			return returns
		else:
			for i in classToScript.values():
				if i.has_method(funcName): 
					var returns = i.callv(funcName, params)
					if returns != null and PRINTING: print_rich("[b]"+str(returns)+"[/b]")
					return returns
	else:
		var fName = funcName.right(-(funcName.find(".")+1))
		var cName = funcName.replace(fName,"")
		cName = cName.replace(".","")
		cName = classToScript[cName]
		
		if fName == "help":
			var returns = cName.get_method_list().map(func(e): var newVersion = e; newVersion["varOrFunc"] = "func"; return newVersion) + cName.get_property_list().map(func(e): var newVersion = e; newVersion["varOrFunc"] = "var"; return newVersion)
			returns = returns.filter(func(e): return not (ClassDB.instantiate(cName.script.get_instance_base_type()).get_method_list().map(func(j): var newVersion = j; newVersion["varOrFunc"] = "func"; return newVersion) + ClassDB.instantiate(cName.script.get_instance_base_type()).get_property_list().map(func(k): var newVersion = k; newVersion["varOrFunc"] = "var"; return newVersion)).has(e))
			returns = returns.map(func(e): return str(e.varOrFunc + " " + e.name))
			returns = "\n\n".join(returns)
			if returns != null and PRINTING: print_rich("[b]"+str(returns))
			return returns
		elif fName == "helpMore":
			var returns = cName.get_method_list() + cName.get_property_list()
			returns = returns.filter(func(e): return not (ClassDB.instantiate(cName.script.get_instance_base_type()).get_method_list() + ClassDB.instantiate(cName.script.get_instance_base_type()).get_property_list()).has(e))
			returns = returns.map(func(e): return str(e))
			returns = "\n\n".join(returns)
			if returns != null and PRINTING: print_rich("[b]"+str(returns))
			return returns
		elif not cheatsOn and PERMISSIOM_TO_RUN and USE_CHEATS_ON and not (passableVars[cName].has(fName) if passableVars.has(cName) else false):
			return null
		else:
			if cName.has_method(fName): 
				var returns = await cName.callv(fName, params)
				if returns != null and PRINTING: print_rich("[b]"+str(returns)+"[/b]")
				return returns
			printerr("Function not in class")

## Either gets or sets the variable with name [param variableName] in class [param className]. Getting or setting is decided by [param constructor]. [param value] is only used when setting. If getting, the value will be printed (unless [member PRINTING] is false).
func useVariable(className, variableName:String, constructor:String = "", value = ""):
	if classToScript.has(className): className = classToScript[className]
	if className.get(variableName) != null: 
		var returns = null
		if constructor == "":
			if not cheatsOn and PERMISSION_TO_GET and USE_CHEATS_ON:
				if passableVars[className].has(variableName) if passableVars.has(className) else false:
					pass
				else:
					return null
			
			returns = className.get(variableName)
		else:
			value = replaceVector2s(value)
			value = JSON.parse_string(value)
			value = convertAllStrToVector2s(value)
			match constructor:
				"=":
					if not isPassable(true,variableName,className): return null
					className.set(variableName, value)
				"+":
					if not isPassable(false,variableName,className): return null
					returns = className.get(variableName) + value
				"-":
					if not isPassable(false,variableName,className): return null
					returns = className.get(variableName) - value
				"*":
					if not isPassable(false,variableName,className): return null
					returns = className.get(variableName) * value
				"/":
					if not isPassable(false,variableName,className): return null
					returns = className.get(variableName) / value
				"+=":
					if not isPassable(true,variableName,className): return null
					className.set(variableName, className.get(variableName) + value)
				"-=":
					if not isPassable(true,variableName,className): return null
					className.set(variableName, className.get(variableName) - value)
				"*=":
					if not isPassable(true,variableName,className): return null
					className.set(variableName, className.get(variableName) * value)
				"/=":
					if not isPassable(true,variableName,className): return null
					className.set(variableName, className.get(variableName) / value)
		
		if returns != null and PRINTING: print_rich("[b]"+str(returns)+"[/b]")
		return returns
	printerr("Variable value is null")

## Checks if you are allowed to use this variable.
func isPassable(isSet:bool,variableName:String,className) -> bool:
	return not (not cheatsOn and (PERMISSION_TO_SET if isSet else PERMISSION_TO_GET) and USE_CHEATS_ON and not (passableVars[className].has(variableName) if passableVars.has(className) else false))

## Converts all the detected [Vector2] strings to [Vector2]s that are in any of the nested values. Works recursively through arrays and dictionaries (for which only the values are changed). Also converts constructors inside strings to the correct type.
func convertAllStrToVector2s(value):
	match typeof(value):
		TYPE_STRING:
			if value.left(1) == "(" and value.right(1) == ")":
				return strToVector2(value)
			elif value.contains("(") and value.contains(")"):
				return str_to_var(value)
			else:
				return value
		TYPE_ARRAY:
			var arrayResult = []
			for i in value:
				arrayResult.append(convertAllStrToVector2s(i))
			return arrayResult
		TYPE_DICTIONARY:
			var dictResult = {}
			for i in value:
				dictResult[i] = (convertAllStrToVector2s(value[i]))
			return dictResult
		_:
			return value

## Converts a [param string] to a [Vector2]. If it is already a [Vector2] or [Vector2i], it will return the original value.
func strToVector2(string) -> Vector2:
	if typeof(string) == 6 or typeof(string) == 5: return Vector2(string)
	return str_to_var("Vector2"+string)

## Contains functions for setting up the command line variables ([member classArgs] and [member classProps]).
class ClassSetup extends Node:
	@export_file var CLASS_PROPS_FILE_PATH := "user://Data/ClassProps.dat"
	
	## The class names to the script it should pull from.
	var classToScript = {}:
		set(value):
			var result = {}
			for i in value:
				if i.left(5) == "DUPL_": continue
				result[i] = value[i]
				result["DUPL_"+abbreveation(i)+"_"+i] = value[i]
			classToScript = result
	
	## Returns a conversion from abbreviated to unabbreviated class names. 
	func unabbreveationClasses() -> Dictionary:
		var result = {}
		for i in classToScript:
			if i.left(4) == "DUPL": continue
			else: result[abbreveation(i)] = i
		return result
	
	## Returns the props (variables and functions) for all the classes.
	func getAllPropsForClasses(checkVersion:=true,versionCheck:={}) -> Dictionary:
		DirAccess.make_dir_absolute("user://Data")
		if not FileAccess.file_exists(CLASS_PROPS_FILE_PATH):
			FileAccess.open(CLASS_PROPS_FILE_PATH,FileAccess.WRITE)
		var file = FileAccess.open(CLASS_PROPS_FILE_PATH,FileAccess.READ)
		var fileData = file.get_line()
		
		if checkVersion:
			if fileData != "":
				var parsedData = JSON.parse_string(fileData)
				if versionCheck.keys().reduce(func(a,e):return parsedData.has(e) and a):
					if versionCheck.keys().reduce(func(a,e):return parsedData[e] == versionCheck[e] and a):
						return parsedData["Data"]
		
		var result = {}
		for i in classToScript:
			if i.left(5) == "DUPL_":
				result[i.split("_")[1]] = result[i.split("_")[2]].duplicate(true)
				continue
			var propResult = classToScript[i].get_method_list().map(func(e): return {e.name:"func"}) + classToScript[i].get_property_list().map(func(e): return {e.name:"var"})
			propResult = propResult.filter(func(l): return not (ClassDB.instantiate(classToScript[i].script.get_instance_base_type()).get_method_list().map(func(e): return {e.name:"func"}) + ClassDB.instantiate(classToScript[i].script.get_instance_base_type()).get_property_list().map(func(e): return {e.name:"var"})).has(l))
			result[i] = propResult
		
		var newFile = FileAccess.open("user://Data/ClassProps.dat",FileAccess.WRITE)
		var dataToSave = {"Data":result}
		if checkVersion:
			for i in versionCheck:
				dataToSave[i] = versionCheck[i]
		newFile.store_line(JSON.stringify(dataToSave))
		return result
	
	## Returns the arguments for all the classes.
	func getAllArgsForClasses(props:Dictionary) -> Dictionary:
		var unabbreveation = unabbreveationClasses()
		for className in props.duplicate(true):
			if "funcArgs" in classToScript[className if className != className.to_upper() else "DUPL_" + className + "_" + unabbreveation[className]]: props[className] = classToScript[className if className != className.to_upper() else "DUPL_" + className + "_" + unabbreveation[className]].get("funcArgs")
			else: props[className] = {}
		return props
	
	## Abbreviates the [param string] by joining the capital letters.
	func abbreveation(string:String) -> String:
		var result = ""
		for i in string.split(""):
			if i.to_upper() == i:
				result += i
		return result
