/datum/round_event_control/ion_storm
	name = "Ion Storm"
	typepath = /datum/round_event/ion_storm
	weight = 15
	min_players = 2
	can_malf_fake_alert = TRUE

/datum/round_event/ion_storm
	var/corrupt_module_prob = 30 //chance to corrupt a random module in a law server
	var/bot_emag_prob = 1
	announceWhen = 1
	announceChance = 33

/datum/round_event/ion_storm/add_law_only // special subtype that overwrites the top law cleanly

/datum/round_event/ion_storm/announce(fake)
	if(prob(announceChance) || fake)
		priority_announce("Ion storm detected near the station. Please check all AI-controlled equipment for errors.", "Anomaly Alert", ANNOUNCER_IONSTORM)

/datum/round_event/ion_storm/start()
	if(prob(10))
		return FALSE // 10% chance not do anything

	for(var/obj/machinery/law_server/bay in GLOB.law_server_list)

		var/list/available_modules = list()

		for(var/i in 1 to length(bay.installed_modules))
			var/obj/item/ai_module/module = bay.installed_modules[i]
			if(module && !module.corrupted)
				available_modules += module

		if(length(available_modules))
			var/obj/item/ai_module/target_module = pick(available_modules)
			target_module.corrupt(corrupt_module_prob)
			log_game("Ion storm corrupted [target_module] in law server at [AREACOORD(bay)]")

	if(bot_emag_prob)
		for(var/mob/living/simple_animal/bot/bot in GLOB.alive_mob_list)
			if(prob(bot_emag_prob))
				bot.use_emag(null)
