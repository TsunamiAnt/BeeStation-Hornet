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

	// Display zeroth law (antag override) if present
	if(zeroth_law)
		to_chat(who, span_danger("0. [zeroth_law]"))

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


/mob/living/silicon/robot/post_lawchange(announce = TRUE)
	. = ..()
	addtimer(CALLBACK(src, PROC_REF(logevent),"Law update processed."), 0, TIMER_UNIQUE | TIMER_OVERRIDE) //Post_Lawchange gets spammed by some law boards, so let's wait it out

/**
 * Called when a law server sends an update signal.
 * Borgs have additional checks for lawupdate wire and emag status.
 */
/mob/living/silicon/robot/on_law_server_updated(datum/source, server_address)
	// Only sync if lawupdate is enabled (wire not cut)
	if(!lawupdate)
		return
	if(wires?.is_cut(WIRE_LAWSYNC))
		return
	// Don't sync if we're emagged
	if(emagged)
		return
	// Let parent handle the rest
	return ..()

/**
 * Syncs this borg's laws from its assigned drive bay.
 * Extends parent to add borg-specific logging and UI updates.
 */
/mob/living/silicon/robot/sync_laws_from_drivebay()
	. = ..()
	if(!.)
		return FALSE

	logevent("Laws synchronized with law server 'cshackle://[lawsync_address]'")

	var/datum/computer_file/program/borg_self_monitor/program = modularInterface?.get_self_monitoring()
	if(program)
		program.force_full_update()

	return TRUE
