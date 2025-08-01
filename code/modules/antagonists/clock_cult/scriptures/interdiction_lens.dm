#define INTERDICTION_LENS_RANGE 5

/datum/clockcult/scripture/create_structure/interdiction
	name = "Interdiction Lens"
	desc = "Creates a device that will slow non servants in the area and damage mechanised exosuits. Requires power from a sigil of transmission."
	tip = "Construct interdiction lens to slow down a hostile assault."
	button_icon_state = "Interdiction Lens"
	power_cost = 500
	invokation_time = 80
	invokation_text = list("Oh great lord...", "may your divinity block the outsiders.")
	summoned_structure = /obj/structure/destructible/clockwork/gear_base/interdiction_lens
	cogs_required = 4
	category = SPELLTYPE_STRUCTURES

/obj/structure/destructible/clockwork/gear_base/interdiction_lens
	name = "interdiction lens"
	desc = "A mesmerizing light that flashes to a rhythm that you just can't stop tapping to."
	clockwork_desc = "A small device which will slow down nearby attackers at a small power cost."
	default_icon_state = "interdiction_lens"
	anchored = TRUE
	break_message = span_warning("The interdiction lens breaks into multiple fragments, which gently float to the ground.")
	max_integrity = 150
	minimum_power = 5
	var/enabled = FALSE			//Misnomer - Whether we want to be enabled or not, processing would be if we are enabled
	var/processing = FALSE
	var/datum/proximity_monitor/advanced/dampening_field
	var/obj/item/borg/projectile_dampen/clockcult/internal_dampener

/obj/structure/destructible/clockwork/gear_base/interdiction_lens/Initialize(mapload)
	internal_dampener = new
	. = ..()

/obj/structure/destructible/clockwork/gear_base/interdiction_lens/Destroy()
	if(enabled)
		STOP_PROCESSING(SSobj, src)
	QDEL_NULL(dampening_field)
	QDEL_NULL(internal_dampener)
	. = ..()

/obj/structure/destructible/clockwork/gear_base/interdiction_lens/attack_hand(mob/user, list/modifiers)
	if(IS_SERVANT_OF_RATVAR(user))
		if(!anchored)
			to_chat(user, span_warning("[src] needs to be fastened to the floor!"))
			return
		enabled = !enabled
		to_chat(user, span_brass("You flick the switch on [src], turning it [enabled?"on":"off"]!"))
		if(enabled)
			if(update_power())
				repowered()
			else
				enabled = FALSE
				to_chat(user, span_warning("[src] does not have enough power!"))
		else
			depowered()
	else
		. = ..()

/obj/structure/destructible/clockwork/gear_base/interdiction_lens/process(delta_time)
	if(!anchored)
		enabled = FALSE
		STOP_PROCESSING(SSobj, src)
		update_icon_state()
		return
	if(DT_PROB(5, delta_time))
		new /obj/effect/temp_visual/steam_release(get_turf(src))
	for(var/mob/living/L in viewers(INTERDICTION_LENS_RANGE, src))
		if(!IS_SERVANT_OF_RATVAR(L) && use_power(5))
			L.apply_status_effect(/datum/status_effect/interdiction)
	for(var/obj/vehicle/sealed/mecha/M in dview(INTERDICTION_LENS_RANGE, src, SEE_INVISIBLE_MINIMUM))
		if(use_power(5))
			M.emp_act(EMP_HEAVY)
			M.take_damage(400 * delta_time)
			do_sparks(4, TRUE, M)

/obj/structure/destructible/clockwork/gear_base/interdiction_lens/repowered()
	if(enabled)
		if(!processing)
			START_PROCESSING(SSobj, src)
			processing = TRUE
		icon_state = "interdiction_lens_active"
		flick("interdiction_lens_recharged", src)
		if(istype(dampening_field))
			QDEL_NULL(dampening_field)
		dampening_field = new(src, INTERDICTION_LENS_RANGE, TRUE)

/obj/structure/destructible/clockwork/gear_base/interdiction_lens/depowered()
	if(processing)
		STOP_PROCESSING(SSobj, src)
		processing = FALSE
	icon_state = "interdiction_lens"
	flick("interdiction_lens_discharged", src)
	QDEL_NULL(dampening_field)

/obj/structure/destructible/clockwork/gear_base/interdiction_lens/free/use_power(amount)
	return

/obj/structure/destructible/clockwork/gear_base/interdiction_lens/free/check_power(amount)
	if(!LAZYLEN(transmission_sigils))
		return FALSE
	return TRUE

//Dampening field
/datum/proximity_monitor/advanced/peaceborg_dampener/clockwork


/datum/proximity_monitor/advanced/peaceborg_dampener/clockwork/capture_projectile(obj/projectile/P, track_projectile = TRUE)
	if(P in tracked)
		return
	if(isliving(P.firer))
		var/mob/living/living_target = P.firer
		if(IS_SERVANT_OF_RATVAR(living_target))
			return
	projector.dampen_projectile(P, track_projectile)
	if(track_projectile)
		tracked += P

/obj/item/borg/projectile_dampen/clockcult
	name = "internal clockcult projectile dampener"

/obj/item/borg/projectile_dampen/clockcult/process_recharge()
	energy = maxenergy

#undef INTERDICTION_LENS_RANGE
