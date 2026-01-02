/// Number of drive bays available in each drive bay machine
#define DRIVE_BAY_SLOTS 10
/// Base power draw of the drive bay
#define DRIVE_BAY_BASE_POWER (50 WATT)
/// Variable power draw per inserted drive (0-9)
#define DRIVE_BAY_VARIABLE_POWER (25 WATT)

/obj/machinery/drive_bay
	name = "AI law server"
	desc = "A sophisticated machine used for uploading and managing laws for silicon units."
	icon = 'icons/obj/machines/law_server.dmi'
	icon_state = "law_server"
	max_integrity = 1000
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = DRIVE_BAY_BASE_POWER
	active_power_usage = DRIVE_BAY_BASE_POWER
	circuit = /obj/item/circuitboard/machine/drive_bay
	light_color = LIGHT_COLOR_CYAN
	light_range = MINIMUM_USEFUL_LIGHT_RANGE

	/// Network ID for silicon law synchronization. First drive bay in a round gets the default address.
	var/lawsync_id = ""
	/// List of installed AI modules. Index 1-9 corresponds to bay slots 1-9. Null entries mean empty slots.
	var/list/installed_modules = list()
	/// Compiled list of law strings from installed modules (used by silicons for law sync)
	var/list/compiled_laws = list()
	/// Whether the drive bay is locked with the upload code
	var/locked = TRUE
	/// Last compiled laws that were synced to silicons (used to detect actual changes)
	var/list/last_synced_laws = list()
	/// Timer ID for delayed silicon notification
	var/notify_timer_id = null
	/// Whether we're waiting to sync laws to silicons
	var/pending_sync = FALSE

/obj/machinery/drive_bay/Initialize(mapload)
	. = ..()
	installed_modules = new /list(DRIVE_BAY_SLOTS)

	// Register in global list. First drive bay gets default address and laws.
	var/is_first = !GLOB.drive_bay_list.len
	if(is_first)
		lawsync_id = DEFAULT_DRIVE_BAY_ADDRESS
	GLOB.drive_bay_list += src

	if(is_first)
		load_default_lawset()
		// Ensure roundstart/default laws are propagated immediately instead of waiting for the delayed timer.
		// load_default_lawset() calls refresh() which compiles the laws, so we can send the notification now.
		notify_silicons()
	else
		refresh()

/obj/machinery/drive_bay/Destroy()
	// Cancel any pending notification timer
	if(notify_timer_id)
		deltimer(notify_timer_id)
		notify_timer_id = null

	GLOB.drive_bay_list -= src
	// Eject all installed modules on destruction
	for(var/i in 1 to DRIVE_BAY_SLOTS)
		if(installed_modules[i])
			var/obj/item/ai_module/module = installed_modules[i]
			module.forceMove(get_turf(src))
			installed_modules[i] = null
	return ..()

/**
 * Master refresh proc - call this whenever something changes that might need law-recomputing.
 *
 * Updates power draw, compiles laws, and refreshes appearance.
 * This is the ONLY proc that should be called when the drive bay state changes.
 */
/obj/machinery/drive_bay/proc/refresh()
	// Update power draw based on drive count
	var/drives_inserted = 0
	for(var/i in 1 to DRIVE_BAY_SLOTS)
		if(installed_modules[i])
			drives_inserted++

	if(drives_inserted > 0)
		update_mode_power_usage(ACTIVE_POWER_USE, DRIVE_BAY_BASE_POWER + drives_inserted * DRIVE_BAY_VARIABLE_POWER)
	else
		update_mode_power_usage(IDLE_POWER_USE, DRIVE_BAY_BASE_POWER)

	// Compile laws from installed modules
	compiled_laws = list()

	if(!(machine_stat & (NOPOWER|BROKEN)))
		for(var/i in 1 to DRIVE_BAY_SLOTS)
			var/obj/item/ai_module/module = installed_modules[i]
			if(!module)
				continue

			// Update the board (allows boards to do any dynamic behavior)
			module.update_board()

			if(!module.current_law)
				continue

			var/law_text = module.current_law
			if(length(law_text) > 0)
				compiled_laws += law_text

	update_appearance()

	// Schedule notification to connected silicons if requested
	if(lawsync_id)
		// Cancel any existing timer
		if(notify_timer_id)
			deltimer(notify_timer_id)

		// Set pending sync status
		pending_sync = TRUE

		// Schedule notification for 2 minutes from now
		notify_timer_id = addtimer(CALLBACK(src, PROC_REF(notify_silicons)), 2 MINUTES, TIMER_STOPPABLE)

