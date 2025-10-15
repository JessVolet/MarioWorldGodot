extends Camera2D

# Variables de control
@export var speed_h: float = 5.0
@export var speed_v: float = 10.0
@export var target: CharacterBody2D
@export var dead_zone_h: float = 10.0
@export var dead_zone_v: float = 20.0

# Valores de Offset y su Velocidad de Transición
@export var max_offset: float = 105.0 # Antes 'p_meter_offset', ahora es el valor MAXIMO
@export var offset_speed: float = 8.0 # Velocidad con la que el offset se aplica (más grande = más rápido)

# Variable privada para rastrear el offset actual de la cámara
var current_offset_x: float = 0.0

# ... (func _ready) ...

func _process(delta):
	if target == null:
		return
	
	# --- Actualizar el Offset Suavemente ---
	var target_offset: float = 0.0
	
	if target.p_meter_flag:
		# Si está activo, el offset objetivo es el valor máximo
		target_offset = max_offset
	
	# El offset actual se mueve SUAVEMENTE hacia el offset objetivo
	# Esto es lo que suaviza la transición de 0 a 105 o viceversa.
	current_offset_x = lerp(current_offset_x, target_offset, delta * offset_speed)
	
	
	var target_pos = target.global_position
	var camera_pos = global_position
	
	# ... (Cálculo de límites de zona muerta: half_h, half_v, etc.) ...
	var half_h = dead_zone_h / 2.0
	var left_limit = camera_pos.x - half_h
	var right_limit = camera_pos.x + half_h
	var half_v = dead_zone_v / 2.0
	var top_limit = camera_pos.y - half_v
	var bottom_limit = camera_pos.y + half_v
	
	
	# Calcular la posicion nueva.
	var new_x = camera_pos.x
	var new_y = camera_pos.y
	
	# --- Control Horizontal (Lógica Base de Zona Muerta) ---
	if target_pos.x < left_limit:
		new_x = target_pos.x + half_h
	elif target_pos.x > right_limit:
		new_x = target_pos.x - half_h
		
	# --- Control Vertical (Lógica Base de Zona Muerta) ---
	if target_pos.y < top_limit:
		new_y = target_pos.y + half_v
	elif target_pos.y > bottom_limit:
		new_y = target_pos.y - half_v
		
	# --- Aplicar el Offset Suavizado (¡AQUÍ USAMOS el current_offset_x!) ---
	var direction = sign(target.velocity.x)
	# Si la dirección es 0 (parado), el offset no se aplica.
	if direction != 0: 
		# Aplicamos el offset actual (suavizado) en la dirección del personaje
		new_x += current_offset_x * direction
		
	# 3. Mover la cámara de forma suave (Lerp por eje)
	var new_position = Vector2(new_x, new_y)
	
	camera_pos.x = lerp(camera_pos.x, new_x, delta * speed_h)
	camera_pos.y = lerp(camera_pos.y, new_y, delta * speed_v)
	
	global_position = camera_pos
