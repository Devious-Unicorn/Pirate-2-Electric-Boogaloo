extends StaticBody2D

var noise = FastNoiseLite.new()

@export_group("Generation Parameters")
@export_range(0, 1, 0.01) var sandThreshold: float = 0.05
@export_range(-1, 1, 0.01) var sea_level = 0.5
@export var noise_seed = null
@export var noise_freq: float = 0.01
@export var octaves: int = 3

@export_group("Game Parameters")
@export var gameSize := Vector2i(480, 270) # Use smaller size for BitMap speed
@export var scale_factor: float = 8.0
@export var LoadingScreen: PanelContainer
@export var Game: Node2D

@export var island_shader: Shader

signal generationComplete

var is_clone := false;
var cols: Array[CollisionPolygon2D]

func generate() -> void:
	if is_clone: return
	LoadingScreen.setStatus.call_deferred("Initialization for island procedural generation")
	# Initialize noise
	if noise_seed: pass
	else: noise_seed = randi()
	noise.seed = noise_seed
	noise_seed = noise.seed
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_ADD
	noise.frequency = noise_freq
	noise.fractal_octaves = octaves
	_buildMesh()
	generationComplete.emit.call_deferred()
	Game._on_islands_generation_complete.call()

func _buildMesh():
	LoadingScreen.setStatus.call_deferred("Convert noise to black and white image")
	# Use the EXPORTED gameSize
	var img = Image.create_empty(gameSize.x, gameSize.y, false, Image.FORMAT_RGBA8)
	
	for y in range(gameSize.y):
		for x in range(gameSize.x):
			# if at edge, set to water to try to fix problem with no collision working
			if x == 0 or y == 0 or x == gameSize.x - 1 or y == gameSize.y - 1:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var val = noise.get_noise_2d(x, y)
			# normalize the noise range from [-1, 1] to [0, 1]
			var normalized_val = (val + 1) / 2
			
			if normalized_val > sea_level:
				img.set_pixel(x, y, Color(1, 1, 1, 1)) # Land
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0)) # Water
	
	LoadingScreen.setStatus.call_deferred("Convert opaque areas of image to polygons")
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(img, 0.5)
	var polys = bitmap.opaque_to_polygons(Rect2i(0, 0, gameSize.x, gameSize.y))
	
	LoadingScreen.setStatus.call_deferred("Initialize SurfaceTool to create island mesh")
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertexOffset = 0
	
	var i: int = 1
	for poly in polys:
		LoadingScreen.setStatus.call_deferred("Create island meshes (%d/%d)" % [i, polys.size()])
		# skip this polygon if it does not have 3 vertices to avoid crashes
		if poly.size() < 3: continue
		var cleaned = Geometry2D.offset_polygon(poly, -0.1)
		
		for finalPoly in cleaned:
			if finalPoly.size() < 3: continue
			
			# turn the polygon into an array of triangles
			var indeces = Geometry2D.triangulate_polygon(finalPoly)
			if indeces.is_empty(): continue
			
			for p in finalPoly:
				# calculate uv and position and add everything to the mesh
				var uv = Vector2(p.x / float(gameSize.x), p.y / float(gameSize.y))
				st.set_uv(uv)
				var pos = p * scale_factor
				st.add_vertex(Vector3(pos.x, pos.y, 0))
			
			for index in indeces:
				# add index to st to build the polygon from vertices
				st.add_index(index + vertexOffset)
			
			vertexOffset += finalPoly.size()
			
			LoadingScreen.setStatus.call_deferred("Create island hitboxes (%d/%d)" % [i, polys.size()])
			# keep collision inside the loop as physics work better when it is multiple islands
			create_island_collision(finalPoly)
			i += 1
	
	# commit whole surface tool to one mesh to improve performance over making a whole mesh for each island
	LoadingScreen.setStatus.call_deferred("Merge island meshes")
	var mesh := MeshInstance2D.new()
	mesh.mesh = st.commit()
	
	LoadingScreen.setStatus.call_deferred("Calculate island color")
	# generate colors using the shader
	var mat := ShaderMaterial.new()
	mat.shader = island_shader
	
	# create noise texture for the shader to use
	var noise_tex := NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.width = gameSize.x
	noise_tex.height = gameSize.y
	await noise_tex.changed # wait for the noise texture to change before sending to the shader to make sure that  it renders properly
	# set the shader parameters
	mat.set_shader_parameter("noise_tex", noise_tex)
	mat.set_shader_parameter("sea_level", sea_level)
	mat.set_shader_parameter("sand_threshold", sandThreshold)
	
	mesh.material = mat
	add_child(mesh)

func create_island_collision(points: PackedVector2Array):
	if points.size() < 3: return
	
	# 1. Create the Visual/Physics Island (Your existing code)
	var scaled_points = PackedVector2Array()
	for p in points: scaled_points.append(p * scale_factor)
	if not Geometry2D.is_polygon_clockwise(scaled_points):
		scaled_points.reverse()
	
	# 2. Add a NavigationRegion2D SPECIFICALLY for this island
	var nav_region := NavigationRegion2D.new()
	var nav_poly := NavigationPolygon.new()
	
	# Modern Godot 4 way to manually build a nav mesh from points:
	nav_poly.vertices = scaled_points
	# Create an array of indices pointing to the vertices (0, 1, 2, 3...)
	var indices = PackedInt32Array()
	for i in range(scaled_points.size()):
		indices.append(i)
	
	# Add one polygon made of all those vertices
	nav_poly.add_polygon(indices)
	
	nav_region.navigation_polygon = nav_poly
	add_child.call_deferred(nav_region)
	
	# 3. Create the Physics Collider (Your existing code)
	var cleaned_polys = Geometry2D.offset_polygon(scaled_points, 0.0)
	for poly in cleaned_polys:
		var col := CollisionPolygon2D.new()
		col.build_mode = CollisionPolygon2D.BUILD_SOLIDS
		col.polygon = poly
		# add this collider to the cols array for use in the house spawning script
		cols.append(col)
		add_child.call_deferred(col)

func duplicate_data_to(target: Node2D) -> void:
	# 1. Share the Mesh and Material
	for child in get_children():
		if child is MeshInstance2D:
			var new_mesh_node = MeshInstance2D.new()
			# Resources (Mesh/Material) are shared by reference, which is very fast
			new_mesh_node.mesh = child.mesh
			new_mesh_node.material = child.material
			target.add_child(new_mesh_node)
		
		# 2. Duplicate Collision Polygons
		#elif child is CollisionPolygon2D:
			#var new_col = child.duplicate() # duplicate() creates a deep copy of the node
			#target.add_child(new_col)
	
	# 3. Copy physics layers
	target.collision_layer = self.collision_layer
	target.collision_mask = self.collision_mask