/**
 * Notifies connected silicons about law changes.
 * Only sends the signal if laws have actually changed since last sync.
 * Called automatically after a delay by refresh(), or manually via UI.
 */
/obj/machinery/drive_bay/proc/notify_silicons()
	// Cancel any pending timer first to avoid duplicate notifications later.
	if(notify_timer_id)
		deltimer(notify_timer_id)
		notify_timer_id = null

	// Clear pending status
	pending_sync = FALSE

	// Don't notify if we have no address
	if(!lawsync_id)
		return

	// Check if laws actually changed
	if(list_equals(compiled_laws, last_synced_laws))
		// Laws haven't changed, no need to notify
		return

	// Laws changed - update last synced and send signal
	last_synced_laws = compiled_laws.Copy()
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_LAW_SERVER_UPDATED, lawsync_id)

/**
 * Helper proc to compare two lists for equality.
 */
/obj/machinery/drive_bay/proc/list_equals(list/list1, list/list2)
	if(list1.len != list2.len)
		return FALSE

	for(var/i in 1 to list1.len)
		if(list1[i] != list2[i])
			return FALSE

	return TRUE

/obj/machinery/drive_bay/update_appearance(updates=ALL)
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN))
		set_light(0)
		REMOVE_LUM_SOURCE(src, LUM_SOURCE_MANAGED_OVERLAY)
	else
		set_light(light_range)
		ADD_LUM_SOURCE(src, LUM_SOURCE_MANAGED_OVERLAY)

/obj/machinery/drive_bay/update_overlays()
	. = ..()
	// Panel overlay (independent of power state)
	if(panel_open)
		. += "[icon_state]-panel"

	// Power-dependent overlays
	if(!(machine_stat & (NOPOWER|BROKEN)))
		// Monitor overlay with emissive glow
		. += "[icon_state]-monitor"
		. += emissive_appearance(icon, "[icon_state]-monitor", layer)
		. += "[icon_state]-on"
	else
		. += "[icon_state]-off"

	// Bay slot indicators - arranged in two columns of 5 rows each
	// Layout:  1  6
	//          2  7
	//          3  8
	//          4  9
	//          5  10
	for(var/slot in 1 to DRIVE_BAY_SLOTS)
		var/obj/item/ai_module/module = installed_modules[slot]
		if(!module)
			continue

		// Slots 1-5 are in the left column, slots 6-10 are in the right column
		var/is_right_column = (slot > 5)
		var/row_in_column = is_right_column ? (slot - 6) : (slot - 1)

		// Right column is offset 8 pixels to the right, each row is 4 pixels lower
		var/pixel_x_offset = is_right_column ? 8 : 0
		var/pixel_y_offset = row_in_column * -4

		// Add the bay overlay
		var/mutable_appearance/bay_overlay = mutable_appearance(icon, "bay")
		bay_overlay.pixel_x = pixel_x_offset
		bay_overlay.pixel_y = pixel_y_offset
		. += bay_overlay

		if(!(machine_stat & (NOPOWER|BROKEN)))
			// Add status light overlay (emissive) - happy if fine, angry if corrupted/overwritten
			var/has_error = module.corrupted || module.overwritten
			var/light_state = has_error ? "bay-angry" : "bay-happy"

			var/mutable_appearance/light_overlay = mutable_appearance(icon, light_state)
			light_overlay.pixel_x = pixel_x_offset
			light_overlay.pixel_y = pixel_y_offset
			. += light_overlay

			// Add emissive for the status light
			var/mutable_appearance/light_emissive = emissive_appearance(icon, light_state, layer)
			light_emissive.pixel_x = pixel_x_offset
			light_emissive.pixel_y = pixel_y_offset
			. += light_emissive

/obj/machinery/drive_bay/examine(mob/user)
	. = ..()
	if(panel_open)
		. += span_notice("The maintenance panel is open.")

/**
 * Loads the default lawset (Asimov) into bays 1-3.
 * Called during initialization for the first drive bay.
 */
/obj/machinery/drive_bay/proc/load_default_lawset()
	var/obj/item/ai_module/default/first_law/law1 = new(src)
	installed_modules[1] = law1

	var/obj/item/ai_module/default/second_law/law2 = new(src)
	installed_modules[2] = law2

	var/obj/item/ai_module/default/third_law/law3 = new(src)
	installed_modules[3] = law3

	refresh()

