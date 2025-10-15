extends CharacterBody2D

# Estados del jugador
enum {IDLE, WALK, RUN, JUMP, FALL, CROUCH, SPIN_JUMP}

# Parámetros de física
@export var max_speed := Vector2(600.0, 900.0)
@export var acceleration := Vector2(1500.0, 1200.0)
@export var deceleration := Vector2(1500.0, 0.0)
@export var jump_force := -500.0
@export var gravity := 1200.0

var current_state := IDLE
var direction := 0
var is_grounded := false

func _ready():
	pass

func _physics_process(delta):
	# Lógica de movimiento basada en estado
	match current_state:
		IDLE:
			handle_idle(delta)
		WALK:
			handle_walk(delta)
		# ... otros estados
	
	apply_gravity(delta)
	move_and_slide()
	update_animation()

func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, max_speed.y)
	else:
		is_grounded = true

func handle_idle(delta):
	# Lógica para estado quieto
	var input_direction = Input.get_axis("move_left", "move_right")
	if abs(input_direction) > 0.1:
		current_state = WALK
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_force
		current_state = JUMP
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration.x * delta)

func handle_walk(delta):
	var input_direction = Input.get_axis("move_left", "move_right")
	
	if abs(input_direction) > 0.1:
		velocity.x = move_toward(velocity.x, input_direction * max_speed.x, acceleration.x * delta)
		direction = sign(input_direction)
	else:
		current_state = IDLE
	
	if Input.is_action_just_pressed("jump"):
		velocity.y = jump_force
		current_state = JUMP

func update_animation():
	# Implementar lógica de animaciones según el estado
	pass
