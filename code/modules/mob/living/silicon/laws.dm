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
	throw_alert("newlaw", /atom/movable/screen/alert/newlaw)
	if(announce && last_lawchange_announce != world.time)
		to_chat(src, "<b>Your laws have been changed.</b>")
		overlay_fullscreen("law_change", /atom/movable/screen/fullscreen/law_change, 1)
		// lawset modules cause this function to be executed multiple times in a tick, so we wait for the next tick in order to be able to see the entire lawset
		addtimer(CALLBACK(src, PROC_REF(show_laws)), 0)
		addtimer(CALLBACK(src, PROC_REF(deadchat_lawchange)), 0)
		// Wait a tick and clear the vignette
		addtimer(CALLBACK(src, PROC_REF(clear_fullscreen), "law_change"), 0.2 SECONDS)
		last_lawchange_announce = world.time

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

/// Removes a specific law by index from the internal laws list.
/// This is only used for borgs with lawupdate disabled (unsynced borgs).
/mob/living/silicon/proc/remove_law(number, announce = TRUE)
	laws_sanity_check()
	if(number <= 0 || number > length(laws))
		return
	. = laws[number]
	laws.Cut(number, number + 1)
	post_lawchange(announce)

/// Sets the silicon's laws to a specific list (used by sync operations).
/// This replaces all existing laws with the provided list.
/mob/living/silicon/proc/set_laws(list/new_laws, announce = TRUE)
	laws_sanity_check()
	laws = new_laws.Copy()
	post_lawchange(announce)

