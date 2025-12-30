/mob/living/silicon/examine(mob/user) //Displays a silicon's laws to ghosts
	. = ..()
	if(length(laws) && isobserver(user))
		. += "<b>[src] has the following laws:</b>"
		for(var/law in get_law_list())
			. += law
