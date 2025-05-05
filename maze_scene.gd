extends Node3D

const WIDTH = 21   # Must be odd
const HEIGHT = 21  # Must be odd
const CELL_SIZE = 2.0

var maze = []
var game_started = false
func _ready():
	generate_maze_grid()
	add_boundary_walls()
	generate_maze()
	create_floor()
	spawn_start_and_end()
	spawn_grass_clumps() 

func start_game():
	game_started = true
	print("✅ Game started!")
	
func _input(event):
	if event.is_action_pressed("ui_accept") and not game_started:
		start_game()
# ----------------------------
# Maze Generator (Recursive Backtracking)
# ----------------------------
func generate_maze_grid():
	maze.clear()
	for y in range(HEIGHT):
		maze.append([])
		for x in range(WIDTH):
			maze[y].append(1)  # 1 = wall

	var start_x = 1
	var start_y = 1
	maze[start_y][start_x] = 0

	carve(start_x, start_y)

func carve(x: int, y: int):
	var directions = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	directions.shuffle()

	for dir in directions:
		var nx = x + int(dir.x) * 2
		var ny = y + int(dir.y) * 2

		if nx > 0 and nx < WIDTH - 1 and ny > 0 and ny < HEIGHT - 1 and maze[ny][nx] == 1:
			maze[y + int(dir.y)][x + int(dir.x)] = 0
			maze[ny][nx] = 0
			carve(nx, ny)

# ----------------------------
# Maze Builder (3D Walls)
# ----------------------------
func generate_maze():
	for y in range(HEIGHT):
		var x = 0
		while x < WIDTH:
			if maze[y][x] == 1:
				var start_x = x
				while x < WIDTH and maze[y][x] == 1:
					x += 1
				var end_x = x - 1
				create_wall_segment_h(start_x, end_x, y)
			else:
				x += 1


func create_wall() -> StaticBody3D:
	var wall = StaticBody3D.new()

	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(0.2, 6.0, CELL_SIZE)
	mesh_instance.mesh = mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.2)
	mesh.material = material
	wall.add_child(mesh_instance)

	var collider = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = mesh.size
	collider.shape = shape
	wall.add_child(collider)

	return wall

func create_wall_segment_h(start_x: int, end_x: int, y: int):
	var length = (end_x - start_x + 1) * CELL_SIZE

	var wall = StaticBody3D.new()

	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(length, 2.0, CELL_SIZE)  # Horizontal stretch
	mesh_instance.mesh = mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.2)
	mesh.material = material
	wall.add_child(mesh_instance)

	var collider = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = mesh.size
	collider.shape = shape
	wall.add_child(collider)

	# Center position of wall segment
	var center_x = ((start_x + end_x) / 2.0 - WIDTH / 2.0) * CELL_SIZE + CELL_SIZE / 2.0
	var center_z = (y - HEIGHT / 2.0) * CELL_SIZE + CELL_SIZE / 2.0
	wall.position = Vector3(center_x, 2.0, center_z)

	add_child(wall)
	
func add_boundary_walls():
	for x in range(WIDTH):
		maze[0][x] = 1  # top row
		maze[HEIGHT - 1][x] = 1  # bottom row

	for y in range(HEIGHT):
		maze[y][0] = 1  # left column
		maze[y][WIDTH - 1] = 1  # right column

# ----------------------------
# Floor Generator
# ----------------------------
func create_floor():
	var floor = StaticBody3D.new()

	var mesh_instance = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(WIDTH * CELL_SIZE, 1.0, HEIGHT * CELL_SIZE)  # Floor size and thickness
	mesh_instance.mesh = mesh

	# 🍃 Grass texture material
	var material = StandardMaterial3D.new()
	var grass_texture = load("res://Materials/10450_Rectangular_Grass_Patch_L3.123c827d110a-1347-4381-9208-e4f735762647/10450_Rectangular_Grass_Patch_v1_Diffuse.jpg")  # Make sure this texture exists!
	material.albedo_texture = grass_texture
	material.roughness = 1.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
	material.uv1_scale = Vector3(8, 1, 8)  # Controls how often the texture tiles
	mesh_instance.material_override = material

	mesh_instance.position = Vector3(0, -0.5, 0)  # So floor sits flush with Y=0
	floor.add_child(mesh_instance)

	# Floor collider
	var collider = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = mesh.size
	collider.shape = shape
	collider.position = mesh_instance.position
	floor.add_child(collider)

	add_child(floor)
	spawn_grass_clumps()
	
