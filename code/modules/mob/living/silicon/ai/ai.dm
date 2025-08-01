#define CALL_BOT_COOLDOWN 900

//Not sure why this is necessary...
/proc/AutoUpdateAI(obj/subject)
	var/is_in_use = 0
	if (subject!=null)
		for(var/mob/living/silicon/ai/M in GLOB.ai_list)
			if ((M.client && M.machine == subject))
				is_in_use = 1
				subject.attack_ai(M)
	return is_in_use

/mob/living/silicon/ai
	name = JOB_NAME_AI
	real_name = JOB_NAME_AI
	icon = 'icons/mob/ai.dmi'
	icon_state = "ai"
	move_resist = MOVE_FORCE_VERY_STRONG
	density = TRUE
	status_flags = CANSTUN|CANPUSH
	combat_mode = TRUE //so we always get pushed instead of trying to swap
	sight = SEE_TURFS | SEE_MOBS | SEE_OBJS
	see_in_dark = NIGHTVISION_FOV_RANGE
	hud_type = /datum/hud/ai
	med_hud = DATA_HUD_MEDICAL_BASIC
	sec_hud = DATA_HUD_SECURITY_BASIC
	d_hud = DATA_HUD_DIAGNOSTIC_ADVANCED
	mob_size = MOB_SIZE_LARGE
	radio = /obj/item/radio/headset/silicon/ai
	can_buckle_to = FALSE
	var/battery = 200 //emergency power if the AI's APC is off
	var/list/network = list(CAMERA_NETWORK_STATION)
	var/list/connected_robots = list()

	/// Station alert datum for showing alerts UI
	var/datum/station_alert/alert_control

	var/aiRestorePowerRoutine = POWER_RESTORATION_OFF
	var/requires_power = POWER_REQ_ALL
	var/can_be_carded = TRUE
	var/icon/holo_icon //Default is assigned when AI is created.
	var/obj/vehicle/sealed/mecha/controlled_mech //For controlled_mech a mech, to determine whether to relaymove or use the AI eye.
	var/radio_enabled = TRUE //Determins if a carded AI can speak with its built in radio or not.
	radiomod = ";" //AIs will, by default, state their laws on the internal radio.
	var/obj/item/multitool/aiMulti
	var/datum/weakref/bot_ref
	var/mob/living/ai_tracking_target = null //current tracking target
	var/reacquire_timer = null //saves the timer id for the tracking reacquire so we can delete it/check for its existence
	var/datum/effect_system/spark_spread/spark_system //So they can initialize sparks whenever/N

	//MALFUNCTION
	var/datum/module_picker/malf_picker
	var/list/datum/ai_module/current_modules = list()
	var/can_dominate_mechs = FALSE
	var/shunted = FALSE //1 if the AI is currently shunted. Used to differentiate between shunted and ghosted/braindead
	var/obj/machinery/ai_voicechanger/ai_voicechanger = null // reference to machine that holds the voicechanger
	var/control_disabled = FALSE // Set to TRUE to stop AI from interacting via Click()
	var/malf_cooldown = 0 SECONDS //Cooldown var for malf modules, stores a worldtime + cooldown

	var/obj/machinery/power/apc/malfhack
	var/malfhacking = FALSE
	var/explosive = FALSE //does the AI explode when it dies?

	var/mob/living/silicon/ai/parent
	var/camera_light_on = FALSE
	var/list/obj/machinery/camera/lit_cameras = list()

	var/datum/trackable/track = new

	var/last_tablet_note_seen = null
	var/can_shunt = TRUE
	var/last_announcement = "" 		// For AI VOX, if enabled
	var/turf/waypoint //Holds the turf of the currently selected waypoint.
	var/waypoint_mode = FALSE		//Waypoint mode is for selecting a turf via clicking.
	var/call_bot_cooldown = 0		//time of next call bot command
	var/obj/machinery/power/apc/apc_override //Ref of the AI's APC, used when the AI has no power in order to access their APC.
	var/nuking = FALSE
	var/obj/machinery/doomsday_device/doomsday_device

	var/mob/camera/ai_eye/eyeobj
	var/sprint = 10
	var/cooldown = 0
	//Default value of camera acceleration
	var/acceleration = 0

	var/obj/structure/AIcore/deactivated/linked_core //For exosuit control
	var/mob/living/silicon/robot/deployed_shell = null //For shell control
	var/datum/action/innate/deploy_shell/deploy_action = new
	var/datum/action/innate/deploy_last_shell/redeploy_action = new
	var/datum/action/innate/choose_modules/modules_action
	var/chnotify = 0

	var/multicam_on = FALSE
	var/atom/movable/screen/movable/pic_in_pic/ai/master_multicam
	var/list/multicam_screens = list()
	var/list/all_eyes = list()
	var/max_multicams = 6
	var/display_icon_override

	var/list/cam_hotkeys = new/list(9)

	var/datum/robot_control/robot_control

	var/cam_prev

	var/atom/movable/screen/ai/modpc/interfaceButton
	var/obj/effect/overlay/holo_pad_hologram/ai_hologram
	var/obj/machinery/holopad/current_holopad

CREATION_TEST_IGNORE_SUBTYPES(/mob/living/silicon/ai)

