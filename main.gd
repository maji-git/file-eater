extends Control

var eating = false

var window_animating = false
var patting = false
var deleteperm = false

# Called when the node enters the scene tree for the first time.
func _ready():
	DirAccess.make_dir_absolute("user://eaten")
	DisplayServer.window_set_drop_files_callback(Callable(_on_file_dropped))
	get_tree().set_auto_accept_quit(false)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		var eatenDir = DirAccess.open("user://eaten")
		var files = eatenDir.get_files()
		
		for f in files: 
			DirAccess.remove_absolute("user://eaten/" + f)
		
		get_tree().quit()

func _on_file_dropped(files):
	if eating:
		return
	
	eating = true
	
	var fz_nodes = []
	
	for f in files:
		var fsp = f.replace("\\", "/").split("/")
		var filename = fsp[fsp.size() - 1]
		var fnsp = filename.split(".")
		var fileextension = fnsp[fnsp.size() - 1]
		var fz = preload("res://filez.tscn").instantiate()
		
		fz.freeze = false
		$Files.add_child(fz)
		
		fz.get_node("Label").text = filename
		
		if fileextension == "png":
			var walf = FileAccess.open(f, FileAccess.READ)
			var walbuffer = walf.get_buffer(walf.get_length())
			walf.close()
		
			var image = Image.new()
			var t1 = image.load_png_from_buffer(walbuffer)
			if t1 == OK:
				fz.get_node("Icon").texture = ImageTexture.create_from_image(image)
		
		fz_nodes.append(fz)
		
		if deleteperm:
			DirAccess.remove_absolute(f)
		else:
			DirAccess.copy_absolute(f, "user://eaten/" + filename)
			DirAccess.remove_absolute(f)
	
	$PlaceFx.position = get_global_mouse_position()
	$PlaceFx.emitting = true
	
	if files.size() >= 6:
		$AnimPlay.play("file_eat_large")
	else:
		$AnimPlay.play("file_eat_normal")
	
	await $AnimPlay.animation_finished
	
	for n in fz_nodes:
		n.queue_free()
	
	eating = false

func _process(delta):
	if window_animating:
		DisplayServer.window_set_position(Vector2i($ActingWindow.position))

func window_jump():
	var origin_winpos = DisplayServer.window_get_position()
	var addup_pos = origin_winpos - Vector2i(0, 30)
	$ActingWindow.position = Vector2(addup_pos)
	
	var tween = get_tree().create_tween()
	tween.tween_property($ActingWindow, "position", Vector2(origin_winpos), 1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_callback(stop_window_animate)
	
	window_animating = true

func window_shake():
	var origin_winpos = DisplayServer.window_get_position()
	var addup_pos = origin_winpos + Vector2i(0, 30)
	$ActingWindow.position = Vector2(addup_pos)
	
	var tween = get_tree().create_tween()
	tween.tween_property($ActingWindow, "position", Vector2(origin_winpos), 1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	tween.tween_callback(stop_window_animate)
	
	window_animating = true

func stop_window_animate():
	window_animating = false


func _on_human_gui_input(event):
	if event is InputEventMouseButton:
		if event.double_click:
			$AboutWindow.visible = true
		elif not eating:
			if event.is_released():
				$human/Animz.speed_scale = 1
			else:
				$human/Animz.play("pat")
				$human/Animz.speed_scale = 0


func open_recover():
	OS.shell_show_in_file_manager(ProjectSettings.globalize_path("user://eaten"))


func _on_deleteperm_toggled(toggled_on):
	deleteperm = toggled_on
