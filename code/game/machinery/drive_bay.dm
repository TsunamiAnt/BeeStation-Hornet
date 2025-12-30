/**
 * AI Law Upload Drive Bay
 *
 * A machine used for uploading laws to silicon units.
 * Part of the new AI lawset system.
 */

/// Base power draw of the drive bay
#define DRIVE_BAY_BASE_POWER (50 WATT)
/// Variable power draw per inserted drive (0-9)
#define DRIVE_BAY_VARIABLE_POWER (25 WATT)

/obj/machinery/drive_bay
	name = "AI law server"
	desc = "A sophisticated machine used for uploading and managing laws for silicon units."
	icon = 'icons/obj/machines/drive_bay.dmi'
	icon_state = "drivebay"
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = DRIVE_BAY_BASE_POWER
	active_power_usage = DRIVE_BAY_BASE_POWER
	circuit = /obj/item/circuitboard/machine/drive_bay

	/// Boilerplate for now, just a single var
	var/drives_inserted = 0

/obj/machinery/drive_bay/Initialize(mapload)
	. = ..()
	update_power_draw()
	update_appearance()

/obj/machinery/drive_bay/examine(mob/user)
	. = ..()
	if(panel_open)
		. += span_notice("The maintenance panel is open.")

/obj/machinery/drive_bay/update_icon_state()
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN))
		icon_state = "drivebay-off"
	else
		icon_state = "drivebay"

/obj/machinery/drive_bay/update_overlays()
	. = ..()
	if(panel_open)
		. += "drivebay-panel"

/obj/machinery/drive_bay/screwdriver_act(mob/living/user, obj/item/tool)
	if(default_deconstruction_screwdriver(user, icon_state, icon_state, tool))
		update_appearance()
		return TOOL_ACT_TOOLTYPE_SUCCESS
	return FALSE

/obj/machinery/drive_bay/crowbar_act(mob/living/user, obj/item/tool)
	if(default_deconstruction_crowbar(tool))
		update_appearance()
		return TOOL_ACT_TOOLTYPE_SUCCESS
	return FALSE

/// Updates the power draw based on the amount of inserted drives
/obj/machinery/drive_bay/proc/update_power_draw()
	if(drives_inserted > 0)
		update_mode_power_usage(ACTIVE_POWER_USE, DRIVE_BAY_BASE_POWER + drives_inserted * DRIVE_BAY_VARIABLE_POWER)
	else
		update_mode_power_usage(IDLE_POWER_USE, DRIVE_BAY_BASE_POWER)

#undef DRIVE_BAY_BASE_POWER
#undef DRIVE_BAY_VARIABLE_POWER
