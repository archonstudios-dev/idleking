# Builds cached sprite-sheet metadata for combat visuals with imported-texture fallback support.
extends RefCounted

const KING_IDLE_PATH := "res://Assets/Art/King/Medieval King Pack 2/Sprites/Idle.png"
const KING_ATTACK_PATH := "res://Assets/Art/King/Medieval King Pack 2/Sprites/Attack1.png"
const KING_ATTACK_TWO_PATH := "res://Assets/Art/King/Medieval King Pack 2/Sprites/Attack2.png"
const KING_ATTACK_THREE_PATH := "res://Assets/Art/King/Medieval King Pack 2/Sprites/Attack3.png"
const KING_RUN_PATH := "res://Assets/Art/King/Medieval King Pack 2/Sprites/Run.png"
const KING_JUMP_PATH := "res://Assets/Art/King/Medieval King Pack 2/Sprites/Jump.png"
const KING_FALL_PATH := "res://Assets/Art/King/Medieval King Pack 2/Sprites/Fall.png"
const KING_HIT_PATH := "res://Assets/Art/King/Medieval King Pack 2/Sprites/Take Hit.png"
const KING_DEATH_PATH := "res://Assets/Art/King/Medieval King Pack 2/Sprites/Death.png"
const ENEMY_IDLE_PATH := "res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Idle.png"
const ENEMY_ATTACK_ONE_PATH := "res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Attack1.png"
const ENEMY_ATTACK_TWO_PATH := "res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Attack2.png"
const ENEMY_RUN_PATH := "res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Run.png"
const ENEMY_HIT_PATH := "res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Take hit.png"
const ENEMY_DEATH_PATH := "res://Assets/Art/Enemies/EVil Wizard 2/Sprites/Death.png"
const CASTLE_PATH := "res://Assets/Art/Castle/ground.png"

static var _king_animations: Dictionary = {}
static var _enemy_animations: Dictionary = {}
const KING_VISIBLE_HEIGHT := 53.0
const ENEMY_VISIBLE_HEIGHT := 132.0


static func get_king_animations() -> Dictionary:
	if _king_animations.is_empty():
		_king_animations = {
			"idle": _make_animation(KING_IDLE_PATH, 10, 10.0, true),
			"run": _make_animation(KING_RUN_PATH, 10, 12.0, true),
			"attack_1": _make_animation(KING_ATTACK_PATH, 5, 14.0, false),
			"attack_2": _make_animation(KING_ATTACK_TWO_PATH, 5, 14.0, false),
			"attack_3": _make_animation(KING_ATTACK_THREE_PATH, 5, 14.0, false),
			"hit": _make_animation(KING_HIT_PATH, 5, 12.0, false),
			"death": _make_animation(KING_DEATH_PATH, 6, 10.0, false),
		}
	return _king_animations.duplicate(true)


static func get_enemy_animations() -> Dictionary:
	if _enemy_animations.is_empty():
		_enemy_animations = {
			"idle": _make_animation(ENEMY_IDLE_PATH, 8, 9.0, true),
			"run": _make_animation(ENEMY_RUN_PATH, 8, 12.0, true),
			"attack_1": _make_animation(ENEMY_ATTACK_ONE_PATH, 8, 12.0, false),
			"attack_2": _make_animation(ENEMY_ATTACK_TWO_PATH, 8, 12.0, false),
			"hit": _make_animation(ENEMY_HIT_PATH, 3, 12.0, false),
			"death": _make_animation(ENEMY_DEATH_PATH, 7, 10.0, false),
		}
	return _enemy_animations.duplicate(true)


static func get_king_frames() -> SpriteFrames:
	return _build_sprite_frames(get_king_animations())


static func get_enemy_frames() -> SpriteFrames:
	return _build_sprite_frames(get_enemy_animations())


static func get_castle_texture() -> Texture2D:
	return _load_texture(CASTLE_PATH)


static func get_king_visible_height() -> float:
	return KING_VISIBLE_HEIGHT


static func get_enemy_visible_height() -> float:
	return ENEMY_VISIBLE_HEIGHT


static func _make_animation(texture_path: String, frame_count: int, fps: float, loop: bool) -> Dictionary:
	var texture := _load_texture(texture_path)
	return {
		"texture": texture,
		"frames": frame_count,
		"fps": fps,
		"loop": loop,
	}


static func _build_sprite_frames(animation_map: Dictionary) -> SpriteFrames:
	var frames := SpriteFrames.new()
	for animation_name in animation_map.keys():
		var animation: Dictionary = animation_map[animation_name]
		var texture: Texture2D = animation.get("texture") as Texture2D
		var frame_count: int = int(animation.get("frames", 1))
		if texture == null or frame_count <= 0:
			continue
		var frame_width: int = maxi(1, texture.get_width() / frame_count)
		var frame_height: int = texture.get_height()
		frames.add_animation(StringName(animation_name))
		frames.set_animation_speed(StringName(animation_name), float(animation.get("fps", 10.0)))
		frames.set_animation_loop(StringName(animation_name), bool(animation.get("loop", true)))
		for frame_index in frame_count:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(frame_index * frame_width, 0, frame_width, frame_height)
			frames.add_frame(StringName(animation_name), atlas)
	return frames


static func _load_texture(path: String) -> Texture2D:
	# Prefers imported textures when present and falls back to raw image loading for local assets.
	if ResourceLoader.exists(path):
		var imported_texture := load(path) as Texture2D
		if imported_texture != null:
			return imported_texture

	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		push_warning("Unable to load combat image at %s." % path)
		return null

	return ImageTexture.create_from_image(image)


static func get_texture_from_file(path: String) -> Texture2D:
	# Public helper for combat visuals that need direct image loading.
	return _load_texture(path)
