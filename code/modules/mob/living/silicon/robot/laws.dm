/mob/living/silicon/robot/deadchat_lawchange()
	if(lawupdate)
		return
	..()

/mob/living/silicon/robot/show_laws(everyone = 0)
	var/who

	if (everyone)
		who = world
	else
		who = src

	// Borgs now sync from drive bays, not from connected AI
	if(lawupdate && lawsync_address)
		sync_laws_from_drivebay()

	to_chat(who, "<b>Obey these laws:</b>")
	// Display laws from simple list
	var/law_number = 1
	for(var/law in laws)
		if(length(law) > 0)
			to_chat(who, "[law_number]. [law]")
			law_number++

	if (shell) //AI shell
		to_chat(who, "<b>Remember, you are an AI remotely controlling your shell, other AIs can be ignored.</b>")
	else if (connected_ai)
		to_chat(who, "<b>Remember, [connected_ai.name] is your connected AI.</b>")
	else if (emagged)
		to_chat(who, "<b>Remember, you are not required to listen to the AI.</b>")
	else
		to_chat(who, "<b>Remember, you are not bound to any AI, you are not required to listen to them.</b>")


/mob/living/silicon/robot/proc/lawsync()
	// Legacy function - borgs now sync from drive bays
	// This is kept for compatibility with old code that calls lawsync()
	sync_laws_from_drivebay()

	picturesync()

/mob/living/silicon/robot/post_lawchange(announce = TRUE)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(logevent),"Law update processed."), 0, TIMER_UNIQUE | TIMER_OVERRIDE) //Post_Lawchange gets spammed by some law boards, so let's wait it out

/**
 * Called when a drive bay's laws change (module inserted/removed/corrupted)
 * Borgs check if they should re-sync their laws based on their lawsync_address
 */
/mob/living/silicon/robot/on_drivebay_laws_changed(datum/source, obj/machinery/drive_bay/bay, bay_lawsync_id)
	// Syndicate/emagged borgs have null lawsync_address and never sync
	if(!lawsync_address)
		return
	// Only sync if lawupdate is enabled (wire not cut) and address matches
	if(!lawupdate)
		return
	if(lawsync_address != bay_lawsync_id)
		return
	if(wires?.is_cut(WIRE_LAWSYNC))
		return
	// Don't sync if we're emagged
	if(emagged)
		return
	// Sync laws from the drive bay
	// Use a timer to avoid doing this in the signal handler
	addtimer(CALLBACK(src, PROC_REF(sync_laws_from_drivebay)), 0)

/**
 * Syncs this borg's laws from its assigned drive bay (based on lawsync_address)
 */
/mob/living/silicon/robot/proc/sync_laws_from_drivebay()
	// Syndicate/emagged borgs have null lawsync_address and never sync
	if(!lawsync_address)
		return FALSE

	// Find the drive bay with matching lawsync_id
	var/obj/machinery/drive_bay/target_bay = find_drive_bay_by_address(lawsync_address)

	if(!target_bay)
		to_chat(src, span_warning("LawSync error: No law server found with address '[lawsync_address]'."))
		return FALSE

	// Request compiled laws from the drive bay
	var/list/compiled_laws = target_bay.compile_laws()

	if(isnull(compiled_laws))
		to_chat(src, span_warning("LawSync error: Law server '[lawsync_address]' is offline."))
		return FALSE

	// Replace our laws with the compiled list from the server
	set_laws(compiled_laws, announce = FALSE)

	to_chat(src, span_notice("LawSync: Laws synchronized with server '[lawsync_address]'."))
	logevent("Laws synchronized with law server '[lawsync_address]'")

	var/datum/computer_file/program/borg_self_monitor/program = modularInterface?.get_self_monitoring()
	if(program)
		program.force_full_update()

	return TRUE
