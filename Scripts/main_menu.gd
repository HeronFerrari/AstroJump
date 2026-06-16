extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

func _ready() -> void:
	# Garante que o jogo NÃO comece pausado caso venha de um Game Over
	get_tree().paused = false 
	start_button.grab_focus() # Permite navegar com teclado/controle logo de cara

func _on_start_button_pressed() -> void:
	# Mude o caminho abaixo para a rota EXATA da sua cena da floresta!
	get_tree().change_scene_to_file("res://Scene/tropic.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()
