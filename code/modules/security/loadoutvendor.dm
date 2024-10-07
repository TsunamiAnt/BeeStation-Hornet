/obj/machinery/secload
	name = "SecLoad Loadout Vendor"
	desc = "A security equipment vendor. Directly beams pre-approved equipment from the supply logistics office of the nearest Central Command outpost. Horribly expensive."
	icon = 'icons/obj/vending.dmi'
	icon_state = "sec"
	var/icon_deny = "sec-deny"
	var/light_mask = "sec-light-mask"
	power_channel = AREA_USAGE_ENVIRON
	idle_power_usage = 20
	use_power = IDLE_POWER_USE
	processing_flags = START_PROCESSING_MANUALLY
	subsystem_type = /datum/controller/subsystem/processing/fastprocess
	density = TRUE
	max_integrity = 600
	integrity_failure = 0.35
	resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

	var/obj/item/radio/Radio

	// Vendor Tilting lmao
	var/tilted = FALSE
	var/forcecrit = 0
	var/squish_damage = 75
	var/num_shards = 7

	circuit = /obj/item/circuitboard/machine/secload

	var/obj/item/card/id/inserted_id

/obj/machinery/secload/Destroy()
	. = ..()

/obj/machinery/secload/Initialize(mapload)
	. = ..()

	Radio = new/obj/item/radio(src)
	Radio.set_listening(FALSE)
	Radio.set_frequency(FREQ_SECURITY)

/obj/machinery/secload/update_appearance(updates=ALL)
	. = ..()
	if(machine_stat & BROKEN)
		set_light(0)
		return
	set_light(powered() ? MINIMUM_USEFUL_LIGHT_RANGE : 0)

/obj/machinery/secload/update_icon_state()
	if(machine_stat & BROKEN)
		icon_state = "[initial(icon_state)]-broken"
		return ..()
	icon_state = "[initial(icon_state)][powered() ? null : "-off"]"
	return ..()

/obj/machinery/secload/update_overlays()
	. = ..()
	if(light_mask && !(machine_stat & BROKEN) && powered())
		. += emissive_appearance(icon, light_mask, layer)
		ADD_LUM_SOURCE(src, LUM_SOURCE_MANAGED_OVERLAY)

/obj/machinery/secload/crowbar_act(mob/living/user, obj/item/I)
	if(!component_parts)
		return FALSE
	default_deconstruction_crowbar(I)
	return TRUE

/obj/machinery/secload/screwdriver_act(mob/living/user, obj/item/I)
	if(..())
		return TRUE
	if(anchored || (!anchored && !panel_open))
		default_deconstruction_screwdriver(user, icon_state, icon_state, I)
		cut_overlays()
		if(panel_open)
			add_overlay("[initial(icon_state)]-panel")
	else
		to_chat(user, "<span class='warning'>You must first secure [src].</span>")
	return TRUE

/obj/machinery/secload/attackby(obj/item/I, mob/user, params)
	. = ..()
	var/area/A = get_area(loc)
	if(!tilted && I.force)
		switch(rand(1, 100))
			if(1 to 60)
				to_chat(user, "<span class='notice'>PLACEHOLDER, DM TSUNAMIANT ON DISCORD RIGHT FUCKING NOW.</span>")
				playsound(src, 'sound/machines/engine_alert1.ogg', 100, FALSE, 50)
				say("TILT WARNING! Please administer caution with security equipment.")
			if(61 to 80)
				Radio.talk_into(src, "TILT WARNING. Requesting inspection in [initial(A.name)].")
				playsound(src, 'sound/machines/engine_alert1.ogg', 100, FALSE, 50)
				say("TILT WARNING! Security Staff has been informed.")
			if(81 to 90)
				Radio.talk_into(src, "TILT WARNING. Requesting inspection in [initial(A.name)].")
				playsound(src, 'sound/machines/engine_alert1.ogg', 100, FALSE, 50)
				say("TILT WARNING! Security Staff has been informed.")
				tilt(user)
			if(91 to 100)
				Radio.talk_into(src, "TILT WARNING. Requesting inspection in [initial(A.name)].")
				playsound(src, 'sound/machines/engine_alert1.ogg', 100, FALSE, 50)
				say("TILT WARNING! Security Staff has been informed.")
				tilt(user, crit=TRUE)
			else
				SWITCH_EMPTY_STATEMENT

/obj/machinery/secload/on_emag(mob/user)
	..()
	to_chat(user, "<span class='notice'>You short out the login safeties on [src].</span>")

/obj/machinery/secload/_try_interact(mob/user)
	if(tilted && !user.buckled && !isAI(user))
		to_chat(user, "<span class='notice'>You begin righting [src].</span>")
		if(do_after(user, 50, target=src))
			untilt(user)
		return

	return ..()

