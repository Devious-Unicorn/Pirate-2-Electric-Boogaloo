extends StaticBody2D

var noise = FastNoiseLite.new()
@export_range(0, 1, 0.01) var sandThreshold = 0.3;
@export var gameSize := Vector2(3840, 2160)
@export var scale_factor: float = 1

func _ready() -> void:
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.cellular_jitter = 1.0
	noise.frequency = 0.001
	_buildMesh()

func _buildMesh():
	# Use FORMAT_RGBA8 so we can explicitly set Alpha
	var img = Image.create(gameSize.x, gameSize.y, false, Image.FORMAT_RGBA8)
	
	for y in range(gameSize.y):
		for x in range(gameSize.x):
			var val = noise.get_noise_2d(x, y)
			# If noise > 0, make it opaque (Alpha 1.0)
			# If noise <= 0, make it transparent (Alpha 0.0)
			if val > 0:
				img.set_pixel(x, y, Color(val, val, val, 1.0)) 
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0.0))

	var bitmap = BitMap.new()
	# Now create_from_image_alpha will correctly find the islands
	bitmap.create_from_image_alpha(img, 0.75) 
	
	var polys = bitmap.opaque_to_polygons(Rect2i(0, 0, gameSize.x, gameSize.y))

	for poly in polys:
		# Scale the raw bitmap points to game space
		var scaled_poly = PackedVector2Array()
		for p in poly:
			scaled_poly.append(p * scale_factor)
			
		# Clean the polygon to prevent physics glitches
		var cleaned = Geometry2D.offset_polygon(scaled_poly, -0.1)
		if cleaned.is_empty(): continue
		
		for final_poly in cleaned:
			create_island_mesh(final_poly)
			create_island_collision(final_poly)

func create_island_mesh(points: PackedVector2Array):
	# 1. Scale the points
	var scaled_points = PackedVector2Array()
	for p in points:
		scaled_points.append(p * scale_factor)

	# 2. CLEAN & SIMPLIFY (The Godot 4.x way)
	# Using offset_polygon with a 0.0 or tiny value "welds" vertices 
	# and removes self-intersections that cause the triangulator to crash.
	var cleaned_polys = Geometry2D.offset_polygon(scaled_points, -0.5, Geometry2D.JOIN_ROUND)
	
	if cleaned_polys.is_empty():
		return

	for poly in cleaned_polys:
		# 3. TRIANGULATE
		var indices = Geometry2D.triangulate_polygon(poly)
		
		if indices.is_empty():
			continue # Skip if triangulation fails

		# 4. BUILD THE MESH
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		
		for p in poly:
			# Get noise value for color (undoing the scale)
			var val = noise.get_noise_2d(p.x / scale_factor, p.y / scale_factor)
			st.set_color(get_noise_color(val))
			st.add_vertex(Vector3(p.x, p.y, 0))

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
	var col = CollisionPolygon2D.new()
	
	# 1. SET THE MODE FIRST (This prevents the default decomposition)
	col.build_mode = CollisionPolygon2D.BUILD_SEGMENTS # Use SEGMENTS for complex noise
	
	# 2. WELD THE POINTS
	# Offsetting by 0.0 or a tiny amount removes duplicate vertices
	# which are the #1 cause of "Convex decomposing failed"
	var cleaned = Geometry2D.offset_polygon(points, 0.0)
	
	if cleaned.is_empty():
		return
		
	# 3. ASSIGN THE CLEANED POLYGON
	col.polygon = cleaned[0]
	add_child(col)

func get_noise_color(v: float) -> Color:
	# 'v' is the raw noise value (e.g., 0.5 to 1.0)
	# Let's normalize it so 'sea level' (0.5) is 0.0 for our math
	var sea_level = 0.5 
	var adjusted_v = (v - sea_level) / (1.0 - sea_level)
	
	if adjusted_v < sandThreshold:
		return Color(0.94, 0.82, 0.6) # Sand
		
	# Gradient for the rest
	var t = (adjusted_v - sandThreshold) / (1.0 - sandThreshold)
	return Color(0.5, 0.9, 0.2).lerp(Color(0.05, 0.3, 0.05), t)