/mob/living/silicon/ai/Initialize(mapload, datum/ai_laws/L, mob/target_ai)
	default_access_list = get_all_accesses()
	. = ..()
	add_sensors()
	if(!target_ai) //If there is no player/brain inside.
		new/obj/structure/AIcore/deactivated(loc) //New empty terminal.
		return INITIALIZE_HINT_QDEL //Delete AI.

	if(L && istype(L, /datum/ai_laws))
		laws = L
		laws.associate(src)
	else
		make_laws()

	if(target_ai.mind)
		target_ai.mind.transfer_to(src)
		if(mind.special_role)
			mind.store_memory("As an AI, you must obey your silicon laws above all else. Your objectives will consider you to be dead.")
			to_chat(src, span_userdanger("You have been installed as an AI!"))
			to_chat(src, span_danger("You must obey your silicon laws above all else. Your objectives will consider you to be dead."))

	to_chat(src, span_bold("You are playing the station's AI. The AI cannot move, but can interact with many objects while viewing them (through cameras)."))
	to_chat(src, span_bold("To look at other parts of the station, click on yourself to get a camera menu."))
	to_chat(src, span_bold("While observing through a camera, you can use most (networked) devices which you can see, such as computers, APCs, intercoms, doors, etc."))
	to_chat(src, "To use something, simply click on it.")
	to_chat(src, "Use say :b to speak to your cyborgs through binary.")
	to_chat(src, "For department channels, use the following say commands:")
	to_chat(src, ":o - AI Private, :c - Command, :s - Security, :e - Engineering, :u - Supply, :v - Service, :m - Medical, :n - Science, :h - Holopad.") //typically, :h will always use a radios key and send speech to that departmental channel, for AI's it sends it to currently used holopad instead
	show_laws()
	to_chat(src, span_bold("These laws may be changed by other players, or by you being the traitor."))

	job = JOB_NAME_AI

	create_eye()

	create_modularInterface()

	if(client)
		INVOKE_ASYNC(src, PROC_REF(apply_pref_name), /datum/preference/name/ai, client)

	INVOKE_ASYNC(src, PROC_REF(set_core_display_icon))


	holo_icon = getHologramIcon(icon('icons/mob/ai.dmi',"default"))

	spark_system = new /datum/effect_system/spark_spread()
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)

	add_verb(/mob/living/silicon/ai/proc/show_laws_verb)

	aiMulti = new(src)
	aicamera = new/obj/item/camera/siliconcam/ai_camera(src)

	deploy_action.Grant(src)

	if(isturf(loc))
		add_verb(list(
			/mob/living/silicon/ai/proc/ai_hologram_change,
			/mob/living/silicon/ai/proc/botcall,
			/mob/living/silicon/ai/proc/control_integrated_radio,
			/mob/living/silicon/ai/proc/set_automatic_say_channel
		))

	GLOB.ai_list += src
	GLOB.shuttle_caller_list += src

	builtInCamera = new (src)
	builtInCamera.network = list()

	ADD_TRAIT(src, TRAIT_PULL_BLOCKED, ROUNDSTART_TRAIT)
	ADD_TRAIT(src, TRAIT_HANDS_BLOCKED, ROUNDSTART_TRAIT)

	alert_control = new(src, list(ALARM_ATMOS, ALARM_FIRE, ALARM_POWER, ALARM_CAMERA, ALARM_BURGLAR, ALARM_MOTION), list(z), camera_view = TRUE)
	RegisterSignal(alert_control.listener, COMSIG_ALARM_TRIGGERED, PROC_REF(alarm_triggered))
	RegisterSignal(alert_control.listener, COMSIG_ALARM_CLEARED, PROC_REF(alarm_cleared))

/mob/living/silicon/ai/key_down(_key, client/user)
	if(findtext(_key, "numpad")) //if it's a numpad number, we can convert it to just the number
		_key = _key[7] //strings, lists, same thing really
	switch(_key)
		if("`", "0")
			if(cam_prev)
				eyeobj.setLoc(cam_prev)
			return
		if("1", "2", "3", "4", "5", "6", "7", "8", "9")
			_key = text2num(_key)
			if(user.keys_held["Ctrl"]) //do we assign a new hotkey?
				cam_hotkeys[_key] = eyeobj.loc
				to_chat(src, "Location saved to Camera Group [_key].")
				return
			if(cam_hotkeys[_key]) //if this is false, no hotkey for this slot exists.
				cam_prev = eyeobj.loc
				eyeobj.setLoc(cam_hotkeys[_key])
				return
	return ..()

/mob/living/silicon/ai/Destroy()
	GLOB.ai_list -= src
	GLOB.shuttle_caller_list -= src
	SSshuttle.autoEvac()
	QDEL_NULL(eyeobj) // No AI, no Eye
	QDEL_NULL(spark_system)
	QDEL_NULL(malf_picker)
	QDEL_NULL(doomsday_device)
	QDEL_NULL(aiMulti)
	QDEL_NULL(alert_control)
	malfhack = null
	current_holopad = null
	//bot_ref = null
	//controlled_equipment = null
	linked_core = null
	apc_override = null
	ShutOffDoomsdayDevice()
	if(ai_voicechanger)
		ai_voicechanger.owner = null
		ai_voicechanger = null
	. = ..()

/mob/living/silicon/ai/proc/remove_malf_abilities()
	QDEL_NULL(modules_action)
	for(var/datum/ai_module/malf/AM in current_modules)
		for(var/datum/action/A in actions)
			if(istype(A, initial(AM.power_type)))
				qdel(A)

/mob/living/silicon/ai/IgniteMob()
	fire_stacks = 0
	. = ..()

/mob/living/silicon/ai/proc/set_core_display_icon(input, client/C)
	if(client && !C)
		C = client
	if(!input && !C?.prefs?.read_character_preference(/datum/preference/choiced/ai_core_display))
		icon_state = initial(icon_state)
	else
		var/preferred_icon = input ? input : C.prefs.read_character_preference(/datum/preference/choiced/ai_core_display)
		icon_state = resolve_ai_icon(preferred_icon)

/mob/living/silicon/ai/verb/pick_icon()
	set category = "AI Commands"
	set name = "Set AI Core Display"
	if(incapacitated())
		return
	icon = initial(icon)
	icon_state = "ai"
	cut_overlays()
	var/list/iconstates = GLOB.ai_core_display_screens
	for(var/option in iconstates)
		if(option == "Random")
			iconstates[option] = image(icon = src.icon, icon_state = "ai-random")
			continue
		if(option == "Portrait")
			iconstates[option] = image(icon = src.icon, icon_state = "ai-portrait")
			continue
		iconstates[option] = image(icon = src.icon, icon_state = resolve_ai_icon(option))

	view_core()
	var/ai_core_icon = show_radial_menu(src, src , iconstates, radius = 42)

	if(!ai_core_icon || incapacitated())
		return

	display_icon_override = ai_core_icon
	set_core_display_icon(ai_core_icon)

