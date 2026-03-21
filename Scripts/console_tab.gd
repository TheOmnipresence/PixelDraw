extends CommandLine

func _ready() -> void:
	classToScript = {"Globals":Globals,"Player":Globals.playerRef,"Camera":Globals.cameraRef,"GridMap":Globals.gridRef}
	setupClassData(classToScript.duplicate_deep())
	passableVars = {Globals:["cheatsOn"]}

	#$VBoxContainer/LineEdit.connect("focus_entered",focusDebug("grabbed"))
	#$VBoxContainer/LineEdit.connect("focus_exited",focusDebug("lost"))
#func focusDebug(text:String):
	#return func():
		#print(text)
		#print(get_viewport().gui_get_focus_owner())

func _process(_delta: float) -> void:
	processLine("plr_enter","plr_up_arrow","plr_down_arrow","plr_tab",$VBoxContainer/LineEdit,$VBoxContainer/Label,self)
	cheatsOn = Globals.cheatsOn
