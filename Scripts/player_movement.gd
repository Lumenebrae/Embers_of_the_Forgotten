extends KinematicBody2D


# Member variables here
export var playerGravity = 600
export var playerSpeed = 400
export var terminalVelocity = 1500
export var sprintVelocity = 2500
export var floatDenominator = 1.3

var playerVelocity = Vector2()
var playerDistance
var jump_power = 500
var jump_count = 0
var max_JC = 1
var fsm #finite state machine
var xPositivity = true
var crouched = false
var currentUse
var jumping
var holdingm1
var holdingm2 = false

var sprinting = false
var wallgrabbing = false

var platform_cling_time = 0
const min_cling_time = 0.3

var platform_clinging = false
var platform_clinging_side
var ledge_area_clinging

#healthbar 
export var playerOnHitInvuln = 1
var invulnTimer
var main

#moveset instanced scene dictionary
onready var movesetDict = {
	"sword": $PlayerCenter/Sword,
	"scythe": $PlayerCenter/Scythe,
	"spear": $PlayerCenter/Spear,
	"fireball": $PlayerCenter/Fireball,
	"firewave": $PlayerCenter/Firewave
}

#var respawn_menu = preload("res://Scenes/RespawnMenu.tscn")
signal respawn

# Called when the node enters the scene tree for the first time.
func _ready():
	#print(PlayerData.abilities)
	if "double jump" in PlayerData.abilities:
		max_JC = 2
	if "triple jump" in PlayerData.abilities:
		max_JC = 3
	if "dash" in PlayerData.abilities:
		sprintVelocity = 3500
	PlayerData.playerNode = self
	main = self.get_parent()
	playerVelocity.y = playerGravity
	invulnTimer = 0
	holdingm1 = false
	holdingm2 = false
	initDefault() #TEMP
	fsm = $AnimationStateMachine.get("parameters/playback")
	connect("respawn", get_node("../Menus/RespawnMenu/Control"), "respawn")

func initDefault():
	PlayerData.playerHealth = PlayerData.playerHealthMax
	equip()

func equip(): 
	match PlayerData.equipped.size():
		0:
			PlayerData.wpnslot1 = null
			PlayerData.wpnslot2 = null
		1:
			PlayerData.wpnslot1 = movesetDict[PlayerData.equipped[0]]
			PlayerData.wpnslot2 = null
		2:
			PlayerData.wpnslot1 = movesetDict[PlayerData.equipped[0]]
			PlayerData.wpnslot2 = movesetDict[PlayerData.equipped[1]]
		_:
			return

func initLoad(stcurrency, stHealth):
	PlayerData.playerHealth = stHealth
	PlayerData.currency = stcurrency

# Called every phys frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	
	#disable actions if game is paused
	if GameData.paused || GameData.player_dead:
		return
	
	if PlayerData.playerHealth == 0: 
		GameData.player_dead = true
		var index = 0
		var lastScore = -1
		for score in PlayerData.scores:
			if(PlayerData.currency > score and lastScore == -1):
				lastScore = score
				PlayerData.scores[index] = PlayerData.currency
			elif(lastScore != -1):
				var swap = lastScore
				lastScore = PlayerData.scores[index]
				PlayerData.scores[index] = swap
			index += 1
			
		respawn()
		return
	
	if platform_clinging :
		platform_cling_time += delta
		
	if platform_clinging && platform_cling_time >= min_cling_time	 :
		if platform_clinging && Input.is_action_pressed("ui_down") :
			let_go_of_ledge()
		elif platform_clinging && platform_clinging_side == "left" && Input.is_action_pressed("ui_right") :
			vault_ledge(platform_clinging_side)
		elif platform_clinging && platform_clinging_side == "right" && Input.is_action_pressed("ui_left") :
			vault_ledge(platform_clinging_side)
			
	# obtain new y velocity and check crouch
	if is_on_floor():
		playerVelocity.y = playerGravity
		if Input.is_action_pressed("ui_down"):
			fsm.travel("Crouch_L")
			crouched = true
		else:
			crouched = false
	else:
		if playerVelocity.y < terminalVelocity:
			playerVelocity.y += delta * playerGravity 
			if Input.is_action_pressed("ui_down") && playerVelocity.y < terminalVelocity:
				playerVelocity.y += 50
		else: 
			playerVelocity.y = terminalVelocity
	
	#obtain new x velocity
	_inputSequence()
	if !platform_clinging:
		var masRET = move_and_slide(playerVelocity, Vector2(0,-1), false, 4, .785398, false)

	var sCount = get_slide_count()
	for index in range(sCount):
		var col = get_slide_collision(index)
		if col.collider.is_in_group("interactables"):
			col.collider.apply_central_impulse(col.normal * -100)