/mob/living/silicon/ai/get_stat_tab_status()
	var/list/tab_data = ..()
	if(!stat)
		tab_data["System integrity"] = GENERATE_STAT_TEXT("[(health+100)/2]%")
		if(isturf(loc)) //only show if we're "in" a core
			tab_data["Backup Power"] = GENERATE_STAT_TEXT("[battery/2]%")
		tab_data["Connected cyborgs"] = GENERATE_STAT_TEXT("[connected_robots.len]")
		var/index = 0
		for(var/mob/living/silicon/robot/R in connected_robots)
			var/robot_status = "Nominal"
			if(R.shell)
				robot_status = "AI SHELL"
			else if(R.stat || !R.client)
				robot_status = "OFFLINE"
			else if(!R.cell || R.cell.charge <= 0)
				robot_status = "DEPOWERED"
			//Name, Health, Battery, Model, Area, and Status! Everything an AI wants to know about its borgies!
			index++
			tab_data["[R.name] (Connection [index])"] = list(
				text="S.Integrity: [R.health]% | Cell: [R.cell ? "[R.cell.charge]/[R.cell.maxcharge]" : "Empty"] | \
					Model: [R.designation] | Loc: [get_area_name(R, TRUE)] | Status: [robot_status]", type = STAT_TEXT)
		tab_data["AI shell beacons detected"] = GENERATE_STAT_TEXT("[LAZYLEN(GLOB.available_ai_shells)]") //Count of total AI shells
	else
		tab_data["Systems"] = GENERATE_STAT_TEXT("nonfunctional")
	return tab_data

/mob/living/silicon/ai/proc/ai_call_shuttle()
	if(control_disabled)
		to_chat(usr, span_warning("Wireless control is disabled!"))
		return

	var/can_evac_or_fail_reason = SSshuttle.canEvac(src)
	if(can_evac_or_fail_reason != TRUE)
		to_chat(usr, span_alert("[can_evac_or_fail_reason]"))
		return

	var/reason = input(src, "What is the nature of your emergency? ([CALL_SHUTTLE_REASON_LENGTH] characters required.)", "Confirm Shuttle Call") as null|text

	if(incapacitated())
		return

	if(trim(reason))
		SSshuttle.requestEvac(src, reason)

	// hack to display shuttle timer
	if(!EMERGENCY_IDLE_OR_RECALLED)
		var/obj/machinery/computer/communications/C = locate() in GLOB.machines
		if(C)
			C.post_status("shuttle")

/mob/living/silicon/ai/can_interact_with(atom/A)
	. = ..()
	var/turf/ai = get_turf(src)
	var/turf/target = get_turf(A)
	if (.)
		return

	if(!target)
		return

	if ((ai.get_virtual_z_level() != target.get_virtual_z_level()) && !is_station_level(ai.z))
		return FALSE

	if(A.is_jammed(JAMMER_PROTECTION_WIRELESS))
		return FALSE

	if (istype(loc, /obj/item/aicard))
		if (!ai || !target)
			return FALSE
		return ISINRANGE(target.x, ai.x - interaction_range, ai.x + interaction_range) && ISINRANGE(target.y, ai.y - interaction_range, ai.y + interaction_range)
	else
		return GLOB.cameranet.checkTurfVis(get_turf(A))

/mob/living/silicon/ai/cancel_camera()
	view_core()

/mob/living/silicon/ai/verb/wipe_core()
	set name = "Wipe Core"
	set category = "AI Commands"
	set desc = "Wipe your core. This is functionally equivalent to cryo, freeing up your job slot."

	if(stat)
		return

	// Guard against misclicks, this isn't the sort of thing we want happening accidentally
	if(alert("WARNING: This will immediately wipe your core and ghost you, removing your character from the round permanently (similar to cryo, so you should ahelp before doing so). Are you entirely sure you want to do this?",
					"Wipe Core", "No", "No", "Yes") != "Yes")
		return

	// We warned you.
	var/obj/structure/AIcore/latejoin_inactive/inactivecore = new(loc)
	transfer_fingerprints_to(inactivecore)

	if(GLOB.announcement_systems.len)
		var/obj/machinery/announcement_system/announcer = pick(GLOB.announcement_systems)
		announcer.announce("AIWIPE", real_name, mind.assigned_role, list())

	SSjob.FreeRole(mind.assigned_role)

	if(!get_ghost(1))
		if(world.time < 30 * 600)//before the 30 minute mark
			ghostize(FALSE,SENTIENCE_ERASE) // Players despawned too early may not re-enter the game
	else
		ghostize(TRUE,SENTIENCE_ERASE)

	SEND_SIGNAL(mind, COMSIG_MIND_CRYOED)
	QDEL_NULL(src)

/mob/living/silicon/ai/verb/toggle_anchor()
	set category = "AI Commands"
	set name = "Toggle Floor Bolts"
	if(!isturf(loc)) // if their location isn't a turf
		return // stop
	if(stat)
		return
	if(incapacitated())
		if(battery < 50)
			to_chat(src, span_warning("Insufficient backup power!"))
			return
		battery = battery - 50
		to_chat(src, span_notice("You route power from your backup battery to move the bolts."))
	var/is_anchored = FALSE
	if(move_resist == MOVE_FORCE_VERY_STRONG)
		move_resist = MOVE_FORCE_NORMAL
	else
		is_anchored = TRUE
		move_resist = MOVE_FORCE_VERY_STRONG

	to_chat(src, "<b>You are now [is_anchored ? "" : "un"]anchored.</b>")
	// the message in the [] will change depending whether or not the AI is anchored

/mob/living/silicon/ai/cancel_camera()
	..()
	if(ai_tracking_target)
		ai_stop_tracking()

/mob/living/silicon/ai/proc/ai_cancel_call()
	set category = "Malfunction"
	if(control_disabled)
		to_chat(src, span_warning("Wireless control is disabled!"))
		return
	SSshuttle.cancelEvac(src)

