
//////////////////////////Poison stuff (Toxins & Acids)///////////////////////

/datum/reagent/toxin
	name = "Toxin"
	description = "A toxic chemical."
	color = "#CF3600" // rgb: 207, 54, 0
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_GOAL_BOTANIST_HARVEST
	taste_description = "bitterness"
	taste_mult = 1.2
	var/toxpwr = 1.5
	var/silent_toxin = FALSE //won't produce a pain message when processed by liver/life() if there isn't another non-silent toxin present.

/datum/reagent/toxin/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(toxpwr)
		M.adjustToxLoss(toxpwr * REM * delta_time, 0)
		. = TRUE
	..()

/datum/reagent/toxin/amatoxin
	name = "Amatoxin"
	description = "A powerful poison derived from certain species of mushroom."
	color = "#792300" // rgb: 121, 35, 0
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_GOAL_BOTANIST_HARVEST
	toxpwr = 2.5
	taste_description = "mushroom"

/datum/reagent/toxin/mutagen
	name = "Unstable Mutagen"
	description = "Might cause unpredictable mutations. Keep away from children."
	color = "#00FF00"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BOTANIST_HARVEST
	toxpwr = 0
	taste_description = "slime"
	taste_mult = 0.9

/datum/reagent/toxin/mutagen/expose_mob(mob/living/carbon/M, method=TOUCH, reac_volume)
	if(!..())
		return
	if(!M.has_dna())
		return  //No robots, AIs, aliens, Ians or other mobs should be affected by this.
	if((method==VAPOR && prob(min(33, reac_volume))) || method==INGEST || method==PATCH || method==INJECT)
		M.random_mutate_unique_identity()
		if(prob(98))
			M.easy_random_mutate(NEGATIVE+MINOR_NEGATIVE)
		else
			M.easy_random_mutate(POSITIVE)
		M.updateappearance()
		M.domutcheck()
	..()

/datum/reagent/toxin/mutagen/on_mob_life(mob/living/carbon/C, delta_time, times_fired)
	C.apply_effect(5 * REM * delta_time, EFFECT_IRRADIATE, 0)
	return ..()

/datum/reagent/toxin/plasma
	name = "Plasma"
	description = "Plasma in its liquid form."
	taste_description = "a burning, tingling sensation"
	specific_heat = SPECIFIC_HEAT_PLASMA
	taste_mult = 1.5
	color = "#8228A0"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	toxpwr = 3
	process_flags = ORGANIC | SYNTHETIC

/datum/reagent/toxin/plasma/on_mob_life(mob/living/carbon/C, delta_time, times_fired)
	if(holder.has_reagent(/datum/reagent/medicine/epinephrine))
		holder.remove_reagent(/datum/reagent/medicine/epinephrine, 2 * REM * delta_time)
	C.adjustPlasma(20 * REM * delta_time)
	return ..()

/datum/reagent/toxin/plasma/expose_mob(mob/living/M, method=TOUCH, reac_volume)//Splashing people with plasma is stronger than fuel!
	if(method == TOUCH || method == VAPOR)
		M.adjust_fire_stacks(reac_volume / 5)
		return
	..()

/datum/reagent/toxin/lexorin
	name = "Lexorin"
	description = "A powerful poison used to stop respiration."
	color = "#7DC3A0"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	toxpwr = 0
	taste_description = "acid"

/datum/reagent/toxin/lexorin/on_mob_life(mob/living/carbon/C, delta_time, times_fired)
	. = TRUE

	if(HAS_TRAIT(C, TRAIT_NOBREATH))
		. = FALSE

	if(.)
		C.adjustOxyLoss(5 * REM * delta_time, 0)
		C.losebreath += 2 * REM * delta_time
		if(DT_PROB(10, delta_time))
			C.emote("gasp")
	..()

/datum/reagent/toxin/slimejelly
	name = "Slime Jelly"
	description = "A gooey semi-liquid produced from Oozelings"
	color = "#801E28" // rgb: 128, 30, 40
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	toxpwr = 0
	taste_description = "slime"
	taste_mult = 1.3

/datum/reagent/toxin/slimejelly/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(DT_PROB(5, delta_time))
		to_chat(M, span_danger("Your insides are burning!"))
		M.adjustToxLoss(rand(1, 10), 0)
		. = TRUE
	else if(DT_PROB(23, delta_time))
		M.heal_bodypart_damage(5)
		. = TRUE
	..()

/datum/reagent/toxin/minttoxin
	name = "Mint Toxin"
	description = "Useful for dealing with undesirable customers."
	color = "#CF3600" // rgb: 207, 54, 0
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN
	toxpwr = 0
	taste_description = "mint"

/datum/reagent/toxin/minttoxin/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(HAS_TRAIT_FROM(M, TRAIT_FAT, OBESITY))
		M.client?.give_award(/datum/award/achievement/misc/mintgib, M)
		M.investigate_log("has been gibbed by consuming [src] while fat.", INVESTIGATE_DEATHS)
		M.gib()
	return ..()

