class_name SFXManager
extends Node

# Audio player nodes for different sounds
var coin_player: AudioStreamPlayer
var roll_player: AudioStreamPlayer
var shot_player: AudioStreamPlayer

# Sound paths
const COIN_SFX_PATH: String = "res://Goti/sfx/coin.wav"
const ROLL_SFX_PATH: String = "res://Goti/sfx/roll.wav"
const SHOT_SFX_PATH: String = "res://Goti/sfx/shot.mp3"

# Base volumes (will adjust per effect)
const COIN_VOLUME_DB: float = -8.0
const ROLL_VOLUME_DB: float = -12.0
const SHOT_VOLUME_DB: float = -18.0

# Pitch ranges for shot (hit effect)
const SHOT_PITCH_MIN: float = 0.8
const SHOT_PITCH_MAX: float = 1.3

func _ready() -> void:
	_setup_audio_players()

func _setup_audio_players() -> void:
	# Create coin player
	coin_player = AudioStreamPlayer.new()
	coin_player.stream = load(COIN_SFX_PATH)
	coin_player.volume_db = COIN_VOLUME_DB
	coin_player.bus = "Master"  # Make sure "Master" bus exists
	add_child(coin_player)
	
	# Create roll player
	roll_player = AudioStreamPlayer.new()
	roll_player.stream = load(ROLL_SFX_PATH)
	roll_player.volume_db = ROLL_VOLUME_DB
	roll_player.bus = "Master"
	add_child(roll_player)
	
	# Create shot player (with pitch shifter)
	shot_player = AudioStreamPlayer.new()
	shot_player.stream = load(SHOT_SFX_PATH)
	shot_player.volume_db = SHOT_VOLUME_DB
	shot_player.bus = "Master"
	add_child(shot_player)

# Play coin sound repeatedly (for credit countup)
func play_coin_loop() -> void:
	if coin_player and not coin_player.playing:
		coin_player.play()

# Stop coin sound
func stop_coin() -> void:
	if coin_player:
		coin_player.stop()

# Play roll sound repeatedly (for spinning reels)
func play_roll_loop() -> void:
	if roll_player and not roll_player.playing:
		roll_player.play()

# Stop roll sound
func stop_roll() -> void:
	if roll_player:
		roll_player.stop()

# Play reel hit sound with random pitch (plays once, then can play again)
func play_shot_hit(pitch: float = 1.0) -> void:
	if shot_player:
		shot_player.pitch_scale = pitch
		shot_player.play()

# Play shot with random pitch variation
func play_shot_random_pitch() -> void:
	var pitch: float = randf_range(SHOT_PITCH_MIN, SHOT_PITCH_MAX)
	play_shot_hit(pitch)

# Stop all sounds
func stop_all() -> void:
	stop_coin()
	stop_roll()
	if shot_player:
		shot_player.stop()
