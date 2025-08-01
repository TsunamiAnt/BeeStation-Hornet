/datum/team/ashwalkers
	name = "Ashwalkers"
	show_roundend_report = FALSE

/datum/antagonist/ashwalker
	name = "Ash Walker"
	banning_key = ROLE_ASHWALKER
	show_in_antagpanel = FALSE
	show_to_ghosts = TRUE
	prevent_roundtype_conversion = FALSE
	antagpanel_category = "Ash Walkers"
	delay_roundend = FALSE
	required_living_playtime = 1
	var/datum/team/ashwalkers/ashie_team

/datum/antagonist/ashwalker/create_team(datum/team/team)
	if(team)
		ashie_team = team
		objectives |= ashie_team.objectives
	else
		ashie_team = new

/datum/antagonist/ashwalker/get_team()
	return ashie_team

/datum/antagonist/ashwalker/on_body_transfer(mob/living/old_body, mob/living/new_body)
	. = ..()
	UnregisterSignal(old_body, COMSIG_MOB_EXAMINATE)
	RegisterSignal(new_body, COMSIG_MOB_EXAMINATE, PROC_REF(on_examinate))

/datum/antagonist/ashwalker/on_gain()
	. = ..()
	RegisterSignal(owner.current, COMSIG_MOB_EXAMINATE, PROC_REF(on_examinate))
	owner.teach_crafting_recipe(/datum/crafting_recipe/skeleton_key)
	owner.teach_crafting_recipe(/datum/crafting_recipe/drakecloak)
	owner.teach_crafting_recipe(/datum/crafting_recipe/primal_lasso)
	owner.teach_crafting_recipe(/datum/crafting_recipe/dragon_lasso)

/datum/antagonist/ashwalker/on_removal()
	. = ..()
	UnregisterSignal(owner.current, COMSIG_MOB_EXAMINATE)

/datum/antagonist/ashwalker/proc/on_examinate(datum/source, atom/A)
	SIGNAL_HANDLER

	if(istype(A, /obj/structure/headpike))
		SEND_SIGNAL(owner.current, COMSIG_ADD_MOOD_EVENT, "oogabooga", /datum/mood_event/sacrifice_good)
