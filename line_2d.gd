extends Line2D

var p1
var p2
var inside : bool = false
var edit : bool = true
var index : int = 2
var horizontal : bool = true


func _ready() -> void:
	p1 = get_point_position(0)
	p2 = get_point_position(1)


func _process(delta: float) -> void:
	if edit and horizontal:
		var p_0 = Vector2(to_local(get_global_mouse_position()).x, get_point_position(index - 1).y)
		set_point_position(index, p_0)
	elif edit and not horizontal:
		var p_1 = Vector2(get_point_position(index - 1).x, to_local(get_global_mouse_position()).y)
		set_point_position(index, p_1)
	else:
		for i in get_point_count():
			if i >= get_point_count() - 1:
				break
			else:
				p1 = get_point_position(i)
				p2 = get_point_position(i + 1)
				if min_dist(p1, p2, to_local(get_global_mouse_position())) < 10:
					inside = true
		if inside:
			self_modulate = Color.RED
		else:
			self_modulate = Color.WHITE
		
	inside = false


func min_dist(v: Vector2, w: Vector2, p: Vector2):
	var l2 = v.distance_squared_to(w)
	if l2 == 0:
		return p.distance_squared_to(v)
	var t = ((p.x -v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l2
	t = max(0, min(1, t))
	return sqrt(p.distance_squared_to(Vector2(v.x + t * (w.x - v.x), v.y + t * (w.y -v.y))))


func _unhandled_input(event: InputEvent) -> void:
	if edit and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				add_point(event.position)
				index += 1
				horizontal = not horizontal
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				edit = true
			if event.ctrl_pressed:
				edit = false
