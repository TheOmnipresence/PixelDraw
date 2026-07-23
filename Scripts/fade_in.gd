extends Control

enum phases {OMNI_FADE_IN,OMNI_FADE_OUT,HGE_FADE_IN,HGE_FADE_OUT,GAME_FADE_IN,BACKGROUND_FADE_IN,GAME_WAIT,GAME_START}
var phase = phases.OMNI_FADE_IN


func _ready() -> void:
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("mouse1"):
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	
	match phase:
		phases.OMNI_FADE_IN:
			if not $Omnipresence.is_playing() and not $Omnipresence.get_meta("played"): 
				$Omnipresence.set_meta("played", true)
				$Omnipresence.play("default")
			if not $Omnipresence.is_playing():
				if $Timer.is_stopped(): $Timer.start()
				await $Timer.timeout
				phase = phases.OMNI_FADE_OUT
		phases.OMNI_FADE_OUT:
			$Omnipresence.self_modulate.a -= 0.1
			if $Omnipresence.self_modulate.a <= 0.0:
				if $Timer.is_stopped(): $Timer.start()
				await $Timer.timeout
				phase = phases.GAME_START
		#phases.HGE_FADE_IN:
			#if not $HGE.is_playing() and not $HGE.get_meta("played"): 
				#$HGE.set_meta("played", true)
				#$HGE.play("default")
			#if not $HGE.is_playing():
				#if $Timer.is_stopped(): $Timer.start()
				#await $Timer.timeout
				#phase = phases.HGE_FADE_OUT
		#phases.HGE_FADE_OUT:
			#$HGE.self_modulate.a -= 0.1
			#if $HGE.self_modulate.a <= 0.0:
				#if $Timer.is_stopped(): $Timer.start()
				#await $Timer.timeout
				#phase = phases.GAME_FADE_IN
		#phases.GAME_FADE_IN:
			#$Game.self_modulate.a += 0.01
			#if $Game.self_modulate.a >= 1.0:
				#if $Timer.is_stopped(): $Timer.start()
				#await $Timer.timeout
				#phase = phases.BACKGROUND_FADE_IN
		#phases.BACKGROUND_FADE_IN:
			#$OtherBackground.self_modulate.a += 0.01
			#if $OtherBackground.self_modulate.a >= 1.0:
				#if $Timer.is_stopped(): $Timer.start()
				#await $Timer.timeout
				#phase = phases.GAME_START
		phases.GAME_START:
			get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
