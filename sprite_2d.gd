extends Sprite2D

func _ready():
	var texture = preload("res://Assets/Graphics/Characters/mariotest.png")
	self.texture = texture
	self.hframes = 4  # Número de frames horizontales
	self.vframes = 2  # Número de frames verticales
	self.frame = 0    # Frame inicial
