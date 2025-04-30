extends Node3D

# Maze dimensions
const WIDTH = 10
const HEIGHT = 10
const CELL_SIZE = 2.0

# Simple maze layout (1 = wall, 0 = path)
var maze = [
	[1,1,1,1,1,1,1,1,1,1],
	[1,0,0,0,1,0,0,0,0,1],
	[1,0,1,0,1,0,1,1,0,1],
	[1,0,1,0,0,0,0,1,0,1],
	[1,0,1,1,1,1,0,1,0,1],
	[1,0,0,0,0,1,0,0,0,1],
	[1,1,1,1,0,1,1,1,0,1],
	[1,0,0,1,0,0,0,1,0,1],
	[1,0,1,1,1,1,0,1,0,1],
	[1,1,1,1,1,1,1,1,1,1],
]

func _ready():
	generate_maze()
	create_floor()

func generate_maze():
	for y in range(HEIGHT):
		for x in range(WIDTH):
			if maze[y][x] == 1:
				var wall = create_wall()
				wall.position = Vector3(x * CELL_SIZE, 1.5, y * CELL_SIZE)
				add_child(wall)

func create_wall() -> StaticBody3D:
	var wall = StaticBody3D.new()

	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(CELL_SIZE, 3, CELL_SIZE)
	mesh_instance.mesh = mesh
	wall.add_child(mesh_instance)

	var collider = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(CELL_SIZE, 3, CELL_SIZE)
	collider.shape = shape
	wall.add_child(collider)

	return wall

func create_floor():
	var floor = StaticBody3D.new()

	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(WIDTH * CELL_SIZE, 1, HEIGHT * CELL_SIZE)
	mesh_instance.mesh = mesh
	mesh_instance.position = Vector3((WIDTH * CELL_SIZE) / 2 - CELL_SIZE / 2, -0.5, (HEIGHT * CELL_SIZE) / 2 - CELL_SIZE / 2)
	floor.add_child(mesh_instance)

	var collider = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = mesh.size
	collider.shape = shape
	collider.position = mesh_instance.position
	floor.add_child(collider)

	add_child(floor)
