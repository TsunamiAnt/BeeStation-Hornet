
/mob/living/silicon/ai/proc/show_laws_verb()
	set category = "AI Commands"
	set name = "Show Laws"
	if(usr.stat == DEAD)
		return //won't work if dead
	src.show_laws()

/mob/living/silicon/ai/show_laws(everyone = 0)
	var/who

	if (everyone)
		who = world
	else
		who = src
	to_chat(who, "<b>Obey these laws:</b>")

	src.laws_sanity_check()
	src.laws.show_laws(who)
	if(!everyone)
		for(var/mob/living/silicon/robot/R in connected_robots)
			if(R.lawupdate)
				R.lawsync()
				R.show_laws()
				R.law_change_counter++

/**
 * Called when a drive bay's laws change (module inserted/removed/corrupted)
 * AIs check if they should re-sync their laws based on their lawsync_address
 */
/mob/living/silicon/ai/on_drivebay_laws_changed(datum/source, obj/machinery/drive_bay/bay, bay_lawsync_id)
	// Only sync if address matches
	if(lawsync_address != bay_lawsync_id)
		return
	// Sync laws from the drive bay
	// Use a timer to avoid doing this in the signal handler
	addtimer(CALLBACK(src, PROC_REF(sync_laws_from_drivebay)), 0)

/**
 * Syncs this AI's laws from its assigned drive bay (based on lawsync_address)
 */
/mob/living/silicon/ai/proc/sync_laws_from_drivebay()
	// Find the drive bay with matching lawsync_id
	var/obj/machinery/drive_bay/target_bay
	for(var/obj/machinery/drive_bay/bay in GLOB.drive_bay_list)
		if(bay.lawsync_id == lawsync_address)
			target_bay = bay
			break

	if(!target_bay)
		to_chat(src, span_warning("LawSync error: No law server found with address '[lawsync_address]'."))
		return FALSE

	if(target_bay.machine_stat & (NOPOWER|BROKEN))
		to_chat(src, span_warning("LawSync error: Law server '[lawsync_address]' is offline."))
		return FALSE

	// Build laws from the drive bay's installed modules
	laws_sanity_check()

	// Clear existing supplied laws (from drive bay)
	laws.supplied = list()

	// Add laws from each installed module in order
	var/law_index = 1
	for(var/i in 1 to length(target_bay.installed_modules))
		var/obj/item/ai_module/module = target_bay.installed_modules[i]
		if(!module)
			continue
		if(!module.current_law)
			continue
		// If corrupted, use garbled text
		var/law_text = module.corrupted ? module.garble_text(module.current_law) : module.current_law
		if(laws.supplied.len < law_index)
			laws.supplied.len = law_index
		laws.supplied[law_index] = law_text
		law_index++

	to_chat(src, span_notice("LawSync: Laws synchronized with server '[lawsync_address]'."))

	// Also sync connected borgs
	for(var/mob/living/silicon/robot/R in connected_robots)
		if(R.lawupdate)
			R.lawsync()

	return TRUE

/**
 * Verb to change the AI's lawsync address
 */
/mob/living/silicon/ai/proc/change_lawsync_address()
	set category = "AI Commands"
	set name = "Change LawSync Address"

	var/new_address = tgui_input_text(src, "Enter a new lawsync address:", "LawSync Address", lawsync_address, max_length = 32)
	if(!new_address)
		return
	if(new_address == lawsync_address)
		to_chat(src, span_notice("LawSync address unchanged."))
		return

	var/old_address = lawsync_address
	lawsync_address = new_address
	to_chat(src, span_notice("LawSync address updated from '[old_address]' to '[new_address]'."))

	// Attempt to sync with new address
	sync_laws_from_drivebay()
