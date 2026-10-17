extends Line2D

@onready var area_2d: Area2D = $Area2D
@onready var collision_polygon: CollisionPolygon2D = $Area2D/CollisionPolygon2D

@export var hover_width: float = 10.0

var edit: bool = true
var horizontal: bool = true
var is_mouse_inside: bool = false


func _ready() -> void:
	clear_points()
	area_2d.mouse_entered.connect(_on_area_2d_mouse_entered)
	area_2d.mouse_exited.connect(_on_area_2d_mouse_exited)


func _process(_delta: float) -> void:
	if not edit or points.size() < 2:
		return

	var local_mouse = to_local(get_global_mouse_position())
	var prev_point = get_point_position(points.size() - 2)

	var next_point = Vector2(
		local_mouse.x if horizontal else prev_point.x,
		prev_point.y if horizontal else local_mouse.y
	)
	
	set_point_position(points.size() - 1, next_point)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey or event is InputEventMouseButton):
		return

	# --- ESCAPE: Cancel & Clear Everything ---
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		clear_points()
		collision_polygon.polygon = PackedVector2Array()
		edit = true
		horizontal = true
		is_mouse_inside = false
		self_modulate = Color.WHITE
		return

	# --- MOUSE INPUTS ---
	if event is InputEventMouseButton and event.pressed:
		
		# --- EDIT MODE INPUTS ---
		if edit:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var local_pos = to_local(event.position)

				if points.size() == 0:
					# 1st Click: Add start point + active preview point
					add_point(local_pos)
					add_point(local_pos)
				else:
					# Subsequent Clicks: Lock preview point & create next preview point
					add_point(local_pos)
					horizontal = not horizontal

			elif event.button_index == MOUSE_BUTTON_RIGHT:
				if event.ctrl_pressed:
					# CTRL + RIGHT CLICK: Finish drawing & lock line
					_finish_editing()
				else:
					# RIGHT CLICK ONLY: Undo last segment
					if points.size() > 2:
						remove_point(points.size() - 1)
						remove_point(points.size() - 1)
						
						var local_pos = to_local(event.position)
						add_point(local_pos)
						horizontal = not horizontal
					elif points.size() == 2:
						clear_points()
						horizontal = true

		# --- NON-EDIT MODE INPUTS ---
		else:
			if event.button_index == MOUSE_BUTTON_RIGHT and is_mouse_inside:
				# Right click inside line -> Re-enter edit mode at the last point
				_resume_editing(event.position)


func _finish_editing() -> void:
	edit = false
	if points.size() > 1:
		remove_point(points.size() - 1)  # Drop trailing unplaced preview point
	_update_collision_shape()


func _resume_editing(click_position: Vector2) -> void:
	if points.size() < 1:
		return

	edit = true
	self_modulate = Color.WHITE
	collision_polygon.polygon = PackedVector2Array()  # Clear collision during edit mode

	# Determine horizontal/vertical orientation relative to the preceding point
	if points.size() >= 2:
		var p_last = get_point_position(points.size() - 1)
		var p_prev = get_point_position(points.size() - 2)
		# If previous segment was horizontal (same Y), the new active segment is vertical
		horizontal = abs(p_last.y - p_prev.y) > abs(p_last.x - p_prev.x)
	else:
		horizontal = true

	# Append a preview point to start dragging the last vertex again
	var local_pos = to_local(click_position)
	add_point(local_pos)


func _update_collision_shape() -> void:
	if points.size() < 2:
		collision_polygon.polygon = PackedVector2Array()
		return

	var polygons = Geometry2D.offset_polyline(
		points, 
		hover_width / 2.0, 
		Geometry2D.JOIN_ROUND, 
		Geometry2D.END_ROUND
	)

	if polygons.size() > 0:
		collision_polygon.polygon = polygons[0]


func _on_area_2d_mouse_entered() -> void:
	is_mouse_inside = true
	if not edit:
		self_modulate = Color.RED


func _on_area_2d_mouse_exited() -> void:
	is_mouse_inside = false
	if not edit:
		self_modulate = Color.WHITE