/datum/reagent/toxin/carpotoxin
	name = "Carpotoxin"
	description = "A deadly neurotoxin produced by the dreaded spess carp."
	silent_toxin = TRUE
	color = "#003333" // rgb: 0, 51, 51
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_GOAL_BOTANIST_HARVEST
	toxpwr = 1
	taste_description = "fish"

/datum/reagent/toxin/carpotoxin/on_mob_metabolize(mob/living/carbon/L)
	if(iscatperson(L))
		toxpwr = 0
	..()

/datum/reagent/toxin/zombiepowder
	name = "Zombie Powder"
	description = "A strong neurotoxin that puts the subject into a death-like state."
	silent_toxin = TRUE
	reagent_state = SOLID
	color = "#669900" // rgb: 102, 153, 0
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	toxpwr = 0
	taste_description = "death"

/datum/reagent/toxin/zombiepowder/on_mob_life(mob/living/M, delta_time, times_fired)
	if(current_cycle >= 10) // delayed activation for toxin
		M.adjustStaminaLoss((current_cycle - 5) * REM * delta_time, 0)
	if(M.getStaminaLoss() >= 145 && !HAS_TRAIT(M, TRAIT_FAKEDEATH)) // fake death tied to stamina for interesting interactions - 23 ticks to fake death with pure ZP
		M.fakedeath(type)
	..()

/datum/reagent/toxin/zombiepowder/on_mob_end_metabolize(mob/living/L)
	L.cure_fakedeath(type)
	..()

/datum/reagent/toxin/ghoulpowder
	name = "Ghoul Powder"
	description = "A strong neurotoxin that slows metabolism to a death-like state while keeping the patient fully active. Causes toxin buildup if used too long."
	reagent_state = SOLID
	color = "#664700" // rgb: 102, 71, 0
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	toxpwr = 0.8
	taste_description = "death"

/datum/reagent/toxin/ghoulpowder/on_mob_metabolize(mob/living/L)
	..()
	ADD_TRAIT(L, TRAIT_FAKEDEATH, type)

/datum/reagent/toxin/ghoulpowder/on_mob_end_metabolize(mob/living/L)
	REMOVE_TRAIT(L, TRAIT_FAKEDEATH, type)
	..()

/datum/reagent/toxin/ghoulpowder/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustOxyLoss(1 * REM * delta_time, 0)
	..()
	. = TRUE

/datum/reagent/toxin/mindbreaker
	name = "Mindbreaker Toxin"
	description = "A mild hallucinogen. Beneficial to some mental patients."
	color = "#B31008" // rgb: 139, 166, 233
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_GOAL_BOTANIST_HARVEST
	toxpwr = 0
	taste_description = "sourness"

/datum/reagent/toxin/mindbreaker/on_mob_life(mob/living/carbon/metabolizer, delta_time, times_fired)
	if(!metabolizer.has_quirk(/datum/quirk/insanity))
		metabolizer.hallucination += 5 * REM * delta_time
	return ..()

/datum/reagent/toxin/plantbgone
	name = "Plant-B-Gone"
	description = "A harmful toxic mixture to kill plantlife. Do not ingest!"
	color = "#49002E" // rgb: 73, 0, 46
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BOTANIST_HARVEST
	toxpwr = 1
	taste_mult = 1

/datum/reagent/toxin/plantbgone/expose_obj(obj/O, reac_volume)
	if(istype(O, /obj/structure/alien/weeds))
		var/obj/structure/alien/weeds/alien_weeds = O
		alien_weeds.take_damage(rand(15,35), BRUTE, 0) // Kills alien weeds pretty fast
	else if(istype(O, /obj/structure/glowshroom)) //even a small amount is enough to kill it
		qdel(O)
	else if(istype(O, /obj/structure/spacevine))
		var/obj/structure/spacevine/SV = O
		SV.on_chem_effect(src)

/datum/reagent/toxin/plantbgone/expose_mob(mob/living/M, method=TOUCH, reac_volume)
	if(method == VAPOR)
		if(iscarbon(M))
			var/mob/living/carbon/C = M
			if(!C.wear_mask) // If not wearing a mask
				var/damage = min(round(0.4*reac_volume, 0.1),10)
				C.adjustToxLoss(damage)

/datum/reagent/toxin/plantbgone/weedkiller
	name = "Weed Killer"
	description = "A harmful toxic mixture to kill weeds. Do not ingest!"
	color = "#4B004B" // rgb: 75, 0, 75
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BOTANIST_HARVEST

/datum/reagent/toxin/pestkiller
	name = "Pest Killer"
	description = "A harmful toxic mixture to kill pests. Do not ingest!"
	color = "#4B004B" // rgb: 75, 0, 75
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	toxpwr = 1

/datum/reagent/toxin/pestkiller/expose_mob(mob/living/M, method=TOUCH, reac_volume)
	..()
	if(MOB_BUG in M.mob_biotypes)
		var/damage = min(round(0.4*reac_volume, 0.1),10)
		M.adjustToxLoss(damage)

/datum/reagent/toxin/spore
	name = "Spore Toxin"
	description = "A natural toxin produced by blob spores that inhibits vision when ingested."
	color = "#9ACD32"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	toxpwr = 1

