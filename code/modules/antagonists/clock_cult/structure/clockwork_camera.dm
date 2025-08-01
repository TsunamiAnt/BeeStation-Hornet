/mob/camera/ai_eye/remote/ratvar
	visible_icon = TRUE
	icon = 'icons/mob/cameramob.dmi'
	icon_state = "generic_camera"

/datum/action/innate/clockcult/warp
	name = "Warp"
	desc = "Warp to a location."
	button_icon_state = "warp_down"
	var/warping = FALSE

/datum/action/innate/clockcult/warp/is_available()
	if(!IS_SERVANT_OF_RATVAR(owner) || owner.incapacitated())
		return FALSE
	return ..()

/datum/action/innate/clockcult/warp/on_activate()
	if(!isliving(owner))
		return
	if(GLOB.gateway_opening)
		to_chat(owner, "[span_sevtugsmall("You cannot warp while the gateway is opening!")]")
		return
	if(warping)
		button_icon_state = "warp_down"
		owner.update_action_buttons_icon()
		warping = FALSE
		return
	var/mob/living/M = owner
	var/mob/camera/ai_eye/remote/ratvar/cam = M.remote_control
	var/target_loc = get_turf(cam)
	var/area/AR = get_area(target_loc)
	if(isclosedturf(target_loc))
		to_chat(owner, "[span_sevtugsmall("You cannot warp into dense objects.")]")
		return
	if(!AR.clockwork_warp_allowed)
		to_chat(owner, "[span_sevtugsmall("[AR.clockwork_warp_fail]")]")
		return
	do_sparks(5, TRUE, get_turf(cam))
	warping = TRUE
	button_icon_state = "warp_cancel"
	owner.update_action_buttons_icon()
	var/mob/previous_mob = owner
	if(do_after(M, 50, target=target_loc, extra_checks=CALLBACK(src, PROC_REF(special_check))))
		try_warp_servant(M, target_loc, 50, FALSE)
		var/obj/machinery/computer/camera_advanced/console = cam.origin
		console.remove_eye_control(M)
	button_icon_state = "warp_down"
	previous_mob.update_action_buttons_icon()
	warping = FALSE

/datum/action/innate/clockcult/warp/proc/special_check()
	return warping

/obj/machinery/computer/camera_advanced/ratvar
	name = "ratvarian observation console"
	desc = "Used by the servants of Ratvar to conduct operations on Nanotrasen property."
	icon_screen = "ratvar1"
	icon_keyboard = "ratvar_key1"
	icon_state = "ratvarcomputer"
	base_icon_state = null
	smoothing_flags = NONE
	smoothing_groups = null
	canSmoothWith = null
	clockwork = TRUE
	lock_override = CAMERA_LOCK_STATION
	broken_overlay_emissive = TRUE
	var/datum/action/innate/clockcult/warp/warp_action

	reveal_camera_mob = TRUE
	camera_mob_icon_state = "ratvar_camera"

/obj/machinery/computer/camera_advanced/ratvar/Initialize(mapload)
	. = ..()
	START_PROCESSING(SSobj, src)
	warp_action = new(src)

/obj/machinery/computer/camera_advanced/ratvar/Destroy()
	STOP_PROCESSING(SSobj, src)
	. = ..()

/obj/machinery/computer/camera_advanced/ratvar/process(delta_time)
	if(DT_PROB(3, delta_time))
		new /obj/effect/temp_visual/steam_release(get_turf(src))
	if(DT_PROB(7, delta_time))
		playsound(get_turf(src), 'sound/machines/beep.ogg', 20, TRUE)

/obj/machinery/computer/camera_advanced/ratvar/can_use(mob/living/user)
	. = ..()
	if(!IS_SERVANT_OF_RATVAR(user) || iscogscarab(user))
		return FALSE

/obj/machinery/computer/camera_advanced/ratvar/GrantActions(mob/living/user)
	. = ..()
	if(warp_action)
		warp_action.Grant(user)
		actions += warp_action

/obj/machinery/computer/camera_advanced/ratvar/CreateEye()
	eyeobj = new /mob/camera/ai_eye/remote/ratvar(get_turf(SSmapping.get_station_center()))
	eyeobj.origin = src
	eyeobj.icon = camera_mob_icon
	eyeobj.icon_state = camera_mob_icon_state
	RevealCameraMob()
