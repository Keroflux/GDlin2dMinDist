extends Line2D

@export var hover_threshold: float = 10.0

var edit: bool = true
var horizontal: bool = false
var index: int = 1  # Standard zero-based index for dynamic point adding


func _process(_delta: float) -> void:
	if not edit:
		return

	# Dynamically update the active editing point to trace mouse alignment
	var local_mouse = to_local(get_global_mouse_position())
	var prev_point = get_point_position(get_point_count() - 2)

	var next_point = Vector2(
		local_mouse.x if horizontal else prev_point.x,
		prev_point.y if horizontal else local_mouse.y
	)
	
	set_point_position(get_point_count() - 1, next_point)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not edit:
		_check_mouse_hover(event.position)

	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and edit:
			# Fix current point position and append new preview point
			var local_pos = to_local(event.position)
			add_point(local_pos)
			horizontal = not horizontal

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			edit = not event.ctrl_pressed
			if not edit:
				# Reset hover check state immediately upon finishing edit
				_check_mouse_hover(get_global_mouse_position())


func _check_mouse_hover(global_mouse_pos: Vector2) -> void:
	var local_mouse = to_local(global_mouse_pos)
	var threshold_sq = hover_threshold * hover_threshold
	var is_inside = false

	# Iterate over line segments using native C++ geometry helper
	for i in range(get_point_count() - 1):
		var p1 = get_point_position(i)
		var p2 = get_point_position(i + 1)
		
		var closest = Geometry2D.get_closest_point_to_segment(local_mouse, p1, p2)
		if local_mouse.distance_squared_to(closest) <= threshold_sq:
			is_inside = true
			break

	self_modulate = Color.RED if is_inside else Color.WHITE
