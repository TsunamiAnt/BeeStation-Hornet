/// Number of drive bays available in each drive bay machine
#define DRIVE_BAY_SLOTS 9
/// Base power draw of the drive bay
#define DRIVE_BAY_BASE_POWER (50 WATT)
/// Variable power draw per inserted drive (0-9)
#define DRIVE_BAY_VARIABLE_POWER (25 WATT)

/**
 * AI Law Upload Drive Bay
 *
 * A machine used for uploading laws to silicon units.
 * Part of the new AI lawset system.
 */
/obj/machinery/drive_bay
	name = "AI law server"
	desc = "A sophisticated machine used for uploading and managing laws for silicon units."
	icon = 'icons/obj/machines/drive_bay.dmi'
	icon_state = "drivebay"
	max_integrity = 1000
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = DRIVE_BAY_BASE_POWER
	active_power_usage = DRIVE_BAY_BASE_POWER
	circuit = /obj/item/circuitboard/machine/drive_bay

	/// This is randomized per drive bay for network identification, except for the first one in a round. That one's always the default.
	var/lawsync_id = ""

	/// List of installed AI modules. Index 1-9 corresponds to bay slots 1-9. Null entries mean empty slots.
	var/list/installed_modules = list()

	/// Whether the drive bay is locked with the upload code
	var/locked = TRUE

/obj/machinery/drive_bay/Initialize(mapload)
	. = ..()
	// Initialize all bay slots to null (empty)
	installed_modules = new /list(DRIVE_BAY_SLOTS)
	update_power_draw()
	update_appearance()
	/// Register in global list. If we are the first, set lawsync_id to default.
	if(!GLOB.drive_bay_list.len)
		lawsync_id = DEFAULT_DRIVE_BAY_ADDRESS
	GLOB.drive_bay_list += src

/obj/machinery/drive_bay/Destroy()
	GLOB.drive_bay_list -= src
	// Eject all installed modules on destruction
	for(var/i in 1 to DRIVE_BAY_SLOTS)
		if(installed_modules[i])
			var/obj/item/ai_module/module = installed_modules[i]
			module.forceMove(get_turf(src))
			installed_modules[i] = null
	return ..()

/obj/machinery/drive_bay/examine(mob/user)
	. = ..()
	if(panel_open)
		. += span_notice("The maintenance panel is open.")

/obj/machinery/drive_bay/update_icon_state()
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN))
		icon_state = "drivebay-off"
	else
		icon_state = "drivebay"

/obj/machinery/drive_bay/update_overlays()
	. = ..()
	if(panel_open)
		. += "drivebay-panel"

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

/// Updates the power draw based on the amount of inserted drives
/obj/machinery/drive_bay/proc/update_power_draw()
	var/drives_inserted = get_drives_count()
	if(drives_inserted > 0)
		update_mode_power_usage(ACTIVE_POWER_USE, DRIVE_BAY_BASE_POWER + drives_inserted * DRIVE_BAY_VARIABLE_POWER)
	else
		update_mode_power_usage(IDLE_POWER_USE, DRIVE_BAY_BASE_POWER)

/// Returns the number of drives currently installed
/obj/machinery/drive_bay/proc/get_drives_count()
	var/count = 0
	for(var/i in 1 to DRIVE_BAY_SLOTS)
		if(installed_modules[i])
			count++
	return count

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
	update_power_draw()
	update_appearance()
	if(user)
		to_chat(user, span_notice("You install [module] into bay [bay_slot]."))
	// Notify all silicons that laws may have changed
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_DRIVEBAY_LAWS_CHANGED, src, lawsync_id)
	return TRUE

/// Remove a module from a specific bay slot
/obj/machinery/drive_bay/proc/remove_module(bay_slot, mob/user)
	if(bay_slot < 1 || bay_slot > DRIVE_BAY_SLOTS)
		return null
	if(!installed_modules[bay_slot])
		if(user)
			to_chat(user, span_warning("Bay [bay_slot] is empty!"))
		return null

	var/obj/item/ai_module/module = installed_modules[bay_slot]
	installed_modules[bay_slot] = null

	if(user)
		user.put_in_hands(module)
		to_chat(user, span_notice("You remove [module] from bay [bay_slot]."))
	else
		module.forceMove(get_turf(src))

	update_power_draw()
	update_appearance()
	// Notify all silicons that laws may have changed
	SEND_GLOBAL_SIGNAL(COMSIG_GLOB_DRIVEBAY_LAWS_CHANGED, src, lawsync_id)
	return module

// TGUI Interface
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
				return FALSE
			var/new_id = tgui_input_text(usr, "Enter a new network ID for this drive bay:", "Network ID", lawsync_id, max_length = 32)
			if(new_id && new_id != lawsync_id)
				lawsync_id = new_id
				return TRUE
			return FALSE

		if("toggle_lock")
			if(locked)
				// Trying to unlock - need upload code
				if(!GLOB.upload_code)
					to_chat(usr, span_warning("No upload code has been generated yet. Extract one from a robotics console first."))
					return FALSE
				var/entered_code = tgui_input_text(usr, "Enter the upload code to unlock the drive bay:", "Upload Code", max_length = 8)
				if(!entered_code)
					return FALSE
				if(entered_code != GLOB.upload_code)
					to_chat(usr, span_warning("Invalid upload code!"))
					return FALSE
				locked = FALSE
				to_chat(usr, span_notice("Drive bay unlocked."))
				return TRUE
			else
				// Locking
				locked = TRUE
				to_chat(usr, span_notice("Drive bay locked."))
				return TRUE

		if("scramble_code")
			if(locked)
				to_chat(usr, span_warning("The drive bay must be unlocked to scramble the upload code!"))
				return FALSE
			GLOB.upload_code = random_code(4)
			message_admins("[ADMIN_LOOKUPFLW(usr)] scrambled the upload code using [src]!")
			to_chat(usr, span_notice("Upload code has been scrambled. A new code must be extracted from a robotics console."))
			// Lock all drive bays when code is scrambled
			for(var/obj/machinery/drive_bay/bay in GLOB.drive_bay_list)
				bay.locked = TRUE
			return TRUE

	return FALSE

#undef DRIVE_BAY_SLOTS

#undef DRIVE_BAY_BASE_POWER
#undef DRIVE_BAY_VARIABLE_POWER
