// ********************************************************
// Here's all the seeds (plants) that can be used in hydro
// ********************************************************

/obj/item/seeds
	name = "seed"
	icon = 'icons/obj/hydroponics/seeds.dmi'
	icon_state = "seed" // Unknown plant seed - these shouldn't exist in-game.
	worn_icon_state = "seed"
	w_class = WEIGHT_CLASS_TINY
	resistance_flags = FLAMMABLE
	tool_behaviour = TOOL_SEED
	var/plantname = "Plants"		// Name of plant when planted.
	var/plantdesc
	var/product						// A type path. The thing that is created when the plant is harvested.
	var/species = ""				// Used to update icons. Should match the name in the sprites unless all icon_* are overridden.

	///the file that stores the sprites of the growing plant from this seed.
	var/growing_icon = 'icons/obj/hydroponics/growing.dmi'
	var/icon_grow					// Used to override grow icon (default is "[species]-grow"). You can use one grow icon for multiple closely related plants with it.
	var/icon_dead					// Used to override dead icon (default is "[species]-dead"). You can use one dead icon for multiple closely related plants with it.
	var/icon_harvest				// Used to override harvest icon (default is "[species]-harvest"). If null, plant will use [icon_grow][growthstages].

	var/lifespan = 25				// How long before the plant begins to take damage from age.
	var/endurance = 15				// Amount of health the plant has.
	var/maturation = 6				// Used to determine which sprite to switch to when growing.
	var/production = 6				// Changes the amount of time needed for a plant to become harvestable.
	var/yield = 3					// Amount of growns created per harvest. If is -1, the plant/shroom/weed is never meant to be harvested.
	var/potency = 10				// The 'power' of a plant. Generally effects the amount of reagent in a plant, also used in other ways.
	var/growthstages = 6			// Amount of growth sprites the plant has.
	var/rarity = 0					// How rare the plant is. Used for giving points to cargo when shipping off to CentCom.
	var/list/mutatelist = list()	// The type of plants that this plant can mutate into.
	var/list/genes = list()			// Plant genes are stored here, see plant_genes.dm for more info.
	var/datum/mind/mind				// For if the seed can hold a mind. Used for diona related stuffs.
	var/list/reagents_add = list()
	// A list of reagents to add to product.
	// Format: "reagent_id" = potency multiplier
	// Stronger reagents must always come first to avoid being displaced by weaker ones.
	// Total amount of any reagent in plant is calculated by formula: 1 + round(potency * multiplier)

	var/weed_rate = 1 //If the chance below passes, then this many weeds sprout during growth
	var/weed_chance = 5 //Percentage chance per tray update to grow weeds

CREATION_TEST_IGNORE_SUBTYPES(/obj/item/seeds)

/obj/item/seeds/Initialize(mapload, nogenes = 0)
	. = ..()
	pixel_x = base_pixel_y + rand(-8, 8)
	pixel_y = base_pixel_x + rand(-8, 8)

	if(!icon_grow)
		icon_grow = "[species]-grow"

	if(!icon_dead)
		icon_dead = "[species]-dead"

	if(!icon_harvest && !get_gene(/datum/plant_gene/trait/plant_type/fungal_metabolism) && yield != -1)
		icon_harvest = "[species]-harvest"

	if(!nogenes) // not used on Copy()
		genes += new /datum/plant_gene/core/lifespan(lifespan)
		genes += new /datum/plant_gene/core/endurance(endurance)
		genes += new /datum/plant_gene/core/weed_rate(weed_rate)
		genes += new /datum/plant_gene/core/weed_chance(weed_chance)
		if(yield != -1)
			genes += new /datum/plant_gene/core/yield(yield)
			genes += new /datum/plant_gene/core/production(production)
		if(potency != -1)
			genes += new /datum/plant_gene/core/potency(potency)

		for(var/p in genes)
			if(ispath(p))
				genes -= p
				genes += new p

		for(var/reag_id in reagents_add)
			genes += new /datum/plant_gene/reagent(reag_id, reagents_add[reag_id])
		reagents_from_genes() //quality coding

/obj/item/seeds/proc/Copy()
	var/obj/item/seeds/S = new type(null, 1)
	// Copy all the stats
	S.lifespan = lifespan
	S.endurance = endurance
	S.maturation = maturation
	S.production = production
	S.yield = yield
	S.potency = potency
	S.weed_rate = weed_rate
	S.weed_chance = weed_chance
	S.name = name
	S.plantname = plantname
	S.desc = desc
	S.plantdesc = plantdesc
	S.genes = list()
	for(var/g in genes)
		var/datum/plant_gene/G = g
		S.genes += G.Copy()
	S.reagents_add = reagents_add.Copy() // Faster than grabbing the list from genes.
	return S