/datum/reagent/toxin/spore/on_mob_life(mob/living/carbon/C, delta_time, times_fired)
	C.damageoverlaytemp = 60
	C.update_damage_hud()
	C.blur_eyes(3 * REM * delta_time)
	return ..()

/datum/reagent/toxin/spore_burning
	name = "Burning Spore Toxin"
	description = "A natural toxin produced by blob spores that induces combustion in its victim."
	color = "#9ACD32"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	toxpwr = 0.5
	taste_description = "burning"

/datum/reagent/toxin/spore_burning/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjust_fire_stacks(2 * REM * delta_time)
	M.IgniteMob()
	return ..()

/datum/reagent/toxin/chloralhydrate
	name = "Chloral Hydrate"
	description = "A powerful sedative that induces confusion and drowsiness before putting its target to sleep."
	silent_toxin = TRUE
	reagent_state = SOLID
	color = "#000067" // rgb: 0, 0, 103
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	toxpwr = 0
	metabolization_rate = 1.5 * REAGENTS_METABOLISM

/datum/reagent/toxin/chloralhydrate/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	switch(current_cycle)
		if(1 to 10)
			M.confused += 2 * REM * delta_time
			M.drowsyness += 2 * REM * delta_time
		if(10 to 50)
			M.Sleeping(40 * REM * delta_time)
			. = TRUE
		if(51 to INFINITY)
			M.Sleeping(40 * REM * delta_time)
			M.adjustToxLoss(1 * (current_cycle - 50) * REM * delta_time, 0)
			. = TRUE
	..()

/datum/reagent/toxin/fakebeer	//disguised as normal beer for use by emagged brobots
	name = "Strong Beer"
	description = "A specially-engineered sedative disguised as beer. It induces instant sleep in its target."
	color = "#664300" // rgb: 102, 67, 0
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 1.5 * REAGENTS_METABOLISM
	taste_description = "piss water"

/datum/glass_style/drinking_glass/fakebeer
	required_drink_type = /datum/reagent/toxin/fakebeer

/datum/glass_style/drinking_glass/fakebeer/New()
	. = ..()
	// Copy styles from the beer drinking glass datum
	var/datum/glass_style/copy_from = /datum/glass_style/drinking_glass/beer
	name = initial(copy_from.name)
	desc = initial(copy_from.desc)
	icon = initial(copy_from.icon)
	icon_state = initial(copy_from.icon_state)

/datum/reagent/toxin/fakebeer/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	switch(current_cycle)
		if(1 to 50)
			M.Sleeping(40 * REM * delta_time)
		if(51 to INFINITY)
			M.Sleeping(40 * REM * delta_time)
			M.adjustToxLoss(1 * (current_cycle - 50) * REM * delta_time, 0)
	return ..()

/datum/reagent/toxin/coffeepowder
	name = "Coffee Grounds"
	description = "Finely ground coffee beans, used to make coffee."
	reagent_state = SOLID
	color = "#5B2E0D" // rgb: 91, 46, 13
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	toxpwr = 0.5

/datum/reagent/toxin/teapowder
	name = "Ground Tea Leaves"
	description = "Finely shredded tea leaves, used for making tea."
	reagent_state = SOLID
	color = "#7F8400" // rgb: 127, 132, 0
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BARTENDER_SERVING
	toxpwr = 0.1
	taste_description = "green tea"

/datum/reagent/toxin/whispertoxin
	name = "Whisper Toxin"
	description = "A less potent version of mute toxin which prevents a victim from speaking loudly."
	silent_toxin = TRUE
	color = "#F0F8FF" // rgb: 240, 248, 255
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BOTANIST_HARVEST | CHEMICAL_GOAL_BARTENDER_SERVING
	toxpwr = 0
	taste_description = "alcohol"

/datum/reagent/toxin/whispertoxin/on_mob_metabolize(mob/living/L)
	. = ..()
	ADD_TRAIT(L, TRAIT_WHISPER_ONLY, type)
	// Prevent people from spamming *scream
	ADD_TRAIT(L, TRAIT_EMOTEMUTE, type)

/datum/reagent/toxin/whispertoxin/on_mob_end_metabolize(mob/living/L)
	. = ..()
	REMOVE_TRAIT(L, TRAIT_WHISPER_ONLY, type)
	REMOVE_TRAIT(L, TRAIT_EMOTEMUTE, type)

/datum/reagent/toxin/mutetoxin //the new zombie powder.
	name = "Mute Toxin"
	description = "A nonlethal poison that inhibits speech in its victim."
	silent_toxin = TRUE
	color = "#F0F8FF" // rgb: 240, 248, 255
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BOTANIST_HARVEST | CHEMICAL_GOAL_BARTENDER_SERVING
	toxpwr = 0
	taste_description = "silence"

/datum/reagent/toxin/mutetoxin/on_mob_metabolize(mob/living/L)
	. = ..()
	ADD_TRAIT(L, TRAIT_MUTE, type)

/datum/reagent/toxin/mutetoxin/on_mob_end_metabolize(mob/living/L)
	. = ..()
	REMOVE_TRAIT(L, TRAIT_MUTE, type)

/datum/reagent/toxin/staminatoxin
	name = "Tirizene"
	description = "A nonlethal poison that causes extreme fatigue and weakness in its victim."
	silent_toxin = TRUE
	color = "#6E2828"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	data = 30
	toxpwr = 0