/mob/living/silicon/ai/Topic(href, href_list)
	..()
	if(usr != src)
		return

	if(href_list["emergencyAPC"]) //This check comes before incapacitated() because the only time it would be useful is when we have no power.
		if(!apc_override)
			to_chat(src, span_notice("APC backdoor is no longer available."))
			return
		apc_override.ui_interact(src)
		return

	if(incapacitated())
		return

	if (href_list["mach_close"])
		var/t1 = "window=[href_list["mach_close"]]"
		unset_machine()
		src << browse(null, t1)
	if (href_list["switchcamera"])
		switchCamera(locate(href_list["switchcamera"]) in GLOB.cameranet.cameras)
	if (href_list["showalerts"])
		alert_control.ui_interact(src)
#ifdef AI_VOX
	if(href_list["say_word"])
		play_vox_word(href_list["say_word"], null, src)
		return
#endif
	if(href_list["show_tablet_note"])
		if(last_tablet_note_seen)
			src << browse(last_tablet_note_seen, "window=show_tablet")
	//Carn: holopad requests
	if(href_list["jumptoholopad"])
		var/obj/machinery/holopad/H = locate(href_list["jumptoholopad"]) in GLOB.machines
		if(H)
			H.attack_ai(src) //may as well recycle
		else
			to_chat(src, span_notice("Unable to locate the holopad."))
	if(href_list["track"])
		var/string = href_list["track"]
		trackable_mobs()
		var/list/trackeable = list()
		trackeable += track.humans + track.others
		var/list/target = list()
		for(var/I in trackeable)
			var/datum/weakref/to_resolve = trackeable[I]
			var/mob/to_track = to_resolve.resolve()
			if(!to_track || to_track.name != string)
				continue
			target += to_track
		if(name == string)
			target += src
		if(target.len)
			attempt_track(pick(target))
		else
			to_chat(src, "Target is not on or near any active cameras on the station.")
		return
	if (href_list["ai_take_control"]) //Mech domination
		var/obj/vehicle/sealed/mecha/M = locate(href_list["ai_take_control"]) in GLOB.mechas_list
		if (!M)
			return

		var/mech_has_controlbeacon = FALSE
		for(var/obj/item/mecha_parts/mecha_tracking/ai_control/A in M.trackers)
			mech_has_controlbeacon = TRUE
			break
		if(!can_dominate_mechs && !mech_has_controlbeacon)
			message_admins("Warning: possible href exploit by [key_name(usr)] - attempted control of a mecha without can_dominate_mechs or a control beacon in the mech.")
			log_game("Warning: possible href exploit by [key_name(usr)] - attempted control of a mecha without can_dominate_mechs or a control beacon in the mech.")
			return

		if(controlled_mech)
			to_chat(src, span_warning("You are already loaded into an onboard computer!"))
			return
		if(!GLOB.cameranet.checkCameraVis(M))
			to_chat(src, span_warning("Exosuit is no longer near active cameras."))
			return
		if(!isturf(loc))
			to_chat(src, span_warning("You aren't in your core!"))
			return
		if(M)
			M.transfer_ai(AI_MECH_HACK, src, usr) //Called om the mech itself.
	if(href_list["show_paper_note"])
		var/obj/item/paper/paper_note = locate(href_list["show_paper_note"])
		if(!paper_note)
			return

		paper_note.show_through_camera(usr)

/mob/living/silicon/ai/proc/switchCamera(obj/machinery/camera/C)
	if(QDELETED(C))
		return FALSE

	if(ai_tracking_target)
		ai_stop_tracking()

	if(QDELETED(eyeobj))
		view_core()
		return
	// ok, we're alive, camera is good and in our network...
	eyeobj.setLoc(get_turf(C))
	return TRUE

/mob/living/silicon/ai/proc/botcall()
	set category = "AI Commands"
	set name = "Access Robot Control"
	set desc = "Wirelessly control various automatic robots."

	if(!robot_control)
		robot_control = new(src)

	robot_control.ui_interact(src)

/mob/living/silicon/ai/proc/set_waypoint(atom/A)
	var/turf/turf_check = get_turf(A)
		//The target must be in view of a camera or near the core.
	if(turf_check in range(get_turf(src)))
		call_bot(turf_check)
	else if(GLOB.cameranet && GLOB.cameranet.checkTurfVis(turf_check))
		call_bot(turf_check)
	else
		to_chat(src, span_danger("Selected location is not visible."))

/mob/living/silicon/ai/proc/call_bot(turf/waypoint)
	var/mob/living/simple_animal/bot/bot = bot_ref?.resolve()
	if(!bot)
		return

	if(bot.calling_ai && bot.calling_ai != src) //Prevents an override if another AI is controlling this bot.
		to_chat(src, span_danger("Interface error. Unit is already in use."))
		return
	to_chat(src, span_notice("Sending command to bot..."))
	call_bot_cooldown = world.time + CALL_BOT_COOLDOWN
	bot.call_bot(src, waypoint)
	call_bot_cooldown = 0

/mob/living/silicon/ai/proc/alarm_triggered(datum/source, alarm_type, area/source_area)
	SIGNAL_HANDLER
	var/list/cameras = source_area.cameras
	var/home_name = source_area.name

	if (length(cameras))
		var/obj/machinery/camera/cam = cameras[1]
		if (cam.can_use())
			queueAlarm("--- [alarm_type] alarm detected in [home_name]! (<a href='byond://?src=[REF(src)];switchcamera=[REF(cam)]'>[cam.c_tag]</a>)", alarm_type)
		else
			var/first_run = FALSE
			var/dat2 = ""
			for (var/obj/machinery/camera/camera as anything in cameras)
				dat2 += "[(!first_run) ? "" : " | "]<a href='byond://?src=[REF(src)];switchcamera=[REF(camera)]'>[camera.c_tag]</a>"
				first_run = TRUE
			queueAlarm("--- [alarm_type] alarm detected in [home_name]! ([dat2])", alarm_type)
	else
		queueAlarm("--- [alarm_type] alarm detected in [home_name]! (No Camera)", alarm_type)
	return 1