/obj/item/seeds/proc/get_gene(typepath)
	return (locate(typepath) in genes)

/obj/item/seeds/proc/reagents_from_genes()
	reagents_add = list()
	for(var/datum/plant_gene/reagent/R in genes)
		reagents_add[R.reagent_id] = R.rate

///This proc adds a mutability_flag to a gene
/obj/item/seeds/proc/set_mutability(typepath, mutability)
	var/datum/plant_gene/g = get_gene(typepath)
	if(g)
		g.mutability_flags |=  mutability

///This proc removes a mutability_flag from a gene
/obj/item/seeds/proc/unset_mutability(typepath, mutability)
	var/datum/plant_gene/g = get_gene(typepath)
	if(g)
		g.mutability_flags &=  ~mutability

/obj/item/seeds/proc/mutate(lifemut = 2, endmut = 5, productmut = 1, yieldmut = 2, potmut = 25, wrmut = 2, wcmut = 5, traitmut = 0)
	adjust_lifespan(rand(-lifemut,lifemut))
	adjust_endurance(rand(-endmut,endmut))
	adjust_production(rand(-productmut,productmut))
	adjust_yield(rand(-yieldmut,yieldmut))
	adjust_potency(rand(-potmut,potmut))
	adjust_weed_rate(rand(-wrmut, wrmut))
	adjust_weed_chance(rand(-wcmut, wcmut))
	if(prob(traitmut))
		add_random_traits(1, 1)



/obj/item/seeds/bullet_act(obj/projectile/Proj) //Works with the Somatoray to modify plant variables.
	if(istype(Proj, /obj/projectile/energy/florayield))
		var/rating = 1
		if(istype(loc, /obj/machinery/hydroponics))
			var/obj/machinery/hydroponics/H = loc
			rating = H.rating

		if(yield == 0)//Oh god don't divide by zero you'll doom us all.
			adjust_yield(1 * rating)
		else if(prob(1/(yield * yield) * 100))//This formula gives you diminishing returns based on yield. 100% with 1 yield, decreasing to 25%, 11%, 6, 4, 2...
			adjust_yield(1 * rating)
	else
		return ..()


// Harvest procs
/obj/item/seeds/proc/getYield()
	var/return_yield = yield

	var/obj/machinery/hydroponics/parent = loc
	if(istype(loc, /obj/machinery/hydroponics))
		if(parent.yieldmod == 0)
			return_yield = min(return_yield, 1)//1 if above zero, 0 otherwise
		else
			return_yield *= (parent.yieldmod)

	return return_yield


/obj/item/seeds/proc/harvest(mob/user)
	var/obj/machinery/hydroponics/parent = loc //for ease of access
	var/t_amount = 0
	var/list/result = list()
	var/output_loc = parent.Adjacent(user) ? user.loc : parent.loc //needed for TK
	var/product_name
	while(t_amount < getYield())
		var/obj/item/food/grown/t_prod = new product(output_loc, src)
		if(parent.myseed.plantname != initial(parent.myseed.plantname))
			t_prod.name = parent.myseed.plantname
		if(parent.myseed.plantdesc)
			t_prod.desc = parent.myseed.plantdesc
		t_prod.seed.name = parent.myseed.name
		t_prod.seed.desc = parent.myseed.desc
		t_prod.seed.plantname = parent.myseed.plantname
		t_prod.seed.plantdesc = parent.myseed.plantdesc
		result.Add(t_prod) // User gets a consumable
		if(!t_prod)
			return
		t_amount++
		product_name = t_prod.seed.plantname
	if(getYield() >= 1)
		SSblackbox.record_feedback("tally", "food_harvested", getYield(), product_name)
		var/investigated_plantname = get_product_true_name_for_investigate()
		if(!investigated_plantname)
			log_game("[key_name(user)] harvested [name]/Location: [AREACOORD(user)]")
			user.investigate_log("harvested [name]/Location: [AREACOORD(user)]", INVESTIGATE_BOTANY)
		else
			var/investigate_data = get_gene_datas_for_investigate()
			log_game("[key_name(user)] harvested [getYield()] of [investigated_plantname]/[investigate_data]/Location: [AREACOORD(user)]")
			user.investigate_log("harvested [getYield()] of [investigated_plantname]/[investigate_data]/Location: [AREACOORD(user)]", INVESTIGATE_BOTANY)
	parent.update_tray(user)

	return result


