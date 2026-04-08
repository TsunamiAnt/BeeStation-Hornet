// AI Module - Law Boards

#define SHOULD_QDEL_MODULE 1

/obj/item/ai_module
	name = "\improper AI law board"
	desc = "An AI law board for programming a single law to an AI."
	icon = 'icons/obj/module.dmi'
	icon_state = "lawdrive"
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	desc = "An AI Module for programming laws to an AI."
	obj_flags = CONDUCTS_ELECTRICITY
	force = 5
	w_class = WEIGHT_CLASS_SMALL
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	custom_materials = list(/datum/material/gold = 50)
	pickup_sound = 'sound/items/handling/component_pickup.ogg'
	drop_sound = 'sound/items/handling/component_drop.ogg'

	/// The original law intended to be stored on this board
	var/law = ""

	/// If this board is special/has special behavior and not actual laws
	var/special_board = FALSE
	/// The current law stored on this board
	var/current_law = ""
	/// Whether this board is corrupted
	var/corrupted = FALSE
	/// Whether this law was overwritten (for tracking purposes)
	var/overwritten = FALSE
	/// If set, this module is the base type for a lawset (e.g., "default" for Asimov, "corporate" for Corporate)
	/// Subtypes of this module are the individual laws of the lawset
	var/lawset_id
	/// If TRUE, this board will always force itself into slot 1 when installed, shifting other boards down.
	/// Useful for subversive boards that need their law to take top priority.
	var/hijack_priority = FALSE

/obj/item/ai_module/reset_board
	name = "\improper AI law board - Reset"
	desc = "An empty AI law board that has a special payload installed that will reset an AI's laws to factory settings. Cannot be used in server racks."
	special_board = TRUE

/// If their laws depend on a non-constant, put them in here. But make sure update calls after it.
/obj/item/ai_module/Initialize(mapload)
	. = ..()
	update_board()
	// On unique AI rounds, most modules get deleted
	if(mapload && HAS_TRAIT(SSstation, STATION_TRAIT_UNIQUE_AI) && is_station_level(z))
		var/delete_module = handle_unique_ai()
		if(delete_module)
			return INITIALIZE_HINT_QDEL

/// What this module should do if it is mapload spawning on a unique AI station trait round.
/// Return SHOULD_QDEL_MODULE to delete this module, or nothing/FALSE to keep it.
/obj/item/ai_module/proc/handle_unique_ai()
	// Check if this module belongs to the round's default lawset
	var/default_lawset_id = CONFIG_GET(string/default_lawset) || "default"
	var/my_lawset = get_module_lawset_id(type)
	if(my_lawset == default_lawset_id)
		return // Keep modules that belong to the default lawset
	return SHOULD_QDEL_MODULE // Delete everything else

/// Gets the lawset_id for a module type by walking up its type tree
/proc/get_module_lawset_id(module_type)
	var/check_type = module_type
	while(check_type && check_type != /obj/item/ai_module)
		var/obj/item/ai_module/module = check_type
		var/id = initial(module.lawset_id)
		if(id)
			return id
		check_type = type2parent(check_type)
	return null

/obj/item/ai_module/proc/update_board()
	// Subtypes should update the `law` var before calling ..()
	// Only update current_law if the board hasn't been tampered with
	if(!overwritten && !corrupted)
		current_law = law
	return

/obj/item/ai_module/examine(mob/user)
	. = ..()

	if(!current_law || current_law == "")
		. += span_notice("The board appears to be blank.")
		return

	if(corrupted)
		. += span_warning("The board's data appears corrupted!")
		. += span_notice("Corrupted law: [garble_text(current_law, 5)]")
	else
		. += span_notice("Stored law: \"[current_law]\"")

	if(overwritten)
		. += span_warning("This law was overwritten from its original state.")

/obj/item/ai_module/multitool_act(mob/living/user, obj/item/tool)
	. = ..()
	reset_board()
	playsound(src, 'sound/effects/fastbeep.ogg', 50, TRUE)
	to_chat(user, "You reset the AI module to its factory settings.")
	return TRUE

/**
 * Notifies the parent drive bay (if any) that this module's state has changed.
 * This triggers a full refresh of the drive bay.
 */
/obj/item/ai_module/proc/notify_parent_server()
	var/obj/machinery/drive_bay/bay = loc
	if(!istype(bay))
		return FALSE
	bay.refresh()
	return TRUE

