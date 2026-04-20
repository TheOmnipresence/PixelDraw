class_name ShopExchange extends Resource

@export var first_item: ShopItem

@export var second_item: ShopItem

@export var purchase_times := 1
var times_bought := 0

@export var shop_type: ShopTypes = ShopTypes.OTHER
enum ShopTypes {
	CURRENCY_EXCHANGE,
	OTHER,
}

func _init(item_1:=ShopItem.new("C_GOL"),item_2:=ShopItem.new("CUBICS",true,1),once:=1) -> void:
	first_item = item_1
	second_item = item_2
	purchase_times = once