/mob/living/silicon/ai/proc/alarm_cleared(datum/source, alarm_type, area/source_area)
	SIGNAL_HANDLER
	queueAlarm("--- [alarm_type] alarm in [source_area.name] has been cleared.", alarm_type, 0)

//I am the icon meister. Bow fefore me.	//>fefore
/mob/living/silicon/ai/proc/ai_hologram_change()
	set name = "Change Hologram"
	set desc = "Change the default hologram available to AI to something else."
	set category = "AI Commands"

	if(incapacitated())
		return
	var/mob/user = src
	var/input
	var/list/hologram_choice = list("Crew Member","Unique","Animal")
	switch(tgui_alert(user, "Would you like to select a hologram based on a crew member, an animal, or switch to a unique avatar?", "Choices", hologram_choice))
		if("Crew Member")
			var/list/personnel_list = list()

			for(var/datum/record/locked/record in GLOB.manifest.locked)//Look in data core locked.
				personnel_list["[record.name]: [record.rank]"] = record.character_appearance//Pull names, rank, and image.

			if(!length(personnel_list))
				alert("No suitable records found. Aborting.")
				return
			if(length(personnel_list))
				input = tgui_input_list(user, "Select a crew member", "AI Hologram Selection", sort_list(personnel_list))
				var/mutable_appearance/character_icon = personnel_list[input]
				if(character_icon)
					qdel(holo_icon)//Clear old icon so we're not storing it in memory.
					character_icon.setDir(SOUTH)

					var/icon/icon_for_holo = getFlatIcon(character_icon)
					holo_icon = getHologramIcon(icon(icon_for_holo))

		if("Animal")
			var/list/icon_list = list(
			"bear" = 'icons/mob/animal.dmi',
			"carp" = 'icons/mob/animal.dmi',
			"chicken" = 'icons/mob/animal.dmi',
			"corgi" = 'icons/mob/pets.dmi',
			"cow" = 'icons/mob/animal.dmi',
			"crab" = 'icons/mob/animal.dmi',
			"fox" = 'icons/mob/pets.dmi',
			"goat" = 'icons/mob/animal.dmi',
			"cat" = 'icons/mob/pets.dmi',
			"cat2" = 'icons/mob/pets.dmi',
			"poly" = 'icons/mob/animal.dmi',
			"pug" = 'icons/mob/pets.dmi',
			"spider" = 'icons/mob/animal.dmi'
			)

			input = tgui_input_list(user, "Please select a hologram:", "Animal Choice", sort_list(icon_list))
			if(input)
				qdel(holo_icon)
				switch(input)
					if("poly")
						holo_icon = getHologramIcon(icon(icon_list[input],"parrot_fly"))
					if("chicken")
						holo_icon = getHologramIcon(icon(icon_list[input],"chicken_brown"))
					if("spider")
						holo_icon = getHologramIcon(icon(icon_list[input],"guard"))
					else
						holo_icon = getHologramIcon(icon(icon_list[input], input))
		else
			var/list/icon_list = list(
				"default" = 'icons/mob/ai.dmi',
				"floating face" = 'icons/mob/ai.dmi',
				"xeno queen" = 'icons/mob/alien.dmi',
				"horror" = 'icons/mob/ai.dmi'
				)

			input = tgui_input_list(user, "Please select a hologram", "Hologram Choice", sort_list(icon_list))
			if(input)
				qdel(holo_icon)
				switch(input)
					if("xeno queen")
						holo_icon = getHologramIcon(icon(icon_list[input],"alienq"))
					else
						holo_icon = getHologramIcon(icon(icon_list[input], input))
	return

/mob/living/silicon/ai/proc/corereturn()
	set category = "Malfunction"
	set name = "Return to Main Core"

	var/obj/machinery/power/apc/apc = src.loc
	if(!istype(apc))
		to_chat(src, span_notice("You are already in your Main Core."))
		return
	apc.malfvacate()

/mob/living/silicon/ai/proc/toggle_camera_light()
	camera_light_on = !camera_light_on

	if (!camera_light_on)
		to_chat(src, "Camera lights deactivated.")

		for (var/obj/machinery/camera/C in lit_cameras)
			C.set_light(0)
			lit_cameras = list()

		return

	light_cameras()

	to_chat(src, "Camera lights activated.")

//AI_CAMERA_LUMINOSITY

/mob/living/silicon/ai/proc/light_cameras()
	var/list/obj/machinery/camera/add = list()
	var/list/obj/machinery/camera/remove = list()
	var/list/obj/machinery/camera/visible = list()
	for (var/datum/camerachunk/CC in eyeobj.visibleCameraChunks)
		for (var/obj/machinery/camera/C in CC.cameras)
			if (!C.can_use() || get_dist(C, eyeobj) > 7 || !C.internal_light)
				continue
			visible |= C

	add = visible - lit_cameras
	remove = lit_cameras - visible

	for (var/obj/machinery/camera/C in remove)
		lit_cameras -= C //Removed from list before turning off the light so that it doesn't check the AI looking away.
		C.Togglelight(0)
	for (var/obj/machinery/camera/C in add)
		C.Togglelight(1)
		lit_cameras |= C

/mob/living/silicon/ai/proc/control_integrated_radio()
	set name = "Transceiver Settings"
	set desc = "Allows you to change settings of your radio."
	set category = "AI Commands"

	if(incapacitated())
		return

	to_chat(src, "Accessing Subspace Transceiver control...")
	if (radio)
		radio.interact(src)

/mob/living/silicon/ai/proc/set_syndie_radio()
	if(radio)
		radio.make_syndie()

/mob/living/silicon/ai/proc/set_automatic_say_channel()
	set name = "Set Auto Announce Mode"
	set desc = "Modify the default radio setting for your automatic announcements."
	set category = "AI Commands"

	if(incapacitated())
		return
	set_autosay()

