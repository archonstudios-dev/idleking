# Manages background music playback and a global mute toggle for the early game.
extends Node

const MAIN_MUSIC_PATH := "res://Assets/Music/universalmusic.mp3"
const BRANDING_MUSIC_PATH := "res://Assets/Music/branding-scene-sfx.mp3"
const DEFAULT_VOLUME_DB := -12.0

signal mute_changed(is_muted: bool)

enum MusicTrack {
	NONE,
	BRANDING,
	MAIN,
}

var is_muted: bool = false

var _music_player: AudioStreamPlayer
var _branding_player: AudioStreamPlayer
var _hit_stream: AudioStream
var _current_music_track: int = MusicTrack.NONE
var _branding_played: bool = false


func _ready() -> void:
	# Restores saved audio preference and prepares looping playback immediately.
	is_muted = SaveManager.get_audio_muted()

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.stream = _load_mp3_stream(MAIN_MUSIC_PATH)
	_music_player.volume_db = DEFAULT_VOLUME_DB
	_music_player.bus = "Master"
	add_child(_music_player)

	_branding_player = AudioStreamPlayer.new()
	_branding_player.name = "BrandingPlayer"
	_branding_player.stream = _load_mp3_stream(BRANDING_MUSIC_PATH, false)
	_branding_player.volume_db = DEFAULT_VOLUME_DB
	_branding_player.bus = "Master"
	add_child(_branding_player)

	_hit_stream = null

	_branding_player.finished.connect(_on_branding_finished)
	_apply_mute_state()


func play_branding() -> void:
	# Plays the branding cue once per session and pauses the main loop.
	if _branding_played:
		play_main_music()
		return
	_branding_played = true
	_set_music_track(MusicTrack.BRANDING)


func play_main_music() -> void:
	# Starts the looping main background track and stops any branding cue.
	_set_music_track(MusicTrack.MAIN)


func stop_music() -> void:
	# Clears the active music state so unmute does not resume an old track.
	_set_music_track(MusicTrack.NONE)


func toggle_mute() -> bool:
	is_muted = not is_muted
	_apply_mute_state()
	SaveManager.set_audio_muted(is_muted)
	mute_changed.emit(is_muted)
	return is_muted


func get_hit_stream() -> AudioStream:
	return _hit_stream


func _apply_mute_state() -> void:
	var master_bus_index: int = AudioServer.get_bus_index("Master")
	if master_bus_index < 0:
		master_bus_index = 0
	AudioServer.set_bus_mute(master_bus_index, is_muted)
	AudioServer.set_bus_volume_db(master_bus_index, DEFAULT_VOLUME_DB)
	if _music_player != null:
		_music_player.volume_db = DEFAULT_VOLUME_DB
		_music_player.stream_paused = is_muted
	if _branding_player != null:
		_branding_player.volume_db = DEFAULT_VOLUME_DB
		_branding_player.stream_paused = is_muted
	if not is_muted:
		_resume_current_music()


func _load_mp3_stream(path: String, loop: bool = true) -> AudioStream:
	# Loads MP3 data directly so playback does not depend on imported resource metadata.
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		push_warning("Unable to load audio stream at %s." % path)
		return null

	var stream := AudioStreamMP3.new()
	stream.data = bytes
	stream.loop = loop
	return stream


func _set_music_track(track: int) -> void:
	_current_music_track = track
	_stop_all_music()
	_resume_current_music()


func _stop_all_music() -> void:
	if _music_player != null:
		_music_player.stop()
	if _branding_player != null:
		_branding_player.stop()


func _resume_current_music() -> void:
	if is_muted:
		return
	match _current_music_track:
		MusicTrack.BRANDING:
			if _branding_player != null and not _branding_player.playing:
				_branding_player.play()
		MusicTrack.MAIN:
			if _music_player != null and not _music_player.playing:
				_music_player.play()
		MusicTrack.NONE:
			pass


func _on_branding_finished() -> void:
	if _current_music_track == MusicTrack.BRANDING:
		_set_music_track(MusicTrack.MAIN)
