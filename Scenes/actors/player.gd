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
@export var gravity_without_jump_held: float = 560.0 # Gravedad "ligera" (cuando sostienes el salto)
@export var jumping: bool = false
@export var spin_jumping: bool = false
@export var jumping_with_full_p_meter: bool = false

# when press jump btn
@export var gravity_with_jump_held: float = 875.0 # Gravedad "fuerte" (cuando sueltas el salto o caes)
@export var base_jump_speed: float = 260.0
@export var jump_speed_incr: float = 6.375
@export var base_spin_jump_speed: float = 277.5
@export var spin_jump_speed_incr: float = 8.671875


@export var p_meter_flag = false

var p_meter: float = 0.0

# Obtener la gravedad del proyecto (Aunque ahora usamos las variables de arriba)
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")


# <--- CORRECCIÓN: El orden de _physics_process es fundamental
func _physics_process(delta) -> void:
	
	# 1. Aplicar gravedad y manejar estados aéreos PRIMERO
	handle_gravity(delta)
	
	# 2. Manejar movimiento horizontal (calcula velocity.x)
	handle_movement(delta)
	
	# 3. Manejar el salto (SOBREESCRIBE velocity.y si se presiona)
	handle_jump()
	
	# 4. Aplicar todo el movimiento
	move_and_slide()

	# 5. Resetear estados DESPUÉS de move_and_slide(), basado en el nuevo is_on_floor()
	# Esta es la corrección MÁS IMPORTANTE para el salto.
	if is_on_floor():
		jumping = false
		spin_jumping = false
		jumping_with_full_p_meter = false
		

func update_animations(direction):
	
	var is_sprinting = p_meter_flag
	
	$AnimatedSprite2D.position.y = 0
	
	if not is_on_floor():
		if velocity.y < 0:
			if is_sprinting:
				$AnimatedSprite2D.play("jump_run")
			else:
				$AnimatedSprite2D.play("jump")
		else: # Cayendo (yendo hacia abajo)
			if is_sprinting:
				$AnimatedSprite2D.play("jump_run")
			else:
				$AnimatedSprite2D.play("fall")
			
	else:
		if velocity.x != 0: # Moviéndose horizontalmente
			
			if direction * sign(velocity.x) == -1:
				$AnimatedSprite2D.play("turn")
			else:
				if is_sprinting:
					$AnimatedSprite2D.play("run")
				else:
					$AnimatedSprite2D.play("walk")
					
			var frame_rates_by_speed: Array[float] = [6.0, 7.5, 10.0, 15.0, 20.0, 30.0 , 60.0, 60.0]
			var index: int = int (abs(velocity.x) / 30)
			index = min(index, 7)
			
			if is_on_wall() and direction * velocity.x > 0:
				index = 3
				
			$AnimatedSprite2D.speed_scale = frame_rates_by_speed[index]
			
		else: # Velocidad X es 0 (Parado)
			$AnimatedSprite2D.play("idle")
			$AnimatedSprite2D.position.y = 1



func handle_movement(delta):
	
	var direction = Input.get_axis("move_left", "move_right")
	var is_charging = is_on_floor() and \
		abs(velocity.x) >= p_meter_starting_speed and \
			Input.is_action_pressed("run")

	if is_charging:
		p_meter = min(p_meter + 2.0 * delta, max_p_meter)
	else:
		p_meter = max(p_meter - delta, 0.0)

	
	if p_meter == max_p_meter:
		p_meter_flag = true
	
	if not Input.is_action_pressed("run") or p_meter <= 0.0:
		p_meter_flag = false
		
	if direction:
		var max_speed: float = max_walk_speed
		
		if Input.is_action_pressed("run"):
			max_speed = max_run_speed
			
		# <--- CORRECCIÓN: Aquí te faltaba asignar el valor "max_speed ="
		if p_meter == max_p_meter:
			max_speed = max_sprint_speed # Faltaba esto
			p_meter_flag = true
			
		velocity.x = move_toward(velocity.x, direction * max_speed, walk_accel * delta)
		$AnimatedSprite2D.flip_h = direction < 0

	else:
		velocity.x = move_toward(velocity.x, 0, stop_decel * delta)
		p_meter = max (p_meter - delta, 0)
		
	update_animations(direction)
	

func _jump_speed():
	var base_speed: float = base_jump_speed
	var speed_incr: float = jump_speed_incr
	if spin_jumping:
		base_speed = base_spin_jump_speed
		speed_incr = spin_jump_speed_incr
	return -(base_speed + speed_incr * int (abs(velocity.x) /30))
		

