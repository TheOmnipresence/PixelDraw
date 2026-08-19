extends Control


var source_panel_scene: PackedScene = preload("res://Scenes/source_panel.tscn")


func _ready() -> void:
	update_info()
	Archipelago.connected.connect(func(_conn, _json): update_info())
	Archipelago.disconnected.connect(update_info)
	
	for i in [$KnockbackLinkPanel/VBoxContainer/AnyCheck, $KnockbackLinkPanel/VBoxContainer/ActionsCheck, $KnockbackLinkPanel/VBoxContainer/EnemiesCheck]:
		i.toggled.connect(check_toggled.bind(str(i.name).trim_suffix("Check")))


func _process(_delta: float) -> void:
	if not Globals.isArchipelago:
		disable_all()
	$KnockbackLinkPanel/VBoxContainer/SliderLabel.text = "Multiplier (%.1f)" % Globals.knockbacklink_multiplier


func update_info(from_connection := true) -> void:
	for i in $KnockbackLinkPanel/VBoxContainer/SourcesHeader/VBoxContainer.get_children():
		i.queue_free()
	if Globals.isArchipelago:
		if from_connection:
			$KnockbackLinkPanel/VBoxContainer/EnabledCheck.button_pressed = not is_zero_approx(Archipelago.conn.slot_data["knockback_link"])
			$KnockbackLinkPanel/VBoxContainer/AnyCheck.button_pressed = Archipelago.conn.slot_data["knockback_link_sources"].has("Any")
			$KnockbackLinkPanel/VBoxContainer/ActionsCheck.button_pressed = Archipelago.conn.slot_data["knockback_link_sources"].has("Actions")
			$KnockbackLinkPanel/VBoxContainer/EnemiesCheck.button_pressed = Archipelago.conn.slot_data["knockback_link_sources"].has("Enemies")
			for i in Archipelago.conn.slot_data["knockback_link_sources"].filter(func(e): return not ["Any", "Actions", "Enemies"].has(e)):
				var new_node = source_panel_scene.instantiate()
				new_node.get_child(0).get_node("LineEdit").text = i
				$KnockbackLinkPanel/VBoxContainer/SourcesHeader/VBoxContainer.add_child(new_node)
			
			$DeathLinkPanel/VBoxContainer/DeathLinkEnabledCheck.button_pressed = not is_zero_approx(Archipelago.conn.slot_data["death_link"])
			$DeathLinkPanel/VBoxContainer/AmnestyCounter.value = Archipelago.conn.slot_data["death_link_amnesty"]
			$DeathLinkPanel/VBoxContainer/GraceCounter.value = Archipelago.conn.slot_data["death_link_grace"]
		else:
			$KnockbackLinkPanel/VBoxContainer/EnabledCheck.button_pressed = Archipelago.has_tag("KnockbackLink")
			$KnockbackLinkPanel/VBoxContainer/AnyCheck.button_pressed = Globals.knockbacklink_sources.has("Any")
			$KnockbackLinkPanel/VBoxContainer/ActionsCheck.button_pressed = Globals.knockbacklink_sources.has("Actions")
			$KnockbackLinkPanel/VBoxContainer/EnemiesCheck.button_pressed = Globals.knockbacklink_sources.has("Enemies")
			for i in Globals.knockbacklink_sources.filter(func(e): return not ["Any", "Actions", "Enemies"].has(e)):
				var new_node = source_panel_scene.instantiate()
				new_node.get_child(0).get_node("LineEdit").text = i
				$KnockbackLinkPanel/VBoxContainer/SourcesHeader/VBoxContainer.add_child(new_node)
			
			$DeathLinkPanel/VBoxContainer/DeathLinkEnabledCheck.button_pressed = Archipelago.is_deathlink()
			$DeathLinkPanel/VBoxContainer/AmnestyCounter.value = Globals.deathlink_amnesty
			$DeathLinkPanel/VBoxContainer/GraceCounter.value = Globals.deathlink_grace
	else:
		$KnockbackLinkPanel/VBoxContainer/EnabledCheck.button_pressed = false
		$KnockbackLinkPanel/VBoxContainer/AnyCheck.button_pressed = true
		$KnockbackLinkPanel/VBoxContainer/ActionsCheck.button_pressed = false
		$KnockbackLinkPanel/VBoxContainer/EnemiesCheck.button_pressed = false
		
		$DeathLinkPanel/VBoxContainer/DeathLinkEnabledCheck.button_pressed = false
		$DeathLinkPanel/VBoxContainer/AmnestyCounter.value = 1
		$DeathLinkPanel/VBoxContainer/GraceCounter.value = 1
	
	disable_all()
	if Globals.isArchipelago:
		$KnockbackLinkPanel/VBoxContainer/EnabledCheck.disabled = false
		if $KnockbackLinkPanel/VBoxContainer/EnabledCheck.button_pressed:
			$KnockbackLinkPanel/VBoxContainer/AnyCheck.disabled = false
			if not $KnockbackLinkPanel/VBoxContainer/AnyCheck.button_pressed:
				$KnockbackLinkPanel/VBoxContainer/ActionsCheck.disabled = false
				$KnockbackLinkPanel/VBoxContainer/EnemiesCheck.disabled = false
				if not ($KnockbackLinkPanel/VBoxContainer/ActionsCheck.button_pressed and $KnockbackLinkPanel/VBoxContainer/EnemiesCheck.button_pressed):
					$KnockbackLinkPanel/VBoxContainer/AddNew.disabled = false
		
		$DeathLinkPanel/VBoxContainer/DeathLinkEnabledCheck.disabled = false
		if $DeathLinkPanel/VBoxContainer/DeathLinkEnabledCheck.button_pressed:
			$DeathLinkPanel/VBoxContainer/AmnestyCounter.editable = true
			$DeathLinkPanel/VBoxContainer/GraceCounter.editable = true