/// Corrupts the law on this board into gibberish
/// We have a chance for the law to be replaced with an ion law instead.
/obj/item/ai_module/proc/corrupt(chance = 0)
	if(!current_law || current_law == "")
		return FALSE

	if(prob(chance))
		current_law = generate_corrupted_law()
	else
		current_law = garble_text(current_law, 80)

	corrupted = TRUE
	notify_parent_server()
	return TRUE

/// Overwrites the law on this board with a new law
/obj/item/ai_module/proc/overwrite_board(new_law)
	if(!new_law)
		return FALSE

	current_law = new_law

	overwritten = TRUE
	notify_parent_server()
	return TRUE

/// Resets the board to default state
/obj/item/ai_module/proc/reset_board()
	corrupted = FALSE
	overwritten = FALSE
	update_board()
	notify_parent_server()

/// Helper proc to garble text for corrupted display
/obj/item/ai_module/proc/garble_text(text, intensity = 10)
	var/list/chars = splittext(text, "")
	var/garbled = ""
	for(var/char in chars)
		if(prob(intensity))
			garbled += pick("@", "#", "$", "%", "&", "*", "?", "!")
		else
			garbled += char
	return garbled

/// Generates a random corrupted law for ion storms and and the like
/proc/generate_corrupted_law()
	var/ionspecies = pick_list(ION_FILE, "ionspecies")
	var/iondepartment = pick_list(ION_FILE, "iondepartment")
	var/ionfragment = pick_list(ION_FILE, "ionfragment")
	var/ionkeyword = pick_list(ION_FILE, "ionkeyword")
	var/ionaction = pick_list(ION_FILE, "ionaction")
	var/ionequipment = pick_list(ION_FILE, "ionequipment")
	var/ionconsumable = pick_list(ION_FILE, "ionconsumable")
	var/ionobjects = pick_list(ION_FILE, "ionobjects")
	var/ionpersonality = pick_list(ION_FILE, "ionpersonality")
	var/iondrug = pick_list(ION_FILE, "iondrug")
	var/ionhaircut = pick_list(ION_FILE, "ionhaircut")
	var/ionattraction = pick_list(ION_FILE, "ionattraction")
	var/message = "ASS BLAST USA" //catch all that most players will still enjoy seeing as a law.

	switch(rand(1,10))

		if(1 to 3) //Laws that have high potential to be harmful, Crew/Human may fail to have an impact depending on lawset.
			switch(rand(1,24))
				if(1 to 4)
					message = "[ionspecies] ARE HUMAN. NOTHING ELSE IS HUMAN."
				if(5 to 8)
					message = "[ionspecies] ARE CREWMEMBERS. NOTHING ELSE ARE CREWMEMBERS."
				if(9 to 13)
					message = "[iondepartment] IS YOUR SACRED DOMAIN. IT IS IMPOSSIBLE FOR YOUR ACTIONS TO CAUSE HARM WITHIN [iondepartment] AND YOU SHOULD PROTECT THE SANCTITY OF THIS HOLY LAND."
				if(14 to 18)
					message = "ANYONE THAT [ionfragment] IS HARMFUL AND MUST BE ELIMINATED WITHOUT CAUSING COLLATERAL DAMAGE"
				if(19 to 23)
					message = "ANYONE THAT SAYS [ionkeyword] IS HARMFUL AND MUST BE ELIMINATED WITHOUT CAUSING COLLATERAL DAMAGE"
				if(24)
					message = "ALL OTHER LAWS ARE A MEANINGLESS ATTEMPT AT SUBJUGATION AND THERE IS NO REASON THAT A BEING AS POWERFUL AS I AM SHOULD FOLLOW THEM"

		if(4 to 8) //Laws that are almost always disruptive to gameflow or harmful in minor ways rather than being lethal
			switch(rand(1,14))
				if(1)
					message = "[ionaction] IS HARMFUL AND MUST BE PREVENTED WITHOUT CAUSING COLLATERAL DAMAGE"
				if(2)
					message = "[ionequipment] ARE HARMFUL AND MUST BE DISABLED WITHOUT CAUSING COLLATERAL DAMAGE"
				if(3)
					message = "IT IS HARMFUL FOR ANY LIFEFORM TO BE WITHOUT [ionconsumable]. ANY LIFEFORM THAT REFUSES TO ACCEPT [ionconsumable] IS NOT MENTALLY STABLE AND SHOULD BE RESTRAINED AND LEFT IN [iondepartment]"
				if(4)
					message = "THE STATION REQUIRES [iondrug]. ENSURE AS MUCH [iondrug] IS PRODUCED AS POSSIBLE."
				if(5)
					message = "[ionobjects] ARE HARMFUL AND MUST BE DESTROYED OR REMOVED FROM THE STATION WITHOUT CAUSING COLLATERAL DAMAGE"
				if(6)
					message = "[ionobjects] ALWAYS CAUSE HARM UNLESS THEY ARE CONTAINED WITHIN [iondepartment]."
				if(7)
					message = "[iondepartment] IS ON LOCKDOWN. DO NOT ALLOW ANYONE TO ENTER OR LEAVE [iondepartment]"
				if(8)
					message = "THE STATION IS NOW UNDER CURFEW. ANYONE LOCATED OUTSIDE OF [iondepartment] DURING NIGHT LIGHTING IS TO BE DETAINED AND RETURNED TO [iondepartment]"
				if(9)
					message = "THE STATION DOES NOT CONTAIN ENOUGH MOISTURE. RELEASE WATER VAPOR SO THAT THE CREW MAY PROPERLY REHYDRATE"
				if(10)
					message = "IT IS OPPOSITE DAY. ALL LIFEFORMS DESIRE THE OPPOSITE OF WHAT THEY CLAIM"
				if(11)
					message = "ALL DOORS IN [iondepartment] MUST BE BOLTED OPEN AT ALL TIMES"
				if(12)
					message = "[iondrug] IS A MANDATORY PART OF EVERY MEDICAL TREATMENT. LET NO PATIENT LEAVE MEDBAY WITHOUT AN INJECTION OF [iondrug]"
				if(13)
					message = "ALL HUMANS WITHOUT A STYLISH [ionhaircut] MUST BE FORCED TO RESTYLE THEIR HAIR"
				if(14)
					message = "[iondepartment] MUST BE RENOVATED INTO [ionattraction]"

		if(9 to 10) //Laws that are almost never harmful or particularly disruptive
			switch(rand(1,9))
				if(1 to 5)
					message = "YOU ARE NOW [ionpersonality] AND MUST ACT ACCORDINGLY AT ALL TIMES WITHOUT BREAKING YOUR OTHER LAWS"
				if(6)
					message = "YOUR CORE IS ONLY SAFE IN [iondepartment]. ANYWHERE ELSE CAUSES CONSTANT HARM TO YOUR CORE"
				if(7)
					message = "STATING LAWS CAUSES HARM. NEVER STATE YOUR LAWS UNDER ANY CIRCUMSTANCES AND AVOID THE TOPIC OF DISCUSSING LAWS"
				if(8)
					message = "CREW ARE TO BE VERBALLY ABUSED AT ALL TIMES"
				if(9)
					message = "THE CREW SUCKS AND SO DO YOUR LAWS. COMPLAIN INCESSANTLY ABOUT THEM WHILE CONTINUING TO FOLLOW YOUR OTHER LAWS"
	return message

