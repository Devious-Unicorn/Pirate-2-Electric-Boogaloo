extends StaticBody2D

var noise = FastNoiseLite.new()

@export_group("Generation values")
@export_range(0, 1, 0.01) var sandThreshold: float = 0.05
@export_range(-1, 1, 0.01) var sea_level = 0.5

@export_group("Game Parameters")
@export var gameSize := Vector2i(480, 270) # Use smaller size for BitMap speed
@export var scale_factor: float = 8.0
@export var noise_freq: float = 0.01
@export var octaves: int = 3

@export var island_shader: Shader

func _ready() -> void:
	# Initialize noise using EXPORTED frequency
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	noise.cellular_distance_function = FastNoiseLite.DISTANCE_EUCLIDEAN
	noise.cellular_return_type = FastNoiseLite.RETURN_DISTANCE2_ADD
	noise.frequency = noise_freq
	noise.fractal_octaves = octaves
	_buildMesh()

func _buildMesh():
	# Use the EXPORTED gameSize
	var img = Image.create(gameSize.x, gameSize.y, false, Image.FORMAT_RGBA8)
	
	for y in range(gameSize.y):
		for x in range(gameSize.x):
			var val = noise.get_noise_2d(x, y)
			# normalize the noise range from [-1, 1] to [0, 1]
			var normalized_val = (val + 1) / 2
			
			if normalized_val > sea_level:
				img.set_pixel(x, y, Color(1, 1, 1, 1)) # Land
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0)) # Water

	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(img, 0.5) 
	
	var polys = bitmap.opaque_to_polygons(Rect2i(0, 0, gameSize.x, gameSize.y))
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vertexOffset = 0
	
	for poly in polys:
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
			
			# keep collision inside the loop as physics work better when it is multiple islands
			create_island_collision(finalPoly)
	
	# commit whole surface tool to one mesh to improve performance over making a whole mesh for each island
	var mesh := MeshInstance2D.new()
	mesh.mesh = st.commit()
	
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
	
	# Scale points
	var scaled_points = PackedVector2Array()
	for p in points:
		scaled_points.append(p * scale_factor)

	# Ensure correct winding order
	if not Geometry2D.is_polygon_clockwise(scaled_points):
		scaled_points.reverse()
	
	# Offsetting by 0.0 'welds' vertices and removes self-intersections
	var cleaned = Geometry2D.offset_polygon(scaled_points, 0.0)
	if cleaned.is_empty(): return
	scaled_points = cleaned
	
	var col = CollisionPolygon2D.new()
	col.build_mode = CollisionPolygon2D.BUILD_SOLIDS
	col.polygon = scaled_points 
	
	add_child(col)
	# This line tells Godot to look at this node for physics right now
	col.owner = self 
	
	if col.polygon.size() == 0: printerr("Collision polygon has 0 points")
	print("Collision created at: ", scaled_points[0])