func check_toggled(on: bool, kind: String) -> void:
	if on:
		if not Globals.knockbacklink_sources.has(kind):
			Globals.knockbacklink_sources.append(kind)
	else:
		if Globals.knockbacklink_sources.has(kind):
			Globals.knockbacklink_sources.erase(kind)
	update_info(false)


func disable_all(enable_instead := false) -> void:
	for i in [$KnockbackLinkPanel/VBoxContainer/EnabledCheck, $KnockbackLinkPanel/VBoxContainer/AnyCheck, 
			$KnockbackLinkPanel/VBoxContainer/ActionsCheck, $KnockbackLinkPanel/VBoxContainer/EnemiesCheck, 
			$KnockbackLinkPanel/VBoxContainer/AddNew, $DeathLinkPanel/VBoxContainer/DeathLinkEnabledCheck,
			$DeathLinkPanel/VBoxContainer/AmnestyCounter, $DeathLinkPanel/VBoxContainer/GraceCounter]:
		if i is BaseButton:
			i.disabled = not enable_instead
		elif i is SpinBox:
			i.editable = enable_instead


func _on_enabled_check_toggled(toggled_on: bool) -> void:
	Archipelago.set_tag("KnockbackLink", toggled_on)
	await get_tree().process_frame
	update_info(false)


func _on_add_new_pressed() -> void:
	if not $KnockbackLinkPanel/VBoxContainer/SourcesHeader/VBoxContainer.get_child_count() >= 30:
		$KnockbackLinkPanel/VBoxContainer/SourcesHeader/VBoxContainer.add_child(source_panel_scene.instantiate())


func _on_slider_value_changed(value: float) -> void:
	Globals.knockbacklink_multiplier = clamp(value, 0.0, 10.0)


func _on_death_link_enabled_check_toggled(toggled_on: bool) -> void:
	Archipelago.set_deathlink(toggled_on)
	await get_tree().process_frame
	update_info(false)


func _on_amnesty_counter_value_changed(value: float) -> void:
	Globals.deathlink_amnesty = clampi(roundi(value), 0, 20)


func _on_grace_counter_value_changed(value: float) -> void:
	Globals.deathlink_grace = clampi(roundi(value), 0, 20)
