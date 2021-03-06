extends Button

var selected


# Called when the node enters the scene tree for the first time.
func _ready():
	selected = false


func _on_pressed():
	selected = !selected
	if selected:
		self.add_color_override("font_color", Color.red)
		self.add_color_override("font_color_hover", Color.red)
		PlayerData.abilities.append(self.name.to_lower())
		if GameData.merchantPool.has(self.name.to_lower()):
			GameData.merchantPool.remove(GameData.merchantPool.find(self.name.to_lower()))
	else:
		get_node("../../MenuSFX").play("select2")
		self.add_color_override("font_color", Color.white)
		self.add_color_override("font_color_hover", Color.white)
		var index = PlayerData.abilities.find(self.name.to_lower())
		PlayerData.abilities.remove(index)
		if !GameData.merchantPool.has(self.name.to_lower()):
			GameData.merchantPool.append(self.name.to_lower())

