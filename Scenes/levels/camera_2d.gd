extends Camera2D

@export var speed: float = 75.0


#llamar el nodo de entrada en la escena por primera vez

func _ready():
	pass #remplazar por la funcion de body

func _process(delta):
	if Input.is_action_pressed("move_left"):
		position.x -= speed * delta
	if Input.is_action_pressed("move_right"):
		position.x += speed * delta
	if Input.is_action_pressed("Up"):
		position.y -= speed * delta
	if Input.is_action_pressed("Down"):
		position.y += speed * delta