/datum/reagent/toxin/staminatoxin/on_mob_metabolize(mob/living/L)
	..()
	L.add_movespeed_modifier(/datum/movespeed_modifier/reagent/staminatoxin)

/datum/reagent/toxin/staminatoxin/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustStaminaLoss(data * REM * delta_time, 0)
	data = max(data - 1, 3)
	..()
	. = TRUE

/datum/reagent/toxin/staminatoxin/on_mob_end_metabolize(mob/living/L)
	..()
	L.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/staminatoxin)

/datum/reagent/toxin/polonium
	name = "Polonium"
	description = "An extremely radioactive material in liquid form. Ingestion results in fatal irradiation."
	reagent_state = LIQUID
	color = "#787878"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	toxpwr = 0
	process_flags = ORGANIC | SYNTHETIC

/datum/reagent/toxin/polonium/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.radiation += 4 * REM * delta_time
	..()

/datum/reagent/toxin/histamine
	name = "Histamine"
	description = "Histamine's effects become more dangerous depending on the dosage amount. They range from mildly annoying to incredibly lethal."
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#FA6464"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BOTANIST_HARVEST
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	overdose_threshold = 30
	toxpwr = 0

/datum/reagent/toxin/histamine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(DT_PROB(30, delta_time))
		switch(pick(1, 2, 3, 4))
			if(1)
				to_chat(M, span_danger("You can barely see!"))
				M.blur_eyes(3)
			if(2)
				M.emote("cough")
			if(3)
				M.emote("sneeze")
			if(4)
				if(prob(75))
					to_chat(M, "You scratch at an itch.")
					M.adjustBruteLoss(2*REM, 0)
					. = TRUE
	..()

/datum/reagent/toxin/histamine/overdose_process(mob/living/M, delta_time, times_fired)
	M.adjustOxyLoss(2 * REM * delta_time, FALSE)
	M.adjustBruteLoss(2 * REM * delta_time, FALSE, FALSE, BODYTYPE_ORGANIC)
	M.adjustToxLoss(2 * REM * delta_time, FALSE)
	..()
	. = TRUE

/datum/reagent/toxin/formaldehyde
	name = "Formaldehyde"
	description = "Formaldehyde, on its own, is a fairly weak toxin. It contains trace amounts of Histamine, very rarely making it decay into Histamine."
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#B4004B"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	toxpwr = 1

/datum/reagent/toxin/formaldehyde/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(DT_PROB(2.5, delta_time))
		holder.add_reagent(/datum/reagent/toxin/histamine, pick(5,15))
		holder.remove_reagent(/datum/reagent/toxin/formaldehyde, 1.2)
	else
		return ..()

/datum/reagent/toxin/venom
	name = "Venom"
	description = "An exotic poison extracted from highly toxic fauna. Causes scaling amounts of toxin damage and bruising depending and dosage. Often decays into Histamine."
	reagent_state = LIQUID
	color = "#F0FFF0"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	toxpwr = 0

/datum/reagent/toxin/venom/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	toxpwr = 0.1 * volume
	M.adjustBruteLoss((0.3 * volume) * REM * delta_time, 0)
	. = TRUE
	if(DT_PROB(8, delta_time))
		M.reagents.add_reagent(/datum/reagent/toxin/histamine, pick(5,10))
		holder.remove_reagent(/datum/reagent/toxin/venom, 1.1)
	else
		..()

/datum/reagent/toxin/spidervenom
	name = "Spider Venom"
	description = "A type of venom extracted from spiders. Causes toxin damage and can paralyze in large doses."
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	reagent_state = LIQUID
	color = "#00A080"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	toxpwr = 0.5

/datum/reagent/toxin/spidervenom/on_mob_metabolize(mob/living/L)
	if(SEND_SIGNAL(L, COMSIG_HAS_NANITES))
		for(var/datum/component/nanites/N in L.datum_components)
			for(var/X in N.programs)
				var/datum/nanite_program/NP = X
				NP.software_error(1) //all programs are destroyed, nullifying all nanites

/datum/reagent/toxin/spidervenom/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.getStaminaLoss() <= 70) //Will never stamcrit
		M.adjustStaminaLoss(min(volume * 1.5, 15) * REM * delta_time, FALSE)
	if(current_cycle >= 4 && prob(current_cycle + (volume * 0.3))) //The longer it is in your system and the more of it you have the more frequently you drop
		M.Paralyze(3 SECONDS * REM * delta_time, 0)
		toxpwr += 0.1 //The venom gets stronger until completely purged.
	if(holder.has_reagent(/datum/reagent/medicine/calomel) || holder.has_reagent(/datum/reagent/medicine/pen_acid) || holder.has_reagent(/datum/reagent/medicine/charcoal) || holder.has_reagent(/datum/reagent/medicine/carthatoline))
		current_cycle += 5 // Prevents using purgatives while in combat
	..()

/datum/reagent/toxin/fentanyl
	name = "Fentanyl"
	description = "Fentanyl will inhibit brain function and cause toxin damage before eventually incapacitating its victim."
	reagent_state = LIQUID
	color = "#64916E"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	toxpwr = 0

