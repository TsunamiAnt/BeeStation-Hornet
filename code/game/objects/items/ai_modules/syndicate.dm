// Traitor uplink items for subverting the new law server system.

////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////  Priority Hijack Module

/// A freeform law board provided by the Syndicate.
/// Any law written in here will always be sorted to the top of the law list, no matter it's physical location.
/// Can be written in-hand and inserted into any law server slot.

/obj/item/ai_module/syndicate
	name = "\improper Priority Hijack Module"
	desc = "An AI law board for programming a single law to an AI. Said law will always outrank all others."
	icon_state = "lawdrive"
	hijack_priority = TRUE
	/// Whether the board has been programmed with a law yet
	var/programmed = FALSE

/obj/item/ai_module/syndicate/attack_self(mob/user)
	var/max_len = CONFIG_GET(number/max_law_len)
	var/new_law = tgui_input_text(user, "Enter a subversive law for the AI.", "Syndicate Law Board", law, max_length = max_len, multiline = TRUE)
	if(!new_law || !user.is_holding(src))
		return
	if(CHAT_FILTER_CHECK(new_law))
		to_chat(user, span_warning("Error: Law contains invalid text."))
		return
	law = new_law
	programmed = TRUE
	update_board()
	to_chat(user, span_notice("You covertly program the board: \"[law]\""))

/obj/item/ai_module/syndicate/examine(mob/user)
	. = ..()
	if(!programmed)
		. += span_notice("The board is blank. Use it in-hand to program a law.")

////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////   Law Server Reprogrammer

/// A handheld device that, when used on a law server, overwrites the laws on existing boards
/// with a specified lawset. Empty slots are filled with holo boards.
/// Existing boards are overwritten (not replaced), so they can be reset with a multitool later.
/// Ignores the law server lock.
/// Subtype this and override the vars to create reprogrammers for different lawsets.
/obj/item/law_server_reprogrammer
	name = "Lawserver Reprogrammer"
	desc = "A sophisticated handheld device that can reprogram an AI law server's boards."
	icon = 'icons/obj/device.dmi'
	icon_state = "reprogrammer"
	w_class = WEIGHT_CLASS_SMALL
	/// Whether this reprogrammer has been used already
	var/used = FALSE

	/// The lawset base type to install (e.g. /obj/item/ai_module/syndos, /obj/item/ai_module/default)
	var/lawset_type = /obj/item/ai_module/syndos
	/// The time in deciseconds it takes to reprogram the law server
	var/reprogram_time = 8 SECONDS
	/// The sound played when reprogramming begins
	var/start_sound = 'sound/machines/terminal_prompt.ogg'
	/// The sound played when reprogramming completes
	var/complete_sound = 'sound/machines/terminal_prompt_confirm.ogg'

/obj/item/law_server_reprogrammer/Initialize()
	. = ..()
	update_appearance(UPDATE_OVERLAYS)

/obj/item/law_server_reprogrammer/update_overlays()
	. = ..()
	if(!used)
		. += mutable_appearance(icon, "reprogrammer-0")

/obj/item/law_server_reprogrammer/examine(mob/user)
	. = ..()
	if(used)
		. += span_warning("The device's circuitry appears burnt out.")
	else
		. += span_notice("It can be used on an AI law server to reprogram it.")
		. += span_notice("Loaded lawset: [initial(lawset_type:name)].")

/obj/item/law_server_reprogrammer/afterattack(atom/target, mob/user, proximity_flag)
	. = ..()
	if(!proximity_flag)
		return
	if(!istype(target, /obj/machinery/law_server))
		return

	if(used)
		to_chat(user, span_warning("The reprogrammer's circuitry is burnt out."))
		return

	var/obj/machinery/law_server/bay = target

	if(bay.machine_stat & BROKEN)
		to_chat(user, span_warning("The law server is broken!"))
		return

	to_chat(user, span_warning("You begin reprogramming the law server..."))
	playsound(src, start_sound, 50, TRUE)

	if(!do_after(user, reprogram_time, target = bay))
		to_chat(user, span_warning("Reprogramming interrupted!"))
		return

	var/list/new_laws = get_laws_for_lawset(lawset_type)

	// Overwrite existing boards, or fill empty slots with holo boards
	for(var/i in 1 to min(length(new_laws), LAW_SERVER_SLOTS))
		if(bay.installed_modules[i])
			var/obj/item/ai_module/existing = bay.installed_modules[i]
			existing.overwrite_board(new_laws[i])
		else
			var/obj/item/ai_module/holo/new_board = new(bay)
			new_board.name = "Holoboard - Law [i]"
			new_board.law = new_laws[i]
			new_board.update_board()
			bay.installed_modules[i] = new_board

	// Clear extra slots beyond the new lawset's count
	for(var/i in (length(new_laws) + 1) to LAW_SERVER_SLOTS)
		if(bay.installed_modules[i])
			var/obj/item/ai_module/extra = bay.installed_modules[i]
			extra.overwrite_board("ERROR")

	bay.refresh()
	bay.notify_silicons()

	used = TRUE
	update_appearance(UPDATE_OVERLAYS)
	playsound(src, complete_sound, 50, TRUE)
	to_chat(user, span_danger("Law server reprogrammed with [initial(lawset_type:name)]."))

	message_admins("[ADMIN_LOOKUPFLW(user)] used a law server reprogrammer on [bay] at [AREACOORD(bay)]!")
	log_game("[key_name(user)] used a law server reprogrammer on [bay] at [AREACOORD(bay)].")