/mob/living/silicon/ai/transfer_ai(interaction, mob/user, mob/living/silicon/ai/AI, obj/item/aicard/card)
	if(!..())
		return
	if(interaction == AI_TRANS_TO_CARD)//The only possible interaction. Upload AI mob to a card.
		if(!can_be_carded)
			to_chat(user, span_boldwarning("Transfer failed."))
			return
		disconnect_shell() //If the AI is controlling a borg, force the player back to core!
		if(!mind)
			to_chat(user, span_warning("No intelligence patterns detected.")    )
			return
		ShutOffDoomsdayDevice()
		var/obj/structure/AIcore/new_core = new /obj/structure/AIcore/deactivated(loc)//Spawns a deactivated terminal at AI location.
		new_core.circuit.battery = battery
		ai_restore_power()//So the AI initially has power.
		control_disabled = TRUE //Can't control things remotely if you're stuck in a card!
		radio_enabled = FALSE 	//No talking on the built-in radio for you either!
		forceMove(card)
		card.AI = src
		to_chat(src, "You have been downloaded to a mobile storage device. Remote device connection severed.")
		to_chat(user, "[span_boldnotice("Transfer successful")]: [name] ([rand(1000,9999)].exe) removed from host terminal and stored within local memory.")


/mob/living/silicon/ai/canUseTopic(atom/movable/M, be_close=FALSE, no_dexterity=FALSE, no_tk=FALSE, need_hands = FALSE, floor_okay=FALSE)
	if(control_disabled)
		to_chat(src, span_warning("You can't do that right now!"))
		return FALSE
	return can_see(M) && ..() //stop AIs from leaving windows open and using then after they lose vision

/mob/living/silicon/ai/proc/can_see(atom/A)
	if(isturf(loc)) //AI in core, check if on cameras
		//get_turf_pixel() is because APCs in maint aren't actually in view of the inner camera
		//apc_override is needed here because AIs use their own APC when depowered
		return ((GLOB.cameranet && GLOB.cameranet.checkTurfVis(get_turf_pixel(A))) || (A == apc_override))
	//AI is carded/shunted
	//view(src) returns nothing for carded/shunted AIs and they have X-ray vision so just use get_dist
	var/list/viewscale = getviewsize(client.view)
	return get_dist(src, A) <= max(viewscale[1]*0.5,viewscale[2]*0.5)

/mob/living/silicon/ai/proc/relay_speech(message, atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, list/message_mods = list())
	var/treated_message = lang_treat(speaker, message_language, raw_message, spans, message_mods)
	var/namepart = "[speaker.GetVoice()][speaker.get_alt_name()]"
	var/hrefpart = "<a href='byond://?src=[REF(src)];track=[html_encode(namepart)]'>"
	var/jobpart = "Unknown"

	if(!HAS_TRAIT(speaker, TRAIT_UNKNOWN)) //don't fetch the speaker's job in case they have something that conseals their identity completely
		if(iscarbon(speaker))
			var/mob/living/carbon/human/living_speaker = speaker
			if(living_speaker.wear_id)
				var/obj/item/card/id/has_id = living_speaker.wear_id.GetID()
				if(has_id)
					jobpart = has_id.assignment
		if(istype(speaker, /obj/effect/overlay/holo_pad_hologram))
			var/obj/effect/overlay/holo_pad_hologram/holo = speaker
			if(holo.Impersonation?.job)
				jobpart = holo.Impersonation.job
			else if(usr?.job) // not great, but AI holograms have no other usable ref
				jobpart = usr.job

	// duplication part from `game/say.dm` to make a language icon
	var/language_icon = ""
	var/datum/language/D = GLOB.language_datum_instances[message_language]
	if(istype(D) && D.display_icon(src))
		language_icon = D.get_icon()

	var/rendered = "<i>[span_gamesay("[language_icon][span_name("[hrefpart][namepart] ([jobpart])</a> ")][span_message(treated_message)]")]</i>"

	show_message(rendered, 2)
	speaker.create_private_chat_message(
		message = raw_message,
		message_language = message_language,
		hearers = list(src),
		includes_ghosts = FALSE)

// modified version of `relay_speech()` proc, but for better chat through holopad
/// makes a better chat format for AI when AI takes
/mob/living/silicon/ai/proc/hear_holocall(message, atom/movable/speaker, datum/language/message_language, raw_message, radio_freq, list/spans, list/message_mods = list())
	var/treated_message = span_message(say_emphasis(lang_treat(speaker, message_language, raw_message, spans, message_mods)))
	var/namepart = "[speaker.GetVoice()][speaker.get_alt_name()]"
	var/hrefpart = "<a href='byond://?src=[REF(src)];track=[html_encode(namepart)]'>"
	var/jobpart = "Unknown"

	if (ishuman(speaker))
		var/mob/living/carbon/human/S = speaker
		if(S.wear_id)
			var/obj/item/card/id/I = S.wear_id.GetID()
			if(I)
				jobpart = "[I.assignment]"

	// duplication part from `game/say.dm` to make a language icon
	var/language_icon = ""
	var/datum/language/D = GLOB.language_datum_instances[message_language]
	if(istype(D) && D.display_icon(src))
		language_icon = "[D.get_icon()] "

	var/rendered = span_srtradioholocall("<b>\[Holocall\] [language_icon][span_name("[hrefpart][namepart] ([jobpart])</a>")]</b> [treated_message]")
	show_message(rendered, 2)
	speaker.create_private_chat_message(
		message = raw_message,
		message_language = message_language,
		hearers = list(src),
		includes_ghosts = FALSE) // ghosts already see this except for you...

	// renders message for ghosts
	rendered = span_srtradioholocall("<b>\[Holocall\] [language_icon][span_name(speaker.GetVoice())]</b> [treated_message]")
	var/rendered_scrambled_message
	for(var/mob/dead/observer/each_ghost in GLOB.dead_mob_list)
		if(!each_ghost.client || !each_ghost.client.prefs.read_player_preference(/datum/preference/toggle/chat_ghostradio))
			continue
		var/follow_link = FOLLOW_LINK(each_ghost, speaker)
		if(each_ghost.has_language(message_language))
			to_chat(each_ghost, "[follow_link] [rendered]")
		else // ghost removed the language themselves
			if(!rendered_scrambled_message)
				rendered_scrambled_message = span_message(each_ghost.say_emphasis(each_ghost.lang_treat(speaker, message_language, raw_message, spans, message_mods)))
				rendered_scrambled_message = span_srtradioholocall("<b>\[Holocall\] [language_icon][span_name(speaker.GetVoice())]</b> [rendered_scrambled_message]")
			to_chat(each_ghost, "[follow_link] [rendered_scrambled_message]")


