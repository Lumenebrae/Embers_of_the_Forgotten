extends Button


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.




func _submit():
	get_node("../MenuSFX").play("select1") #need to do it in the same function otherwise it will pass the timer to another thread
	yield(get_tree().create_timer(0.8), "timeout")
	var exec = get_tree().change_scene("res://Scenes/Stage.tscn")
	if exec != OK:
		print("ERROR SWITCHING FROM MAIN MENU TO STAGE")
	return 
	
	#var parent = get_parent()
	#var root = get_tree().get_root()
	#var level_node = load("res://Scenes/Stage.tscn")
	#root.add_child(level_node.instance())
	#root.remove_child(parent)
	#parent.queue_free()
	
