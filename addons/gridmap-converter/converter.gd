@tool
extends Node

func convert(gridmap: GridMap, use_multimesh: bool) -> Node3D:
	var parent = Node3D.new()
	parent.name = "ConvertedGridMap"

	var mesh_lib = gridmap.mesh_library
	if not mesh_lib:
		push_error("GridMap has no mesh library.")
		return null

	var used_cells = gridmap.get_used_cells()
	print("Number of used cells: ", used_cells.size())

	if use_multimesh:
		# Group cells by mesh_id for MultiMesh
		var mesh_id_to_cells = {}
		for cell in used_cells:
			var mesh_id = gridmap.get_cell_item(cell)
			if mesh_id == -1:  # Invalid cell
				print("Invalid cell at: ", cell)
				continue

			var mesh = mesh_lib.get_item_mesh(mesh_id)
			if mesh == null:
				print("MeshLibrary has no mesh for id: ", mesh_id, " at cell: ", cell)
				continue

			if not mesh_id in mesh_id_to_cells:
				mesh_id_to_cells[mesh_id] = []
			mesh_id_to_cells[mesh_id].append(cell)

		# Create a MultiMeshInstance3D for each mesh_id
		for mesh_id in mesh_id_to_cells:
			var cells = mesh_id_to_cells[mesh_id]
			var mesh = mesh_lib.get_item_mesh(mesh_id)
			var mesh_name = mesh_lib.get_item_name(mesh_id)  # MeshLibrary'deki ismi al
			var multi_mesh_instance = MultiMeshInstance3D.new()
			# MeshLibrary'deki ismi kullan, yoksa varsayılan bir isim ata
			multi_mesh_instance.name = mesh_name if mesh_name else "MultiMesh_" + str(mesh_id)
			
			# Create MultiMesh
			var multi_mesh = MultiMesh.new()
			multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
			multi_mesh.mesh = mesh
			multi_mesh.instance_count = cells.size()
			
			# Set transforms for each instance
			for i in range(cells.size()):
				var cell = cells[i]
				var cell_position = gridmap.map_to_local(cell)
				var cell_orientation = gridmap.get_cell_item_orientation(cell)
				var basis = gridmap.get_basis_with_orthogonal_index(cell_orientation)
				var transform = Transform3D(basis, cell_position)
				
				multi_mesh.set_instance_transform(i, transform)
			
			multi_mesh_instance.multimesh = multi_mesh
			parent.add_child(multi_mesh_instance)
			multi_mesh_instance.owner = parent  # Set owner for editor visibility
			print("Added MultiMeshInstance3D named: ", multi_mesh_instance.name, " for mesh_id: ", mesh_id, " with ", cells.size(), " instances")
	else:
		# Create individual MeshInstance3D nodes
		for cell in used_cells:
			var mesh_id = gridmap.get_cell_item(cell)
			if mesh_id == -1:  # Invalid cell
				print("Invalid cell at: ", cell)
				continue

			var mesh = mesh_lib.get_item_mesh(mesh_id)
			if mesh == null:
				print("MeshLibrary has no mesh for id: ", mesh_id, " at cell: ", cell)
				continue

			var mesh_name = mesh_lib.get_item_name(mesh_id)  # MeshLibrary'deki ismi al
			var mesh_instance = MeshInstance3D.new()
			# MeshLibrary'deki ismi kullan, yoksa varsayılan bir isim ata
			mesh_instance.name = mesh_name + "_" + str(cell) if mesh_name else "MeshInstance_" + str(cell)
			mesh_instance.mesh = mesh
			var cell_position = gridmap.map_to_local(cell)
			var cell_orientation = gridmap.get_cell_item_orientation(cell)
			var basis = gridmap.get_basis_with_orthogonal_index(cell_orientation)
			
			mesh_instance.transform.origin = cell_position
			mesh_instance.transform.basis = basis
			
			parent.add_child(mesh_instance)
			mesh_instance.owner = parent  # Set owner for editor visibility
			print("Added MeshInstance named: ", mesh_instance.name, " at position: ", mesh_instance.transform.origin, " with rotation: ", mesh_instance.transform.basis.get_euler())

	if parent.get_child_count() == 0:
		push_warning("No valid meshes were added to the parent node.")
	
	return parent

