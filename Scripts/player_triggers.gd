extends Area2D


# Declare member variables here. Examples:
# var a = 2


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#pass

func add_money(value):
	var Player = get_parent()
	Player.currency += value
	Player.get_parent().get_node("HUD").change_money(get_parent().currency)
	#trigger sounds and stuff