# Get x velocity from LR inputs
func _inputSequence():
	attack_check()
	lr_check()
	wall_grab_check()
	jump_check()
	dodge_check()
	use_check()
	
	down_check()
	
	if Input.is_action_just_pressed("kill_self"):
		healthChange(-PlayerData.playerHealthMax)
		
func attack_check():
	if (Input.is_action_pressed("pr_fire") && PlayerData.wpnslot1 == null):
		return
	if (Input.is_action_pressed("alt_fire") && PlayerData.wpnslot2 == null):
		return
	if Input.is_action_pressed("pr_fire") && !(holdingm1 && !PlayerData.wpnslot1.chargeable):
		if (PlayerData.wpnactionable):
			PlayerData.wpnactionable = false
			holdingm1 = true
			wslot1()
	elif Input.is_action_pressed("alt_fire") && !(holdingm2 && !PlayerData.wpnslot2.chargeable):
		if (PlayerData.wpnactionable):
			PlayerData.wpnactionable = false
			holdingm2 = true
			wslot2()
	if (Input.is_action_just_released("alt_fire") && holdingm2):
		holdingm2 = false
	if (Input.is_action_just_released("pr_fire") && holdingm1):
		holdingm1 = false
func lr_check():
	if Input.is_action_pressed("ui_right") && !Input.is_action_pressed("ui_left"):
		if wallgrabbing:
				playerVelocity.y = 0
		else: 
			fsm.travel("Run_Right")
			xPositivity = true
		#check if sprint key hit inside here
		if Input.is_action_pressed("ui_shift"):
			sprinting = true
		else:
			sprinting = false
		#change the rate at which the player moves horizontally 
		fsm.travel("Run_Right")
		xPositivity = true
		if sprinting && is_on_floor():
			#increase player speed to 1.5x normal when sprinting
			#change this value in both if statements to make sprinting >1.5x
			playerSpeed = 600
			if playerVelocity.x < playerSpeed:
				playerVelocity.x += (playerSpeed)
			else:
				playerVelocity.x = playerSpeed
		else:			
			if wallgrabbing:
				playerVelocity.y = 0
			else: 
				fsm.travel("Run_Right")
				xPositivity = true
			if playerVelocity.x < playerSpeed:
				playerVelocity.x += (playerSpeed / 10)
			else:
				playerVelocity.x = playerSpeed
	elif Input.is_action_pressed("ui_left") && !Input.is_action_pressed("ui_right"):
		if wallgrabbing:
			  playerVelocity.y = 0
		else:
			fsm.travel("Run_Left")
			xPositivity = false
		#check if sprint key hit inside here
		if Input.is_action_pressed("ui_shift"):
			sprinting = true
		#change the rate at which the player moves horizontally 
		fsm.travel("Run_Left")
		xPositivity = false
		if sprinting && is_on_floor():
			playerSpeed = 600
			if playerVelocity.x > -playerSpeed:
				playerVelocity.x -= (playerSpeed)
			else:
				playerVelocity.x = -playerSpeed
		else:
			if wallgrabbing:
				playerVelocity.y = 0
			else:
				fsm.travel("Run_Left")
				xPositivity = false
			if playerVelocity.x > -playerSpeed:
				playerVelocity.x -= (playerSpeed / 10)
			else:
				playerVelocity.x = -playerSpeed	
	else:
		if !crouched && is_on_floor():
			if xPositivity:
				fsm.travel("Idle_Right")
			else:
				fsm.travel("Idle_Left")
		if playerVelocity.x > 1 || playerVelocity.x < -1:
			playerVelocity.x = playerVelocity.x / floatDenominator
		else:
			playerVelocity.x = 0

