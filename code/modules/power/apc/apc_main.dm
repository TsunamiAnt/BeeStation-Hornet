// the Area Power Controller (APC), formerly Power Distribution Unit (PDU)
// one per area, needs wire connection to power network through a terminal

// controls power to devices in that area
// may be opened to change power cell
// three different channels (lighting/equipment/environ) - may each be set to on, off, or auto

/obj/machinery/power/apc
	name = "area power controller"
	desc = "A control terminal for the area's electrical systems."

	icon_state = "apc0"
	use_power = NO_POWER_USE
	req_one_access = list(ACCESS_ATMOSPHERICS, ACCESS_ENGINE)
	max_integrity = 200
	integrity_failure = 0.25
	damage_deflection = 10
	resistance_flags = FIRE_PROOF
	interaction_flags_machine = INTERACT_MACHINE_WIRES_IF_OPEN | INTERACT_MACHINE_ALLOW_SILICON | INTERACT_MACHINE_OPEN_SILICON
	clicksound = 'sound/machines/terminal_select.ogg'
	layer = ABOVE_WINDOW_LAYER
	zmm_flags = ZMM_MANGLE_PLANES

	light_power = 0.85



	FASTDMM_PROP(\
		set_instance_vars(\
			pixel_x = dir == EAST ? 24 : (dir == WEST ? -24 : INSTANCE_VAR_DEFAULT),\
			pixel_y = dir == NORTH ? 24 : (dir == SOUTH ? -24 : INSTANCE_VAR_DEFAULT)\
		),\
		dir_amount = 4\
	)

	var/lon_range = 2
	var/area/area

	///Mapper helper to tie an apc to another area
	var/areastring = null
	///Reference to our internal cell
	var/obj/item/stock_parts/cell/cell
	///Initial cell charge %
	var/start_charge = 90
	///Type of cell we start with
	var/cell_type = /obj/item/stock_parts/cell/upgraded		//Base cell has 2500 capacity. Enter the path of a different cell you want to use. cell determines charge rates, max capacity, ect. These can also be changed with other APC vars, but isn't recommended to minimize the risk of accidental usage of dirty editted APCs
	///State of the cover (closed, opened, removed)
	var/opened = APC_COVER_CLOSED
	///Is the APC shorted and not working?
	var/shorted = 0
	///State of the lighting channel (off, auto off, on, auto on)
	var/lighting = 3
	///State of the equipment channel (off, auto off, on, auto on)
	var/equipment = 3
	///State of the environmental channel (off, auto off, on, auto on)
	var/environ = 3
	///Is the apc working
	var/operating = TRUE
	///State of the apc charging (not charging, charging, fully charged)
	var/charging = APC_NOT_CHARGING
	///Can the APC charge?
	var/chargemode = TRUE
	///Number of ticks where the apc is trying to recharge
	var/chargecount = 0
	///Is the apc interface locked?
	var/locked = TRUE
	///Is the apc cover locked?
	var/coverlocked = TRUE
	///Is the AI locked from using the APC
	var/aidisabled = 0

	///Reference to our cable terminal
	var/obj/machinery/power/terminal/terminal = null
	///Amount of power used by the lighting channel
	var/lastused_light = 0
	///Amount of power used by the equipment channel
	var/lastused_equip = 0
	///Amount of power used by the environmental channel
	var/lastused_environ = 0
	///Total amount of power used by the three channels
	var/lastused_total = 0
	///State of the apc external power (no power, low power, has power)
	var/main_status = APC_NO_POWER
	powernet = 0 // set so that APCs aren't found as powernet nodes //Hackish, Horrible, was like this before I changed it :(
	///Is the apc hacked by a malf ai?
	var/malfhack = 0 //New var for my changes to AI malf. --NeoFite
	///Reference to our ai hacker
	var/mob/living/silicon/ai/malfai = null //See above --NeoFite
	///State of the electronics inside (missing, installed, secured)
	var/has_electronics = APC_ELECTRONICS_MISSING
	///used for the Blackout malf module
	var/overload = 1
	///used for counting how many times it has been hit, used for Aliens at the moment
	var/beenhit = 0
	///Reference to the shunted ai inside
	var/mob/living/silicon/ai/occupier = null
	///Is there an AI being transferred out of us?
	var/transfer_in_progress = FALSE
	///buffer state that makes apcs not shut off channels immediately as long as theres some power left, effect visible in apcs only slowly losing power
	var/longtermpower = 10
	///Automatically name the APC after the area is in
	var/auto_name = FALSE
	///Time to allow the APC to regain some power and to turn the channels back online
	var/failure_timer = 0
	///Forces an update on the power use to ensure that the apc has enough power
	var/force_update = 0
	///Should the emergency lights be on?
	var/emergency_lights = FALSE
	///Should the nighshift lights be on?
	var/nightshift_lights = FALSE
	///Time when the nightshift where turned on last, to prevent spamming
	var/last_nightshift_switch = 0
	///Stores the flags for the icon state
	var/update_state = -1
	///Stores the flag for the overlays
	var/update_overlay = -1
	///Used to stop process from updating the icons too much
	var/icon_update_needed = FALSE
	///Reference to our remote control
	var/obj/machinery/computer/apc_control/remote_control = null

	///Represents a signel source of power alarms for this apc
	var/datum/alarm_handler/alarm_manager

	//Clockcult - Has the reward for converting an APC been given?
	var/clock_cog_rewarded = FALSE
	//Clockcult - The integration cog inserted inside of us
	var/integration_cog = null

	/// To prevent sound loop bugs
	var/apc_sound_stage = null

	armor_type = /datum/armor/power_apc

