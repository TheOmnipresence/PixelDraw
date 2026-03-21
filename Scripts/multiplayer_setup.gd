extends Node

const PORT = 9541
var enet = ENetMultiplayerPeer.new()

#const letters = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]

func host():
	Globals.isMultiplayer = true
	enet.create_server(PORT)
	Globals.multiplayer.multiplayer_peer = enet
	Globals.playerRef.queue_free()
	Globals.playerRef = null
	addPlayer(Globals.multiplayer.get_unique_id())
	return upnp_setup()

func join(ip:String) -> void:
	Globals.isMultiplayer = true
	enet.create_client(ip, PORT)
	Globals.multiplayer.multiplayer_peer = enet
	await Globals.multiplayer.connected_to_server
	rpc_id(1,"addPlayer",Globals.multiplayer.get_unique_id())
	Globals.playerRef.queue_free()
	Globals.playerRef = null

func upnp_setup():
	var upnp = UPNP.new()
	
	var discover_result = upnp.discover()
	assert(discover_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP discover failed! error %s" % discover_result)
	
	assert(upnp.get_gateway() and upnp.get_gateway().is_valid_gateway(), \
		"UPNP invalid Gateway!")
	
	var map_result = upnp.add_port_mapping(PORT)
	assert(map_result == UPNP.UPNP_RESULT_SUCCESS, \
		"UPNP Port Mapping Failed! Error %s" % map_result)
	
	return upnp.query_external_address()

@rpc("any_peer","call_remote")
func addPlayer(id:int) -> void:
	var instance = load("res://Scenes/player.tscn").instantiate()
	instance.name = str(id)
	Globals.gridRef.get_parent().add_child(instance)