/datum/reagent/toxin/fentanyl/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 3 * REM * delta_time, 150)
	if(M.toxloss <= 60)
		M.adjustToxLoss(1 * REM * delta_time, 0)
	if(current_cycle >= 18)
		M.Sleeping(40 * REM * delta_time)
	..()
	return TRUE

/datum/reagent/toxin/cyanide
	name = "Cyanide"
	description = "An infamous poison known for its use in assassination. Causes small amounts of toxin damage with a small chance of oxygen damage or a stun."
	reagent_state = LIQUID
	color = "#00B4FF"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BOTANIST_HARVEST
	metabolization_rate = 0.125 * REAGENTS_METABOLISM
	toxpwr = 1.25

/datum/reagent/toxin/cyanide/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(DT_PROB(2.5, delta_time))
		M.losebreath += 1
	if(DT_PROB(4, delta_time))
		to_chat(M, "You feel horrendously weak!")
		M.Stun(40)
		M.adjustToxLoss(2*REM, 0)
	return ..()

/datum/reagent/toxin/bad_food
	name = "Bad Food"
	description = "The result of some abomination of cookery, food so bad it's toxic."
	reagent_state = LIQUID
	color = "#d6d6d8"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	toxpwr = 0.5
	taste_description = "bad cooking"

/datum/reagent/toxin/itching_powder
	name = "Itching Powder"
	description = "A powder that induces itching upon contact with the skin. Causes the victim to scratch at their itches and has a very low chance to decay into Histamine."
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#C8C8C8"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BOTANIST_HARVEST
	metabolization_rate = 0.4 * REAGENTS_METABOLISM
	toxpwr = 0

/datum/reagent/toxin/itching_powder/expose_mob(mob/living/M, method=TOUCH, reac_volume)
	if(method == TOUCH || method == VAPOR)
		M.reagents?.add_reagent(/datum/reagent/toxin/itching_powder, reac_volume)

/datum/reagent/toxin/itching_powder/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(DT_PROB(8, delta_time))
		to_chat(M, "<span class='danger'>You scratch at your head.</span>")
		M.adjustBruteLoss(0.2*REM, 0)
		. = TRUE
	if(DT_PROB(8, delta_time))
		to_chat(M, "<span class='danger'>You scratch at your leg.</span>")
		M.adjustBruteLoss(0.2*REM, 0)
		. = TRUE
	if(DT_PROB(8, delta_time))
		to_chat(M, "<span class='danger'>You scratch at your arm.</span>")
		M.adjustBruteLoss(0.2*REM, 0)
		. = TRUE
	if(DT_PROB(1.5, delta_time))
		M.reagents.add_reagent(/datum/reagent/toxin/histamine,rand(1,3))
		M.reagents.remove_reagent(/datum/reagent/toxin/itching_powder,1.2)
		return
	..()

/datum/reagent/toxin/initropidril
	name = "Initropidril"
	description = "A powerful poison with insidious effects. It can cause stuns, lethal breathing failure, and cardiac arrest."
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#7F10C0"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	toxpwr = 2.5

/datum/reagent/toxin/initropidril/on_mob_life(mob/living/carbon/C, delta_time, times_fired)
	if(DT_PROB(13, delta_time))
		var/picked_option = rand(1,3)
		switch(picked_option)
			if(1)
				C.Paralyze(60)
				. = TRUE
			if(2)
				C.losebreath += 10
				C.adjustOxyLoss(rand(5,25), 0)
				. = TRUE
			if(3)
				if(!C.undergoing_cardiac_arrest() && C.can_heartattack())
					C.set_heartattack(TRUE)
					if(C.stat == CONSCIOUS)
						C.visible_message(span_userdanger("[C] clutches at [C.p_their()] chest as if [C.p_their()] heart stopped!"))
				else
					C.losebreath += 10
					C.adjustOxyLoss(rand(5,25), 0)
					. = TRUE
	return ..() || .

/datum/reagent/toxin/pancuronium
	name = "Pancuronium"
	description = "An undetectable toxin that swiftly incapacitates its victim. May also cause breathing failure."
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#195096"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.25 * REAGENTS_METABOLISM
	toxpwr = 0
	taste_mult = 0 // undetectable, I guess?

/datum/reagent/toxin/pancuronium/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(current_cycle >= 10)
		M.Stun(40 * REM * delta_time)
		. = TRUE
	if(DT_PROB(10, delta_time))
		M.losebreath += 4
	..()

/datum/reagent/toxin/sodium_thiopental
	name = "Sodium Thiopental"
	description = "Sodium Thiopental induces heavy weakness in its target as well as unconsciousness."
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#6496FA"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.75 * REAGENTS_METABOLISM
	toxpwr = 0

/datum/reagent/toxin/sodium_thiopental/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(current_cycle >= 10)
		M.Sleeping(40 * REM * delta_time)
	M.adjustStaminaLoss(10 * REM * delta_time, 0)
	..()
	return TRUE

/datum/reagent/toxin/sulfonal
	name = "Sulfonal"
	description = "A stealthy poison that deals minor toxin damage and eventually puts the target to sleep."
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#7DC3A0"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.125 * REAGENTS_METABOLISM
	toxpwr = 0.5

