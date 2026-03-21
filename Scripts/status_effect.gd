class_name StatusEffect extends Resource

@export var status : Globals.allStatuses
@export var initialTime : float

var timer = Timer.new()

signal finished

func _init(new_status:Globals.allStatuses=Globals.allStatuses.NONE,time:float=-1) -> void:
	if new_status != Globals.allStatuses.NONE:
		status = new_status
		initialTime = time
		timer.time_left = time
		timer.timeout.connect(finish)
		timer.start()

func finish() -> void:
	finished.emit(self)