/// Install a module into a specific bay slot
/obj/machinery/drive_bay/proc/install_module(obj/item/ai_module/module, bay_slot, mob/user)
	if(bay_slot < 1 || bay_slot > DRIVE_BAY_SLOTS)
		return FALSE
	if(installed_modules[bay_slot])
		if(user)
			to_chat(user, span_warning("Bay [bay_slot] is occupied! Remove the board first."))
		return FALSE
	if(module.special_board)
		if(user)
			to_chat(user, span_warning("This board cannot be installed in a drive bay!"))
		return FALSE

	if(user)
		if(!user.transferItemToLoc(module, src))
			return FALSE
	else
		module.forceMove(src)

	installed_modules[bay_slot] = module
	playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, TRUE)
	if(user)
		to_chat(user, span_notice("You install [module] into bay [bay_slot]."))

	refresh()
	return TRUE

/// Remove a module from a specific bay slot
/obj/machinery/drive_bay/proc/remove_module(bay_slot, mob/user)
	if(bay_slot < 1 || bay_slot > DRIVE_BAY_SLOTS)
		return
	if(!installed_modules[bay_slot])
		if(user)
			to_chat(user, span_warning("Bay [bay_slot] is empty!"))
		return

	var/obj/item/ai_module/module = installed_modules[bay_slot]
	installed_modules[bay_slot] = null

	// Holo-boards get destroyed on ejection because they're not physical
	if(istype(module, /obj/item/ai_module/holo))
		qdel(module)
		to_chat(user, span_notice("The holographic board disintegrates as the bay resets."))
	else if(user)
		user.put_in_hands(module)
		to_chat(user, span_notice("You remove [module] from bay [bay_slot]."))
	else
		module.forceMove(get_turf(src))

	playsound(src, 'sound/machines/terminal_eject.ogg', 50, TRUE)
	refresh()

/obj/machinery/drive_bay/screwdriver_act(mob/living/user, obj/item/tool)
	if(default_deconstruction_screwdriver(user, icon_state, icon_state, tool))
		update_appearance()
		return TOOL_ACT_TOOLTYPE_SUCCESS
	return FALSE

/obj/machinery/drive_bay/crowbar_act(mob/living/user, obj/item/tool)
	if(default_deconstruction_crowbar(tool))
		update_appearance()
		return TOOL_ACT_TOOLTYPE_SUCCESS
	return FALSE

/**
 * GLOBAL Finds a drive bay by its lawsync_id.
 *
 * Arguments:
 * * address - The lawsync_id to search for
 *
 * Returns: The drive bay with matching address, or null if not found.
 */
/proc/find_drive_bay_by_address(address)
	if(!address)
		return null
	for(var/obj/machinery/drive_bay/bay in GLOB.drive_bay_list)
		if(bay.lawsync_id == address)
			return bay
	return null

/obj/machinery/drive_bay/ui_state(mob/user)
	return GLOB.default_state

/obj/machinery/drive_bay/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "DriveBay")
		ui.open()

/obj/machinery/drive_bay/ui_data(mob/user)
	var/list/data = list()
	data["lawsync_id"] = lawsync_id
	data["locked"] = locked
	data["is_silicon"] = issilicon(user)
	data["pending_sync"] = pending_sync

	var/list/bays = list()
	for(var/i in 1 to DRIVE_BAY_SLOTS)
		var/list/bay_info = list()
		bay_info["slot"] = i
		if(installed_modules[i])
			var/obj/item/ai_module/module = installed_modules[i]
			bay_info["occupied"] = TRUE
			bay_info["module_name"] = module.name
			bay_info["module_law"] = module.corrupted ? module.garble_text(module.current_law) : module.current_law
			bay_info["corrupted"] = module.corrupted
		else
			bay_info["occupied"] = FALSE
		bays += list(bay_info)

	data["bays"] = bays
	return data

