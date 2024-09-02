#define DISARM_COMBO "DH"
#define TRIP_COMBO "DG"
#define ARMLOCK "DHGG"

/datum/martial_art/jiujitsu
	name = "jiujitsu"
	id = MARTIALART_JIUJITSU
	no_guns = TRUE
	allow_temp_override = FALSE
	help_verb = /mob/living/carbon/human/proc/jiujitsu_help

/datum/martial_art/jiujitsu/proc/check_streak(mob/living/carbon/human/A, mob/living/carbon/human/D)
	if(findtext(streak,DISARM_COMBO))
		streak = ""
		return 1
	if(findtext(streak,TRIP_COMBO))
		streak = ""
		return 1
	if(findtext(streak,ARMLOCK))
		streak = ""
		return 1
	return 0

/datum/martial_art/jiujitsu/harm_act(mob/living/carbon/human/A, mob/living/carbon/human/D)
	add_to_streak("H",D)
	if(check_streak(A,D))
		return 1
	var/obj/item/bodypart/affecting = D.get_bodypart(ran_zone(A.get_combat_bodyzone(D)))
	var/armor_block = D.run_armor_check(affecting, MELEE)
	if(D.body_position == STANDING_UP)
		D.visible_message("<span class='danger'>[A] strikes [D]!</span>", \
					"<span class='userdanger'>You're jabbed by [A]!</span>", "<span class='hear'>You hear a sickening sound of flesh hitting flesh!</span>", COMBAT_MESSAGE_RANGE, A)
		to_chat(A, "<span class='danger'>You jab [D]!</span>")
		A.do_attack_animation(D, ATTACK_EFFECT_PUNCH)
		playsound(D, 'sound/effects/hit_punch.ogg', 50, TRUE, -1)
		D.apply_damage(15, STAMINA, affecting, armor_block)
		log_combat(A, D, "punched nonlethally", name)
	if(D.body_position == LYING_DOWN)
		D.visible_message("<span class='danger'>[A] strikes [D]!</span>", \
					"<span class='userdanger'>You're manhandled by [A]!</span>", "<span class='hear'>You hear a sickening sound of flesh hitting flesh!</span>", COMBAT_MESSAGE_RANGE, A)
		to_chat(A, "<span class='danger'>You strike [D]!</span>")
		A.do_attack_animation(D, ATTACK_EFFECT_KICK)
		playsound(D, 'sound/effects/hit_punch.ogg', 50, TRUE, -1)
		D.apply_damage(25, STAMINA, affecting, armor_block)
		log_combat(A, D, "stomped nonlethally", name)
	return ..()

/datum/martial_art/jiujitsu/grab_act(mob/living/carbon/human/A, mob/living/carbon/human/D)
	add_to_streak("G",D)
	if(check_streak(A,D))
		return 1
	return ..()

/datum/martial_art/jiujitsu/disarm_act(mob/living/carbon/human/A, mob/living/carbon/human/D)
	add_to_streak("D",D)
	if(check_streak(A,D))
		return 1
	return ..()

/mob/living/carbon/human/proc/jiujitsu_help()
	set name = "Recall Security Training"
	set desc = "Remember your Jiujitsu training."
	set category = "Jiujitsu"

	to_chat(usr, "<b><i>You try to remember the fundamentals of Jiujitsu...</i></b>")

	to_chat(usr, "<span class='notice'>Calf Kick</span>: Harm Grab Disarm. Paralyses one of your opponent's legs.")
	to_chat(usr, "<span class='notice'>Jumping Knee</span>: Harm Disarm Harm. Deals significant stamina damage and knocks your opponent down briefly.")
	to_chat(usr, "<span class='notice'>Karate Chop</span>: Grab Harm Disarm. Very briefly confuses your opponent and blurs their vision.")
	to_chat(usr, "<span class='notice'>Floor Stomp</span>: Harm Grab Harm. Deals brute and stamina damage if your opponent isn't standing up.")
