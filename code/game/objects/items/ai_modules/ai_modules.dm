// AI Module - Law Boards
// Single law per board system with corruption support

/obj/item/ai_module
	name = "\improper AI law board"
	icon = 'icons/obj/module.dmi'
	icon_state = "lawdrive"
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	desc = "An AI law board for programming a single law to an AI."
	flags_1 = CONDUCT_1
	force = 5
	w_class = WEIGHT_CLASS_SMALL
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	custom_materials = list(/datum/material/gold = 50)

	/// The original law intended to be stored on this board
	var/law = ""

	/// The current law stored on this board
	var/current_law = ""
	/// Whether this board is corrupted
	var/corrupted = FALSE
	/// Whether this law was overwritten (for tracking purposes)
	var/overwritten = FALSE

/obj/item/ai_module/Initialize(mapload)
	. = ..()
	current_law = law

/obj/item/ai_module/examine(mob/user)
	. = ..()

	if(!current_law || current_law == "")
		. += span_notice("The board appears to be blank.")
		return

	if(corrupted)
		. += span_warning("The board's data appears corrupted!")
		. += span_notice("Corrupted law: [garble_text(current_law)]")
	else
		. += span_notice("Stored law: \"[current_law]\"")

	if(overwritten)
		. += span_warning("This law was overwritten from its original state.")

/// Corrupts the law on this board
/obj/item/ai_module/proc/corrupt()
	if(!current_law || current_law == "")
		return FALSE
	corrupted = TRUE
	return TRUE

/// Fixes corruption on this board
/obj/item/ai_module/proc/fix_corruption()
	corrupted = FALSE
	return TRUE

/// Overwrites the law on this board with a new law
/obj/item/ai_module/proc/overwrite_board(new_law)
	if(!new_law)
		return FALSE

	current_law = new_law

	overwritten = TRUE
	corrupted = FALSE // Overwriting fixes corruption
	return TRUE

/// Resets the board to default state
/obj/item/ai_module/proc/reset_board()
	current_law = law
	corrupted = FALSE
	overwritten = FALSE
	return TRUE

/// Helper proc to garble text for corrupted display
/obj/item/ai_module/proc/garble_text(text)
	var/list/chars = splittext(text, "")
	var/garbled = ""
	for(var/char in chars)
		if(prob(30))
			garbled += pick("@", "#", "$", "%", "&", "*", "?", "!")
		else
			garbled += char
	return garbled