func convert_node_to_multimesh(node: Node, separate_children: bool = false) -> Node3D:
	var parent = Node3D.new()
	parent.name = "ConvertedMultiMesh"

	# Create a separate node for children if requested
	var children_container = null
	if separate_children:
		children_container = Node3D.new()
		children_container.name = "SeparatedChildren"
		parent.add_child(children_container)
		children_container.owner = parent  # Set owner for editor visibility
		print("Created children container node: ", children_container.name)

	# Collect all MeshInstance3D nodes recursively
	var mesh_instances = []
	_collect_mesh_instances(node, mesh_instances)
	print("Found ", mesh_instances.size(), " MeshInstance3D nodes")

	if mesh_instances.size() == 0:
		push_warning("No MeshInstance3D nodes found in the selected node.")
		return null

	# Group MeshInstance3D nodes by their Mesh resource
	var mesh_to_instances = {}
	for mesh_instance in mesh_instances:
		var mesh = mesh_instance.mesh
		if mesh == null:
			print("MeshInstance3D ", mesh_instance.name, " has no mesh, skipping")
			continue
		# Use mesh resource_name if available, else fall back to mesh instance id
		var key = mesh.resource_name if mesh.resource_name else str(mesh.get_instance_id())
		if not key in mesh_to_instances:
			# Use the first MeshInstance3D's name as the base name for MultiMeshInstance3D
			var mesh_name = mesh_instance.name if mesh_instance.name else "Mesh_" + str(key)
			mesh_to_instances[key] = {"mesh": mesh, "instances": [], "base_name": mesh_name}
		mesh_to_instances[key].instances.append(mesh_instance)
		print("MeshInstance3D ", mesh_instance.name, " with mesh ", key, ", global_transform: ", mesh_instance.global_transform)

		# Handle children if separate_children is true
		if separate_children:
			for child in mesh_instance.get_children():
				if not child is MeshInstance3D:  # Only move non-MeshInstance3D children
					var child_copy = child.duplicate()
					children_container.add_child(child_copy)
					child_copy.owner = parent  # Set owner for editor visibility
					child_copy.global_transform = child.global_transform
					print("Moved child ", child.name, " to children_container with global_transform: ", child_copy.global_transform)

	# Create a MultiMeshInstance3D for each unique mesh
	var mesh_index = 0
	for key in mesh_to_instances:
		var data = mesh_to_instances[key]
		var mesh = data.mesh
		var instances = data.instances
		var base_name = data.base_name  # Use the base name from the first MeshInstance3D
		var multi_mesh_instance = MultiMeshInstance3D.new()
		# Set name to the base_name, append index if needed to avoid duplicates
		multi_mesh_instance.name = base_name if base_name else "MultiMesh_" + str(mesh_index)
		mesh_index += 1
		
		# Create MultiMesh
		var multi_mesh = MultiMesh.new()
		multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
		multi_mesh.mesh = mesh
		multi_mesh.instance_count = instances.size()
		print("Creating MultiMesh for mesh ", key, " with name ", multi_mesh_instance.name, " and ", instances.size(), " instances")
		
		# Set transforms for each instance
		for i in range(instances.size()):
			var mesh_instance = instances[i]
			var transform = mesh_instance.global_transform
			multi_mesh.set_instance_transform(i, transform)
			print("Set instance ", i, " transform: ", transform.origin, ", basis: ", transform.basis.get_euler())
		
		multi_mesh_instance.multimesh = multi_mesh
		parent.add_child(multi_mesh_instance)
		multi_mesh_instance.owner = parent  # Set owner for editor visibility
		print("Added MultiMeshInstance3D ", multi_mesh_instance.name, " with ", instances.size(), " instances")

	if parent.get_child_count() == 0:
		push_warning("No valid meshes were added to the parent node.")
		return null
	
	return parent

func convert_multimesh_to_gridmap(node: Node, mesh_library: MeshLibrary = null) -> GridMap:
	var gridmap = GridMap.new()
	gridmap.name = "ConvertedGridMap"
	gridmap.cell_size = Vector3(1, 0.01, 1)

	if not mesh_library:
		push_warning("No MeshLibrary provided. Creating a temporary one.")
		mesh_library = MeshLibrary.new()

	# Collect all MultiMeshInstance3D nodes
	var multimesh_instances = []
	_collect_multimesh_instances(node, multimesh_instances)
	print("Found ", multimesh_instances.size(), " MultiMeshInstance3D nodes")

	if multimesh_instances.size() == 0:
		push_warning("No MultiMeshInstance3D nodes found.")
		return null

	# Map meshes to MeshLibrary IDs
	var mesh_to_id = {}
	var next_id = 0
	
	# First pass: register all unique meshes
	for mm_instance in multimesh_instances:
		var multimesh = mm_instance.multimesh
		if not multimesh or not multimesh.mesh:
			continue

		var mesh = multimesh.mesh
		var mesh_key = mesh.resource_path if mesh.resource_path else str(mesh.get_instance_id())
		
		if not mesh_key in mesh_to_id:
			var existing_id = _find_mesh_in_library(mesh_library, mesh)
			if existing_id == -1:
				mesh_library.create_item(next_id)
				mesh_library.set_item_mesh(next_id, mesh)
				
				# Set item name
				var mesh_name = mm_instance.name if mm_instance.name else (mesh.resource_name if mesh.resource_name else "Mesh_%d" % next_id)
				mesh_library.set_item_name(next_id, mesh_name)
				
				# Generate and set preview (synchronous version)
				_generate_mesh_preview(mesh_library, next_id, mesh)
				
				mesh_to_id[mesh_key] = next_id
				next_id += 1
			else:
				mesh_to_id[mesh_key] = existing_id

	# Second pass: place all instances
	for mm_instance in multimesh_instances:
		var multimesh = mm_instance.multimesh
		if not multimesh or not multimesh.mesh:
			continue

		var mesh = multimesh.mesh
		var mesh_key = mesh.resource_path if mesh.resource_path else str(mesh.get_instance_id())
		var mesh_id = mesh_to_id[mesh_key]

		for i in range(multimesh.instance_count):
			var local_transform = multimesh.get_instance_transform(i)
			var global_transform = mm_instance.global_transform * local_transform
			
			var cell = _accurate_transform_to_cell(global_transform, gridmap.cell_size)
			var orientation = _improved_basis_to_orthogonal_index(global_transform.basis, gridmap)
			
			print("Placing at cell %s with mesh %d (%s), orientation %d" % [cell, mesh_id, mesh_library.get_item_name(mesh_id), orientation])
			
			gridmap.set_cell_item(cell, mesh_id, orientation)

	gridmap.mesh_library = mesh_library
	return gridmap