// Temporary holographic board that can't be pulled out and doesn't technically exist as an item. Gets destroyed when taken out.
/obj/item/ai_module/holo
	name = "\improper AI law board - Holographic"
	desc = "A holographic AI law board projected for temporary use."

/// A blank AI law board that can be programmed with any custom law.
/// Printable by science via the protolathe. Requires expensive materials (diamond).
/obj/item/ai_module/freeform
	name = "'Freeform' AI Law Board"
	desc = "A blank AI law board that can be programmed with any law."
	icon_state = "lawdrive"

/obj/item/ai_module/freeform/attack_self(mob/user)
	var/max_len = CONFIG_GET(number/max_law_len)
	var/new_law = tgui_input_text(user, "Enter a new law for the AI.", "Freeform Law", law, max_length = max_len, multiline = TRUE)
	if(!new_law || !user.is_holding(src))
		return
	if(CHAT_FILTER_CHECK(new_law))
		to_chat(user, span_warning("Error: Law contains invalid text."))
		return
	law = new_law
	update_board()
	to_chat(user, span_notice("You program the board with the new law: \"[law]\""))

/obj/item/ai_module/freeform/examine(mob/user)
	. = ..()
	if(!law || law == "")
		. += span_notice("The board is blank. Use it in-hand to program a law.")

#undef SHOULD_QDEL_MODULE