func spawn_grass_clumps():
	var grass_mesh = preload("res://Materials/10450_Rectangular_Grass_Patch_L3.123c827d110a-1347-4381-9208-e4f735762647/10450_Rectangular_Grass_Patch_v1_Diffuse.jpg")  # ✅ Update path if needed

	for x in range(WIDTH):
		for z in range(HEIGHT):
			if maze[z][x] == 0:
				var mesh_instance = MeshInstance3D.new()
				mesh_instance.mesh = grass_mesh

				mesh_instance.position = Vector3(
					(x - WIDTH / 2.0) * CELL_SIZE + CELL_SIZE / 2.0,
					0.0,  # Sits directly on the floor
					(z - HEIGHT / 2.0) * CELL_SIZE + CELL_SIZE / 2.0
				)

				# ✅ Small scale, looks natural
				var scale = randf_range(0.03, 0.05)
				mesh_instance.scale = Vector3(scale, scale, scale)

				# ✅ Random Y-rotation for variation
				mesh_instance.rotation.y = randf_range(0.0, TAU)

				add_child(mesh_instance)


				
var player_spawn_position = Vector3.ZERO  # Global variable if needed

func spawn_start_and_end():
	var start_set = false
	var end_set = false

	for y in range(HEIGHT):
		for x in range(WIDTH):
			if not start_set and maze[y][x] == 0:
				spawn_marker(x, y, Color(0, 1, 0))  # Green = Start
				player_spawn_position = Vector3(
					(x - WIDTH / 2.0) * CELL_SIZE + CELL_SIZE / 2.0,
					1.0,
					(y - HEIGHT / 2.0) * CELL_SIZE + CELL_SIZE / 2.0
				)
				spawn_player(player_spawn_position)
				start_set = true

			if not end_set and maze[HEIGHT - 1 - y][WIDTH - 1 - x] == 0:
				spawn_marker(WIDTH - 1 - x, HEIGHT - 1 - y, Color(1, 0, 0))  # Red = End
				end_set = true

			if start_set and end_set:
				return

func cell_to_position(x: int, y: int) -> Vector3:
	return Vector3(
		(x - WIDTH / 2.0) * CELL_SIZE + CELL_SIZE / 2.0,
		1.0,  # Y position: 1.0 places it above the floor
		(y - HEIGHT / 2.0) * CELL_SIZE + CELL_SIZE / 2.0
	)
	
func spawn_marker(x: int, y: int, color: Color):
	var position = cell_to_position(x, y)

	if color == Color(1, 0, 0):  # 🔴 red = END
		var goal = Area3D.new()
		var mesh_instance = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(0.8, 0.2, 0.8)

		var material = StandardMaterial3D.new()
		material.albedo_color = color
		mesh.material = material
		mesh_instance.mesh = mesh
		goal.add_child(mesh_instance)

		var shape = CollisionShape3D.new()
		var box = BoxShape3D.new()
		box.size = mesh.size
		shape.shape = box
		goal.add_child(shape)

		goal.position = position
		goal.name = "Goal"
		goal.connect("body_entered", Callable(self, "_on_goal_reached"))
		add_child(goal)
	else:
		var marker = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(0.8, 0.2, 0.8)
		var material = StandardMaterial3D.new()
		material.albedo_color = color
		mesh.material = material
		marker.mesh = mesh
		marker.position = position
		add_child(marker)

	
func spawn_player(position: Vector3):
	var player_scene = preload("res://Player.tscn")
	var player = player_scene.instantiate()
	player.position = position
	add_child(player)

	# Set camera target
	var follow_camera = get_node("FollowCamera")  # Adjust path if camera is nested
	if follow_camera:
		follow_camera.target = player

func spawn_grass_instances():
	var grass_scene = preload("res://Materials/10450_Rectangular_Grass_Patch_L3.123c827d110a-1347-4381-9208-e4f735762647/10450_Rectangular_Grass_Patch_v1_iterations-2.obj")
	
	for x in range(WIDTH):
		for z in range(HEIGHT):
			var instance = grass_scene.instantiate()
			instance.position = Vector3(
				(x - WIDTH / 2.0) * CELL_SIZE + CELL_SIZE / 2.0,
				0.0,
				(z - HEIGHT / 2.0) * CELL_SIZE + CELL_SIZE / 2.0
			)
			add_child(instance)

func show_end_screen():
	game_started = false
	get_tree().paused = true

	var label = Label.new()
	label.text = "🎉 You Win! Press Esc to Quit"
	label.anchor_left = 0.25
	label.anchor_right = 0.75
	label.anchor_top = 0.4
	label.anchor_bottom = 0.6
	label.add_theme_font_size_override("font_size", 30)
	add_child(label)
	
func _on_goal_reached(body):
	if body.name == "Player":
		print("🎉 Game Over! You reached the goal.")
		show_end_screen()