/obj/item/seeds/proc/prepare_result(obj/item/T)
	if(!T.reagents)
		CRASH("[T] has no reagents.")

	var/output_multiply = 1
	var/datum/plant_gene/trait/richer_juice/richer_juice = locate(/datum/plant_gene/trait/richer_juice) in genes
	if(richer_juice)
		output_multiply = richer_juice.rate

	for(var/rid in reagents_add)
		var/amount = (1 + round(potency * reagents_add[rid], 1)) * output_multiply

		var/list/data = null
		if(rid == /datum/reagent/blood) // Hack to make blood in plants always O-
			data = list("blood_type" = "O-")
		if(rid == /datum/reagent/consumable/nutriment || rid == /datum/reagent/consumable/nutriment/vitamin)
			// apple tastes of apple.
			if(istype(T, /obj/item/food/grown))
				var/obj/item/food/grown/grown_edible = T
				data = grown_edible.tastes

		T.reagents.add_reagent(rid, amount, data)

//--------- For investigation
/obj/item/seeds/proc/get_gene_datas_for_investigate()
	var/list/gene_result = list()
	for(var/datum/plant_gene/trait/each_gene in genes)
		if(istype(each_gene, /datum/plant_gene/trait/plant_type))
			continue
		gene_result += "[each_gene.name]"

	var/list/chem_result = list()
	for(var/datum/plant_gene/reagent/each_gene in genes)
		chem_result += "[each_gene.name] [each_gene.rate*100]%"

	var/return_text_format
	var/datum/plant_gene/core/C = get_gene(/datum/plant_gene/core/potency)
	return_text_format = "potency: [C.value]"
	if(length(gene_result))
		return_text_format = "/traits: [english_list(gene_result)]"
	else
		return_text_format = "/no traits"
	if(length(chem_result))
		return_text_format = "[return_text_format]/chems: [english_list(chem_result)]"
	else
		return_text_format = "[return_text_format]/no chems"

	return return_text_format

/obj/item/seeds/proc/get_product_true_name_for_investigate()
	if(!product)
		return FALSE
	var/obj/plant = product
	if(plantname == initial(plantname))
		return initial(plant.name)
	else
		return "[initial(plant.name)] (renamed as [plantname])"
//---------

/// Setters procs ///
/obj/item/seeds/proc/adjust_yield(adjustamt)
	if(yield != -1) // Unharvestable shouldn't suddenly turn harvestable
		yield = clamp(yield + adjustamt, 0, 10)

		if(yield <= 0 && get_gene(/datum/plant_gene/trait/plant_type/fungal_metabolism))
			yield = 1 // Mushrooms always have a minimum yield of 1.
		var/datum/plant_gene/core/C = get_gene(/datum/plant_gene/core/yield)
		if(C)
			C.value = yield

/obj/item/seeds/proc/adjust_lifespan(adjustamt)
	lifespan = clamp(lifespan + adjustamt, 10, 100)
	var/datum/plant_gene/core/C = get_gene(/datum/plant_gene/core/lifespan)
	if(C)
		C.value = lifespan

/obj/item/seeds/proc/adjust_endurance(adjustamt)
	endurance = clamp(endurance + adjustamt, 10, 100)
	var/datum/plant_gene/core/C = get_gene(/datum/plant_gene/core/endurance)
	if(C)
		C.value = endurance

/obj/item/seeds/proc/adjust_production(adjustamt)
	if(yield != -1)
		production = clamp(production + adjustamt, 1, 10)
		var/datum/plant_gene/core/C = get_gene(/datum/plant_gene/core/production)
		if(C)
			C.value = production

/obj/item/seeds/proc/adjust_potency(adjustamt)
	if(potency != -1)
		potency = clamp(potency + adjustamt, 0, 100)
		var/datum/plant_gene/core/C = get_gene(/datum/plant_gene/core/potency)
		if(C)
			C.value = potency

/obj/item/seeds/proc/adjust_weed_rate(adjustamt)
	weed_rate = clamp(weed_rate + adjustamt, 0, 10)
	var/datum/plant_gene/core/C = get_gene(/datum/plant_gene/core/weed_rate)
	if(C)
		C.value = weed_rate

