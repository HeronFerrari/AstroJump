extends TileMapLayer

@export var max_health: int = 5
@export var current_health: int = 5

# Set these based on your TileSet coordinates (Heart vs Dot)
const TILE_FULL = Vector2i(0, 0)   # Coordinates for the Heart
const TILE_EMPTY = Vector2i(1, 0)  # Coordinates for the Dot

const SOURCE_ID = 0 # Default ID for your texture atlas

func _ready() -> void:
	update_health_bar()

func update_health_bar() -> void:
	clear() # Erases old tiles before drawing new ones
	
	for i in range(max_health):
		# Vector2i(i, 0) lines them up horizontally
		var tile_position = Vector2i(i, 0)
		
		if i < current_health:
			set_cell(tile_position, SOURCE_ID, TILE_FULL)
		else:
			set_cell(tile_position, SOURCE_ID, TILE_EMPTY)

# Call this function later to change health during gameplay
func change_health(amount: int) -> void:
	current_health = clampi(current_health + amount, 0, max_health)
	update_health_bar()
