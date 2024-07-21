/datum/map_generator/deep_jungle_generator
	// just lair jungle please. Slight Jank but who cares.

/datum/map_generator/deep_jungle_generator/generate_terrain(list/turfs, area/generate_in)
	. = ..()

	for(var/t in turfs)
		var/turf/gen_turf = t

		var/datum/biome/selected_biome

		selected_biome = SSmapping.biomes[/datum/biome/lairjungle]
		selected_biome.generate_turf(gen_turf)
		CHECK_TICK