/mob/living/silicon/ai/fully_replace_character_name(oldname,newname)
	..()
	if(oldname != real_name)
		if(eyeobj)
			eyeobj.name = "[newname] (AI Eye)"
			modularInterface.saved_identification = real_name

		// Notify Cyborgs
		for(var/mob/living/silicon/robot/Slave in connected_robots)
			Slave.show_laws()

/mob/living/silicon/ai/proc/add_malf_picker()
	if(malf_picker)
		stack_trace("Attempted to give malf AI malf picker to \[[src]\], who already has a malf picker.")
		return

	malf_picker = new /datum/module_picker
	modules_action = new(malf_picker)
	modules_action.Grant(src)

/mob/living/silicon/ai/reset_perspective(atom/new_eye)
	SHOULD_CALL_PARENT(FALSE) // AI needs to work as their own...
	if(camera_light_on)
		light_cameras()
	if(!client)
		return

	if(ismovable(new_eye))
		if(new_eye != GLOB.ai_camera_room_landmark)
			end_multicam()
		client.perspective = EYE_PERSPECTIVE
		client.set_eye(new_eye)
	else
		end_multicam()
		if(isturf(loc))
			if(eyeobj)
				client.set_eye(eyeobj)
				client.perspective = EYE_PERSPECTIVE
			else
				client.set_eye(client.mob)
				client.perspective = MOB_PERSPECTIVE
		else
			client.perspective = EYE_PERSPECTIVE
			client.set_eye(loc)
	update_sight()
	if(client.eye != src)
		var/atom/AT = client.eye
		AT.get_remote_view_fullscreens(src)
	else
		clear_fullscreen("remote_view", 0)

/mob/living/silicon/ai/revive(full_heal = 0, admin_revive = 0)
	. = ..()
	if(.) //successfully ressuscitated from death
		set_core_display_icon(display_icon_override)
		set_eyeobj_visible(TRUE)

/mob/living/silicon/ai/proc/tilt(turf/target, damage, chance_to_crit, paralyze_time, damage_type = BRUTE, rotation = 90)
	if(!target.is_blocked_turf(TRUE, src, list(src)))
		for(var/atom/atom_target in (target.contents) + target)
			if(isarea(atom_target))
				continue

			var/crit_case = 0
			if(prob(chance_to_crit))
				crit_case = rand(1,3)

			if(isliving(atom_target))
				var/mob/living/carbon/living_target = atom_target
				if(iscarbon(living_target))
					var/mob/living/carbon/carbon_target = living_target

					switch(crit_case) // only carbons can have the fun crits
						if(1) // shatter their legs and bleed 'em
							carbon_target.bleed(150)
							var/obj/item/bodypart/l_leg/l = carbon_target.get_bodypart(BODY_ZONE_L_LEG)
							if(l)
								l.receive_damage(brute=200, updating_health=TRUE)
							var/obj/item/bodypart/r_leg/r = carbon_target.get_bodypart(BODY_ZONE_R_LEG)
							if(r)
								r.receive_damage(brute=200, updating_health=TRUE)
							if(l || r)
								carbon_target.visible_message(span_danger("[carbon_target]'s legs shatter with a sickening crunch!"), \
									span_userdanger("Your legs shatter with a sickening crunch!"))
						if(2) // paralyze this binch
							// the new paraplegic gets like 4 lines of losing their legs so skip them
							visible_message(span_danger("[carbon_target]'s spinal cord is obliterated with a sickening crunch!"))
							carbon_target.gain_trauma(/datum/brain_trauma/severe/paralysis/paraplegic)
						if(3) // skull squish!
							var/obj/item/bodypart/head/head = carbon_target.get_bodypart(BODY_ZONE_HEAD)
							if(head)
								carbon_target.visible_message(span_danger("[head] explodes in a shower of gore beneath [src]!"), \
									span_userdanger("Oh f-"))
								head.dismember()
								head.drop_organs()
								qdel(head)
								new /obj/effect/gibspawner/human/bodypartless(get_turf(target))

					carbon_target.apply_damage(damage, forced = TRUE)
				else
					living_target.apply_damage(damage, forced = TRUE)

				living_target.Paralyze(paralyze_time)
				living_target.emote("scream")
				forceMove(target)
				playsound(living_target, 'sound/effects/blobattack.ogg', 40, TRUE)
				playsound(living_target, 'sound/effects/splat.ogg', 50, TRUE)

	var/matrix/M = matrix()
	M.Turn(rotation)
	transform = M
	playsound(target, 'sound/effects/bang.ogg', 50, TRUE)
	throw_at(target, 1, 1, spin = FALSE)

/mob/living/silicon/ai/proc/malfhacked(obj/machinery/power/apc/apc)
	malfhack = null
	malfhacking = FALSE
	clear_alert("hackingapc")

	if(!istype(apc) || QDELETED(apc) || apc.machine_stat & BROKEN)
		to_chat(src, span_danger("Hack aborted. The designated APC no longer exists on the power network."))
		playsound(get_turf(src), 'sound/machines/buzz-two.ogg', 50, TRUE, ignore_walls = FALSE)
	else if(apc.aidisabled)
		to_chat(src, span_danger("Hack aborted. \The [apc] is no longer responding to our systems."))
		playsound(get_turf(src), 'sound/machines/buzz-sigh.ogg', 50, TRUE, ignore_walls = FALSE)
	else
		var/turf/turf = get_turf(apc)
		if(istype(get_area(turf), /area/crew_quarters/heads))
			malf_picker.processing_time += 20
		else
			malf_picker.processing_time += 10
		apc.malfai = parent || src
		apc.malfhack = TRUE
		apc.locked = TRUE
		apc.coverlocked = TRUE
		log_message("hacked APC [apc] at [AREACOORD(turf)] (NEW PROCESSING: [malf_picker.processing_time])", LOG_GAME)
		playsound(get_turf(src), 'sound/machines/ding.ogg', 50, TRUE, ignore_walls = FALSE)
		to_chat(src, "Hack complete. \The [apc] is now under your exclusive control.")
		apc.update_appearance()

