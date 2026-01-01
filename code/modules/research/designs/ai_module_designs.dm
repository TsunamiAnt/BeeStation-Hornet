#define AI_MODULE_MATERIALS_CHEAP list(/datum/material/glass = 1000, /datum/material/gold = 1000, /datum/material/copper = 300)
#define AI_MODULE_MATERIALS_EXPENSIVE list(/datum/material/glass = 1000, /datum/material/diamond = 1000, /datum/material/copper = 300)

/datum/design/board/aicore
	name = "AI Core Board"
	desc = "Allows for the construction of circuit boards used to build new AI cores."
	id = "aicore"
	build_path = /obj/item/circuitboard/aicore
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/reset_module
	name = "Reset Module"
	desc = "Allows for the construction of a Reset AI Module."
	id = "reset_module"
	materials = list(/datum/material/glass = 1000, /datum/material/gold = 5000, /datum/material/copper = 300)
	build_path = /obj/item/ai_module/reset_board
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

#undef AI_MODULE_MATERIALS_CHEAP
#undef AI_MODULE_MATERIALS_EXPENSIVE
