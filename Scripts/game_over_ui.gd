extends CanvasLayer

@onready var retry_button: Button = $VBoxContainer/RetryButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var death_anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	# Garante que o jogo possa receber cliques mesmo pausado
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	retry_button.grab_focus() # Facilita o uso do teclado/controle

func _on_retry_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_quit_button_pressed() -> void:
	get_tree().paused = false # Despausa o jogo antes de mudar de cena
	get_tree().change_scene_to_file("res://Entidades/main_menu.tscn") # Caminho do seu menu


func exibir_game_over() -> void:
	visible = true
	retry_button.grab_focus()
	
	if death_anim:
		death_anim.frame = 0 # Força o sprite a voltar para o primeiríssimo frame
		death_anim.play("dead") # Substitua pelo nome exato da animação de morte