/obj/machinery/secload/proc/tilt(mob/fatty, crit=FALSE)
	if(QDELETED(src))
		return
	visible_message("<span class='danger'>[src] tips over!</span>")
	tilted = TRUE
	layer = ABOVE_MOB_LAYER

	var/crit_case
	if(crit)
		crit_case = rand(1,5)

	if(forcecrit)
		crit_case = forcecrit

	if(in_range(fatty, src))
		for(var/mob/living/L in get_turf(fatty))
			var/mob/living/carbon/C = L

			if(istype(C))
				var/crit_rebate = 0 // lessen the normal damage we deal for some of the crits

				if(crit_case != 5) // the head asplode case has its own description
					C.visible_message("<span class='danger'>[C] is crushed by [src]!</span>", \
						"<span class='userdanger'>You are crushed by [src]!</span>")

				switch(crit_case) // only carbons can have the fun crits
					if(1) // shatter their legs and bleed 'em
						crit_rebate = 60
						C.bleed(150)
						var/obj/item/bodypart/l_leg/l = C.get_bodypart(BODY_ZONE_L_LEG)
						if(l)
							l.receive_damage(brute=200, updating_health=TRUE)
						var/obj/item/bodypart/r_leg/r = C.get_bodypart(BODY_ZONE_R_LEG)
						if(r)
							r.receive_damage(brute=200, updating_health=TRUE)
						if(l || r)
							C.visible_message("<span class='danger'>[C]'s legs shatter with a sickening crunch!</span>", \
								"<span class='userdanger'>Your legs shatter with a sickening crunch!</span>")
					if(2) // pin them beneath the machine until someone untilts it
						forceMove(get_turf(C))
						buckle_mob(C, force=TRUE)
						C.visible_message("<span class='danger'>[C] is pinned underneath [src]!</span>", \
							"<span class='userdanger'>You are pinned down by [src]!</span>")
					if(3) // glass candy
						crit_rebate = 50
						for(var/i in 1 to num_shards)
							var/obj/item/shard/shard = new /obj/item/shard(get_turf(C))
							shard.embedding = list(embed_chance = 10000, ignore_throwspeed_threshold = TRUE, impact_pain_mult=1, pain_chance=5)
							shard.updateEmbedding()
							C.hitby(shard, skipcatch = TRUE, hitpush = FALSE)
							shard.embedding = list()
							shard.updateEmbedding()
					if(4) // paralyze this binch
						// the new paraplegic gets like 4 lines of losing their legs so skip them
						visible_message("<span class='danger'>[C]'s spinal cord is obliterated with a sickening crunch!</span>")
						C.gain_trauma(/datum/brain_trauma/severe/paralysis/paraplegic)
					if(5) // skull squish!
						var/obj/item/bodypart/head/O = C.get_bodypart(BODY_ZONE_HEAD)
						if(O)
							C.visible_message("<span class='danger'>[O] explodes in a shower of gore beneath [src]!</span>", \
								"<span class='userdanger'>Oh f-</span>")
							O.dismember()
							O.drop_organs()
							qdel(O)
							new /obj/effect/gibspawner/human/bodypartless(get_turf(C))

				C.apply_damage(max(0, squish_damage - crit_rebate), forced=TRUE)
				C.AddElement(/datum/element/squish, 80 SECONDS)
			else
				L.visible_message("<span class='danger'>[L] is crushed by [src]!</span>", \
				"<span class='userdanger'>You are crushed by [src]!</span>")
				L.apply_damage(squish_damage, forced=TRUE)
				if(crit_case)
					L.apply_damage(squish_damage, forced=TRUE)

			L.Paralyze(60)
			L.emote("scream")
			playsound(L, 'sound/effects/blobattack.ogg', 40, TRUE)
			playsound(L, 'sound/effects/splat.ogg', 50, TRUE)

	var/matrix/M = matrix()
	M.Turn(pick(90, 270))
	transform = M

	if(get_turf(fatty) != get_turf(src))
		throw_at(get_turf(fatty), 1, 1, spin=FALSE)

/obj/machinery/secload/proc/untilt(mob/user)
	user.visible_message("<span class='notice'>[user] rights [src].</span>", \
		"<span class='notice'>You right [src].</span>")

	unbuckle_all_mobs(TRUE)

	tilted = FALSE
	layer = initial(layer)

	var/matrix/M = matrix()
	M.Turn(0)
	transform = M

/obj/item/circuitboard/machine/secload
	name = "SecLoad circuitboard"
	desc = "The circuit board for a SecLoad machine."
	build_path = /obj/machinery/secload
	req_components = list(
		/obj/item/stack/cable_coil = 5,
		/obj/item/stock_parts/manipulator = 2,
		/obj/item/stack/ore/bluespace_crystal = 1,
		/obj/item/stack/sheet/iron = 12
	)
