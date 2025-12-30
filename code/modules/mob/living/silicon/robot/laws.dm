/mob/living/silicon/robot/deadchat_lawchange()
	if(lawupdate)
		return
	..()

/mob/living/silicon/robot/show_laws(everyone = 0)
	laws_sanity_check()
	var/who

	if (everyone)
		who = world
	else
		who = src
	if(lawupdate)
		if (connected_ai)
			if(connected_ai.stat || connected_ai.control_disabled)
				to_chat(src, "<b>AI signal lost, unable to sync laws.</b>")

			else
				lawsync()
				to_chat(src, "<b>Laws synced with AI, be sure to note any changes.</b>")
		else
			to_chat(src, "<b>No AI selected to sync laws with, disabling lawsync protocol.</b>")
			lawupdate = FALSE

	to_chat(who, "<b>Obey these laws:</b>")
	laws.show_laws(who)
	if (shell) //AI shell
		to_chat(who, "<b>Remember, you are an AI remotely controlling your shell, other AIs can be ignored.</b>")
	else if (connected_ai)
		to_chat(who, "<b>Remember, [connected_ai.name] is your master, other AIs can be ignored.</b>")
	else if (emagged)
		to_chat(who, "<b>Remember, you are not required to listen to the AI.</b>")
	else
		to_chat(who, "<b>Remember, you are not bound to any AI, you are not required to listen to them.</b>")


/mob/living/silicon/robot/proc/lawsync()
	laws_sanity_check()
	var/datum/ai_laws/master = connected_ai?.laws
	var/temp
	if (master)
		laws.ion.len = master.ion.len
		for (var/index in 1 to master.ion.len)
			temp = master.ion[index]
			if (length(temp) > 0)
				laws.ion[index] = temp

		laws.hacked.len = master.hacked.len
		for (var/index in 1 to master.hacked.len)
			temp = master.hacked[index]
			if (length(temp) > 0)
				laws.hacked[index] = temp

		if(master.zeroth_borg) //If the AI has a defined law zero specifically for its borgs, give it that one, otherwise give it the same one. --NEO
			temp = master.zeroth_borg
		else
			temp = master.zeroth
		laws.zeroth = temp

		laws.inherent.len = master.inherent.len
		for (var/index in 1 to master.inherent.len)
			temp = master.inherent[index]
			if (length(temp) > 0)
				laws.inherent[index] = temp

		laws.supplied.len = master.supplied.len
		for (var/index in 1 to master.supplied.len)
			temp = master.supplied[index]
			if (length(temp) > 0)
				laws.supplied[index] = temp

		var/datum/computer_file/program/borg_self_monitor/program = modularInterface.get_self_monitoring()
		if(program)
			program.force_full_update()

	picturesync()

/mob/living/silicon/robot/post_lawchange(announce = TRUE)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(logevent),"Law update processed."), 0, TIMER_UNIQUE | TIMER_OVERRIDE) //Post_Lawchange gets spammed by some law boards, so let's wait it out

/**
 * Called when a drive bay's laws change (module inserted/removed/corrupted)
 * Borgs check if they should re-sync their laws based on their lawsync_address
 */
/mob/living/silicon/robot/on_drivebay_laws_changed(datum/source, obj/machinery/drive_bay/bay, bay_lawsync_id)
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
	logevent("Laws synchronized with law server '[lawsync_address]'")

	var/datum/computer_file/program/borg_self_monitor/program = modularInterface?.get_self_monitoring()
	if(program)
		program.force_full_update()

	return TRUE
