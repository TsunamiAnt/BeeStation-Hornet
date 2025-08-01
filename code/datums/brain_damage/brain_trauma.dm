//Brain Traumas are the new actual brain damage. Brain damage itself acts as a way to acquire traumas: every time brain damage is dealt, there's a chance of receiving a trauma.
//This chance gets higher the higher the mob's brainloss is. Removing traumas is a separate thing from removing brain damage: you can get restored to full brain operativity,
// but keep the quirks, until repaired by neurine, surgery, lobotomy or magic; depending on the resilience
// of the trauma.

/datum/brain_trauma
	var/name = "Brain Trauma"
	var/desc = "A trauma caused by brain damage, which causes issues to the patient."
	var/scan_desc = "generic brain trauma" //description when detected by a health scanner
	var/mob/living/carbon/owner //the poor bastard
	var/obj/item/organ/brain/brain //the poor bastard's brain
	var/gain_text = span_notice("You feel traumatized.")
	var/lose_text = span_notice("You no longer feel traumatized.")
	var/can_gain = TRUE
	/// How hard is this trauma to cure?
	var/resilience = TRAUMA_RESILIENCE_BASIC
	/// Flags for this trauma. See `TRAUMA_X` defines.
	var/trauma_flags = TRAUMA_DEFAULT_FLAGS

/datum/brain_trauma/Destroy()
	// Handles our references with our brain
	brain?.remove_trauma_from_traumas(src)
	if(owner)
		on_lose()
		owner = null
	return ..()

/datum/brain_trauma/proc/on_clone()
	if(CHECK_BITFIELD(trauma_flags, TRAUMA_CLONEABLE))
		return new type

//Called on life ticks
/datum/brain_trauma/proc/on_life(delta_time, times_fired)
	return

//Called on death
/datum/brain_trauma/proc/on_death()
	return

//Called when given to a mob
/datum/brain_trauma/proc/on_gain()
	to_chat(owner, gain_text)
	RegisterSignal(owner, COMSIG_MOB_SAY, PROC_REF(handle_speech))
	RegisterSignal(owner, COMSIG_MOVABLE_HEAR, PROC_REF(handle_hearing))

//Called when removed from a mob
/datum/brain_trauma/proc/on_lose(silent)
	if(!silent)
		to_chat(owner, lose_text)
	UnregisterSignal(owner, COMSIG_MOB_SAY)
	UnregisterSignal(owner, COMSIG_MOVABLE_HEAR)

//Called when hearing a spoken message
/datum/brain_trauma/proc/handle_hearing(datum/source, list/hearing_args)
	SIGNAL_HANDLER
	UnregisterSignal(owner, COMSIG_MOVABLE_HEAR)

//Called when speaking
/datum/brain_trauma/proc/handle_speech(datum/source, list/speech_args)
	SIGNAL_HANDLER
	UnregisterSignal(owner, COMSIG_MOB_SAY)

//Called when hugging. expand into generally interacting, where future coders could switch the intent?
/datum/brain_trauma/proc/on_hug(mob/living/hugger, mob/living/hugged)
	return