/obj/item/seeds/proc/adjust_weed_chance(adjustamt)
	weed_chance = clamp(weed_chance + adjustamt, 0, 67)
	var/datum/plant_gene/core/C = get_gene(/datum/plant_gene/core/weed_chance)
	if(C)
		C.value = weed_chance

//Directly setting stats

/obj/item/seeds/proc/set_yield(adjustamt)
	if(yield != -1) // Unharvestable shouldn't suddenly turn harvestable
		yield = clamp(adjustamt, 0, 10)

		if(yield <= 0 && get_gene(/datum/plant_gene/trait/plant_type/fungal_metabolism))
			yield = 1 // Mushrooms always have a minimum yield of 1.
		var/datum/plant_gene/core/C = get_gene(/datum/plant_gene/core/yield)
		if(C)
			C.value = yield

/obj/item/seeds/proc/set_lifespan(adjustamt)
	lifespan = clamp(adjustamt, 10, 100)
	var/datum/plant_gene/core/C = get_gene(/datum/plant_gene/core/lifespan)
	if(C)
		C.value = lifespan

/obj/item/seeds/proc/set_endurance(adjustamt)
	endurance = clamp(adjustamt, 10, 100)
	var/datum/plant_gene/core/C = get_gene(/datum/plant_gene/core/endurance)
	if(C)
		C.value = endurance

/obj/item/seeds/proc/set_production(adjustamt)
	if(yield != -1)
		production = clamp(adjustamt, 1, 10)
		var/datum/plant_gene/core/C = get_gene(/datum/plant_gene/core/production)
		if(C)
			C.value = production

/obj/item/seeds/proc/set_potency(adjustamt)
	if(potency != -1)
		potency = clamp(adjustamt, 0, 100)
		var/datum/plant_gene/core/C = get_gene(/datum/plant_gene/core/potency)
		if(C)
			C.value = potency

/obj/item/seeds/proc/set_weed_rate(adjustamt)
	weed_rate = clamp(adjustamt, 0, 10)
	var/datum/plant_gene/core/C = get_gene(/datum/plant_gene/core/weed_rate)
	if(C)
		C.value = weed_rate

/obj/item/seeds/proc/set_weed_chance(adjustamt)
	weed_chance = clamp(adjustamt, 0, 67)
	var/datum/plant_gene/core/C = get_gene(/datum/plant_gene/core/weed_chance)
	if(C)
		C.value = weed_chance


/obj/item/seeds/proc/get_analyzer_text()  //in case seeds have something special to tell to the analyzer
	var/text = ""
	if(!get_gene(/datum/plant_gene/trait/plant_type/weed_hardy) && !get_gene(/datum/plant_gene/trait/plant_type/fungal_metabolism) && !get_gene(/datum/plant_gene/trait/plant_type/alien_properties))
		text += "- Plant type: Normal plant\n"
	if(get_gene(/datum/plant_gene/trait/plant_type/weed_hardy))
		text += "- Plant type: Weed. Can grow in nutrient-poor soil.\n"
	if(get_gene(/datum/plant_gene/trait/plant_type/fungal_metabolism))
		text += "- Plant type: Mushroom. Can grow in dry soil.\n"
	if(get_gene(/datum/plant_gene/trait/plant_type/alien_properties))
		text += "- Plant type: [span_warning("UNKNOWN")] \n"
	if(potency != -1)
		text += "- Potency: [potency]\n"
	if(yield != -1)
		text += "- Yield: [yield]\n"
	text += "- Maturation speed: [maturation]\n"
	if(yield != -1)
		text += "- Production speed: [production]\n"
	text += "- Endurance: [endurance]\n"
	text += "- Lifespan: [lifespan]\n"
	text += "- Weed Growth Rate: [weed_rate]\n"
	text += "- Weed Vulnerability: [weed_chance]\n"
	if(rarity)
		text += "- Species Discovery Value: [rarity]\n"
	var/all_traits = ""
	for(var/datum/plant_gene/trait/traits in genes)
		if(istype(traits, /datum/plant_gene/trait/plant_type))
			continue
		all_traits += " [traits.get_name()]"
	text += "- Plant Traits:[all_traits]\n"

	text += "*---------*"

	return text

/obj/item/seeds/proc/on_chem_reaction(datum/reagents/S)  //in case seeds have some special interaction with special chems
	return

