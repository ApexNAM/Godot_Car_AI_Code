extends VehicleBody3D
class_name CarAIController

@export var horsepower: float = 125
@export var acceleration: float = 5
@export var navAgent : NavigationAgent3D
@export var randomPoint : Vector3

@export var steer_limit : float = 1
var targetDir: Vector3

@export var left : Array[RayCast3D]
@export var right : Array[RayCast3D]
@export var wall_check_l : RayCast3D
@export var wall_check_r : RayCast3D
@export var brake_check : RayCast3D

func _ready():
	navAgent.velocity_computed.connect(Callable(_on_velocity_computed))
	body_entered.connect(OnCollisionEnter)
	set_physics_process(false)
	call_deferred("dump_first_physics_frame")
	
func dump_first_physics_frame() -> void:
	await get_tree().physics_frame
	set_physics_process(true)

func _process(delta):
	if global_transform.origin.distance_to(randomPoint) < 10:
		randomPoint = Vector3(randf_range(-35.0, 35.0), global_position.y, randf_range(-35.0, 35.0))

func _physics_process(delta):
	var target = randomPoint
	pickup_processing(target)
	
	var drive_input = 1
	engine_force = lerpf(engine_force, drive_input * horsepower, acceleration * delta)
	
	var steer_input = angle_dir(global_transform.basis.z, targetDir.normalized(), global_transform.basis.y)
	steering = steer_input * steer_limit
		
	if IsLeft():
		if steering != (-45 * steer_limit):
			steering = -45 * steer_limit
	elif IsRight():
		if steering != (45 * steer_limit):
			steering = 45 * steer_limit
			
	if IsLeftAll():
		if steering != (45 * steer_limit):
			steering = 45 * steer_limit
		engine_force = -120
	elif IsRightAll():
		if steering != (-45 * steer_limit):
			steering = -45 * steer_limit
		engine_force = -120
	elif IsLeftAll() and IsRightAll():
		print("All")
		engine_force = -120
		
	print(name + ", L : " + str(IsLeftAll()))
	print(name + ", R : " + str(IsLeftAll()))
	
	if brake_check.is_colliding():
		engine_force = -80
					
func pickup_processing(target) -> void:
	navAgent.set_target_position(target)
	var nextPathPoint = navAgent.get_next_path_position()
	var dir = global_transform.origin.direction_to(nextPathPoint) * acceleration
	var velocity = dir * navAgent.max_speed
	navAgent.set_velocity(velocity)	
	
func angle_dir(fwd, target, up):
	var p = fwd.cross(target)
	var dir = p.dot(up)
	return dir
	
func _on_velocity_computed(safe_velocity: Vector3) -> void:
	targetDir = safe_velocity

func IsLeft() -> bool:
	for l in left:
		if l.is_colliding():
			return true
			
	return false
	
func IsRight() -> bool:
	for e in right:
		if e.is_colliding():
			return true
			
	return false
	
func OnCollisionEnter(body) -> void:
	if body != null:
		engine_force = -80

func IsLeftAll() -> bool:
	for l in left:
		if not l.is_colliding():
			return false
			
	return true
	
func IsRightAll() -> bool:
	for r in right:
		if not r.is_colliding():
			return false
			
	return true
