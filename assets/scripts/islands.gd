extends StaticBody2D

var noise = FastNoiseLite.new()
@export_range(0, 1, 0.01) var sandThreshold = 0.3;
@export var gameSize := Vector2(3840, 2160)
@export var scale_factor: float = 1
@export var sea_level := 0.75
@export var noise_freq := 0.01

func _ready() -> void:
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.cellular_jitter = 1.0
	noise.frequency = noise_freq
	noise.fractal_octaves = 5
	_buildMesh()

func _buildMesh():
	var img = Image.create(gameSize.x, gameSize.y, false, Image.FORMAT_RGBA8)
	
	for y in range(gameSize.y):
		for x in range(gameSize.x):
			var val = noise.get_noise_2d(x, y)
			# Normalize noise: -1.0...1.0 becomes 0.0...1.0
			var normalized_val = (val + 1.0) / 2.0
			
			# IMPORTANT: If sea_level is 0.75, only values > 0.75 become land
			if normalized_val > sea_level:
				# Use Alpha 1.0 for land
				img.set_pixel(x, y, Color(1, 1, 1, 1.0)) 
			else:
				# Use Alpha 0.0 for water
				img.set_pixel(x, y, Color(0, 0, 0, 0.0))

	var bitmap = BitMap.new()
	# The 0.5 threshold here refers to the ALPHA channel we just set (0.0 or 1.0)
	bitmap.create_from_image_alpha(img, 0.5) 
	
	var polys = bitmap.opaque_to_polygons(Rect2i(0, 0, gameSize.x, gameSize.y))
	
	# DEBUG: If this prints 0, your sea_level is too high for this seed
	print("Islands found: ", polys.size())
	
	for poly in polys:
		# Remove the manual 'scaled_poly' loop here. 
		# Just clean the raw poly from the bitmap.
		var cleaned = Geometry2D.offset_polygon(poly, -0.1)
		if cleaned.is_empty(): continue
		
		for final_poly in cleaned:
			create_island_mesh(final_poly)
			create_island_collision(final_poly)

func create_island_mesh(points: PackedVector2Array):
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# 'points' are now 0-480 (pixel space)
	var indices = Geometry2D.triangulate_polygon(points)
	if indices.is_empty(): return

	for p in points:
		# Use the RAW pixel coordinate for noise sampling
		var val = noise.get_noise_2d(p.x, p.y) 
		st.set_color(get_noise_color(val))
		
		# Scale only the POSITION for the game world
		var final_pos = p * scale_factor
		st.add_vertex(Vector3(final_pos.x, final_pos.y, 0))

	for index in indices:
		st.add_index(index)

		var mesh_instance = MeshInstance2D.new()
		mesh_instance.mesh = st.commit()
		
		# Set Material to show Vertex Colors
		var mat = CanvasItemMaterial.new()
		mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		mesh_instance.material = mat
		
		add_child(mesh_instance)

func create_island_collision(points: PackedVector2Array):
	var scaled_points = PackedVector2Array()
	for p in points:
		scaled_points.append(p * scale_factor)
		
	var col = CollisionPolygon2D.new()
	col.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
	col.polygon = scaled_points # Use the scaled ones!
	add_child(col)

func get_noise_color(v: float) -> Color:
	var normalized_v = (v + 1.0) / 2.0
	# This maps the range [sea_level to 1.0] onto [0.0 to 1.0]
	var adjusted_v = (normalized_v - sea_level) / (1.0 - sea_level)
	adjusted_v = clamp(adjusted_v, 0.0, 1.0)

	if adjusted_v < sandThreshold:
		return Color(0.94, 0.82, 0.6) # Sand
		
	# 3. Calculate gradient for the grass
	var t = (adjusted_v - sandThreshold) / (1.0 - sandThreshold)
	t = clamp(t, 0.0, 1.0) # Always clamp for lerps
	
	return Color(0.5, 0.9, 0.2).lerp(Color(0.05, 0.3, 0.05), t)
