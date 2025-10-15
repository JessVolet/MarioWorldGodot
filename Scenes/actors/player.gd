extends CharacterBody2D

# MOVEMENT X

@export var SPEED = 75.0
@export var JUMP_VELOCITY = -400.0
@export var MAX_FALL_SPEED = 800.0

@export var max_walk_speed: float = 75.0
@export var max_run_speed: float = 135.0
@export var max_sprint_speed: float = 180.0

@export var walk_accel: float = 337.5
@export var stop_decel: float = 225

@export var p_meter_starting_speed = 131.25
@export var max_p_meter = 1.867

#MOVEMENT Y
@export var gravity_without_jump_held: float = 1350.0
@export var jumping: bool = false
@export var spin_jumping: bool = false
@export var jumping_with_full_p_meter: bool = false

# when press jump btn
@export var gravity_with_jump_held: float = 675.0
@export var base_jump_speed: float = 300.0
@export var jump_speed_incr: float = 9.375
@export var base_spin_jump_speed: float = 277.5
@export var spin_jump_speed_incr: float = 8.671875

var p_meter: float = 0.0

# Obtener la gravedad del proyecto en el apartado de configuracion de este para sync con el rigidbody node
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta) -> void:
	handle_movement(delta)
	handle_jump()
	move_and_slide()
	handle_gravity(delta)

func update_animations(direction):
	print_debug(p_meter)
	if not is_on_floor():
		if velocity.y < 0:
			if p_meter == 1.867:
				$AnimatedSprite2D.play("jump_run")
			else:
				$AnimatedSprite2D.play("jump")
		else:
			$AnimatedSprite2D.play("fall")
	else:
		if velocity.x:
			if p_meter == 1.867:
				$AnimatedSprite2D.play("run")
			else:
				$AnimatedSprite2D.play("walk")
		$AnimatedSprite2D.position.y = $AnimatedSprite2D.frame
		var frame_rates_by_speed: Array[float] = [6.0, 7.5, 10.0, 15.0, 20.0, 30.0 , 60.0, 60.0]
		var index: int = int (abs(velocity.x) / 30)
		index = min(index, 7)
		if is_on_wall() and direction * velocity.x > 0:
			index = 3
		$AnimatedSprite2D.speed_scale = frame_rates_by_speed[index]
		if direction * sign(velocity.x) == -1:
			$AnimatedSprite2D.play("turn")
	if velocity.x == 0 and is_on_floor():
		$AnimatedSprite2D.play("idle")
		$AnimatedSprite2D.position.y = 1

func handle_movement(delta):
	var direction = Input.get_axis("move_left", "move_right")
	if is_on_floor() and abs(velocity.x) >= p_meter_starting_speed and Input.is_action_pressed("run"):
		p_meter = min(p_meter + 2 * delta, max_p_meter)
	else:
		p_meter = max (p_meter - delta, 0)
		
	if direction:
		var max_speed: float = max_walk_speed
		
		if Input.is_action_pressed("run"):
			max_speed = max_run_speed
		if p_meter == max_p_meter:
			max_sprint_speed
		velocity.x = move_toward(velocity.x, direction * max_speed, walk_accel * delta)
		#facing_dir = direction
		$AnimatedSprite2D.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, stop_decel * delta)
	update_animations(direction)

func _jump_speed():
	var base_speed: float = base_jump_speed
	var speed_incr: float = jump_speed_incr
	if spin_jumping:
		base_speed = base_spin_jump_speed
		speed_incr = spin_jump_speed_incr
	return -(base_speed + speed_incr * int (abs(velocity.x) /30))

func handle_jump():
	jumping = false
	spin_jumping = false
	jumping_with_full_p_meter = false
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		jumping = true
		velocity.y = _jump_speed()

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