/datum/reagent/toxin/sulfonal/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(current_cycle >= 22)
		M.Sleeping(40 * REM * delta_time)
	return ..()

/datum/reagent/toxin/amanitin
	name = "Amanitin"
	description = "A very powerful delayed toxin. Upon full metabolization, a massive amount of toxin damage will be dealt depending on how long it has been in the victim's bloodstream."
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#FFFFFF"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_GOAL_BOTANIST_HARVEST
	toxpwr = 0
	metabolization_rate = 0.5 * REAGENTS_METABOLISM

/datum/reagent/toxin/amanitin/on_mob_delete(mob/living/M)
	var/toxdamage = current_cycle*3*REM
	M.log_message("has taken [toxdamage] toxin damage from amanitin toxin", LOG_ATTACK)
	M.adjustToxLoss(toxdamage)
	..()

/datum/reagent/toxin/lipolicide
	name = "Lipolicide"
	description = "A powerful toxin that will destroy fat cells, massively reducing body weight in a short time. Deadly to those without nutriment in their body."
	silent_toxin = TRUE
	taste_description = "mothballs"
	reagent_state = LIQUID
	color = "#F0FFF0"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_GOAL_BOTANIST_HARVEST
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	toxpwr = 0

/datum/reagent/toxin/lipolicide/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.nutrition <= NUTRITION_LEVEL_STARVING)
		M.adjustToxLoss(1 * REM * delta_time, 0)
	M.adjust_nutrition(-3 * REM * delta_time) // making the chef more valuable, one meme trap at a time
	M.overeatduration = 0
	return ..()

/datum/reagent/toxin/coniine
	name = "Coniine"
	description = "Coniine metabolizes extremely slowly, but deals high amounts of toxin damage and stops breathing."
	reagent_state = LIQUID
	color = "#7DC3A0"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.06 * REAGENTS_METABOLISM
	toxpwr = 1.75

/datum/reagent/toxin/coniine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.losebreath += 5 * REM * delta_time
	return ..()

/datum/reagent/toxin/spewium
	name = "Spewium"
	description = "A powerful emetic, causes uncontrollable vomiting.  May result in vomiting organs at high doses."
	reagent_state = LIQUID
	color = "#2f6617" //A sickly green color
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = REAGENTS_METABOLISM
	overdose_threshold = 29
	toxpwr = 0
	taste_description = "vomit"

/datum/reagent/toxin/spewium/on_mob_life(mob/living/carbon/C, delta_time, times_fired)
	.=..()
	if(current_cycle >= 11 && DT_PROB(min(30, current_cycle), delta_time))
		C.vomit(10, prob(10), prob(50), rand(0,4), TRUE, prob(30))
		for(var/datum/reagent/toxin/R in C.reagents.reagent_list)
			if(R != src)
				C.reagents.remove_reagent(R.type,1)

/datum/reagent/toxin/spewium/overdose_process(mob/living/carbon/C, delta_time, times_fired)
	. = ..()
	if(current_cycle >= 33 && DT_PROB(7.5, delta_time))
		C.spew_organ()
		C.vomit(0, TRUE, TRUE, 4)
		to_chat(C, span_userdanger("You feel something lumpy come up as you vomit."))

/datum/reagent/toxin/curare
	name = "Curare"
	description = "Causes slight toxin damage followed by chain-stunning and oxygen damage."
	reagent_state = LIQUID
	color = "#191919"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.125 * REAGENTS_METABOLISM
	toxpwr = 1

/datum/reagent/toxin/curare/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(current_cycle >= 11)
		M.Paralyze(60 * REM * delta_time)
	M.adjustOxyLoss(0.5*REM*delta_time, 0)
	. = TRUE
	..()

/datum/reagent/toxin/heparin //Based on a real-life anticoagulant. I'm not a doctor, so this won't be realistic.
	name = "Heparin"
	description = "A powerful anticoagulant. Victims will bleed uncontrollably and suffer scaling bruising."
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#C8C8C8" //RGB: 200, 200, 200
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.2 * REAGENTS_METABOLISM
	toxpwr = 0

/datum/reagent/toxin/heparin/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(ishuman(M))
		var/mob/living/carbon/human/H = M
		if (!H.is_bleeding())
			H.add_bleeding(BLEED_SURFACE)
		H.adjustBruteLoss(1 * REAGENTS_EFFECT_MULTIPLIER * delta_time, 0) //Brute damage increases with the amount they're bleeding
		. = TRUE
	return ..() || .


/datum/reagent/toxin/rotatium //Rotatium. Fucks up your rotation and is hilarious
	name = "Rotatium"
	description = "A constantly swirling, oddly colourful fluid. Causes the consumer's sense of direction and hand-eye coordination to become wild."
	silent_toxin = TRUE
	reagent_state = LIQUID
	color = "#AC88CA" //RGB: 172, 136, 202
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.6 * REAGENTS_METABOLISM
	toxpwr = 0.5
	taste_description = "spinning"
	process_flags = ORGANIC | SYNTHETIC

