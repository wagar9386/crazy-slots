extends RigidBody2D

@export var hit_sound: AudioStream


func _ready():
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	contact_monitor = true
	max_contacts_reported = 20
	linear_velocity = Vector2(randf_range(-15, 15), 0)
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if body.is_in_group("pins"):
		play_hit_sound()


func play_hit_sound():
	var player = AudioStreamPlayer2D.new()
	add_child(player)

	player.stream = hit_sound

	# 🔥 variación aleatoria
	player.pitch_scale = randf_range(0.9, 1.1)
	player.volume_db = randf_range(-5, 0)

	player.play()

	# 🧹 borrar cuando termine
	player.finished.connect(player.queue_free)
