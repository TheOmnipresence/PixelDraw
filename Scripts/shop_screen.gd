extends Control

@export var shop_items: Array[ShopExchange]
@export var shop_name: String
@export var summoner: String

signal recieved_scout

#func _ready() -> void:
	#setup()

func setup() -> void:
	#Input.action_press("plr_leave")
	Globals.cameraRef.get_child(0).get_node("MarginContainer").get_child(0).get_node("TabBar").current_tab = Globals.cameraRef.tabs.MONEY
	#Input.parse_input_event(InputMap.action_get_events("plr_leave")[0])
	visible = true
	
	$PanelContainer/MarginContainer/VBoxContainer/Name.text = shop_name
	
	for child in $PanelContainer/MarginContainer/VBoxContainer.get_children():
		if child.name == &"Name": continue
		child.queue_free()
	
	for i in shop_items:
		if not (i.times_bought >= i.purchase_times and not i.purchase_times == -1):
			$PanelContainer/MarginContainer/VBoxContainer.add_child(get_shop_node(i))
	
	var button = Button.new()
	button.text = "Exit"
	button.pressed.connect(func(): visible = false)
	$PanelContainer/MarginContainer/VBoxContainer.add_child(button)


func get_shop_node(exchange:ShopExchange) -> HBoxContainer:
	var result = HBoxContainer.new()
	result.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var label = Label.new()
	label.text = ((str(exchange.first_item.currency_amount) + " ") if exchange.first_item.is_currency else "") + exchange.first_item.item
	if Globals.isArchipelago:
		if Archipelago.conn.slot_data["randomize_salesmen"]:
			var loc_name:String
			loc_name = summoner + "_ITEM_" + str(shop_items.find(exchange) + 1)
			if exchange.purchase_times > 1:
				loc_name += "-" + str(exchange.times_bought + 1)
			Archipelago.conn.scout(Globals.ALL_SHOP_ITEMS.find(loc_name) + 4000, 2, func(e):set_archipelago_item_name(e,label))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.add_child(label)
	
	var button = Button.new()
	button.text = str(exchange.second_item.currency_amount) + " " + exchange.second_item.item
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.add_child(button)
	button.pressed.connect(func(): purchase_item(exchange,result))
	
	return result


func set_archipelago_item_name(info:NetworkItem,label:Label) -> void:
	var playerName = Archipelago.conn.get_player_name(info.dest_player_id)
	var itemName = info.get_name()
	var fullText = "Archipelago Item: " + playerName + "'s " + itemName
	label.text = fullText
	recieved_scout.emit()
	#Globals.gridRef.trigger_popup(fullText, Globals.gridRef.popupTypes.ARCHIPELAGO_SEND)


func purchase_item(exchange:ShopExchange,node:HBoxContainer) -> void:
	if exchange.second_item.is_currency:
		if not Globals.currencies.has(exchange.second_item.item):
			return
		elif Globals.currencies[exchange.second_item.item] < exchange.second_item.currency_amount:
			return
	if exchange.first_item.is_currency:
		if not Globals.currencies.has(exchange.first_item.item):
			return
	
	exchange.times_bought += 1
	if exchange.times_bought >= exchange.purchase_times and not exchange.purchase_times == -1: node.queue_free()
	
	if exchange.first_item.is_currency:
		Globals.gridRef.giveCurrency(exchange.first_item.item,exchange.first_item.currency_amount)
	elif Archipelago.conn.slot_data["randomize_salesmen"] if Globals.isArchipelago else false:
		var loc_name:String
		loc_name = summoner + "_ITEM_" + str(shop_items.find(exchange) + 1)
		if exchange.purchase_times > 1:
			loc_name += "-" + str(exchange.times_bought)
		Globals.gridRef.sendArchipelagoItem(Globals.ALL_SHOP_ITEMS.find(loc_name) + 4000, loc_name)
		
		if not (exchange.times_bought >= exchange.purchase_times and not exchange.purchase_times == -1):
			var label = node.get_child(0)
			Archipelago.conn.scout(Globals.ALL_SHOP_ITEMS.find(loc_name) + 4000 + 1, 2, func(e):set_archipelago_item_name(e,label))
	else:
		Globals.gridRef.runShape(exchange.first_item.item)
	
	if exchange.second_item.is_currency:
		Globals.gridRef.giveCurrency(exchange.second_item.item,-exchange.second_item.currency_amount)
