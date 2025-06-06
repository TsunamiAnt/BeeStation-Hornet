/*! How material datums work
Materials are now instanced datums, with an associative list of them being kept in SSmaterials. We only instance the materials once and then re-use these instances for everything.

These materials call on_applied() on whatever item they are applied to, common effects are adding components, changing color and changing description. This allows us to differentiate items based on the material they are made out of.area

*/

SUBSYSTEM_DEF(materials)
	name = "Materials"
	flags = SS_NO_FIRE | SS_NO_INIT
	///Dictionary of material.type || material ref
	var/list/materials
	///Dictionary of category || list of material refs
	var/list/materials_by_category
	///Dictionary of category || list of material types, mostly used by rnd machines like autolathes.
	var/list/materialtypes_by_category
	///A cache of all material combinations that have been used
	var/list/list/material_combos
	///List of stackcrafting recipes for materials using rigid materials
	var/list/rigid_stack_recipes = list(
		new /datum/stack_recipe("Chair", /obj/structure/chair/greyscale, crafting_flags = CRAFT_CHECK_DENSITY | CRAFT_ONE_PER_TURF | CRAFT_ON_SOLID_GROUND | CRAFT_APPLIES_MATS, category = CAT_FURNITURE),
		new /datum/stack_recipe("Material floor tile", /obj/item/stack/tile/material, 1, 4, 20, crafting_flags = CRAFT_APPLIES_MATS, category = CAT_TILES),
	)

///Ran on initialize, populated the materials and materials_by_category dictionaries with their appropiate vars (See these variables for more info)
/datum/controller/subsystem/materials/proc/InitializeMaterials()
	materials = list()
	materials_by_category = list()
	materialtypes_by_category = list()
	material_combos = list()
	for(var/type in subtypesof(/datum/material))
		var/datum/material/ref = type
		if(!(initial(ref.init_flags) & MATERIAL_INIT_MAPLOAD))
			continue // Do not initialize

		ref = new ref
		materials[type] = ref
		for(var/c in ref.categories)
			materials_by_category[c] += list(ref)
			materialtypes_by_category[c] += list(type)

		// Adds the dupe recipes into multiple material recipes
		var/list/global_mat_recipes = ref.get_material_recipes()
		if(global_mat_recipes)
			if(ref.categories[MAT_CATEGORY_BASE_RECIPES])
				global_mat_recipes += SSmaterials.rigid_stack_recipes.Copy()
			/* put more material recipes here. example:
			if(ref.categories[MAT_CATEGORY_SOME_NEW_RECIPES])
				global_mat_recipes += SSmaterials.SOME_NEW_RECIPES.Copy()
			*/

/datum/controller/subsystem/materials/proc/GetMaterialRef(datum/material/fakemat)
	if(!materials)
		InitializeMaterials()
	return materials[fakemat] || fakemat

///Returns a list to be used as an object's custom_materials. Lists will be cached and re-used based on the parameters.
/datum/controller/subsystem/materials/proc/FindOrCreateMaterialCombo(list/materials_declaration, multiplier)
	if(!material_combos)
		InitializeMaterials()
	var/list/combo_params = list()
	for(var/x in materials_declaration)
		var/datum/material/mat = x
		var/path_name = ispath(mat) ? "[mat]" : "[mat.type]"
		combo_params += "[path_name]=[materials_declaration[mat] * multiplier]"
	sortTim(combo_params, /proc/cmp_text_asc) // We have to sort now in case the declaration was not in order
	var/combo_index = combo_params.Join("-")
	var/list/combo = material_combos[combo_index]
	if(!combo)
		combo = list()
		for(var/mat in materials_declaration)
			combo[GetMaterialRef(mat)] = materials_declaration[mat] * multiplier
		material_combos[combo_index] = combo
	return combo