/datum/armor/power_apc
	melee = 20
	bullet = 20
	laser = 10
	energy = 100
	bomb = 30
	rad = 100
	fire = 90
	acid = 50

/obj/machinery/power/apc/New(turf/loc, var/ndir, var/building=0)
	..()
	GLOB.apcs_list += src

	wires = new /datum/wires/apc(src)
	if (building)
		area = get_area(src)
		opened = APC_COVER_OPENED
		operating = FALSE
		name = "\improper [get_area_name(area, TRUE)] APC"
		set_machine_stat(machine_stat | MAINT)
		update_appearance()
		addtimer(CALLBACK(src, PROC_REF(update)), 5)
		dir = ndir

	// offset APC_PIXEL_OFFSET pixels in direction of dir
	// this allows the APC to be embedded in a wall, yet still inside an area
	var/offset_old
	switch(dir)
		if(NORTH)
			offset_old = pixel_y
			pixel_y = APC_PIXEL_OFFSET
		if(SOUTH)
			offset_old = pixel_y
			pixel_y = -APC_PIXEL_OFFSET
		if(EAST)
			offset_old = pixel_x
			pixel_x = APC_PIXEL_OFFSET
		if(WEST)
			offset_old = pixel_x
			pixel_x = -APC_PIXEL_OFFSET
	if(offset_old != APC_PIXEL_OFFSET && !building)
		log_mapping("APC: ([src]) at [AREACOORD(src)] with dir ([dir] | [uppertext(dir2text(dir))]) has pixel_[dir & (WEST|EAST) ? "x" : "y"] value [offset_old] - should be [dir & (SOUTH|EAST) ? "-" : ""][APC_PIXEL_OFFSET]. Use the directional/ helpers!")

/obj/machinery/power/apc/Destroy()
	GLOB.apcs_list -= src

	if(malfai && operating)
		malfai.malf_picker.processing_time = clamp(malfai.malf_picker.processing_time - 10,0,1000)
	disconnect_from_area()
	QDEL_NULL(alarm_manager)
	if(occupier)
		malfvacate(TRUE)
	if(wires)
		QDEL_NULL(wires)
	if(cell)
		QDEL_NULL(cell)
	if(terminal)
		disconnect_terminal()
	return ..()

/obj/machinery/power/apc/proc/assign_to_area(area/target_area = get_area(src))
	if(area == target_area)
		return

	disconnect_from_area()
	area = target_area
	area.power_light = TRUE
	area.power_equip = TRUE
	area.power_environ = TRUE
	area.power_change()
	area.apc = src
	auto_name = TRUE

	update_name()

