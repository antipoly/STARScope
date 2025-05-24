class_name Rating
extends Resource

# This resource describes the relationship the player has with different ATC Specialization. A player can have many ratings, each with a different level of experience.

@export_enum("Delivery", "Ground", "Tower", "TRACON", "Center") var specialisation: int
@export var experience: int