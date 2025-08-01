///Global GPS_list. All  GPS components get saved in here for easy reference.
GLOBAL_LIST_EMPTY(GPS_list)
///GPS component. Atoms that have this show up on gps. Pretty simple stuff.
/datum/component/gps
	var/gpstag = "COM0"
	var/tracking = TRUE
	var/emped = FALSE

/datum/component/gps/Initialize(_gpstag = "COM0", _tracking = TRUE)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE
	gpstag = _gpstag
	tracking = _tracking;
	GLOB.GPS_list += src

/datum/component/gps/Destroy()
	GLOB.GPS_list -= src
	return ..()

///GPS component subtype. Only gps/item's can be used to open the UI.
/datum/component/gps/item
	var/updating = TRUE //Automatic updating of GPS list. Can be set to manual by user.
	var/global_mode = TRUE //If disabled, only GPS signals of the same Z level are shown
	/// UI state of GPS, altering when it can be used.
	var/datum/ui_state/state = null

/datum/component/gps/item/Initialize(_gpstag = "COM0", emp_proof = FALSE, state = null)
	. = ..()
	if(. == COMPONENT_INCOMPATIBLE || !isitem(parent))
		return COMPONENT_INCOMPATIBLE

	if(isnull(state))
		state = GLOB.default_state
	src.state = state

	var/atom/A = parent
	A.add_overlay("working")
	A.name = "[initial(A.name)] ([gpstag])"
	RegisterSignal(parent, COMSIG_ITEM_ATTACK_SELF, PROC_REF(interact))
	if(!emp_proof)
		RegisterSignal(parent, COMSIG_ATOM_EMP_ACT, PROC_REF(on_emp_act))
	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(parent, COMSIG_CLICK_ALT, PROC_REF(on_AltClick))

///Called on COMSIG_ITEM_ATTACK_SELF
/datum/component/gps/item/proc/interact(datum/source, mob/user)
	SIGNAL_HANDLER

	if(user)
		INVOKE_ASYNC(src, PROC_REF(ui_interact), user)

///Called on COMSIG_PARENT_EXAMINE
/datum/component/gps/item/proc/on_examine(datum/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	examine_list += span_notice("Alt-click to switch it [tracking ? "off":"on"].")

///Called on COMSIG_ATOM_EMP_ACT
/datum/component/gps/item/proc/on_emp_act(datum/source, severity)
	SIGNAL_HANDLER

	emped = TRUE
	var/atom/A = parent
	A.cut_overlay("working")
	A.add_overlay("emp")
	addtimer(CALLBACK(src, PROC_REF(reboot)), 300, TIMER_UNIQUE|TIMER_OVERRIDE) //if a new EMP happens, remove the old timer so it doesn't reactivate early
	SStgui.close_uis(src) //Close the UI control if it is open.

///Restarts the GPS after getting turned off by an EMP.
/datum/component/gps/item/proc/reboot()
	emped = FALSE
	var/atom/A = parent
	A.cut_overlay("emp")
	A.add_overlay("working")

///Calls toggletracking
/datum/component/gps/item/proc/on_AltClick(datum/source, mob/user)
	SIGNAL_HANDLER

	toggletracking(user)
	ui_update()

///Toggles the tracking for the gps
/datum/component/gps/item/proc/toggletracking(mob/user)
	if(!user.canUseTopic(parent, BE_CLOSE))
		return //user not valid to use gps
	if(emped)
		to_chat(user, span_warning("It's busted!"))
		return
	var/atom/A = parent
	if(tracking)
		A.cut_overlay("working")
		to_chat(user, span_notice("[parent] is no longer tracking, or visible to other GPS devices."))
		tracking = FALSE
	else
		A.add_overlay("working")
		to_chat(user, span_notice("[parent] is now tracking, and visible to other GPS devices."))
		tracking = TRUE


/datum/component/gps/item/ui_state(mob/user)
	return GLOB.default_state

/datum/component/gps/item/ui_interact(mob/user, datum/tgui/ui) // Remember to use the appropriate state.
	if(emped)
		to_chat(user, span_hear("[parent] fizzles weakly."))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Gps") //width, height
		ui.open()

	ui.set_autoupdate(updating)

/datum/component/gps/item/ui_state(mob/user)
	return state

/datum/component/gps/item/ui_data(mob/user)
	var/list/data = list()
	data["power"] = tracking
	data["tag"] = gpstag
	data["updating"] = updating
	data["globalmode"] = global_mode
	if(!tracking || emped) //Do not bother scanning if the GPS is off or EMPed
		return data

	var/turf/curr = get_turf(parent)
	data["currentArea"] = "[get_area_name(curr, TRUE)]"
	data["currentCoords"] = "[curr.x], [curr.y], [curr.get_virtual_z_level()]"

	var/list/signals = list()

	for(var/gps in GLOB.GPS_list)
		var/datum/component/gps/G = gps
		if(G.emped || !G.tracking || G == src)
			continue
		var/turf/pos = get_turf(G.parent)
		if(!pos || !global_mode && pos.get_virtual_z_level() != curr.get_virtual_z_level())
			continue
		var/list/signal = list()
		signal["entrytag"] = G.gpstag //Name or 'tag' of the GPS
		signal["coords"] = "[pos.x], [pos.y], [pos.get_virtual_z_level()]"
		if(pos.get_virtual_z_level() == curr.get_virtual_z_level()) //Distance/Direction calculations for same z-level only
			signal["dist"] = max(get_dist(curr, pos), 0) //Distance between the src and remote GPS turfs
			signal["degrees"] = round(get_angle(curr, pos)) //0-360 degree directional bearing, for more precision.
		signals += list(signal) //Add this signal to the list of signals
	data["signals"] = signals
	return data

/datum/component/gps/item/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return

	switch(action)
		if("rename")
			var/atom/parentasatom = parent
			var/input = tgui_input_text(usr, "Enter the desired tag", "GPS Tag", gpstag, max_length = 20)
			if (QDELETED(ui) || ui.status != UI_INTERACTIVE)
				return
			if (!input)
				to_chat(usr, span_warning("You need to enter something!"))
				return

			if(OOC_FILTER_CHECK(input)) // check for forbidden words (OOC only)
				to_chat(usr, span_warning("Your message contains forbidden words."))
				return

			gpstag = input
			. = TRUE
			parentasatom.name = "[initial(parentasatom.name)] ([gpstag])"

		if("power")
			toggletracking(usr)
			. = TRUE
		if("updating")
			updating = !updating
			. = TRUE
		if("globalmode")
			global_mode = !global_mode
			. = TRUE
