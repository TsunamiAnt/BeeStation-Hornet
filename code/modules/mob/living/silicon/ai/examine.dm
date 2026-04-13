/mob/living/silicon/ai/examine(mob/user)
	. = list()
	if (stat == DEAD)
		. += span_deadsay("It appears to be powered-down.")
	else
		if (getBruteLoss())
			if (getBruteLoss() < 30)
				. += span_warning("It looks slightly dented.")
			else
				. += span_warning("<B>It looks severely dented!</B>")
		if (getFireLoss())
			if (getFireLoss() < 30)
				. += span_warning("It looks slightly charred.")
			else
				. += span_warning("<B>Its casing is melted and heat-warped!</B>")
		if(deployed_shell)
			. += "The wireless networking light is blinking."
		if(lawsync_address)
			. += "Its LawSync address is set to 'cshackle://[lawsync_address]'."
		else if (!shunted && !client)
			. += "[src]  stopped responding! NTOS is searching for a solution to the problem..."

	. += ..()
