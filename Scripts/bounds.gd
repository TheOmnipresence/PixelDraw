extends Area3D

func _ready() -> void:
	$CollisionShape3D.shape.size.y = (Globals.maxHeight + 20) * 2

func _on_body_exited(body: Node3D) -> void:
	#print(abs(body.velocity.x) + abs(body.velocity.z))
	if abs(body.velocity.x) + abs(body.velocity.z) > 90: return
	body.velocity.y += 10
	var resultPoint = closestPoint(vector3to2(Globals.playerRef.position),[Vector2(0,200),Vector2(200,0),Vector2(0,-200),Vector2(-200,0)])
	body.velocity *= replaceZeros(vector2to3(abs(resultPoint)/-200))

func replaceZeros(vector:Vector3) -> Vector3:
	if vector.x == 0: vector.x = 1
	if vector.y == 0: vector.y = 1
	if vector.z == 0: vector.z = 1
	return vector

func vector2to3(vector:Vector2,y:=0.0) -> Vector3:
	return Vector3(vector.x,0,vector.y)

func vector3to2(vector:Vector3) -> Vector2:
	return Vector2(vector.x,vector.z)

func closestPoint(point:Vector2,points:Array) -> Vector2:
	var result = points[0]
	for i in points:
		if point.distance_to(i) < point.distance_to(result): result = i
	return result
