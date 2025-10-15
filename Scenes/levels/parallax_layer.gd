extends ParallaxLayer

# Velocidad con la que se mueve la capa respecto a la cámara.
# Un valor de (1.0, 1.0) hará que el fondo se mueva 1:1 con la cámara (tiling infinito).
@export var parallax_speed = Vector2(1.0, 1.0) 

func _process(delta):
	# Obtener la posición global del viewport (la cámara).
	# Necesitas la posición de la cámara (viewport.position) para calcular el offset.
	var camera_pos = get_viewport().get_camera_2d().global_position
	
	# El 'offset' es la propiedad que mueve la capa.
	# Ajustamos el offset usando la posición de la cámara y la velocidad deseada.
	# Usamos fmod para asegurar que el valor se mantenga dentro del límite del mirroring
	# y no crezca infinitamente, aunque el motor lo maneja en gran parte.
	
	# La clave de un fondo 1:1 sin paralaje es:
	# 1. El 'Motion / Scale' del ParallaxLayer debe ser (1, 1).
	# 2. El 'Motion / Offset' del ParallaxLayer debe reflejar la posición de la cámara.
	
	# El valor de position debe ser siempre la posición de la cámara.
	# El sistema de Godot se encarga de la repetición si Mirroring está configurado.
	
	# Para un fondo que solo se repite (1:1), solo necesitamos actualizar su posición
	# si la cámara tiene un target.
	
	# Asignamos la posición de la cámara (modificada por la velocidad) directamente al offset.
	# Para un fondo 1:1:
	motion_offset = camera_pos
	
	# Si quisieras un EFECTO PARALLAX, usarías:
	motion_offset.x = fmod(camera_pos.x * parallax_speed.x, 1800)
	motion_offset.y = fmod(camera_pos.y * parallax_speed.y, 1200)
	# ... donde 'texture_size' es el valor que pusiste en 'Mirroring'.

# NOTA: En la mayoría de los casos de "tiling infinito" 1:1,
# simplemente configurar correctamente 'Mirroring' en el Inspector
# del ParallaxLayer y dejar el motion_scale en (1, 1) es suficiente,
# sin necesidad de script. Si no funciona, el script anterior forzará la posición.
