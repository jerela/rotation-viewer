extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var rotation_time = 1.0
var elapsed_time = 0
var mouse_sens = 0.3
var dragging = false
var target_rotation = Quat()
var initial_rotation = Quat()
var current_rotation = Quat()
var animate_rotation = true

onready var current_rotation_grid = $UI/HBoxContainer/RightPanelContainer/VBoxContainer/PanelContainer/CurrentRotationContainer/CurrentRotationGrid
onready var target_rotation_grid = $UI/HBoxContainer/RightPanelContainer/VBoxContainer/PanelContainer2/TargetRotationContainer/TargetRotationGrid
onready var object = $CoordinateAxes/Objects/ObjectFrame/CSGBox
onready var object_frame = $CoordinateAxes/Objects/ObjectFrame
onready var camera = $CameraOffsetX/CameraOffsetY/Camera
onready var coordinate_system = $CoordinateAxes
onready var animation_speed_label = $UI/HBoxContainer/RightPanelContainer/VBoxContainer/PanelContainer3/VBoxContainer/HBoxContainer/AnimSpeedLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	current_rotation = Quat(object_frame.get_transform().basis)
	update_current_rotation_display(current_rotation)
	target_rotation = current_rotation

func _input(event):
	# is right mouse button is down, camera can be dragged around
	if event is InputEventMouseMotion and dragging:
		$CameraOffsetX.rotate_y(deg2rad(-event.relative.x*mouse_sens))
		$CameraOffsetX/CameraOffsetY.rotate_x(deg2rad(-event.relative.y*mouse_sens))
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if Input.is_action_just_released("mouse_scroll_down"):
		camera.set_translation(camera.get_translation()+Vector3(0, 0, 1))
	elif Input.is_action_just_released("mouse_scroll_up"):
		camera.set_translation(camera.get_translation()-Vector3(0, 0, 1))
	
	if Input.is_action_pressed("mouse_right"):
		dragging = true
	else:
		dragging = false
		
	# if esc is pressed, close program
	if Input.is_action_just_pressed("key_esc"):
		get_tree().quit()
		
	# if time elapsed since starting rotation is smaller than rotation duration, add to timer
	if elapsed_time < rotation_time:
		elapsed_time = clamp(elapsed_time+delta,0,rotation_time)
		
	# if current rotation doesn't match target rotation, rotate the object
	if current_rotation != target_rotation:
		
		# if elapsed time is smaller than rotation time, animate the rotation
		if elapsed_time < rotation_time:
			if animate_rotation:
				current_rotation = initial_rotation.slerp(target_rotation,elapsed_time/rotation_time)

		# update visible rotation matrix to user		
		update_current_rotation_display(current_rotation)
		# rotate the object iself
		object_frame.set_transform(Transform(current_rotation.normalized()))
		


# update the values shown to the user in the current rotation grid
func update_current_rotation_display(in_rotation):
	
	var rotation
	
	if typeof(in_rotation) == TYPE_QUAT:
		rotation = Basis(in_rotation)
	else:
		rotation = in_rotation
	
	var children =  current_rotation_grid.get_children()
	var iter = 0
	for i in range(3):
		for j in range(3):
			children[iter].text = str(rotation[i][j])
			iter += 1

# update the values shown to the user in the target rotation grid
func update_target_rotation_display(in_rotation):
	
	var rotation
	
	if typeof(in_rotation) == TYPE_QUAT:
		rotation = Basis(in_rotation)
	elif typeof(in_rotation) == TYPE_BASIS:
		rotation = in_rotation
	else:
		print("Variable in_rotation is of unidentified type!")
	
	var children =  target_rotation_grid.get_children()
	var iter = 0
	for i in range(3):
		for j in range(3):
			children[iter].text = str(rotation[i][j])
			iter += 1

# get an array of values and construct it into a suitable rotation data type depending on the number of elements
func construct_rotation(values):
	var n = values.size()
	var rotation
	
	if n == 4:
		rotation = Quat(values[0], values[1], values[2], values[3])
	elif n == 9:
		rotation = Basis(Vector3(values[0], values[1], values[2]), Vector3(values[3], values[4], values[5]), Vector3(values[6], values[7], values[8]))
	
	return rotation