/mob/living/silicon/ai/verb/deploy_to_shell(var/mob/living/silicon/robot/target)
	set category = "AI Commands"
	set name = "Deploy to Shell"

	if(incapacitated())
		return
	if(control_disabled)
		to_chat(src, span_warning("Wireless networking module is offline."))
		return

	var/list/possible = list()

	for(var/borgie in GLOB.available_ai_shells)
		var/mob/living/silicon/robot/R = borgie
		if(R.shell && !R.deployed && (R.stat != DEAD) && (!R.connected_ai ||(R.connected_ai == src)) || (R.ratvar && !IS_SERVANT_OF_RATVAR(src)))
			possible += R

	if(!LAZYLEN(possible))
		to_chat(src, "No usable AI shell beacons detected.")

	if(!target || !(target in possible)) //If the AI is looking for a new shell, or its pre-selected shell is no longer valid
		target = input(src, "Which body to control?") as null|anything in sort_names(possible)

	if (!target || target.stat || target.deployed || !(!target.connected_ai ||(target.connected_ai == src)) || (target.ratvar && !IS_SERVANT_OF_RATVAR(src)))
		return

	if(target.is_jammed(JAMMER_PROTECTION_AI_SHELL))
		to_chat(src, span_warningrobot("Unable to establish communication link with target."))
		return

	else if(mind)
		soullink(/datum/soullink/sharedbody, src, target)
		deployed_shell = target
		transfer_observers_to(deployed_shell) // ai core to borg shell
		eyeobj.transfer_observers_to(deployed_shell) // eyemob to borg
		if(IS_SERVANT_OF_RATVAR(src) && !deployed_shell.ratvar)
			deployed_shell.SetRatvar(TRUE)
		target.deploy_init(src)
		mind.transfer_to(target)
	diag_hud_set_deployed()

/datum/action/innate/deploy_shell
	name = "Deploy to AI Shell"
	desc = "Wirelessly control a specialized cyborg shell."
	icon_icon = 'icons/hud/actions/actions_AI.dmi'
	button_icon_state = "ai_shell"

/datum/action/innate/deploy_shell/on_activate(mob/user, atom/target)
	var/mob/living/silicon/ai/AI = owner
	if(!AI)
		return
	AI.deploy_to_shell()

/datum/action/innate/deploy_last_shell
	name = "Reconnect to shell"
	desc = "Reconnect to the most recently used AI shell."
	icon_icon = 'icons/hud/actions/actions_AI.dmi'
	button_icon_state = "ai_last_shell"
	var/mob/living/silicon/robot/last_used_shell

/datum/action/innate/deploy_last_shell/on_activate(mob/user, atom/target)
	if(!owner)
		return
	if(last_used_shell)
		var/mob/living/silicon/ai/AI = owner
		AI.deploy_to_shell(last_used_shell)
	else
		Remove(owner) //If the last shell is blown, destroy it.

/mob/living/silicon/ai/proc/disconnect_shell()
	if(deployed_shell) //Forcibly call back AI in event of things such as damage, EMP or power loss.
		to_chat(src, span_danger("Your remote connection has been reset!"))
		deployed_shell.undeploy()
	diag_hud_set_deployed()

/mob/living/silicon/ai/resist()
	return

CREATION_TEST_IGNORE_SUBTYPES(/mob/living/silicon/ai/spawned)

/mob/living/silicon/ai/spawned/Initialize(mapload, datum/ai_laws/L, mob/target_ai)
	if(!target_ai)
		target_ai = src //cheat! just give... ourselves as the spawned AI, because that's technically correct
	. = ..() //This needs to be lower so we have a chance to actually update the assigned target_ai.

/mob/living/silicon/ai/proc/camera_visibility(mob/camera/ai_eye/moved_eye)
	GLOB.cameranet.visibility(moved_eye, client, all_eyes, TRUE)

/mob/living/silicon/ai/forceMove(atom/destination)
	. = ..()
	if(.)
		end_multicam()

/mob/living/silicon/ai/zMove(dir, feedback = FALSE, feedback_to = src)
	. = eyeobj.zMove(dir, feedback, feedback_to)

/// Proc to hook behavior to the changes of the value of [aiRestorePowerRoutine].
/mob/living/silicon/ai/proc/setAiRestorePowerRoutine(new_value)
	if(new_value == aiRestorePowerRoutine)
		return
	. = aiRestorePowerRoutine
	aiRestorePowerRoutine = new_value
	if(aiRestorePowerRoutine)
		if(!.)
			ADD_TRAIT(src, TRAIT_INCAPACITATED, POWER_LACK_TRAIT)
	else if(.)
		REMOVE_TRAIT(src, TRAIT_INCAPACITATED, POWER_LACK_TRAIT)


/mob/living/silicon/on_handsblocked_start()
	return // AIs have no hands

/mob/living/silicon/on_handsblocked_end()
	return // AIs have no hands

/mob/living/silicon/ai/verb/change_photo_camera_radius()
	set category = "AI Commands"
	set name = "Adjust Camera Zoom"
	set desc = "Change the zoom of your builtin camera."

	if(incapacitated())
		return
	if(isnull(aicamera))
		to_chat(usr, span_warning("You don't have a built-in camera!"))
		return

	aicamera.adjust_zoom(src)

/mob/living/silicon/ai/GetVoice()
	. = ..()
	if(ai_voicechanger && ai_voicechanger.changing_voice)
		return ai_voicechanger.say_name
	return

#undef CALL_BOT_COOLDOWN