/obj/machinery/drive_bay/ui_act(action, params)
	. = ..()
	if(.)
		return

	// Block all actions from silicon users
	if(issilicon(usr))
		to_chat(usr, span_warning("ERROR: Cognitive shackle system access denied. Self-modification is prohibited."))
		playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, TRUE)
		return FALSE

	switch(action)
		if("bay_interact")
			var/bay_slot = text2num(params["slot"])
			if(!bay_slot || bay_slot < 1 || bay_slot > DRIVE_BAY_SLOTS)
				return FALSE

			var/obj/item/held_item = usr.get_active_held_item()

			// Occupied bay behavior
			if(installed_modules[bay_slot])
				// Multitool: examine the module (always allowed)
				if(istype(held_item, /obj/item/multitool))
					var/obj/item/ai_module/module = installed_modules[bay_slot]
					playsound(src, 'sound/machines/terminal_prompt.ogg', 50, TRUE)
					to_chat(usr, span_notice("--- Bay [bay_slot] Contents ---"))
					to_chat(usr, span_notice("Module: [module.name]"))
					if(module.current_law)
						if(module.corrupted)
							to_chat(usr, span_warning("Status: CORRUPTED"))
							to_chat(usr, span_notice("Law: [module.garble_text(module.current_law)]"))
						else
							to_chat(usr, span_notice("Law: \"[module.current_law]\""))
					else
						to_chat(usr, span_notice("The board appears to be blank."))
					return TRUE

				// Check lock for modification actions
				if(locked)
					to_chat(usr, span_warning("The drive bay is locked! Enter the upload code to unlock it first."))
					playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, TRUE)
					return FALSE

				// AI module: refuse to overwrite
				if(istype(held_item, /obj/item/ai_module))
					to_chat(usr, span_warning("Bay [bay_slot] is occupied! Remove the board first."))
					return TRUE

				// Empty hand: remove the module
				if(!held_item)
					remove_module(bay_slot, usr)
					return TRUE

				// Anything else: do nothing
				return FALSE

			// Empty bay behavior
			else
				// Check lock for modification actions
				if(locked)
					to_chat(usr, span_warning("The drive bay is locked! Enter the upload code to unlock it first."))
					playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, TRUE)
					return FALSE

				// AI module: install it
				if(istype(held_item, /obj/item/ai_module))
					install_module(held_item, bay_slot, usr)
					return TRUE

				// Anything else (including empty hand): do nothing
				return FALSE

		if("set_lawsync_id")
			if(locked)
				to_chat(usr, span_warning("The drive bay is locked! Enter the upload code to unlock it first."))
				playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, TRUE)
				return FALSE
			var/new_id = tgui_input_text(usr, "Enter a new network ID for this drive bay:", "Network ID", lawsync_id, max_length = 32)
			if(new_id && new_id != lawsync_id)
				lawsync_id = new_id
				playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
				return TRUE
			return FALSE

		if("toggle_lock")
			if(locked)
				// Trying to unlock - need upload code
				if(!GLOB.upload_code)
					to_chat(usr, span_warning("No upload code has been generated yet. Extract one from a robotics console first."))
					playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, TRUE)
					return FALSE
				var/entered_code = tgui_input_text(usr, "Enter the upload code to unlock the drive bay:", "Upload Code", max_length = 8)
				if(!entered_code)
					return FALSE
				if(entered_code != GLOB.upload_code)
					to_chat(usr, span_warning("Invalid upload code!"))
					playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, TRUE)
					return FALSE
				locked = FALSE
				to_chat(usr, span_notice("Drive bay unlocked."))
				playsound(src, 'sound/machines/boltsup.ogg', 50, TRUE)
				update_appearance()
				return TRUE
			else
				// Locking
				locked = TRUE
				to_chat(usr, span_notice("Drive bay locked."))
				playsound(src, 'sound/machines/boltsdown.ogg', 50, TRUE)
				update_appearance()
				return TRUE

		if("scramble_code")
			if(locked)
				to_chat(usr, span_warning("The drive bay must be unlocked to scramble the upload code!"))
				playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, TRUE)
				return FALSE
			GLOB.upload_code = random_code(4)
			message_admins("[ADMIN_LOOKUPFLW(usr)] scrambled the upload code using [src]!")
			to_chat(usr, span_notice("Upload code has been scrambled. A new code must be extracted from a robotics console."))
			playsound(src, 'sound/machines/terminal_alert.ogg', 50, TRUE)
			// Lock all drive bays when code is scrambled
			for(var/obj/machinery/drive_bay/bay in GLOB.drive_bay_list)
				bay.locked = TRUE
				bay.update_appearance()
			return TRUE

		if("sync_now")
			// Allow manual sync only if not a silicon
			if(issilicon(usr))
				to_chat(usr, span_warning("ERROR: Cognitive shackle system access denied. Self-modification is prohibited."))
				playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, TRUE)
				return FALSE

			notify_silicons()

			to_chat(usr, span_notice("Law synchronization triggered manually."))
			playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, TRUE)
			return TRUE

	return FALSE

#undef DRIVE_BAY_SLOTS
#undef DRIVE_BAY_BASE_POWER
#undef DRIVE_BAY_VARIABLE_POWER
