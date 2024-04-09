extends Window


# Called when the node enters the scene tree for the first time.
func _ready():
	close_requested.connect(_close)

func open():
	visible = true

func _close():
	visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
