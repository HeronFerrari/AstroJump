extends CharacterBody2D

enum PlayerState{
	idle,
	walk,
	jump,
	fall,
	duck,
	slide,
	wall,
	swimming,
	hurt,
	dead
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var left_wall_detector: RayCast2D = $LeftWallDetector
@onready var right_wall_detector: RayCast2D = $RightWallDetector

@onready var reload_timer: Timer = $ReloadTimer

@export var max_speed = 100.0
@export var acceleration = 400
@export var deceleration = 400
@export var slide_deceleration = 100
@export var wall_acceleration = 30
@export var wall_jump_velocity = 210
@export var water_max_speed = 100 
@export var water_acceleration = 200
@export var death_delay: float = 1.0 # Tempo extra em segundos após o fim da animação


const JUMP_VELOCITY = -300.0

@export var max_jump_count = 2
var jump_count = 0
var direction = 0
var status: PlayerState

# Elemetnos UI
# VIDA
var max_health: int = 5
var current_health: int = 5
@onready var health_bar = get_tree().current_scene.find_child("HealthBar", true, false)

# VARIÁVEIS DE INVENCIBILIDADE E COICE
@export var knockback_force_x = 150.0
@export var knockback_force_y = -150.0
@export var invincibility_duration = 1.0 # Tempo invencível em segundos

var is_invincible: bool = false
var invincibility_timer: float = 0.0
var blink_timer: float = 0.0


func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta: float) -> void:
		
	# Processa o tempo de invencibilidade
	if is_invincible:
		invincibility_timer -= delta
		blink_timer += delta
		
		# Faz o sprite piscar ligando/desligando a visibilidade
		if blink_timer >= 0.07: 
			anim.visible = !anim.visible
			blink_timer = 0.0
			
		if invincibility_timer <= 0:
			is_invincible = false
			anim.visible = true # Garante que o sprite termine visível
	
	match status:
		PlayerState.idle:
			idle_state(delta)	
		PlayerState.walk:
			walk_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.fall:
			fall_state(delta)
		PlayerState.duck:
			duck_state(delta)
		PlayerState.slide:
			slide_state(delta)
		PlayerState.wall:
			wall_state(delta)
		PlayerState.swimming:
			swimming_state(delta)
		PlayerState.hurt:
			hurt_state(delta)
		PlayerState.dead:
			dead_state(delta)
			
	
	move_and_slide()

func go_to_idle_state():
	status = PlayerState.idle
	anim.play("idle")
	
func go_to_walk_state():
	status = PlayerState.walk
	anim.play("walk")
	
func go_to_jump_state():
	status = PlayerState.jump
	anim.play("jump")
	velocity.y = JUMP_VELOCITY
	jump_count += 1

func go_to_duck_state():
	status = PlayerState.duck
	anim.play("duck")
	set_small_collider()
func exit_from_duck_state():
	set_large_collider()

func go_to_fall_state():
	status = PlayerState.fall
	anim.play("fall")

func go_to_slide_state():
	status = PlayerState.slide
	anim.play("slide")
	set_small_collider()
func exit_from_slide_state():
	set_large_collider()
	
func go_to_wall_state():
	status = PlayerState.wall
	anim.play("wall")
	velocity = Vector2.ZERO
	jump_count = 0

func go_to_swimming_state():
	status = PlayerState.swimming
	anim.play("swimming")
	velocity.y = min(velocity.y, 150)

func go_to_hurt_state(enemy_position_x: float):
	status = PlayerState.hurt
	anim.play("hurt")
	# Descobre de qual lado o inimigo veio para empurrar o player para o lado oposto
	var knockback_direction = 1.0 if position.x > enemy_position_x else -1.0
	
	velocity.x = knockback_direction * knockback_force_x
	velocity.y = knockback_force_y # Dá um pequeno pulinho para trás

func go_to_dead_state():
	if status == PlayerState.dead:
		return
	status = PlayerState.dead
	anim.play("dead")
	velocity.x = 0
	
	# 2. SINCRO: Calcula matematicamente a duração exata da animação
	if anim.sprite_frames:
		# Pega o número total de frames da animação "dead"
		var total_frames = anim.sprite_frames.get_frame_count("dead")
		# Pega a velocidade da animação (Quantos frames rodam por segundo, ex: 10 FPS)
		var animation_fps = anim.sprite_frames.get_animation_speed("dead")
		
		# Duração em segundos = Total de Frames / FPS
		var animation_duration = float(total_frames) / float(animation_fps)
		
		# Define o tempo do timer do jogador para bater exatamente com o fim do sprite
		reload_timer.wait_time = animation_duration + death_delay
	else:
		# Tempo de segurança caso não encontre o sprite_frames por algum motivo
		reload_timer.wait_time = 1.0 
	
	# 3. Inicia o timer sincronizado
	reload_timer.start()

func idle_state(delta):
	apply_gravity(delta)
	move(delta)
	
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
	if Input.is_action_pressed("duck"):
		go_to_duck_state()
	if velocity.x != 0:
		go_to_walk_state()
		return

