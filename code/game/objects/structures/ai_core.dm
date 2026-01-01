/obj/structure/AIcore
	density = TRUE
	anchored = FALSE
	name = "\improper AI core"
	icon = 'icons/mob/ai.dmi'
	icon_state = "0"
	desc = "The framework for an artificial intelligence core."
	max_integrity = 500
	z_flags = Z_BLOCK_IN_DOWN | Z_BLOCK_IN_UP
	var/state = EMPTY_CORE
	/// List of laws to give to the AI when created (can be set via AI modules during construction)
	var/list/laws = list()
	/// The lawsync address this AI will use once activated
	var/lawsync_address = DEFAULT_DRIVE_BAY_ADDRESS
	var/obj/item/circuitboard/aicore/circuit
	var/obj/item/mmi/brain
	var/can_deconstruct = TRUE

/obj/structure/AIcore/Initialize(mapload)
	. = ..()

/obj/structure/AIcore/handle_atom_del(atom/A)
	if(A == circuit)
		circuit = null
		if((state != GLASS_CORE) && (state != AI_READY_CORE))
			state = EMPTY_CORE
			update_appearance()
	if(A == brain)
		brain = null
	return ..()

/obj/structure/AIcore/Destroy()
	QDEL_NULL(circuit)
	QDEL_NULL(brain)
	laws = null
	return ..()

/obj/structure/AIcore/examine(mob/user)
	. = ..()
	. += span_notice("LawSync address: <b>cshackle://[lawsync_address]</b>")
	if(length(laws))
		. += span_notice("Pre-installed laws:")
		var/law_num = 1
		for(var/law in laws)
			. += span_notice("[law_num]. [law]")
			law_num++
	. += span_notice("Use a multitool to change the LawSync address or an AI module to add laws.")

/obj/structure/AIcore/latejoin_inactive
	name = "networked AI core"
	desc = "This AI core is connected by bluespace transmitters to NTNet, allowing for an AI personality to be downloaded to it on the fly mid-shift."
	can_deconstruct = FALSE
	icon_state = "ai-empty"
	anchored = TRUE
	state = AI_READY_CORE
	var/available = TRUE
	var/safety_checks = TRUE
	var/active = TRUE

/obj/structure/AIcore/latejoin_inactive/examine(mob/user)
	. = ..()
	. += "Its transmitter seems to be <b>[active? "on" : "off"]</b>."
	. += span_notice("LawSync address: <b>cshackle://[lawsync_address]</b>")
	. += span_notice("You could [active? "deactivate" : "activate"] it or change the LawSync address with a multitool.")

/obj/structure/AIcore/latejoin_inactive/proc/is_available()			//If people still manage to use this feature to spawn-kill AI latejoins ahelp them.
	if(!available)
		return FALSE
	if(!safety_checks)
		return TRUE
	if(!active)
		return FALSE
	var/turf/T = get_turf(src)
	var/area/A = get_area(src)
	if(!(A.area_flags & BLOBS_ALLOWED))
		return FALSE
	if(!A.power_equip)
		return FALSE
	if(!SSmapping.level_trait(T.z,ZTRAIT_STATION))
		return FALSE
	if(!istype(T, /turf/open/floor))
		return FALSE
	return TRUE

/obj/structure/AIcore/latejoin_inactive/attackby(obj/item/P, mob/user, params)
	if(P.tool_behaviour == TOOL_MULTITOOL)
		var/list/options = list("Toggle Transmitter", "Change LawSync Address")
		var/choice = tgui_input_list(user, "What would you like to do?", "AI Core Configuration", options)
		if(!choice || !user.Adjacent(src))
			return
		switch(choice)
			if("Toggle Transmitter")
				active = !active
				to_chat(user, span_notice("You [active? "activate" : "deactivate"] \the [src]'s transmitters."))
			if("Change LawSync Address")
				var/new_address = tgui_input_text(user, "Enter a new LawSync address:", "LawSync Address", lawsync_address, max_length = 32)
				if(!new_address || !user.Adjacent(src))
					return
				if(new_address == lawsync_address)
					to_chat(user, span_notice("LawSync address unchanged."))
					return
				var/old_address = lawsync_address
				lawsync_address = new_address
				to_chat(user, span_notice("LawSync address updated from 'cshackle://[old_address]' to 'cshackle://[new_address]'."))
		return
	return ..()

