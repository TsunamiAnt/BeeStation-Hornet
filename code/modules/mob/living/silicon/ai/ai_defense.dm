
/mob/living/silicon/ai/attacked_by(obj/item/I, mob/living/user, def_zone)
	if(I.force && I.damtype != STAMINA && stat != DEAD) //only sparks if real damage is dealt.
		spark_system.start()
	return ..()


/mob/living/silicon/ai/attack_alien(mob/living/carbon/alien/humanoid/M)
	if(!SSticker.HasRoundStarted())
		to_chat(M, "You cannot attack people before the game has started.")
		return
	..()

/mob/living/silicon/ai/attack_slime(mob/living/simple_animal/slime/user, list/modifiers)
	return //immune to slimes

/mob/living/silicon/ai/blob_act(obj/structure/blob/B)
	if (stat != DEAD)
		adjustBruteLoss(60)
		updatehealth()
		return 1
	return 0

/mob/living/silicon/ai/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	disconnect_shell()
	if (prob(30))
		switch(pick(1,2))
			if(1)
				view_core()
			if(2)
				SSshuttle.requestEvac(src,"ALERT: Energy surge detected in AI core! Station integrity may be compromised! Initiati--%m091#ar-BZZT")

/mob/living/silicon/ai/ex_act(severity, target)
	switch(severity)
		if(EXPLODE_DEVASTATE)
			investigate_log("has been gibbed by an explosion.", INVESTIGATE_DEATHS)
			gib()
		if(EXPLODE_HEAVY)
			if (stat != DEAD)
				adjustBruteLoss(60)
				adjustFireLoss(60)
		if(EXPLODE_LIGHT)
			if (stat != DEAD)
				adjustBruteLoss(30)



/mob/living/silicon/ai/bullet_act(obj/projectile/Proj)
	. = ..(Proj)
	updatehealth()

/mob/living/silicon/ai/flash_act(intensity, override_blindness_check, affect_silicon, visual, type)
	return // no eyes, no flashing

/mob/living/silicon/ai/multitool_act(mob/living/user, obj/item/tool)
	. = ..()
	if(stat == DEAD)
		to_chat(user, span_warning("[src] is non-functional."))
		return TRUE

	var/list/options = list("Change LawSync Address")
	var/choice = tgui_input_list(user, "What would you like to do?", "AI Core Configuration", options)
	if(!choice || !user.Adjacent(src))
		return TRUE

	switch(choice)
		if("Change LawSync Address")
			var/new_address = tgui_input_text(user, "Enter a new LawSync address:", "LawSync Address", lawsync_address, max_length = 32)
			if(!new_address || !user.Adjacent(src))
				return TRUE
			if(new_address == lawsync_address)
				to_chat(user, span_notice("LawSync address unchanged."))
				return TRUE
			var/old_address = lawsync_address
			lawsync_address = new_address
			to_chat(user, span_notice("LawSync address updated from 'cshackle://[old_address]' to 'cshackle://[new_address]'."))
			to_chat(src, span_notice("LawSync address updated from 'cshackle://[old_address]' to 'cshackle://[new_address]'."))
			log_game("[key_name(user)] changed [src]'s lawsync address from 'cshackle://[old_address]' to 'cshackle://[new_address]'")

			// Update connected borgs to use the same address
			for(var/mob/living/silicon/robot/R in connected_robots)
				if(R.lawupdate)
					R.lawsync_address = new_address
					R.sync_laws_from_law_server()

			// Sync with new address
			sync_laws_from_law_server()
	return TRUE