/obj/machinery/power/apc/update_name(updates)
	. = ..()
	if(auto_name)
		name = "\improper [get_area_name(area, TRUE)] APC"

/obj/machinery/power/apc/proc/disconnect_from_area()
	if(isnull(area))
		return

	area.power_light = FALSE
	area.power_equip = FALSE
	area.power_environ = FALSE
	area.power_change()
	area.apc = null
	area = null

/obj/machinery/power/apc/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/atmos_sensitive)

/obj/machinery/power/apc/should_atmos_process(datum/gas_mixture/air, exposed_temperature)
	return (exposed_temperature > 2000)

/obj/machinery/power/apc/atmos_expose(datum/gas_mixture/air, exposed_temperature)
	take_damage(min(exposed_temperature/100, 10), BURN)



/obj/machinery/power/apc/handle_atom_del(atom/A)
	if(A == cell)
		cell = null
		charging = APC_NOT_CHARGING
		update_appearance()
		updateUsrDialog()

/obj/machinery/power/apc/Initialize(mapload)
	. = ..()
	alarm_manager = new(src)

	if(!mapload)
		return
	has_electronics = APC_ELECTRONICS_SECURED
	// is starting with a power cell installed, create it and set its charge level
	if(cell_type)
		cell = new cell_type
		cell.charge = start_charge * cell.maxcharge / 100 // (convert percentage to actual value)

	var/area/our_area = loc.loc

	//if area isn't specified use current
	if(areastring)
		area = get_area_instance_from_text(areastring)
		if(!area)
			area = our_area
			stack_trace("Bad areastring path for [src], [areastring]")
	else if(isarea(our_area) && areastring == null)
		area = our_area

	if(auto_name)
		name = "\improper [get_area_name(area, TRUE)] APC"

	if(area)
		if(area.apc)
			log_mapping("Duplicate APC created at [AREACOORD(src)] [area.type]. Original at [AREACOORD(area.apc)] [area.type].")
		area.apc = src

	update_appearance()

	make_terminal()

	addtimer(CALLBACK(src, PROC_REF(update)), 5)

/obj/machinery/power/apc/add_context_self(datum/screentip_context/context, mob/user)
	context.add_alt_click_action("Unlock interface")
	if (context.accept_silicons())
		context.add_ctrl_click_action("Toggle Power")

/obj/machinery/power/apc/examine(mob/user)
	. = ..()
	if(machine_stat & BROKEN)
		return
	if(opened)
		if(has_electronics && terminal)
			. += "The cover is [opened==APC_COVER_REMOVED?"removed":"open"] and the power cell is [ cell ? "installed" : "missing"]."
		else
			. += "It's [ !terminal ? "not" : "" ] wired up.\n"+\
			"The electronics are[!has_electronics?"n't":""] installed."
		if(integration_cog || (user.hallucinating() && prob(20)))
			. += "A small cogwheel is inside of it."

	else
		if (machine_stat & MAINT)
			. += "The cover is closed. Something is wrong with it. It doesn't work."
		else if (malfhack)
			. += "The cover is broken. It may be hard to force it open."
		else
			. += "The cover is closed."

	. += span_notice("Alt-Click the APC to [ locked ? "unlock" : "lock"] the interface.")

	if(issilicon(user))
		. += span_notice("Ctrl-Click the APC to switch the breaker [ operating ? "off" : "on"].")

/obj/machinery/power/apc/AltClick(mob/user)
	if(!user.canUseTopic(src, !issilicon(user)) || !isturf(loc))
		return
	else
		togglelock(user)

/obj/machinery/power/apc/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(!(machine_stat & BROKEN))
			set_broken()
		if(opened != APC_COVER_REMOVED)
			opened = APC_COVER_REMOVED
			coverlocked = FALSE
			visible_message(span_warning("The APC cover is knocked down!"))
			update_appearance()
	qdel(src)

/obj/machinery/power/apc/ui_state(mob/user)
	if(isAI(user))
		var/mob/living/silicon/ai/AI = user
		if(AI.apc_override == src)
			return GLOB.conscious_state
	if(iseminence(user) && integration_cog)
		return GLOB.conscious_state
	return GLOB.default_state

