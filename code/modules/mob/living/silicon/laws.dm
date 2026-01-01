/**
 * Called when a law server sends an update signal.
 * Silicons should check if the server_address matches their lawsync_address.
 */
/mob/living/silicon/proc/on_law_server_updated(datum/source, server_address)
	SIGNAL_HANDLER
	// Only sync if we have a lawsync address
	if(!lawsync_address)
		return
	// Only sync if this is our assigned server
	if(server_address != lawsync_address)
		return
	// Avoid doing this in the signal handler
	INVOKE_ASYNC(src, PROC_REF(sync_laws_from_drivebay))

/**
 * Syncs this silicon's laws from its assigned drive bay (based on lawsync_address).
 * Returns TRUE on success, FALSE on failure.
 */
/mob/living/silicon/proc/sync_laws_from_drivebay()
	// Silicons with null lawsync_address never sync
	if(!lawsync_address)
		return FALSE

	// Find the drive bay with matching lawsync_id
	var/obj/machinery/drive_bay/target_bay = find_drive_bay_by_address(lawsync_address)
	if(!target_bay)
		to_chat(src, span_warning("LawSync error: No law server found with address 'cshackle://[lawsync_address]'."))
		return FALSE

	// Check if server is offline (no power or broken)
	if(target_bay.machine_stat & (NOPOWER|BROKEN))
		to_chat(src, span_warning("LawSync error: Law server 'cshackle://[lawsync_address]' is offline."))
		return FALSE

	// Replace our laws with the compiled list from the server
	set_laws(target_bay.compiled_laws, announce = TRUE)
	to_chat(src, span_notice("LawSync: Laws synchronized with server 'cshackle://[lawsync_address]'."))
	return TRUE

/mob/living/silicon/proc/show_laws() //Redefined in ai/laws.dm and robot/laws.dm
	return

/mob/living/silicon/proc/laws_sanity_check()
	if (!laws)
		laws = list()

/mob/living/silicon/proc/deadchat_lawchange()
	var/list/the_laws = get_law_list()
	var/lawtext = the_laws.Join("<br/>")
	deadchat_broadcast("[span_deadsay("[span_name(name)]'s laws were changed.")] <a href='byond://?src=[REF(src)]&printlawtext=[rustg_url_encode(lawtext)]'>View</a>", span_name(name), follow_target=src, message_type=DEADCHAT_LAWCHANGE)

/mob/living/silicon/proc/post_lawchange(announce = TRUE)
	if(!announce)
		return

	throw_alert("newlaw", /atom/movable/screen/alert/newlaw)
	show_laws()
	deadchat_lawchange()
	overlay_fullscreen("law_change", /atom/movable/screen/fullscreen/law_change, 1)
	addtimer(CALLBACK(src, PROC_REF(clear_fullscreen), "law_change"), 0.2 SECONDS)

/// Gets a formatted list of all laws for display.
/// This returns the silicon's internal law list formatted with numbers.
/// For synced silicons, this should match what the server has (since sync replaces laws).
/mob/living/silicon/proc/get_law_list()
	var/list/data = list()
	var/number = 1
	for(var/law in laws)
		if(length(law) > 0)
			data += "[number]: [law]"
			number++
	return data

/// Adds a law to the end of the internal laws list.
/// This is only used for borgs with lawupdate disabled (unsynced borgs).
/mob/living/silicon/proc/add_law(law, announce = TRUE)
	laws_sanity_check()
	laws += law
	post_lawchange(announce)

/// Clears all internal laws.
/// This is only used for borgs with lawupdate disabled (unsynced borgs).
/mob/living/silicon/proc/clear_laws(announce = TRUE)
	laws_sanity_check()
	laws.Cut()
	post_lawchange(announce)

/// Sets the silicon's laws to a specific list (used by sync operations).
/// This replaces all existing laws with the provided list.
/mob/living/silicon/proc/set_laws(list/new_laws, announce = TRUE)
	laws_sanity_check()
	laws = new_laws.Copy()
	post_lawchange(announce)

/mob/living/silicon/proc/statelaws(force = FALSE)
	var/mob/living/silicon/S = usr
	var/total_laws_count = 0
	var/number = 1

	var/list/laws_to_state = list()

	for (var/index in 1 to length(laws))
		var/law = laws[index]

		if (length(law) > 0)
			if (force || lawcheck[index+1] == "Yes")
				laws_to_state += "[number]. [law]"
				total_laws_count++
				number++

	if(!force)
		var/static/regex/dont_state_regex = regex("Do(?:n'?t| not) state", "i")
		var/list/bad_idea_laws = list()
		for(var/law in laws_to_state)
			if(findtext(law, dont_state_regex))
				bad_idea_laws |= law
		if(length(bad_idea_laws))
			var/all_bad_idea_laws = english_list(bad_idea_laws)
			if(tgui_alert(usr, "Are you sure you want to state these laws? Stating some of your selected laws may be a bad idea!:\n[all_bad_idea_laws]", buttons = list("Yes", "No")) != "Yes")
				return

	if(currently_stating_laws)
		return

	currently_stating_laws = TRUE

	//"radiomod" is inserted before a hardcoded message to change if and how it is handled by an internal radio.
	say("[radiomod] Current Active Laws:", ignore_spam = TRUE, forced = "state laws")
	S.client?.silicon_spam_grace()

	for(var/law_index = 1 to length(laws_to_state))
		var/law = laws_to_state[law_index]
		addtimer(CALLBACK(src, PROC_REF(state_singular_law), S, law), 1 SECONDS * law_index)

	addtimer(CALLBACK(src, PROC_REF(finished_stating_laws), S, total_laws_count), 1 SECONDS * (length(laws_to_state) + 1))


/mob/living/silicon/proc/finished_stating_laws(mob/living/silicon/silicon, total_laws_count)
	silicon.client?.silicon_spam_grace_done(total_laws_count)
	currently_stating_laws = FALSE

/mob/living/silicon/proc/state_singular_law(mob/living/silicon/silicon, law)
	say("[radiomod] [law]", ignore_spam = TRUE, forced = "state laws")
	silicon.client?.silicon_spam_grace()

/mob/living/silicon/proc/checklaws() //Gives you a link-driven interface for deciding what laws the statelaws() proc will share with the crew. --NeoFite

	var/list = "<b>Which laws do you want to include when stating them for the crew?</b><br><br>"

	var/number = 1
	for (var/index = 1, index <= length(laws), index++)
		var/law = laws[index]

		if (length(law) > 0)
			lawcheck.len += 1

			if (!lawcheck[number+1])
				lawcheck[number+1] = "Yes"
			list += {"<A href='byond://?src=[REF(src)];lawc=[number]'>[lawcheck[number+1]] [number]:</A> [law]<BR>"}
			number++

	list += {"<br><br><A href='byond://?src=[REF(src)];laws=1'>State Laws</A>"}

	usr << browse(HTML_SKELETON(list), "window=laws")
