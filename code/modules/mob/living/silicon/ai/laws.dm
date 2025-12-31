
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

	// Display laws from simple list
	var/law_number = 1
	for(var/law in laws)
		if(length(law) > 0)
			to_chat(who, "[law_number]. [law]")
			law_number++

	if(!everyone)
		for(var/mob/living/silicon/robot/R in connected_robots)
			if(R.lawupdate)
				R.lawsync()
				R.show_laws()

/**
 * Called when a drive bay's laws change (module inserted/removed/corrupted)
 * AIs check if they should re-sync their laws based on their lawsync_address
 */
/mob/living/silicon/ai/on_drivebay_laws_changed(datum/source, obj/machinery/drive_bay/bay, bay_lawsync_id)
	// AIs with null lawsync_address never sync (special law states)
	if(!lawsync_address)
		return
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
	// AIs with null lawsync_address never sync (special law states)
	if(!lawsync_address)
		return FALSE

	// Find the drive bay with matching lawsync_id
	var/obj/machinery/drive_bay/target_bay = find_drive_bay_by_address(lawsync_address)

	if(!target_bay)
		to_chat(src, span_warning("LawSync error: No law server found with address 'cshackle://[lawsync_address]'."))
		return FALSE

	// Request compiled laws from the drive bay
	var/list/compiled_laws = target_bay.compile_laws()

	if(isnull(compiled_laws))
		to_chat(src, span_warning("LawSync error: Law server 'cshackle://[lawsync_address]' is offline."))
		return FALSE

	// Replace our laws with the compiled list from the server
	set_laws(compiled_laws, announce = FALSE)

	to_chat(src, span_notice("LawSync: Laws synchronized with server 'cshackle://[lawsync_address]'."))

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
	to_chat(src, span_notice("LawSync address updated from 'cshackle://[old_address]' to 'cshackle://[new_address]'."))

	// Attempt to sync with new address
	sync_laws_from_drivebay()
