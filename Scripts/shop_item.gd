class_name ShopItem extends Resource

@export var item: String

@export var is_currency: bool
@export var currency_amount: int

func _init(item_name:="",currency:=false,amount:=1) -> void:
	item = item_name
	is_currency = currency
	currency_amount = amount