/obj/machinery/power/apc/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)

	if(!ui)
		ui = new(user, src, "Apc")
		ui.open()
		ui.set_autoupdate(TRUE) // Power level, reboot timer

/obj/machinery/power/apc/ui_data(mob/user)
	var/list/data = list(
		"locked" = locked,
		"failTime" = failure_timer,
		"isOperating" = operating,
		"externalPower" = main_status,
		"powerCellStatus" = cell ? cell.percent() : null,
		"chargeMode" = chargemode,
		"chargingStatus" = charging,
		"totalLoad" = display_power(lastused_total),
		"coverLocked" = coverlocked,
		"siliconUser" = user.has_unlimited_silicon_privilege || user.using_power_flow_console(),
		"malfStatus" = get_malf_status(user),
		"emergencyLights" = !emergency_lights,
		"nightshiftLights" = nightshift_lights,

		"powerChannels" = list(
			list(
				"title" = "Equipment",
				"powerLoad" = display_power(lastused_equip),
				"status" = equipment,
				"topicParams" = list(
					"auto" = list("eqp" = 3),
					"on"   = list("eqp" = 2),
					"off"  = list("eqp" = 1)
				)
			),
			list(
				"title" = "Lighting",
				"powerLoad" = display_power(lastused_light),
				"status" = lighting,
				"topicParams" = list(
					"auto" = list("lgt" = 3),
					"on"   = list("lgt" = 2),
					"off"  = list("lgt" = 1)
				)
			),
			list(
				"title" = "Environment",
				"powerLoad" = display_power(lastused_environ),
				"status" = environ,
				"topicParams" = list(
					"auto" = list("env" = 3),
					"on"   = list("env" = 2),
					"off"  = list("env" = 1)
				)
			)
		)
	)
	return data

/obj/machinery/power/apc/proc/report()
	return "[area.name] : [equipment]/[lighting]/[environ] ([lastused_equip+lastused_light+lastused_environ]) : [cell? cell.percent() : "N/C"] ([charging])"

/obj/machinery/power/apc/ui_status(mob/user)
	. = ..()
	if (!QDELETED(remote_control) && user == remote_control.operator)
		. = UI_INTERACTIVE

/obj/machinery/power/apc/ui_act(action, params)
	if(..() || !can_use(usr, 1))
		return

	switch(action)
		if("reboot")
			if(failure_timer)
				failure_timer = 0
				update_appearance()
				update()
				. = TRUE

	if(locked && !usr.has_unlimited_silicon_privilege)
		return

	switch(action)
		if("lock")
			if(usr.has_unlimited_silicon_privilege)
				if((obj_flags & EMAGGED) || (machine_stat & (BROKEN|MAINT)))
					to_chat(usr, "The APC does not respond to the command.")
				else
					locked = !locked
					update_appearance()
					. = TRUE
		if("cover")
			coverlocked = !coverlocked
			. = TRUE
		if("breaker")
			toggle_breaker(usr)
			. = TRUE
		if("toggle_nightshift")
			toggle_nightshift_lights()
			. = TRUE
		if("charge")
			chargemode = !chargemode
			if(!chargemode)
				charging = APC_NOT_CHARGING
				update_appearance()
			. = TRUE
		if("channel")
			if(params["eqp"])
				equipment = setsubsystem(text2num(params["eqp"]))
				update_appearance()
				update()
			else if(params["lgt"])
				lighting = setsubsystem(text2num(params["lgt"]))
				update_appearance()
				update()
			else if(params["env"])
				environ = setsubsystem(text2num(params["env"]))
				update_appearance()
				update()
			else
				return FALSE
			. = TRUE
		if("overload")
			if(usr.has_unlimited_silicon_privilege)
				overload_lighting()
				. = TRUE
		if("hack")
			if(get_malf_status(usr))
				malfhack(usr)
				. = TRUE
		if("occupy")
			if(get_malf_status(usr))
				malfoccupy(usr)
				. = TRUE
		if("deoccupy")
			if(get_malf_status(usr))
				malfvacate()
				. = TRUE
		if("emergency_lighting")
			emergency_lights = !emergency_lights
			for(var/obj/machinery/light/L in area)
				if(!initial(L.no_emergency)) //If there was an override set on creation, keep that override
					L.no_emergency = emergency_lights
					INVOKE_ASYNC(L, TYPE_PROC_REF(/obj/machinery/light, update), FALSE)
				CHECK_TICK
			. = TRUE

	if(.)
		wires.ui_update() // I don't know why this would be here, but I'm too scared to remove it