/obj/item/seeds/attackby(obj/item/O, mob/user, params)
	if (istype(O, /obj/item/plant_analyzer))
		to_chat(user, span_info("*---------*\n This is \a [span_name("[src]")]."))
		var/text = get_analyzer_text()
		if(text)
			to_chat(user, examine_block(span_notice("[text]")))

		return

	if (istype(O, /obj/item/pen))
		var/penchoice = tgui_input_list(user, "What would you like to edit on [src]?", "Seed editing", list("Plant Name","Plant Description","Seed Description"))

		if(QDELETED(src) || !user.canUseTopic(src, BE_CLOSE))
			return

		if(penchoice == "Plant Name")
			var/input = tgui_input_text(user, "What do you want to name the plant?", "Plant Name", plantname, MAX_NAME_LEN)
			if(QDELETED(src) || !user.canUseTopic(src, BE_CLOSE))
				return
			if(!input) // empty input so we return
				to_chat(user, span_warning("You need to enter a name!"))
				return
			if(CHAT_FILTER_CHECK(input)) // check for forbidden words
				to_chat(user, span_warning("Your message contains forbidden words."))
				return
			name = "pack of [input] seeds"
			plantname = input
			renamedByPlayer = TRUE

		if(penchoice == "Plant Description")
			var/input = tgui_input_text(user, "What do you want to change the description of the plant to?", "Plant Description", plantdesc, MAX_NAME_LEN)
			if(QDELETED(src) || !user.canUseTopic(src, BE_CLOSE))
				return
			if(!input) // empty input so we return
				to_chat(user, span_warning("You need to enter a description!"))
				return
			if(CHAT_FILTER_CHECK(input)) // check for forbidden words
				to_chat(user, span_warning("Your message contains forbidden words."))
				return
			plantdesc = input

		if(penchoice == "Seed Description")
			var/input = tgui_input_text(user, "What do you want to change the description of the seeds to?", "Seed Description", desc, MAX_NAME_LEN)
			if(QDELETED(src) || !user.canUseTopic(src, BE_CLOSE))
				return
			if(!input) // empty input so we return
				to_chat(user, span_warning("You need to enter a description!"))
				return
			if(CHAT_FILTER_CHECK(input)) // check for forbidden words
				to_chat(user, span_warning("Your message contains forbidden words."))
				return
			desc = input
	..() // Fallthrough to item/attackby() so that bags can pick seeds up

/obj/item/seeds/proc/randomize_stats()
	set_lifespan(rand(25, 60))
	set_endurance(rand(15, 35))
	set_production(rand(2, 10))
	set_yield(rand(1, 10))
	set_potency(rand(10, 35))
	set_weed_rate(rand(1, 10))
	set_weed_chance(rand(5, 100))
	maturation = rand(6, 12)

/obj/item/seeds/proc/add_random_reagents(lower = 0, upper = 2)
	var/amount_random_reagents = rand(lower, upper)
	for(var/i in 1 to amount_random_reagents)
		var/random_amount = rand(4, 15) * 0.01 // this must be multiplied by 0.01, otherwise, it will not properly associate
		var/datum/plant_gene/reagent/R = new(get_random_reagent_id(CHEMICAL_RNG_BOTANY), random_amount)
		if(R.can_add(src))
			genes += R
		else
			qdel(R)
	reagents_from_genes()

/obj/item/seeds/proc/add_random_traits(lower = 0, upper = 2)
	var/amount_random_traits = rand(lower, upper)
	for(var/i in 1 to amount_random_traits)
		var/random_trait = pick((subtypesof(/datum/plant_gene/trait)-typesof(/datum/plant_gene/trait/plant_type)))
		var/datum/plant_gene/trait/T = new random_trait
		if(T.can_add(src))
			genes += T
		else
			qdel(T)

/obj/item/seeds/proc/add_random_glow()
	var/static/glow_traits  = subtypesof(/datum/plant_gene/trait/glow) - /datum/plant_gene/trait/glow/shadow
	var/random_trait = pick(glow_traits)
	var/datum/plant_gene/trait/T = new random_trait
	for(var/datum/plant_gene/trait/glow/R in genes) //Replaces the old color
		genes -= R
	genes += T

/obj/item/seeds/proc/add_random_plant_type(normal_plant_chance = 75)
	if(prob(normal_plant_chance))
		var/random_plant_type = pick(subtypesof(/datum/plant_gene/trait/plant_type))
		var/datum/plant_gene/trait/plant_type/P = new random_plant_type
		if(P.can_add(src))
			genes += P
		else
			qdel(P)