# <--- CORRECCIÓN: Función de salto arreglada
func handle_jump():
	
	# Eliminados los 'jumping = false' de aquí. Ahora están en _physics_process
	# Eliminado el código duplicado.

	# Esto es solo para saber si el salto *será* con P-Meter
	if p_meter > p_meter_starting_speed:
		jumping_with_full_p_meter = true
	else:
		jumping_with_full_p_meter = false # Asegúrate de resetearlo también
	
	# Solo se ejecuta EN EL FRAME que presionas "jump" Y estás en el suelo
	if Input.is_action_just_pressed("jump") and is_on_floor():
		jumping = true # Establece el estado
		
		if jumping_with_full_p_meter == true:
			# <--- CORRECCIÓN: Tu 100.25 era un typo. Lo puse a 1.25 (25% más alto).
			# Si de verdad era 100.25, cámbialo de vuelta.
			velocity.y = _jump_speed() * 1.25 
		else:
			velocity.y = _jump_speed()
		

# <--- CORRECCIÓN: Implementación del SALTO VARIABLE
func handle_gravity(delta):
	
	# Si estamos en el suelo, no hay gravedad que aplicar.
	# El 'handle_jump' se encargará de la velocidad de salto.
	if is_on_floor():
		return 

	# --- Lógica de gravedad en el aire ---
	var current_gravity: float

	# Tus variables están nombradas al revés, pero la lógica es esta:
	# 200.0 es la gravedad LIGERA (para sostener el salto)
	# 675.0 es la gravedad FUERTE (para soltar el salto o caer)

	# Si estamos SUBIENDO (velocity.y < 0) Y SÍ estamos sosteniendo el botón
	if velocity.y < 0.0 and Input.is_action_pressed("jump"):
		# Aplicamos gravedad ligera para que el salto sea más alto
		current_gravity = gravity_without_jump_held # 200.0
	else:
		# Si estamos CAYENDO (velocity.y > 0) O si SOLTAMOS el botón
		# Aplicamos gravedad fuerte para caer rápido
		current_gravity = gravity_with_jump_held # 675.0

	# Aplicar la gravedad seleccionada
	velocity.y += current_gravity * delta
	
	# Limitar la velocidad de caída
	velocity.y = min(velocity.y, MAX_FALL_SPEED)




#old code
"""
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
	
	var is_sprinting = p_meter_flag 
	
	$AnimatedSprite2D.position.y = 0 
	
	if not is_on_floor():
		if velocity.y < 0:
			if is_sprinting:
				$AnimatedSprite2D.play("jump_run")
			else:
				$AnimatedSprite2D.play("jump")
		else: # Cayendo (yendo hacia abajo)
			if is_sprinting:
				$AnimatedSprite2D.play("jump_run")
			else:
				$AnimatedSprite2D.play("fall")
			
	else:
		if velocity.x != 0: # Moviéndose horizontalmente
			
			if direction * sign(velocity.x) == -1:
				$AnimatedSprite2D.play("turn")
			else:
				if is_sprinting:
					$AnimatedSprite2D.play("run")
				else:
					$AnimatedSprite2D.play("walk")
					
			var frame_rates_by_speed: Array[float] = [6.0, 7.5, 10.0, 15.0, 20.0, 30.0 , 60.0, 60.0]
			var index: int = int (abs(velocity.x) / 30)
			index = min(index, 7)
			
			if is_on_wall() and direction * velocity.x > 0:
				index = 3
				
			$AnimatedSprite2D.speed_scale = frame_rates_by_speed[index]
			
		else: # Velocidad X es 0 (Parado)
			$AnimatedSprite2D.play("idle")
			$AnimatedSprite2D.position.y = 1




func handle_movement(delta):
	
	var direction = Input.get_axis("move_left", "move_right")
	var is_charging = is_on_floor() and \
		abs(velocity.x) >= p_meter_starting_speed and \
			Input.is_action_pressed("run")

	if is_charging:
		p_meter = min(p_meter + 2.0 * delta, max_p_meter)
	else:
		p_meter = max(p_meter - delta, 0.0)

	
	if p_meter == max_p_meter:
		p_meter_flag = true
	
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
###
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
	
	if p_meter > p_meter_starting_speed:
		jumping_with_full_p_meter = true
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		if jumping_with_full_p_meter == true:
			jumping = true
			velocity.y = _jump_speed() * 100.25
		else:
			jumping = true
			velocity.y = _jump_speed()
	if p_meter > p_meter_starting_speed:
		jumping_with_full_p_meter = true
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		if jumping_with_full_p_meter == true:
			jumping = true
			velocity.y = _jump_speed() * 100.25
		else:
			jumping = true
			velocity.y = _jump_speed()
		

func handle_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
"""
