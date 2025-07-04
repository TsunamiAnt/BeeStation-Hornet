#define POINT_TIME (2.5 SECONDS)

/**
 * Point at an atom
 *
 * Intended to enable and standardise the pointing animation for all atoms
 *
 * Not intended as a replacement for the mob verb
 */
/atom/movable/proc/point_at(atom/pointed_atom, params = "" as text, mob/M)
	if(!isturf(loc))
		return

	if (pointed_atom in src)
		create_point_bubble(pointed_atom)
		return

	var/turf/tile = get_turf(pointed_atom)
	if (!tile)
		return

	var/turf/our_tile = get_turf(src)
	var/obj/visual = new /obj/effect/temp_visual/point(our_tile, invisibility)

	/// Set position
	var/final_x = (tile.x - our_tile.x) * world.icon_size + pointed_atom.pixel_x
	var/final_y = (tile.y - our_tile.y) * world.icon_size + pointed_atom.pixel_y
	var/list/modifiers = params2list(params)
	if(!length(modifiers) || !LAZYACCESS(modifiers, SCREEN_LOC))
		animate(visual, pixel_x = (tile.x - our_tile.x) * world.icon_size + pointed_atom.pixel_x, pixel_y = (tile.y - our_tile.y) * world.icon_size + pointed_atom.pixel_y, time = 1.7, easing = EASE_OUT)
		return
	else
		var/list/actual_view = getviewsize(M.client ? M.client.view : world.view)
		var/list/split_coords = splittext(LAZYACCESS(modifiers, SCREEN_LOC), ",")
		final_x = (text2num(splittext(split_coords[1], ":")[1]) - actual_view[1] / 2) * world.icon_size + (text2num(splittext(split_coords[1], ":")[2]) - world.icon_size)
		final_y = (text2num(splittext(split_coords[2], ":")[1]) - actual_view[2] / 2) * world.icon_size + (text2num(splittext(split_coords[2], ":")[2]) - world.icon_size)
	//

	/// Set rotation
	var/matrix/rotated_matrix = new()
	var/matrix/old_visual = visual.transform
	rotated_matrix.TurnTo(0, get_pixel_angle(-final_y, -final_x))
	visual.transform = rotated_matrix
	//

	animate(visual, pixel_x = final_x, pixel_y = final_y, time = 1.7, easing = EASE_OUT, transform = old_visual)

/atom/movable/proc/create_point_bubble(atom/pointed_atom)
	var/obj/effect/thought_bubble_effect = new

	var/mutable_appearance/thought_bubble = mutable_appearance(
		'icons/effects/effects.dmi',
		"thought_bubble",
		plane = POINT_PLANE,
		appearance_flags = KEEP_APART,
	)

	var/mutable_appearance/pointed_atom_appearance = new(pointed_atom.appearance)
	pointed_atom_appearance.blend_mode = BLEND_INSET_OVERLAY
	pointed_atom_appearance.plane = thought_bubble.plane
	pointed_atom_appearance.layer = FLOAT_LAYER
	pointed_atom_appearance.pixel_x = 0
	pointed_atom_appearance.pixel_y = 0
	thought_bubble.overlays += pointed_atom_appearance

	var/hover_outline_index = pointed_atom.get_filter_index(HOVER_OUTLINE_FILTER)
	if (!isnull(hover_outline_index))
		pointed_atom_appearance.filters.Cut(hover_outline_index, hover_outline_index + 1)

	thought_bubble.pixel_x = 16
	thought_bubble.pixel_y = 32
	thought_bubble.alpha = 200
	thought_bubble.mouse_opacity = MOUSE_OPACITY_TRANSPARENT

	var/mutable_appearance/point_visual = mutable_appearance(
		'icons/hud/screen_gen.dmi',
		"arrow",
		plane = thought_bubble.plane,
	)

	thought_bubble.overlays += point_visual

	// vis_contents is used to preserve mouse opacity
	thought_bubble_effect.appearance = thought_bubble
	vis_contents += thought_bubble_effect

	QDEL_IN(thought_bubble_effect, POINT_TIME)

/obj/effect/temp_visual/point
	name = "pointer"
	icon = 'icons/hud/screen_gen.dmi'
	icon_state = "arrow"
	plane = POINT_PLANE
	duration = POINT_TIME

CREATION_TEST_IGNORE_SUBTYPES(/obj/effect/temp_visual/point)

/obj/effect/temp_visual/point/Initialize(mapload, set_invis = 0)
	. = ..()
	var/atom/old_loc = loc
	abstract_move(get_turf(src))
	pixel_x = old_loc.pixel_x
	pixel_y = old_loc.pixel_y
	invisibility = set_invis

#undef POINT_TIME

/**
 * Point at an atom
 *
 * mob verbs are faster than object verbs. See
 * [this byond forum post](https://secure.byond.com/forum/?post=1326139&page=2#comment8198716)
 * for why this isn't atom/verb/pointed()
 *
 * note: ghosts can point, this is intended
 *
 * visible_message will handle invisibility properly
 *
 * overridden here and in /mob/dead/observer for different point span classes and sanity checks
 */
/mob/verb/pointed(atom/A as mob|obj|turf in view(), params = "" as text)
	set name = "Point To"
	set category = "Object"
	if(isnewplayer(src))
		return FALSE
	if(client && !(A in view(client.view, src)))
		return FALSE
	if(istype(A, /obj/effect/temp_visual/point))
		return FALSE
	point_at(A, params, usr)
	SEND_SIGNAL(src, COMSIG_MOB_POINTED, A)
	return TRUE