#Use this function for all non-DoT damage sources
func damageHandler(dmgamount, direction, force):
	if invulnTimer <= 0:
		invulnTimer = playerOnHitInvuln
		knockback(direction, force)
		healthChange(-1*dmgamount)
		$SFX/damage.play()
		if PlayerData.playerHealth == 0:
			GameData.camera_node.shake(GameData.HEAVYSHAKE, 0.2)
			pass
		else:
			GameData.camera_node.shake(GameData.MEDIUMSHAKE, 0.2)
		yield(get_tree().create_timer(playerOnHitInvuln), "timeout")
		invulnTimer = 0

func knockback(direction, force):
	playerVelocity.x += direction*force.x
	playerVelocity.y += force.y

func heal(value):
	if (PlayerData.playerHealth == PlayerData.playerHealthMax):
		return false
	elif (value + PlayerData.playerHealth > PlayerData.playerHealthMax):
		healthChange(PlayerData.playerHealthMax - PlayerData.playerHealth)
	else:
		healthChange(value)
	$SFX/heal.play()
	return true

func healthChange(amount):
	PlayerData.playerHealth += amount
	if PlayerData.playerHealth < 0:
		PlayerData.playerHealth = 0
	get_node("../HUD/HUD").change_health(PlayerData.playerHealth, float(PlayerData.playerHealth)/float(PlayerData.playerHealthMax))

func down_check():

	if Input.is_action_pressed("ui_down"):
		#find layer platform
		set_collision_mask_bit(19, false)
	else:
		set_collision_mask_bit(19, true)
		
func handle_platform_cling(ledge_area):
	
	platform_clinging = true;
	ledge_area_clinging = ledge_area
	
	var platform_position = ledge_area.get_parent().get_global_position()
	
	if ledge_area.get_global_position().x < platform_position.x:
		platform_clinging_side = "left"
		position = get_hang_left_pos(ledge_area)
	else:
		platform_clinging_side = "right"
		position = get_hang_right_pos(ledge_area)
	
func get_hang_left_pos(ledge_area):
	
	var platform = ledge_area.get_parent()
	var platform_position = platform.get_global_position()
	var platform_shape = get_node(platform.get_collision_shape()).shape
	var ledge_shape = get_node(ledge_area.collision_shape_path).shape
	
	var at_ledge_pos_x = - (ledge_shape.extents.x)*2 + platform_position.x - platform_shape.extents.x
	var at_ledge_pos_y = - ledge_shape.extents.y + platform_position.y #- platform_shape.extents.y/2
	
	return Vector2(at_ledge_pos_x, at_ledge_pos_y)

func get_hang_right_pos(ledge_area):
	
	var platform = ledge_area.get_parent()
	var platform_position = platform.get_global_position()
	var platform_shape = get_node(platform.get_collision_shape()).shape
	var ledge_shape = get_node(ledge_area.collision_shape_path).shape
	
	var at_ledge_pos_x = - (ledge_shape.extents.x)*2 + platform_position.x + platform_shape.extents.x
	var at_ledge_pos_y = - ledge_shape.extents.y + platform_position.y #- platform_shape.extents.y/2
	
	return Vector2(at_ledge_pos_x, at_ledge_pos_y)
	
	
func let_go_of_ledge():
	platform_clinging = false
	platform_cling_time = 0
	