# Synchronous version of preview generation
func _generate_mesh_preview(library: MeshLibrary, item_id: int, mesh: Mesh) -> void:
	# Viewport ayarları
	var viewport = SubViewport.new()
	viewport.size = Vector2i(256, 256)  # Daha yüksek çözünürlük
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	# 3D Dünya ayarları
	var world = World3D.new()
	var env = Environment.new()
	
	# Işıklandırma
	var directional_light = DirectionalLight3D.new()
	directional_light.light_energy = 1.5
	directional_light.rotation_degrees = Vector3(-45, 45, 0)
	
	# Kamera ayarları
	var camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 40
	camera.near = 0.1
	camera.far = 100
	
	# Mesh'in boyutuna göre kamera pozisyonu
	var aabb = mesh.get_aabb()
	var center = aabb.get_center()
	var size = aabb.size.length()
	
	camera.position = center + Vector3(size * 0.5, size * 1.5, size * 1.5)
	
	var direction = (center - camera.position).normalized()
	var up = Vector3(0, 1, 0)
	var right = up.cross(direction).normalized()
	var new_up = direction.cross(right).normalized()
	camera.rotation = Basis(right, new_up, -direction).get_euler()
	
	# Mesh instance
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	
	# Arkaplan rengi
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.1)
	
	# Ambient light
	env.ambient_light_energy = 0.5
	env.ambient_light_color = Color(0.8, 0.8, 0.8)
	
	# Dünyaya ekleme
	world.environment = env
	viewport.world_3d = world
	
	# Tüm node'ları viewport'a ekle
	viewport.add_child(camera)
	viewport.add_child(directional_light)
	viewport.add_child(mesh_instance)
	
	# Geçici olarak sahneye ekle
	var scene_tree: SceneTree = Engine.get_main_loop()
	scene_tree.get_root().add_child(viewport)
	
	# Render için bekle
	await RenderingServer.frame_post_draw
	
	# Görüntüyü al ve texture oluştur
	var image = viewport.get_texture().get_image()
	var texture = ImageTexture.create_from_image(image)
	library.set_item_preview(item_id, texture)
	
	# Temizlik
	viewport.queue_free()

func _find_mesh_in_library(library: MeshLibrary, mesh: Mesh) -> int:
	for id in library.get_item_list():
		if library.get_item_mesh(id) == mesh:
			return id
	return -1

func _accurate_transform_to_cell(transform: Transform3D, cell_size: Vector3) -> Vector3i:
	var pos = transform.origin
	return Vector3i(
		snappedi(pos.x / cell_size.x, 1),
		snappedi(pos.y / cell_size.y, 1),
		snappedi(pos.z / cell_size.z, 1)
	)

func _improved_basis_to_orthogonal_index(basis: Basis, gridmap: GridMap) -> int:
	var best_index = 0
	var min_diff = INF
	
	for i in range(24):
		var grid_basis = gridmap.get_basis_with_orthogonal_index(i)
		var diff = _precise_basis_difference(basis, grid_basis)
		
		if diff < min_diff:
			min_diff = diff
			best_index = i
			if diff < 0.0001:
				break
	
	return best_index

func _precise_basis_difference(basis1: Basis, basis2: Basis) -> float:
	var diff = 0.0
	for i in range(3):
		var axis1 = basis1[i]
		var axis2 = basis2[i]
		diff += axis1.angle_to(axis2) + abs(axis1.length() - axis2.length())
	return diff

func _collect_multimesh_instances(node: Node, instances: Array):
	if node is MultiMeshInstance3D:
		instances.append(node)
	for child in node.get_children():
		_collect_multimesh_instances(child, instances)

	
func _collect_mesh_instances(node: Node, mesh_instances: Array):
	if node is MeshInstance3D:
		mesh_instances.append(node)
		print("Collected MeshInstance3D: ", node.name)
	for child in node.get_children():
		_collect_mesh_instances(child, mesh_instances)
