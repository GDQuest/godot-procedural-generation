extends Node2D

enum PlantState { GROWN, DIED = -1 }

const NEIGHBORS := [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP,
	Vector2.DOWN,
	Vector2(-1, -1),
	Vector2(-1, 1),
	Vector2(1, -1),
	Vector2(1, 1)
]

export var chance_to_start_alive := 0.52

var _map := {}
var _grid_size := Vector2(20, 11)

onready var _tilemap: TileMap = $FoliageTileMap


func _ready() -> void:
	_initialize_map()
	_paint_map()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed:
		return

	var click_position := get_global_mouse_position()
	var grid_position := _tilemap.world_to_map(click_position)

	if not _map.has(grid_position):
		return

	if event.button_index == BUTTON_LEFT:
		_map[grid_position] = (
			PlantState.DIED
			if not _map[grid_position] == PlantState.DIED
			else PlantState.GROWN
		)
		_paint_map()


func _initialize_map() -> void:
	for x in range(_grid_size.x):
		for y in range(_grid_size.y):
			_map[Vector2(x, y)] = (
				PlantState.GROWN
				if randf() < chance_to_start_alive
				else PlantState.DIED
			)


func _count_alive_neighbors(location: Vector2) -> int:
	var count = 0

	for neighbor in NEIGHBORS:
		var neighbor_cell = location + neighbor
		var is_neighbor_outside_grid: bool = (
			neighbor_cell.x < 0
			or neighbor_cell.y < 0
			or neighbor_cell.x >= _grid_size.x
			or neighbor_cell.y >= _grid_size.y
		)

		if is_neighbor_outside_grid:
			continue

		if _map[neighbor_cell] == PlantState.GROWN:
			count += 1

	return count


func update_grid() -> void:
	_map = _advance_simulation(_map)
	_paint_map()


func _advance_simulation(input_map: Dictionary) -> Dictionary:
	var new_map := {}

	for cell in input_map:
		var alive_count = _count_alive_neighbors(cell)

		if input_map[cell] == PlantState.GROWN:
			if alive_count < 2 or alive_count > 3:
				new_map[cell] = PlantState.DIED
			elif alive_count == 2 or alive_count == 3:
				new_map[cell] = input_map[cell]
		elif alive_count == 3:
			new_map[cell] = PlantState.GROWN
		else:
			new_map[cell] = input_map[cell]

	return new_map


func _paint_map() -> void:
	_tilemap.clear()

	for cell in _map:
		_tilemap.set_cellv(cell, _map[cell])