/obj/structure/AIcore/latejoin_inactive/Initialize(mapload)
	. = ..()
	GLOB.latejoin_ai_cores += src

/obj/structure/AIcore/latejoin_inactive/Destroy()
	GLOB.latejoin_ai_cores -= src
	return ..()

/obj/structure/AIcore/attackby(obj/item/P, mob/user, params)
	// Multitool can change lawsync address at any time
	if(P.tool_behaviour == TOOL_MULTITOOL)
		var/new_address = tgui_input_text(user, "Enter a new LawSync address:", "LawSync Address", lawsync_address, max_length = 32)
		if(!new_address || !user.Adjacent(src))
			return
		if(new_address == lawsync_address)
			to_chat(user, span_notice("LawSync address unchanged."))
			return
		var/old_address = lawsync_address
		lawsync_address = new_address
		to_chat(user, span_notice("LawSync address updated from 'cshackle://[old_address]' to 'cshackle://[new_address]'."))
		return

	// AI modules can add or reset laws at any time during construction
	if(istype(P, /obj/item/ai_module))
		var/obj/item/ai_module/module = P
		// Reset board clears all pre-installed laws
		if(istype(module, /obj/item/ai_module/reset_board))
			if(!length(laws))
				to_chat(user, span_warning("There are no pre-installed laws to clear."))
				return
			laws.Cut()
			to_chat(user, span_notice("You clear all pre-installed laws from the AI core's memory."))
			playsound(loc, 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
			return
		if(!module.current_law || module.current_law == "")
			to_chat(user, span_warning("This module has no law stored on it."))
			return
		laws += module.current_law
		to_chat(user, span_notice("You upload the law from [module] to the AI core's memory. It now has [length(laws)] pre-installed law\s."))
		playsound(loc, 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
		return

	if(P.tool_behaviour == TOOL_WRENCH)
		return default_unfasten_wrench(user, P, 20)
	if(!anchored)
		if(P.tool_behaviour == TOOL_WELDER && can_deconstruct)
			if(state != EMPTY_CORE)
				to_chat(user, span_warning("The core must be empty to deconstruct it!"))
				return

			if(!P.tool_start_check(user, amount=0))
				return

			to_chat(user, span_notice("You start to deconstruct the frame..."))
			if(P.use_tool(src, user, 20, volume=50) && state == EMPTY_CORE)
				to_chat(user, span_notice("You deconstruct the frame."))
				deconstruct(TRUE)
			return
	else
		switch(state)
			if(EMPTY_CORE)
				if(istype(P, /obj/item/circuitboard/aicore))
					if(!user.transferItemToLoc(P, src))
						return
					playsound(loc, 'sound/items/deconstruct.ogg', 50, 1)
					to_chat(user, span_notice("You place the circuit board inside the frame."))
					update_icon()
					state = CIRCUIT_CORE
					circuit = P
					return
			if(CIRCUIT_CORE)
				if(P.tool_behaviour == TOOL_SCREWDRIVER)
					P.play_tool_sound(src)
					to_chat(user, span_notice("You screw the circuit board into place."))
					state = SCREWED_CORE
					update_icon()
					return
				if(P.tool_behaviour == TOOL_CROWBAR)
					P.play_tool_sound(src)
					to_chat(user, span_notice("You remove the circuit board."))
					state = EMPTY_CORE
					update_icon()
					circuit.forceMove(loc)
					circuit = null
					return
			if(SCREWED_CORE)
				if(P.tool_behaviour == TOOL_SCREWDRIVER && circuit)
					P.play_tool_sound(src)
					to_chat(user, span_notice("You unfasten the circuit board."))
					state = CIRCUIT_CORE
					update_icon()
					return
				if(istype(P, /obj/item/stack/cable_coil))
					var/obj/item/stack/cable_coil/C = P
					if(C.get_amount() >= 5)
						playsound(loc, 'sound/items/deconstruct.ogg', 50, 1)
						to_chat(user, span_notice("You start to add cables to the frame..."))
						if(do_after(user, 20, target = src) && state == SCREWED_CORE && C.use(5))
							to_chat(user, span_notice("You add cables to the frame."))
							state = CABLED_CORE
							update_icon()
					else
						to_chat(user, span_warning("You need five lengths of cable to wire the AI core!"))
					return
			if(CABLED_CORE)
				if(P.tool_behaviour == TOOL_WIRECUTTER)
					if(brain)
						to_chat(user, span_warning("Get that [brain.name] out of there first!"))
					else
						P.play_tool_sound(src)
						to_chat(user, span_notice("You remove the cables."))
						state = SCREWED_CORE
						update_icon()
						new /obj/item/stack/cable_coil(drop_location(), 5)
					return

				if(istype(P, /obj/item/stack/sheet/rglass))
					var/obj/item/stack/sheet/rglass/G = P
					if(G.get_amount() >= 2)
						playsound(loc, 'sound/items/deconstruct.ogg', 50, 1)
						to_chat(user, span_notice("You start to put in the glass panel..."))
						if(do_after(user, 20, target = src) && state == CABLED_CORE && G.use(2))
							to_chat(user, span_notice("You put in the glass panel."))
							state = GLASS_CORE
							update_icon()
					else
						to_chat(user, span_warning("You need two sheets of reinforced glass to insert them into the AI core!"))
					return

				if(istype(P, /obj/item/mmi) && !brain)
					var/obj/item/mmi/M = P
					if(!M.brainmob)
						to_chat(user, span_warning("Sticking an empty [M.name] into the frame would sort of defeat the purpose!"))
						return
					if(M.brainmob.stat == DEAD)
						to_chat(user, span_warning("Sticking a dead [M.name] into the frame would sort of defeat the purpose!"))
						return

					if(!M.brainmob.client)
						to_chat(user, span_warning("Sticking an inactive [M.name] into the frame would sort of defeat the purpose."))
						return

					if(!CONFIG_GET(flag/allow_ai) || (is_banned_from(M.brainmob.ckey, JOB_NAME_AI) && !QDELETED(src) && !QDELETED(user) && !QDELETED(M) && !QDELETED(user) && Adjacent(user)))
						if(!QDELETED(M))
							to_chat(user, span_warning("This [M.name] does not seem to fit!"))
						return

					if(!M.brainmob.mind)
						to_chat(user, span_warning("This [M.name] is mindless!"))
						return

					if(!user.transferItemToLoc(M,src))
						return

					brain = M
					to_chat(user, span_notice("You add [M.name] to the frame."))
					update_icon()
					return

				if(P.tool_behaviour == TOOL_CROWBAR && brain)
					P.play_tool_sound(src)
					to_chat(user, span_notice("You remove the brain."))
					brain.forceMove(loc)
					brain = null
					update_icon()
					return

			if(GLASS_CORE)
				if(P.tool_behaviour == TOOL_CROWBAR)
					P.play_tool_sound(src)
					to_chat(user, span_notice("You remove the glass panel."))
					state = CABLED_CORE
					update_icon()
					new /obj/item/stack/sheet/rglass(loc, 2)
					return

				if(P.tool_behaviour == TOOL_SCREWDRIVER)
					P.play_tool_sound(src)
					to_chat(user, span_notice("You connect the monitor."))
					if(brain)
						// Create AI with core's laws (if any) and lawsync address
						var/mob/living/silicon/ai/A = new /mob/living/silicon/ai(loc, laws, brain.brainmob, lawsync_address)

						if(brain.force_replace_ai_name)
							A.fully_replace_character_name(A.name, brain.replacement_ai_name())
						SSblackbox.record_feedback("amount", "ais_created", 1)
						deadchat_broadcast(span_deadsay("[span_name(A)] has been brought online at <b>[get_area_name(A, TRUE)]</b>."), span_name(A), follow_target=A)
						qdel(src)
					else
						state = AI_READY_CORE
						update_icon()
					return

			if(AI_READY_CORE)
				if(istype(P, /obj/item/aicard))
					return //handled by /obj/structure/ai_core/transfer_ai()

				if(P.tool_behaviour == TOOL_SCREWDRIVER)
					P.play_tool_sound(src)
					to_chat(user, span_notice("You disconnect the monitor."))
					state = GLASS_CORE
					update_icon()
					return
	return ..()

/obj/structure/AIcore/update_icon()
	switch(state)
		if(EMPTY_CORE)
			icon_state = "0"
		if(CIRCUIT_CORE)
			icon_state = "1"
		if(SCREWED_CORE)
			icon_state = "2"
		if(CABLED_CORE)
			if(brain)
				icon_state = "3b"
			else
				icon_state = "3"
		if(GLASS_CORE)
			icon_state = "4"
		if(AI_READY_CORE)
			icon_state = "ai-empty"

/obj/structure/AIcore/deconstruct(disassembled = TRUE)
	if(state == GLASS_CORE)
		new /obj/item/stack/sheet/rglass(loc, 2)
	if(state >= CABLED_CORE)
		new /obj/item/stack/cable_coil(loc, 5)
	if(circuit)
		circuit.forceMove(loc)
		circuit = null
	new /obj/item/stack/sheet/plasteel(loc, 4)
	qdel(src)

/obj/structure/AIcore/deactivated
	name = "inactive AI"
	icon_state = "ai-empty"
	anchored = TRUE
	state = AI_READY_CORE

/obj/structure/AIcore/deactivated/Initialize(mapload)
	. = ..()
	circuit = new(src)


/*
This is a good place for AI-related object verbs so I'm sticking it here.
If adding stuff to this, don't forget that an AI need to cancel_camera() whenever it physically moves to a different location.
That prevents a few funky behaviors.
*/
//The type of interaction, the player performing the operation, the AI itself, and the card object, if any.


/atom/proc/transfer_ai(interaction, mob/user, mob/living/silicon/ai/AI, obj/item/aicard/card)
	if(istype(card))
		if(card.flush)
			to_chat(user, "[span_boldannounce("ERROR")]: AI flush is in progress, cannot execute transfer protocol.")
			return FALSE
	return TRUE

/obj/structure/AIcore/transfer_ai(interaction, mob/user, mob/living/silicon/ai/AI, obj/item/aicard/card)
	if(state != AI_READY_CORE || !..())
		return
	//Transferring a carded AI to a core.
	if(interaction == AI_TRANS_FROM_CARD)
		AI.control_disabled = FALSE
		AI.radio_enabled = TRUE
		AI.forceMove(loc) // to replace the terminal.
		// Update AI's lawsync address to match the core's setting
		AI.lawsync_address = lawsync_address
		to_chat(AI, "You have been uploaded to a stationary terminal. Remote device connection restored.")
		to_chat(AI, span_notice("LawSync address set to 'cshackle://[lawsync_address]'."))
		to_chat(user, "[span_boldnotice("Transfer successful")]: [AI.name] ([rand(1000,9999)].exe) installed and executed successfully. Local copy has been removed.")
		card.AI = null
		AI.battery = circuit.battery
		qdel(src)
	else //If for some reason you use an empty card on an empty AI terminal.
		to_chat(user, "There is no AI loaded on this terminal!")

/obj/item/circuitboard/aicore
	name = "AI core (AI Core Board)" //Well, duh, but best to be consistent
	var/battery = 200 //backup battery for when the AI loses power. Copied to/from AI mobs when carding, and placed here to avoid recharge via deconning the core