# set target rotation according to the values given in the target rotation boxes
func _on_Button_pressed():
	#var rotation = object.get_transform().basis
	var rotation = Basis()
	var children =  target_rotation_grid.get_children()
	var iter = 0
	for i in range(3):
		for j in range(3):
			rotation[i][j] = float(children[iter].get_text())
			#print(str(i) + ", " + str(j))
			iter += 1
	target_rotation = rotation.get_rotation_quat()
	initial_rotation = current_rotation
	elapsed_time = 0

# copy the contents of the object's current rotation to the target rotation boxes
func _on_ButtonCopyCurrent_pressed():
	var rotation = object_frame.get_transform().basis
	var children =  target_rotation_grid.get_children()
	var iter = 0
	for i in range(3):
		for j in range(3):
			children[iter].text = str(rotation[i][j])
			#print(str(i) + ", " + str(j))
			iter += 1
	
# parse a string (e.g., from clipboard) to extract its numeric values in a nested array
func parse_text_to_arrays(text):
	var arr_lines = []
	
	# split by line breaks
	var textlines = text.rsplit("\n", true, 0)
	# for each line, split into substrings
	for line in textlines:
		
		var arr_major_elems = []
		
		# split by tabulator
		var line_elems = line.rsplit("\t", true, 0)
		
		# for each line elem, extract quats
		for elem in line_elems:
			
			var arr_minor_elems = []
			
			# split by comma
			var values = elem.rsplit(",", true, 0)
			
			# for each value, trim useless parts
			for value in values:
				var current_value = value.trim_prefix("~").trim_prefix("[").trim_suffix("]")
				print("Value extracted: " + current_value)
				arr_minor_elems.push_back(current_value)
			
			arr_major_elems.push_back(arr_minor_elems)
		arr_lines.push_back(arr_major_elems)
		
		return arr_lines

# go through a nested array of numeric text elements and convert them into a single-dimensional array
func fetch_rotation_elements(in_array):	
	var final_values = []
	
	for line in in_array:
		for major_elem in line:
			var n_minor_elems = major_elem.size()
			print("Number of minor elements in currently iterated major element: " + str(n_minor_elems))
			for minor_elem in major_elem:
				final_values.push_back(minor_elem)
	
	print("Final extracted values from text: " + str(final_values))
	
	return final_values

func _on_ButtonCopyFromClipboard_pressed():
	# load text from clipboard
	var clipboard = OS.clipboard
	print(clipboard)
	
	var lines_array = parse_text_to_arrays(clipboard)
	
	
	var final_values = fetch_rotation_elements(lines_array)

	var n_values = final_values.size()
	
	# if there are 4 values, the element is a quaternion
	if n_values == 4:
		var rotation = construct_rotation(final_values)
		#target_rotation = rotation
		update_target_rotation_display(rotation)
	elif n_values == 9:
		var rotation = construct_rotation(final_values)
		update_target_rotation_display(rotation)



func _on_CoordinateSystemList_item_selected(index):
	if index == 0:
		print("ENU coordinate system selected")
		coordinate_system.rotation_degrees = Vector3(-90,0,0)
	elif index == 1:
		print("OpenSim coordinate system selected")
		coordinate_system.rotation_degrees = Vector3(0,0,0)
	else:
		print("item not implemented yet")


func _on_ButtonResetCurrentRotation_pressed():
	current_rotation = Quat()
	update_current_rotation_display(current_rotation)


func _on_ButtonResetTargetRotation_pressed():
	update_target_rotation_display(Quat())

# sets whether to animate rotation (for smooth rotation) or not (for immediate rotation)
func _on_CheckButton_toggled(button_pressed):
	animate_rotation = button_pressed

# sets new rotation time when the slider is manipulated
func _on_AnimSpeedSlider_value_changed(value):
	# set label to new rotation time
	animation_speed_label.text = str(value)
	# set new rotation time
	rotation_time = value
	# set elapsed time to the new max value to stop the animation
	elapsed_time = value
