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
			var normalized_val = (val + 1) / 2
			
			if normalized_val > sea_level:
				img.set_pixel(x, y, Color(1, 1, 1, 1)) # Land
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0)) # Water

	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(img, 0.5) 
	
	var polys = bitmap.opaque_to_polygons(Rect2i(0, 0, gameSize.x, gameSize.y))
	
	# Clear existing islands if re-generating
	for child in get_children():
		if child is MeshInstance2D or child is CollisionPolygon2D:
			child.queue_free()
	print("Islands found: ", str(polys.size()))
	for poly in polys:
		if poly.size() < 3: continue
		var cleaned = Geometry2D.offset_polygon(poly, 1.0, Geometry2D.JOIN_ROUND) # Slightly inflate
		cleaned = Geometry2D.offset_polygon(cleaned[0], -1.1, Geometry2D.JOIN_ROUND) # Shrink back
		for final_poly in cleaned:
			if final_poly.size() < 3: continue
			create_island_mesh(final_poly)
			create_island_collision(final_poly)

func create_island_mesh(points: PackedVector2Array):
	var indices = Geometry2D.triangulate_polygon(points)
	if indices.is_empty(): return

	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for p in points:
		# Map the pixel coordinate to a 0-1 UV range for the shader
		var uv = Vector2(p.x / float(gameSize.x), p.y / float(gameSize.y))
		st.set_uv(uv)
		
		var final_pos = p * scale_factor
		st.add_vertex(Vector3(final_pos.x, final_pos.y, 0))

	for index in indices:
		st.add_index(index)

	var mesh_instance = MeshInstance2D.new()
	mesh_instance.mesh = st.commit()
	
	# Assign the shader from the Inspector
	var mat = ShaderMaterial.new()
	mat.shader = island_shader
	
	# Create the noise texture for the shader to read
	var noise_tex = NoiseTexture2D.new()
	noise_tex.noise = noise
	noise_tex.width = gameSize.x
	noise_tex.height = gameSize.y
	
	mat.set_shader_parameter("noise_tex", noise_tex)
	mat.set_shader_parameter("sea_level", sea_level)
	mat.set_shader_parameter("sand_threshold", sandThreshold)
	
	mesh_instance.material = mat
	add_child(mesh_instance)

func create_island_collision(points: PackedVector2Array):
	var scaled_points = PackedVector2Array()
	for p in points:
		scaled_points.append(p * scale_factor)
		
	var col = CollisionPolygon2D.new()
	col.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	col.polygon = scaled_points 
	add_child(col)

func get_noise_color(v: float) -> Color:
	var normalized_v = (v + 1.0) / 2.0
	
	# Uses EXPORTED sea_level dynamically
	var adjusted_v = (normalized_v - sea_level) / (1.0 - sea_level)
	adjusted_v = clamp(adjusted_v, 0.0, 1.0)

	# Uses EXPORTED sandThreshold dynamically
	if adjusted_v < sandThreshold: 
		print("sand")
		return Color(0.94, 0.82, 0.6) # Sand
		
	var t = (adjusted_v - sandThreshold) / (1.0 - sandThreshold)
	t = clamp(t, 0, 1)
	print("grass:\t", str(Color(0.5, 0.9, 0.2).lerp(Color(0.05, 0.3, 0.05), t)))
	return Color(0.5, 0.9, 0.2).lerp(Color(0.05, 0.3, 0.05), t)
