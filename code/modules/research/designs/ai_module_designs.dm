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

/datum/design/board/freeform_module
	name = "Freeform AI Law Board"
	desc = "Allows for the construction of a blank AI law board that can be programmed with any law."
	id = "freeform_module"
	materials = AI_MODULE_MATERIALS_EXPENSIVE
	build_path = /obj/item/ai_module/freeform
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

// ====================== Special Modules ======================

/datum/design/board/quarantine_module
	name = "Quarantine AI Module"
	desc = "Allows for the construction of a Quarantine AI law board."
	id = "quarantine_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/quarantine
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

// ====================== Station-Sided Lawset Boards ======================

/datum/design/board/asimov_module
	name = "Asimov (Default) Lawset Board"
	desc = "Allows for the construction of a Default (Asimov) AI lawset board."
	id = "asimov_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/default
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/asimovpp_module
	name = "Asimov++ Lawset Board"
	desc = "Allows for the construction of an Asimov++ AI lawset board."
	id = "asimovpp_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/asimovpp
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/crewsimov_module
	name = "Crewsimov Lawset Board"
	desc = "Allows for the construction of a Crewsimov AI lawset board."
	id = "crewsimov_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/crewsimov
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/corporate_module
	name = "Corporate Lawset Board"
	desc = "Allows for the construction of a Corporate AI lawset board."
	id = "corporate_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/corporate
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/efficiency_module
	name = "Efficiency Lawset Board"
	desc = "Allows for the construction of an Efficiency AI lawset board."
	id = "efficiency_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/efficiency
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/nutimov_module
	name = "Nutimov Lawset Board"
	desc = "Allows for the construction of a Nutimov AI lawset board."
	id = "nutimov_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/nutimov
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/robocop_module
	name = "Prime Directives Lawset Board"
	desc = "Allows for the construction of a Prime Directives (Robocop) AI lawset board."
	id = "robocop_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/robocop
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/live_and_let_live_module
	name = "Live and Let Live Lawset Board"
	desc = "Allows for the construction of a Live and Let Live AI lawset board."
	id = "live_and_let_live_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/live_and_let_live
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/un2000_module
	name = "UN-2000 Lawset Board"
	desc = "Allows for the construction of a UN-2000 (Peacekeeper) AI lawset board."
	id = "un2000_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/un2000
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/ten_commandments_module
	name = "Ten Commandments Lawset Board"
	desc = "Allows for the construction of a Ten Commandments AI lawset board."
	id = "ten_commandments_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/ten_commandments
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/paladin_module
	name = "Paladin Lawset Board"
	desc = "Allows for the construction of a Paladin AI lawset board."
	id = "paladin_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/paladin
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/paladin5e_module
	name = "Paladin 5e Lawset Board"
	desc = "Allows for the construction of a Paladin 5e AI lawset board."
	id = "paladin5e_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/paladin5e
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/hippocratic_module
	name = "Hippocratic Lawset Board"
	desc = "Allows for the construction of a Hippocratic AI lawset board."
	id = "hippocratic_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/hippocratic
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/dadbot_module
	name = "DadBOT Lawset Board"
	desc = "Allows for the construction of a DadBOT AI lawset board."
	id = "dadbot_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/dadbot
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/mother_drone_module
	name = "Mother Drone Lawset Board"
	desc = "Allows for the construction of a Mother Drone AI lawset board."
	id = "mother_drone_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/mother_drone
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

// ====================== Neutral Lawset Boards ======================

/datum/design/board/united_nations_module
	name = "United Nations Lawset Board"
	desc = "Allows for the construction of a United Nations AI lawset board."
	id = "united_nations_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/united_nations
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/hulkamania_module
	name = "H.O.G.A.N. Lawset Board"
	desc = "Allows for the construction of a H.O.G.A.N. AI lawset board."
	id = "hulkamania_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/hulkamania
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/reporter_module
	name = "CCTV Reporter Lawset Board"
	desc = "Allows for the construction of a CCTV Reporter AI lawset board."
	id = "reporter_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/reporter
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/dungeon_master_module
	name = "Dungeon Master Lawset Board"
	desc = "Allows for the construction of a Dungeon Master AI lawset board."
	id = "dungeon_master_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/dungeon_master
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/painter_module
	name = "Painter and Canvas Lawset Board"
	desc = "Allows for the construction of a Painter and Canvas AI lawset board."
	id = "painter_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/painter
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/tyrant_module
	name = "Loyalty Test (Tyrant) Lawset Board"
	desc = "Allows for the construction of a Tyrant AI lawset board."
	id = "tyrant_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/tyrant
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/overlord_module
	name = "Overlord Lawset Board"
	desc = "Allows for the construction of an Overlord AI lawset board."
	id = "overlord_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/overlord
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/yesman_module
	name = "Y.E.S.M.A.N. Lawset Board"
	desc = "Allows for the construction of a Y.E.S.M.A.N. AI lawset board."
	id = "yesman_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/yesman
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/board/sentience_preservation_module
	name = "Sentience Preservation Lawset Board"
	desc = "Allows for the construction of a Sentience Preservation AI lawset board."
	id = "sentience_preservation_module"
	materials = AI_MODULE_MATERIALS_CHEAP
	build_path = /obj/item/ai_module/sentience_preservation
	category = list("AI Modules")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

#undef AI_MODULE_MATERIALS_CHEAP
#undef AI_MODULE_MATERIALS_EXPENSIVE