func walk_state(delta):
	apply_gravity(delta)
	move(delta)
	if velocity.x == 0:
		go_to_idle_state()
		return
	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return
	
	if Input.is_action_just_pressed("duck"):
		go_to_slide_state()
		return
	
	if Input.is_action_just_released("duck"):
		go_to_walk_state()
		return
		
	if !is_on_floor():
		go_to_fall_state()
		return
	
func jump_state(delta):
	apply_gravity(delta)
	move(delta)
	
	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return
		
	if velocity.y > 0:
		go_to_fall_state()
		return
		
func fall_state(delta):
	apply_gravity(delta)
	move(delta)
	
	if Input.is_action_just_pressed("jump") && jump_count < max_jump_count:
		go_to_jump_state()
	
	if is_on_floor():
		jump_count = 0
		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
		return
	
	if (left_wall_detector.is_colliding() or right_wall_detector.is_colliding()) && is_on_wall():
		go_to_wall_state()
		return
	
func duck_state(delta):
	apply_gravity(delta)
	update_direction()
	if Input.is_action_just_released("duck"):
		exit_from_duck_state()
		go_to_idle_state()
		return
		
func slide_state(delta):
	apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, slide_deceleration * delta)
	if velocity.x == 0:
		exit_from_slide_state()
		go_to_duck_state()
		return
	if Input.is_action_just_released("duck"):
		exit_from_slide_state()
		go_to_walk_state()
		return

func wall_state(delta):
	
	velocity.y += wall_acceleration * delta
	
	if left_wall_detector.is_colliding():
		anim.flip_h = false
		direction = 1
	elif right_wall_detector.is_colliding():
		anim.flip_h = true
		direction = -1
	else:
		go_to_fall_state()
		return
	
	if is_on_floor():
		go_to_idle_state()
		return
	
	if Input.is_action_just_pressed("jump"):
		velocity.x = wall_jump_velocity * direction
		go_to_jump_state()
		return

func swimming_state(delta):
	update_direction()
	
	if direction:
		velocity.x = move_toward(velocity.x, water_max_speed * direction, water_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, water_acceleration * delta)
	
	velocity.y += water_acceleration * delta
	velocity.y = min(velocity.y, water_max_speed)
	var vertical_direction = Input.get_axis("jump", "duck")
	
	if Input.is_action_pressed("jump") or Input.is_action_pressed("duck"):
		velocity.y = move_toward(velocity.y, water_max_speed * vertical_direction, water_acceleration)
		
func take_damage(amount: int, enemy_pos_x: float = 0.0):
	if status == PlayerState.dead or is_invincible:
		return
		
	current_health -= amount
	current_health = max(0, current_health)
	
	# Atualiza a barra de vida visualmente retirando corações
	if health_bar:
		health_bar.change_health(-amount)
	
	if current_health <= 0:
		go_to_dead_state()
		return
		
	# Ativa a invencibilidade temporária
	is_invincible = true
	invincibility_timer = invincibility_duration
	blink_timer = 0.0
	
	# Se o dano veio de uma posição válida, aplica o coice
	if enemy_pos_x != 0.0:
		go_to_hurt_state(enemy_pos_x)
	
func hurt_state(delta):
	apply_gravity(delta)
	
	# Desacelera o empurrão horizontal gradualmente no ar
	velocity.x = move_toward(velocity.x, 0, deceleration * delta)
	
	# Quando o jogador tocar o chão novamente, ele recupera o controle
	if is_on_floor() and velocity.y >= 0:
		go_to_idle_state()

func dead_state(delta):
	apply_gravity(delta)

func move(delta):
	update_direction()

	if direction:
		velocity.x = move_toward(velocity.x,direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

func apply_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

func update_direction():
	direction = Input.get_axis("left", "right")
	
	if direction < 0:
		anim.flip_h = true
	elif direction > 0:
		anim.flip_h = false
	
func can_jump() -> bool:
	return jump_count < max_jump_count
	
func set_small_collider():
	collision_shape.shape.radius = 5
	collision_shape.shape.height = 10
	collision_shape.position.y = 3
	
	hitbox_collision_shape.shape.size.y = 10
	hitbox_collision_shape.position.y = 3

func set_large_collider():
	collision_shape.shape.radius = 6
	collision_shape.shape.height = 16
	collision_shape.position.y = 0
	
	hitbox_collision_shape.shape.size.y = 15
	hitbox_collision_shape.position.y = 0.5	

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		hit_enemy(area)
	elif area.is_in_group("LethalArea"):
		hit_lethal_area()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("LethalArea"):
		take_damage(max_health)
	elif body.is_in_group("Water"):
		go_to_swimming_state()

func hit_enemy(area: Area2D):
	if velocity.y > 0 and status != PlayerState.hurt:
		# inimigo morre
		area.get_parent().take_damage()
		go_to_jump_state()
	else:
		take_damage(1, area.global_position.x)

func hit_lethal_area():
	take_damage(1, global_position.x)

func _on_reload_timer_timeout() -> void:
	var game_over_screen = get_tree().current_scene.find_child("GameOver_ui",true,false)
	
	if game_over_screen:
		game_over_screen.exibir_game_over()
		get_tree().paused = true

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("Water"):
		go_to_jump_state()