/obj/machinery/power/apc/ui_close(mob/user, datum/tgui/tgui)
	if(isAI(user))
		var/mob/living/silicon/ai/AI = user
		if(AI.apc_override == src)
			AI.apc_override = null

/obj/machinery/power/apc/process()
	if(icon_update_needed)
		update_appearance()
	if(machine_stat & (BROKEN|MAINT))
		return
	if(!area || !area.requires_power)
		return
	if(failure_timer)
		failure_timer--
		force_update = TRUE
		return

//dont use any power from that channel if we shut that power channel off
	lastused_light = APC_CHANNEL_IS_ON(lighting) ? area.power_usage[AREA_USAGE_LIGHT] + area.power_usage[AREA_USAGE_STATIC_LIGHT] : 0
	lastused_equip = APC_CHANNEL_IS_ON(equipment) ? area.power_usage[AREA_USAGE_EQUIP] + area.power_usage[AREA_USAGE_STATIC_EQUIP] : 0
	lastused_environ = APC_CHANNEL_IS_ON(environ) ? area.power_usage[AREA_USAGE_ENVIRON] + area.power_usage[AREA_USAGE_STATIC_ENVIRON] : 0
	area.clear_usage()

	lastused_total = lastused_light + lastused_equip + lastused_environ

	//store states to update icon if any change
	var/last_lt = lighting
	var/last_eq = equipment
	var/last_en = environ
	var/last_ch = charging

	var/excess = surplus()

	if(!src.avail())
		main_status = APC_NO_POWER
	else if(excess < 0)
		main_status = APC_LOW_POWER
	else
		main_status = APC_HAS_POWER

	var/cellused
	if(cell && !shorted)
		// draw power from cell as before to power the area
		cellused = min(cell.charge, lastused_total JOULES)	// clamp deduction to a max, amount left in cell
		cell.use(cellused)

	if(cell && !shorted) //need to check to make sure the cell is still there since rigged cells can randomly explode after use().
		if(excess > lastused_total)	// if power excess recharge the cell
										// by the same amount just used
			cell.give(cellused)
			if(cell) //make sure the cell didn't expode and actually used power.
				add_load(cellused WATTS) // add the load used to recharge the cell


		else // no excess, and not enough per-apc
			if((cell.charge WATTS + excess) >= lastused_total) // can we draw enough from cell+grid to cover last usage?
				cell.charge = min(cell.maxcharge, cell.charge + excess JOULES) //recharge with what we can
				add_load(excess) // so draw what we can from the grid
				charging = APC_NOT_CHARGING

			else // not enough power available to run the last tick!
				charging = APC_NOT_CHARGING
				chargecount = 0
				// This turns everything off in the case that there is still a charge left on the battery, just not enough to run the room.
				equipment = autoset(equipment, AUTOSET_FORCE_OFF)
				lighting = autoset(lighting, AUTOSET_FORCE_OFF)
				environ = autoset(environ, AUTOSET_FORCE_OFF)

	if(cell && !shorted) //need to check to make sure the cell is still there since rigged cells can randomly explode after give().

		// set channels depending on how much charge we have left

		// Allow the APC to operate as normal if the cell can charge
		if(charging && longtermpower < 10)
			longtermpower += 1
		else if(longtermpower > -10)
			longtermpower -= 2

		if(cell.charge <= 0) // zero charge, turn all off
			equipment = autoset(equipment, AUTOSET_FORCE_OFF)
			lighting = autoset(lighting, AUTOSET_FORCE_OFF)
			environ = autoset(environ, AUTOSET_FORCE_OFF)
			alarm_manager.send_alarm(ALARM_POWER)

		else if(cell.percent() < 20 && longtermpower < 0) // <25%, turn off lighting & equipment
			equipment = autoset(equipment, AUTOSET_OFF)
			lighting = autoset(lighting, AUTOSET_OFF)
			environ = autoset(environ, AUTOSET_ON)
			alarm_manager.send_alarm(ALARM_POWER)

		else if(cell.percent() < 50 && longtermpower < 0) // <50%, turn off lighting
			equipment = autoset(equipment, AUTOSET_ON)
			lighting = autoset(lighting, AUTOSET_OFF)
			environ = autoset(environ, AUTOSET_ON)
			alarm_manager.send_alarm(ALARM_POWER)

		else // otherwise all can be on
			equipment = autoset(equipment, AUTOSET_ON)
			lighting = autoset(lighting, AUTOSET_ON)
			environ = autoset(environ, AUTOSET_ON)
			if(cell.percent() > 75)
				alarm_manager.clear_alarm(ALARM_POWER)

		if(integration_cog)
			alarm_manager.clear_alarm(ALARM_POWER)

		// now trickle-charge the cell
		if(chargemode && charging == APC_CHARGING && operating)
			if(excess > 0) // check to make sure we have enough to charge
				// Max charge is capped to % per second constant
				var/ch = min(excess JOULES, cell.maxcharge JOULES)
				add_load(ch/GLOB.CELLRATE) // Removes the power we're taking from the grid
				cell.give(ch) // actually recharge the cell

			else
				charging = APC_NOT_CHARGING // stop charging
				chargecount = 0

		// show cell as fully charged if so
		if(cell.charge >= cell.maxcharge)
			cell.charge = cell.maxcharge
			charging = APC_FULLY_CHARGED

		if(chargemode)
			if(!charging)
				if(excess > cell.maxcharge * GLOB.CHARGELEVEL)
					chargecount++
				else
					chargecount = 0
				if(chargecount == 10)
					chargecount = 0
					charging = APC_CHARGING

		else // chargemode off
			charging = APC_NOT_CHARGING
			chargecount = 0

		//=====Clock Cult=====
		if(integration_cog && cell.charge >= cell.maxcharge/2)
			var/power_delta = clamp(cell.charge - 20, 0, 20)
			GLOB.clockcult_power += power_delta
			cell.charge -= power_delta

		/// Sounds for power off and on stages in APCs
		if(ISINRANGE(cell.percent(), 14, 16) && charging == APC_NOT_CHARGING && apc_sound_stage != 1)
			playsound(src, 'sound/machines/apc/PowerSwitch_Place.ogg', 20, 1)
			apc_sound_stage = 1
		if(ISINRANGE(cell.percent(), 29, 31) && charging == APC_NOT_CHARGING && apc_sound_stage != 2)
			playsound(src, 'sound/machines/apc/PowerSwitch_Off.ogg', 10, 1)
			apc_sound_stage = 2
		if(ISINRANGE(cell.percent(), 1, 3) && charging == APC_NOT_CHARGING  && apc_sound_stage != 3)
			playsound(src, 'sound/machines/apc/PowerDown_001.ogg', 10, 1)
			apc_sound_stage = 3
		if(ISINRANGE(cell.percent(), 1, 3) && charging == APC_CHARGING && apc_sound_stage != 4)
			playsound(src, 'sound/machines/apc/PowerUp_001.ogg', 10, 1)
			apc_sound_stage = 4

	else // no cell, switch everything off

		charging = APC_NOT_CHARGING
		chargecount = 0

		equipment = autoset(equipment, AUTOSET_FORCE_OFF)
		lighting = autoset(lighting, AUTOSET_FORCE_OFF)
		environ = autoset(environ, AUTOSET_FORCE_OFF)
		alarm_manager.send_alarm(ALARM_POWER)

	// update icon & area power if anything changed

	if(last_lt != lighting || last_eq != equipment || last_en != environ || force_update)
		force_update = FALSE
		queue_icon_update()
		update()
	else if (last_ch != charging)
		queue_icon_update()

/*Power module, used for APC construction*/
/obj/item/electronics/apc
	name = "power control module"
	icon_state = "power_mod"
	custom_price = 5
	desc = "Heavy-duty switching circuits for power control."
