///Adds the mob reference to the list and directory of all mobs. Called on Initialize().
/mob/proc/add_to_mob_list()
	GLOB.mob_list |= src
	GLOB.mob_directory[tag] = src

///Removes the mob reference from the list and directory of all mobs. Called on Destroy().
/mob/proc/remove_from_mob_list()
	GLOB.mob_list -= src
	GLOB.mob_directory -= tag

///Adds the mob reference to the list of all mobs alive. If mob is cliented, it adds it to the list of all living player-mobs.
/mob/proc/add_to_alive_mob_list()
	if(QDELETED(src))
		return
	GLOB.alive_mob_list |= src
	if(client)
		add_to_current_living_players()

///Removes the mob reference from the list of all mobs alive. If mob is cliented, it removes it from the list of all living player-mobs.
/mob/proc/remove_from_alive_mob_list()
	GLOB.alive_mob_list -= src
	if(client)
		remove_from_current_living_players()

///Adds a mob reference to the list of all suicided mobs
/mob/proc/add_to_mob_suicide_list()
	GLOB.suicided_mob_list += src

///Removes a mob references from the list of all suicided mobs
/mob/proc/remove_from_mob_suicide_list()
	GLOB.suicided_mob_list -= src

///Removes a mob references from the list of external logout mobs
/mob/proc/remove_from_disconnected_mob_list()
	var/saved_key = null
	for(var/ckey in GLOB.disconnected_mobs)
		if(GLOB.disconnected_mobs[ckey] == src)
			saved_key = ckey
			break
	if(!isnull(saved_key))
		GLOB.disconnected_mobs -= saved_key

///Adds the mob reference to the list of all the dead mobs. If mob is cliented, it adds it to the list of all dead player-mobs.
/mob/proc/add_to_dead_mob_list()
	if(QDELETED(src))
		return
	GLOB.dead_mob_list |= src
	if(client)
		add_to_current_dead_players()

///Remvoes the mob reference from list of all the dead mobs. If mob is cliented, it adds it to the list of all dead player-mobs.
/mob/proc/remove_from_dead_mob_list()
	GLOB.dead_mob_list -= src
	if(client)
		remove_from_current_dead_players()

///Adds the cliented mob reference to the list of all player-mobs, besides to either the of dead or alive player-mob lists, as appropriate. Called on Login().
/mob/proc/add_to_player_list()
	SHOULD_CALL_PARENT(TRUE)
	GLOB.player_list |= src

	if(stat == DEAD)
		add_to_current_dead_players()
	else
		add_to_current_living_players()

///Removes the mob reference from the list of all player-mobs, besides from either the of dead or alive player-mob lists, as appropriate. Called on Logout().
/mob/proc/remove_from_player_list()
	SHOULD_CALL_PARENT(TRUE)
	GLOB.player_list -= src

	if(stat == DEAD)
		remove_from_current_dead_players()
	else
		remove_from_current_living_players()


///Adds the cliented mob reference to either the list of dead player-mobs or to the list of observers, depending on how they joined the game.
/mob/proc/add_to_current_dead_players()
	SSdynamic.current_players[CURRENT_DEAD_PLAYERS] |= src

/mob/dead/observer/add_to_current_dead_players()
	if(started_as_observer)
		SSdynamic.current_players[CURRENT_OBSERVERS] |= src
		return
	return ..()

/mob/dead/new_player/add_to_current_dead_players()
	return

///Removes the mob reference from either the list of dead player-mobs or from the list of observers, depending on how they joined the game.
/mob/proc/remove_from_current_dead_players()
	SSdynamic.current_players[CURRENT_DEAD_PLAYERS] -= src

/mob/dead/observer/remove_from_current_dead_players()
	if(started_as_observer)
		SSdynamic.current_players[CURRENT_OBSERVERS] -= src
		return
	return ..()


///Adds the cliented mob reference to the list of living player-mobs. If the mob is an antag, it adds it to the list of living antag player-mobs.
/mob/proc/add_to_current_living_players()
	SSdynamic.current_players[CURRENT_LIVING_PLAYERS] |= src
	if(length(mind?.antag_datums))
		add_to_current_living_antags()

///Removes the mob reference from the list of living player-mobs. If the mob is an antag, it removes it from the list of living antag player-mobs.
/mob/proc/remove_from_current_living_players()
	SSdynamic.current_players[CURRENT_LIVING_PLAYERS] -= src
	if(LAZYLEN(mind?.antag_datums))
		remove_from_current_living_antags()


///Adds the cliented mob reference to the list of living antag player-mobs.
/mob/proc/add_to_current_living_antags()
	if (!length(mind.antag_datums))
		return
	SSdynamic.current_players[CURRENT_LIVING_ANTAGS] |= src

///Removes the mob reference from the list of living antag player-mobs.
/mob/proc/remove_from_current_living_antags()
	if(!SSticker.HasRoundStarted())
		return
	SSdynamic.current_players[CURRENT_LIVING_ANTAGS] -= src