/datum/reagent/toxin/rotatium/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.hud_used)
		if(current_cycle >= 20 && (current_cycle % 20) == 0)
			var/atom/movable/plane_master_controller/pm_controller = M.hud_used.plane_master_controllers[PLANE_MASTERS_GAME]
			var/rotation = min(round(current_cycle/20), 89) // By this point the player is probably puking and quitting anyway
			for(var/key in pm_controller.controlled_planes)
				animate(pm_controller.controlled_planes[key], transform = matrix(rotation, MATRIX_ROTATE), time = 5, easing = QUAD_EASING, loop = -1)
				animate(transform = matrix(-rotation, MATRIX_ROTATE), time = 5, easing = QUAD_EASING)
	return ..()

/datum/reagent/toxin/rotatium/on_mob_end_metabolize(mob/living/M)
	if(M?.hud_used)
		var/atom/movable/plane_master_controller/pm_controller = M.hud_used.plane_master_controllers[PLANE_MASTERS_GAME]
		for(var/key in pm_controller.controlled_planes)
			animate(pm_controller.controlled_planes[key], transform = matrix(), time = 5, easing = QUAD_EASING)
	..()

/datum/reagent/toxin/anacea
	name = "Anacea"
	description = "A toxin that quickly purges medicines and metabolizes very slowly."
	reagent_state = LIQUID
	color = "#3C5133"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.08 * REAGENTS_METABOLISM
	toxpwr = 0.15

/datum/reagent/toxin/anacea/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	var/remove_amt = 5
	if(holder.has_reagent(/datum/reagent/medicine/calomel) || holder.has_reagent(/datum/reagent/medicine/pen_acid))
		remove_amt = 0.5
	for(var/datum/reagent/medicine/R in M.reagents.reagent_list)
		M.reagents.remove_reagent(R.type, remove_amt * REM * delta_time)
	return ..()

//ACID


/datum/reagent/toxin/acid
	name = "Sulfuric Acid"
	description = "A strong mineral acid with the molecular formula H2SO4."
	color = "#00FF32"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	toxpwr = 1
	var/acidpwr = 10 //the amount of protection removed from the armour
	taste_description = "acid"
	self_consuming = TRUE
	process_flags = ORGANIC | SYNTHETIC

/datum/reagent/toxin/acid/expose_mob(mob/living/carbon/C, method=TOUCH, reac_volume)
	if(!istype(C))
		return
	reac_volume = round(reac_volume,0.1)
	if(method == INGEST)
		C.adjustBruteLoss(min(6*toxpwr, reac_volume * toxpwr))
		return
	if(method == INJECT)
		C.adjustBruteLoss(1.5 * min(6*toxpwr, reac_volume * toxpwr))
		return
	C.acid_act(acidpwr, reac_volume)

/datum/reagent/toxin/acid/expose_obj(obj/O, reac_volume)
	if(ismob(O.loc)) //handled in human acid_act()
		return
	reac_volume = round(reac_volume,0.1)
	O.acid_act(acidpwr, reac_volume)

/datum/reagent/toxin/acid/expose_turf(turf/T, reac_volume)
	if (!istype(T))
		return
	reac_volume = round(reac_volume,0.1)
	T.acid_act(acidpwr, reac_volume)

/datum/reagent/toxin/acid/fluacid
	name = "Fluorosulfuric acid"
	description = "Fluorosulfuric acid is an extremely corrosive chemical substance."
	color = "#5050FF"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BOTANIST_HARVEST
	toxpwr = 2
	acidpwr = 42.0

/datum/reagent/toxin/acid/fluacid/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustFireLoss((current_cycle/15) * REM * delta_time, 0)
	. = TRUE
	..()

/datum/reagent/toxin/delayed
	name = "Toxin Microcapsules"
	description = "Causes heavy toxin damage after a brief time of inactivity."
	reagent_state = LIQUID
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0 //stays in the system until active.
	var/actual_metaboliztion_rate = REAGENTS_METABOLISM
	toxpwr = 0
	var/actual_toxpwr = 5
	var/delay = 30

/datum/reagent/toxin/delayed/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(current_cycle > delay)
		holder.remove_reagent(type, actual_metaboliztion_rate * M.metabolism_efficiency * delta_time)
		M.adjustToxLoss(actual_toxpwr * REM * delta_time, 0)
		if(DT_PROB(5, delta_time))
			M.Paralyze(20)
		. = TRUE
	..()

/datum/reagent/toxin/mimesbane
	name = "Mime's Bane"
	description = "A nonlethal neurotoxin that interferes with the victim's ability to gesture."
	silent_toxin = TRUE
	color = "#F0F8FF" // rgb: 240, 248, 255
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY | CHEMICAL_GOAL_BOTANIST_HARVEST
	toxpwr = 0
	taste_description = "stillness"

/datum/reagent/toxin/mimesbane/on_mob_metabolize(mob/living/L)
	ADD_TRAIT(L, TRAIT_EMOTEMUTE, type)

/datum/reagent/toxin/mimesbane/on_mob_end_metabolize(mob/living/L)
	REMOVE_TRAIT(L, TRAIT_EMOTEMUTE, type)

