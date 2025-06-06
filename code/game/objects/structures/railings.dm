/obj/structure/railing
	name = "railing"
	desc = "Basic railing meant to protect idiots like you from falling."
	icon = 'icons/obj/fluff.dmi'
	icon_state = "railing"
	flags_1 = ON_BORDER_1
	obj_flags = CAN_BE_HIT | BLOCKS_CONSTRUCTION_DIR
	density = TRUE
	anchored = TRUE
	pass_flags_self = LETPASSTHROW|PASSSTRUCTURE
	/// armor more or less consistent with grille. max_integrity about one time and a half that of a grille.
	armor_type = /datum/armor/structure_railing
	max_integrity = 75

	var/climbable = TRUE
	///Initial direction of the railing.
	var/ini_dir


/datum/armor/structure_railing
	melee = 50
	bullet = 70
	laser = 70
	energy = 100
	bomb = 10
	rad = 100

/obj/structure/railing/corner //aesthetic corner sharp edges hurt oof ouch
	icon_state = "railing_corner"
	density = FALSE
	climbable = FALSE

/obj/structure/railing/Initialize(mapload)
	. = ..()
	ini_dir = dir
	if(climbable)
		AddElement(/datum/element/climbable)

	if(density && (flags_1 & ON_BORDER_1)) // blocks normal movement from and to the direction it's facing.
		var/static/list/loc_connections = list(
			COMSIG_ATOM_EXIT = PROC_REF(on_exit),
		)
		AddElement(/datum/element/connect_loc, loc_connections)

	AddComponent(/datum/component/simple_rotation, ROTATION_NEEDS_ROOM)

/obj/structure/railing/attackby(obj/item/I, mob/living/user, params)
	..()
	add_fingerprint(user)

	if(I.tool_behaviour == TOOL_WELDER && !user.combat_mode)
		if(atom_integrity < max_integrity)
			if(!I.tool_start_check(user, amount=0))
				return

			to_chat(user, span_notice("You begin repairing [src]..."))
			if(I.use_tool(src, user, 40, volume=50))
				atom_integrity = max_integrity
				to_chat(user, span_notice("You repair [src]."))
		else
			to_chat(user, span_warning("[src] is already in good condition!"))
		return

/obj/structure/railing/AltClick(mob/user)
	return ..() // This hotkey is BLACKLISTED since it's used by /datum/component/simple_rotation

/obj/structure/railing/wirecutter_act(mob/living/user, obj/item/I)
	. = ..()
	if(flags_1 & NODECONSTRUCT_1)
		return
	if(!anchored)
		to_chat(user, span_warning("You begin to cut apart [src]..."))
		// Insta-disassemble is bad
		if(I.use_tool(src, user, 2.5 SECONDS))
			deconstruct()
			return TRUE

/obj/structure/railing/deconstruct(disassembled)
	if(!(flags_1 & NODECONSTRUCT_1))
		var/drop_loc = drop_location()
		var/obj/R = new /obj/item/stack/rods(drop_loc, 3)
		if(QDELETED(R)) // the rods merged with something on the tile
			R = locate(/obj/item/stack/rods) in drop_loc
		if(R)
			transfer_fingerprints_to(R)
	return ..()

///Implements behaviour that makes it possible to unanchor the railing.
/obj/structure/railing/wrench_act(mob/living/user, obj/item/I)
	. = ..()
	if(flags_1&NODECONSTRUCT_1)
		return
	to_chat(user, span_notice("You begin to [anchored ? "unfasten the railing from":"fasten the railing to"] the floor..."))
	if(I.use_tool(src, user, 1 SECONDS, volume = 75, extra_checks = CALLBACK(src, PROC_REF(check_anchored), anchored)))
		set_anchored(!anchored)
		to_chat(user, span_notice("You [anchored ? "fasten the railing to":"unfasten the railing from"] the floor."))
	return TRUE

/obj/structure/railing/CanPass(atom/movable/mover, border_dir)
	. = ..()
	if(border_dir & dir)
		return . || mover.throwing || mover.movement_type & MOVETYPES_NOT_TOUCHING_GROUND
	return TRUE

/obj/structure/railing/proc/on_exit(datum/source, atom/movable/leaving, direction)
	SIGNAL_HANDLER

	if(leaving == src)
		return // Let's not block ourselves.

	if(!(direction & dir))
		return

	if (!density)
		return

	if (leaving.throwing)
		return

	if (leaving.movement_type & (PHASING | MOVETYPES_NOT_TOUCHING_GROUND))
		return

	if (leaving.move_force >= MOVE_FORCE_EXTREMELY_STRONG)
		return

	leaving.Bump(src)
	return COMPONENT_ATOM_BLOCK_EXIT

/obj/structure/railing/proc/check_anchored(checked_anchored)
	if(anchored == checked_anchored)
		return TRUE

/obj/structure/railing/sec
	name = "checkpoint railing"
	desc = "A security wall used in checkpoints. It is just small enough that you can climb over..."
	icon_state = "railing_sec"
	layer = ABOVE_MOB_LAYER

/obj/structure/railing/sec/corner
	icon_state = "railing_corner"
	density = FALSE
	climbable = FALSE
