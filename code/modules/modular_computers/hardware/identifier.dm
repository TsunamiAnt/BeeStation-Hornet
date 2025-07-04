/obj/item/computer_hardware/identifier
	name = "identifier"
	desc = "Used to automatically update the names of modular devices."
	power_usage = 0
	w_class = WEIGHT_CLASS_TINY
	device_type = MC_IDENTIFY
	expansion_hw = FALSE

/obj/item/computer_hardware/identifier/proc/UpdateDisplay()
	var/name = holder.saved_identification
	var/job = holder.saved_job

	if(istype(holder, /obj/item/modular_computer/tablet/pda))
		holder.name = "PDA-[name] ([job])"
	else if(istype(holder, /obj/item/modular_computer/tablet))
		holder.name = "Tablet-[name] ([job])"