func vault_ledge(ledge_side):
	let_go_of_ledge()
	var platform = ledge_area_clinging.get_parent()
	var platform_position = platform.get_global_position()
	var platform_shape = get_node(platform.get_collision_shape()).shape
	
	if(ledge_side == "left"):
		position = Vector2(-platform_shape.extents.x + platform_position.x, platform_position.y - platform_shape.extents.y*3)
	elif(ledge_side == "right"):
		position = Vector2(platform_shape.extents.x + platform_position.x, platform_position.y - platform_shape.extents.y*3)
		
func jump_check():
	if Input.is_action_pressed("ui_up") && jumping != true:
		if jump_count < max_JC: 
			if playerSpeed != 600: capSpeed(600)
			$SFX/jump.play()
			jumping = true
			playerVelocity.y = -jump_power
			#controls speed of descent after jump 
			playerVelocity.y += 200
			if xPositivity:
				fsm.travel("Jump_L")
			else:
				fsm.travel("Jump_R")
		else:
			if PlayerData.check_abilities("wall jump"):
				if next_to_left_wall():
					playerVelocity.y = -jump_power
					playerVelocity.y += 250
					#playerVelocity.x += jump_power
					playerVelocity.x = 100
					wallgrabbing = false
				if next_to_right_wall():
					playerVelocity.y = -jump_power
					playerVelocity.y += 250
					#playerVelocity.x -= jump_power
					playerVelocity.x = -100
					wallgrabbing = false
	elif Input.is_action_just_released("ui_up"):
		jump_count += 1
		jumping = false
	if is_on_floor():
		jump_count = 0
		jumping = false
				
func wall_grab_check():
	
	if Input.is_action_pressed("wall_grab") && is_on_wall():
		if PlayerData.check_abilities("wall grab"):
			wallgrabbing = true
			playerVelocity.y = 0
			jump_count = 0
	if Input.is_action_just_released("wall_grab"):
		wallgrabbing = false
			
func dodge_check():
	if Input.is_action_just_pressed("dodge"):
		if PlayerData.check_abilities("dodge"):
			playerVelocity.x = playerVelocity.x * 10

func use_check():
	if Input.is_action_just_pressed("use") && currentUse != null:
		use(currentUse)
		

func next_to_left_wall():
	return $WallRaycasts/LeftRaycasts/LeftRay1.is_colliding() || $WallRaycasts/LeftRaycasts/LeftRay2.is_colliding()

func next_to_right_wall():
	return $WallRaycasts/RightRaycasts/RightRay1.is_colliding() || $WallRaycasts/RightRaycasts/RightRay2.is_colliding()
		
func wslot1():
	#should probably base attack orientation on cursor relative to player given mouse controls
	#oh god we have to support multiple control schemes
	if (PlayerData.wpnslot1 != null && !PlayerData.wpnactionable):
		PlayerData.wpnslot1.attack(xPositivity)

func wslot2():
	if (PlayerData.wpnslot2 != null && !PlayerData.wpnactionable):
		PlayerData.wpnslot2.attack(xPositivity)



func use(object):
	
	if (object.type == "switch"):
		pass
	elif (object.type == "door"):
		pass
	elif (object.type == "health"):
		if (heal(object.value)):
			object.use()
		else:
			#flash_notice(1)
			pass
	elif (object.type == "money"):
		pass
	elif (object.type == "equippable"):
		pass
		
func clearUse():
	get_node("UsePrompt/Prompt").visible = false
	currentUse = null

func capSpeed(speed):
	playerSpeed = speed
	if (abs(playerVelocity.x) > playerSpeed && playerVelocity.x != 0):
		playerVelocity.x /= (abs(playerVelocity.x)/playerSpeed)

func _on_UsePrompt_body_entered(body):
	currentUse = body
	get_node("UsePrompt/Prompt").visible = true

func _on_UsePrompt_body_exited(_body):
	clearUse()
	
func _on_LedgeGrab_area_entered(area):
	handle_platform_cling(area)
	
func respawn():
	#var tree = get_tree()
	#var root = tree.get_root()
	#self.add_child(respawn_menu.instance())
	emit_signal("respawn")
