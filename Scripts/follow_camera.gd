extends Camera3D

var target: Node3D
@export var offset: Vector3 = Vector3(0, 5, -10)
@export var smooth_speed := 5.0

func _process(delta):
	if target:
		var desired_position = target.global_transform.origin + offset
		global_transform.origin = global_transform.origin.lerp(desired_position, delta * smooth_speed)
		look_at(target.global_transform.origin, Vector3.UP)
		
