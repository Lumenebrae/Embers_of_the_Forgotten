extends KinematicBody2D

var movement = 1100
var damageValue = 350
var orientation = 1
var force = Vector2(400, -120) #
var velocity
# Called when the node enters the scene tree for the first time.
func _ready():
	if (orientation == 1):
		$Right.visible = true
		$Left.visible = false
		$AnimationPlayer.play("right")
	else:
		$Left.visible = true
		$Right.visible = false
		$AnimationPlayer.play("left")
	velocity = Vector2(movement*orientation, 0)

func _physics_process(_delta):
	var _MASret = move_and_slide(velocity)
	#print(position.y)
	if position.x < -1000:
		queue_free()

#func fire():
	#velocity.x = movement*orientation
	#print(PlayerData.playerNode.get_parent())

func _on_Hitbox_body_entered(body):
	$Hitbox.queue_free()
	if (body.has_method("damageHandler")):
		body.damageHandler(damageValue, orientation, force)
	GameData.camera_node.shake(GameData.LIGHTSHAKE, 0.15)
	$sfx.play()
	hide()
	yield($sfx, "finished")
	queue_free()

