
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
				R.sync_laws_from_drivebay()
				R.show_laws()
