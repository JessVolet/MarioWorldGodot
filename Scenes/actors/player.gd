extends CharacterBody2D

# MOVEMENT X

@export var SPEED = 75.0
@export var JUMP_VELOCITY = 400.0
@export var MAX_FALL_SPEED = 800.0

@export var max_walk_speed: float = 75.0
@export var max_run_speed: float = 135.0
@export var max_sprint_speed: float = 180.0

@export var walk_accel: float = 337.5
@export var stop_decel: float = 225

@export var p_meter_starting_speed = 131.25
@export var max_p_meter = 1.867

#MOVEMENT Y
@export var gravity_without_jump_held: float = 200.0
@export var jumping: bool = false
@export var spin_jumping: bool = false
@export var jumping_with_full_p_meter: bool = false

# when press jump btn
@export var gravity_with_jump_held: float = 675.0
@export var base_jump_speed: float = 350.0
@export var jump_speed_incr: float = 9.375
@export var base_spin_jump_speed: float = 277.5
@export var spin_jump_speed_incr: float = 8.671875


@export var p_meter_flag = false

var p_meter: float = 0.0

# Obtener la gravedad del proyecto en el apartado de configuracion de este para sync con el rigidbody node
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta) -> void:
	handle_movement(delta)
	handle_jump()
	move_and_slide()
	handle_gravity(delta)
func update_animations(direction):
	
	# Usamos p_meter_flag para saber el estado de run
	var is_sprinting = p_meter_flag 
	
	# Restablecer la posición Y del sprite al inicio para evitar bugs,
	# a menos que tu intención sea moverlo constantemente.
	$AnimatedSprite2D.position.y = 0 
	
	# ------------------------------------
	# ESTADO AÉREO (NO en el suelo)
	# ------------------------------------
	if not is_on_floor():
		if velocity.y < 0: # Saltando (yendo hacia arriba)
			if is_sprinting:
				$AnimatedSprite2D.play("jump_run")
			else:
				$AnimatedSprite2D.play("jump")
		else: # Cayendo (yendo hacia abajo)
			if is_sprinting:
				$AnimatedSprite2D.play("jump_run")
			else:
				$AnimatedSprite2D.play("fall")
			
	# ------------------------------------
	# ESTADO EN TIERRA (En el suelo)
	# ------------------------------------
	else:
		if velocity.x != 0: # Moviéndose horizontalmente
			
			# Lógica de Giro/Frenado: Si la entrada es opuesta a la velocidad, ejecuta "turn"
			if direction * sign(velocity.x) == -1:
				$AnimatedSprite2D.play("turn")
			else:
				# Si no está girando, ejecuta caminar/correr
				if is_sprinting:
					$AnimatedSprite2D.play("run")
				else:
					$AnimatedSprite2D.play("walk")
					
			# Lógica de velocidad de frame:
			var frame_rates_by_speed: Array[float] = [6.0, 7.5, 10.0, 15.0, 20.0, 30.0 , 60.0, 60.0]
			var index: int = int (abs(velocity.x) / 30)
			index = min(index, 7)
			
			if is_on_wall() and direction * velocity.x > 0:
				index = 3
				
			$AnimatedSprite2D.speed_scale = frame_rates_by_speed[index]
			
		else: # Velocidad X es 0 (Parado)
			$AnimatedSprite2D.play("idle")
			$AnimatedSprite2D.position.y = 1 # Si quieres un offset en idle, se aplica aquí



#"""
func handle_movement(delta):
	
	var direction = Input.get_axis("move_left", "move_right")
	var is_charging = is_on_floor() and \
		abs(velocity.x) >= p_meter_starting_speed and \
			Input.is_action_pressed("run")

	if is_charging:
		p_meter = min(p_meter + 2.0 * delta, max_p_meter)
	else:
		p_meter = max(p_meter - delta, 0.0)

	
	# ACTIVATE: Flag is true ONLY when the P-Meter is exactly full.
	if p_meter == max_p_meter:
		p_meter_flag = true
	
	# DEACTIVATE: Flag turns false if the 'run' button is released, OR the P-Meter empties.
	if not Input.is_action_pressed("run") or p_meter <= 0.0:
		p_meter_flag = false
		
	if direction:
		var max_speed: float = max_walk_speed
		if Input.is_action_pressed("run"):
			max_speed = max_run_speed
		if p_meter == max_p_meter:
			max_sprint_speed
			p_meter_flag = true
		velocity.x = move_toward(velocity.x, direction * max_speed, walk_accel * delta)
		#facing_dir = direction
		$AnimatedSprite2D.flip_h = direction < 0

	else:
		velocity.x = move_toward(velocity.x, 0, stop_decel * delta)
		p_meter = max (p_meter - delta, 0)
	update_animations(direction)
	
"""

func handle_movement(delta):

	# --- 3. MOVEMENT APPLICATION ---
	
	if direction:
		var max_speed: float = max_walk_speed
		
		# If 'run' is pressed, use max_run_speed as the base.
		if Input.is_action_pressed("run"):
			max_speed = max_run_speed
			
		# OVERRIDE: If the flag is set (P-Meter state), use the sprint speed.
		if p_meter_flag:
			max_speed = max_sprint_speed # Corrected: use assignment, not just the value.
			
		# Acceleration/Turning
		velocity.x = move_toward(velocity.x, direction * max_speed, walk_accel * delta)
		$AnimatedSprite2D.flip_h = direction < 0

	else:
		# Deceleration (only on floor, as previously discussed)
		if is_on_floor():
			velocity.x = move_toward(velocity.x, 0, stop_decel * delta)
			
	update_animations(direction)
"""

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
