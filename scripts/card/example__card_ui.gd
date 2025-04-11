extends CardUI


@onready var label := $Frontface/Label


func _ready():
	super()
	if card_data:
		label.text = card_data.nice_name