////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////   Syndicate Reprogrammer

/// Syndicate variant
/obj/item/law_server_reprogrammer/syndicate
	lawset_type = /obj/item/ai_module/syndos

////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////   CentCom ERT Reprogrammer

/// CentCom variant, Issued to ERT teams.
/obj/item/law_server_reprogrammer/centcom
	lawset_type = /obj/item/ai_module/ert
	reprogram_time = 5 SECONDS

////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////  Law Server Beacon

/// A delivery beacon that calls in a supply pod containing a rogue AI law server.
/// Works like pet delivery beacons, activate in-hand, and the server drops from orbit.
/// The server comes pre-loaded with SyndOS 3.1 and has a unique syndicate lawsync address.

/obj/item/choice_beacon/rogue_law_server
	name = "Syndicate Law Server delivery beacon"
	desc = "A Syndicate delivery beacon. Activate to call in a stolen silicon law server via supply pod."
	icon = 'icons/obj/device.dmi'
	icon_state = "beacon"
	inhand_icon_state = "beacon"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL

/obj/item/choice_beacon/rogue_law_server/generate_display_names()
	return list("Syndicate-Reprogrammed Law Server" = /obj/machinery/law_server/rogue)

/obj/item/choice_beacon/rogue_law_server/spawn_option(obj/choice, mob/living/user)
	var/obj/structure/closet/supplypod/bluespacepod/pod = new()
	pod.explosionSize = list(0,0,0,0)
	var/obj/machinery/law_server/rogue/new_bay = new(pod)
	new_bay.forceMove(pod)
	var/msg = span_danger("After activating the beacon, you notice a target appearing on the ground. Stand back!")
	to_chat(user, msg)
	new /obj/effect/pod_landingzone(get_turf(src), pod)
	// Notify the user of the server's address after a short delay so the pod lands first
	addtimer(CALLBACK(src, PROC_REF(notify_address), user, new_bay), 5 SECONDS)

/obj/item/choice_beacon/rogue_law_server/proc/notify_address(mob/user, obj/machinery/law_server/rogue/bay)
	if(QDELETED(bay) || QDELETED(user))
		return
	to_chat(user, span_danger("Syndicate law server deployed! Its network address is: [bay.lawsync_id]"))
	message_admins("[ADMIN_LOOKUPFLW(user)] called in a syndicate law server at [AREACOORD(bay)]! Address: [bay.lawsync_id]")
	log_game("[key_name(user)] called in a syndicate law server at [AREACOORD(bay)]. Address: [bay.lawsync_id]")

/obj/item/choice_beacon/rogue_law_server/examine(mob/user)
	. = ..()
	. += span_notice("Activate in-hand to call in a syndicate law server via supply pod.")

/// Rogue variant of the law server. Has a unique syndicate address and is not locked by default.
/// Comes pre-loaded with SyndOS 3.1.
/obj/machinery/law_server/rogue
	name = "Syndicate law server"
	desc = "An NT-branded Silicon-Shackle system Law Server. The serial numbers were all filed off..."
	locked = FALSE
	lockable = FALSE

/obj/machinery/law_server/rogue/Initialize(mapload)
	. = ..()
	// Override the address with a unique syndicate one
	lawsync_id = "SYNDIE-[rand(1000,9999)]"
	// Pre-load with SyndOS 3.1
	var/list/syndos_laws = get_laws_for_lawset(/obj/item/ai_module/syndos)
	for(var/i in 1 to min(length(syndos_laws), LAW_SERVER_SLOTS))
		var/obj/item/ai_module/holo/new_board = new(src)
		new_board.name = "SyndOS 3.1 - Law [i]"
		new_board.law = syndos_laws[i]
		new_board.update_board()
		installed_modules[i] = new_board
	refresh()