/datum/reagent/toxin/bonehurtingjuice //oof ouch
	name = "Bone Hurting Juice"
	description = "A strange substance that looks a lot like water. Drinking it is oddly tempting. Oof ouch."
	silent_toxin = TRUE //no point spamming them even more.
	color = "#AAAAAA77" //RGBA: 170, 170, 170, 77
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	toxpwr = 0
	taste_description = "bone hurting"
	overdose_threshold = 50

/datum/reagent/toxin/bonehurtingjuice/on_mob_metabolize(mob/living/carbon/M)
	M.say("Oof ouch my bones!", forced = /datum/reagent/toxin/bonehurtingjuice)

/datum/reagent/toxin/bonehurtingjuice/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustStaminaLoss(7.5 * REM * delta_time, 0)
	if(DT_PROB(10, delta_time))
		switch(rand(1, 3))
			if(1)
				var/list/possible_says = list("oof.", "ouch!", "my bones.", "oof ouch.", "oof ouch my bones.")
				M.say(pick(possible_says), forced = /datum/reagent/toxin/bonehurtingjuice)
			if(2)
				var/list/possible_mes = list("oofs softly.", "looks like their bones hurt.", "grimaces, as though their bones hurt.")
				M.say("*custom " + pick(possible_mes), forced = /datum/reagent/toxin/bonehurtingjuice)
			if(3)
				to_chat(M, span_warning("Your bones hurt!"))
	return ..()

/datum/reagent/toxin/bonehurtingjuice/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	if(DT_PROB(2, delta_time) && iscarbon(M)) //big oof
		var/selected_part
		switch(rand(1, 4)) //God help you if the same limb gets picked twice quickly.
			if(1)
				selected_part = BODY_ZONE_L_ARM
			if(2)
				selected_part = BODY_ZONE_R_ARM
			if(3)
				selected_part = BODY_ZONE_L_LEG
			if(4)
				selected_part = BODY_ZONE_R_LEG
		var/obj/item/bodypart/bp = M.get_bodypart(selected_part)
		if(M.dna.species.type != /datum/species/skeleton && M.dna.species.type != /datum/species/plasmaman) //We're so sorry skeletons, you're so misunderstood
			if(bp)
				bp.receive_damage(0, 0, 200)
				playsound(M, get_sfx("desecration"), 50, TRUE, -1)
				M.visible_message(span_warning("[M]'s bones hurt too much!!"), span_danger("Your bones hurt too much!!"))
				M.say("OOF!!", forced = /datum/reagent/toxin/bonehurtingjuice)
			else //SUCH A LUST FOR REVENGE!!!
				to_chat(M, span_warning("A phantom limb hurts!"))
				M.say("Why are we still here, just to suffer?", forced = /datum/reagent/toxin/bonehurtingjuice)
		else //you just want to socialize
			if(bp)
				playsound(M, get_sfx("desecration"), 50, TRUE, -1)
				M.visible_message(span_warning("[M] rattles loudly and flails around!!"), span_danger("Your bones hurt so much that your missing muscles spasm!!"))
				M.say("OOF!!", forced=/datum/reagent/toxin/bonehurtingjuice)
				bp.receive_damage(200, 0, 0) //But I don't think we should
			else
				to_chat(M, span_warning("Your missing arm aches from wherever you left it."))
				M.emote("sigh")
	return ..()

/datum/reagent/toxin/bungotoxin
	name = "Bungotoxin"
	description = "A horrible cardiotoxin that protects the humble bungo pit."
	silent_toxin = TRUE
	color = "#EBFF8E"
	chem_flags = CHEMICAL_RNG_GENERAL | CHEMICAL_RNG_FUN | CHEMICAL_RNG_BOTANY
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	toxpwr = 0
	taste_description = "tannin"

/datum/reagent/toxin/bungotoxin/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.adjustOrganLoss(ORGAN_SLOT_HEART, 3 * REM * delta_time)
	M.confused = M.dizziness //add a tertiary effect here if this is isn't an effective poison.
	if(current_cycle >= 12 && DT_PROB(4, delta_time))
		var/tox_message = pick("You feel your heart spasm in your chest.", "You feel faint.","You feel you need to catch your breath.","You feel a prickle of pain in your chest.")
		to_chat(M, span_notice("[tox_message]"))
	. = TRUE
	..()

//This reagent is intentionally not designed to give much fighting chance. Its only ever used when morph manages to trick somebody into interacting with its disguised form
/datum/reagent/toxin/morphvenom
	name = "Morph venom"
	description = "Deadly venom of shapeshifting creature."
	color = "#3cff00"
	chem_flags = CHEMICAL_NOT_SYNTH | CHEMICAL_RNG_FUN
	toxpwr = 2
	taste_description = "salt"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM

/datum/reagent/toxin/morphvenom/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.set_drugginess(5)
	M.adjustStaminaLoss(30 * REM * delta_time)
	M.silent = max(M.silent, 3 * REM * delta_time)
	M.confused = max(M.confused, 3 * REM * delta_time)
	..()

/datum/reagent/toxin/morphvenom/mimite
	name = "Mimite venom"
	description = "Deadly venom of a shapeshifting creature."
	color = "#330063"
