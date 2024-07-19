/datum/map_generator/deep_jungle_generator
	// just superdeep please
	var/list/possible_biomes = list(
		BIOME_LOW_HEAT = list(
			BIOME_LOW_HUMIDITY = /datum/biome/jungle/superdeep,
			BIOME_LOWMEDIUM_HUMIDITY = /datum/biome/jungle/superdeep,
			BIOME_HIGHMEDIUM_HUMIDITY = /datum/biome/jungle/superdeep,
			BIOME_HIGH_HUMIDITY = /datum/biome/jungle/superdeep
		),
		BIOME_LOWMEDIUM_HEAT = list(
			BIOME_LOW_HUMIDITY = /datum/biome/jungle/superdeep,
			BIOME_LOWMEDIUM_HUMIDITY = /datum/biome/jungle/superdeep,
			BIOME_HIGHMEDIUM_HUMIDITY = /datum/biome/jungle/superdeep,
			BIOME_HIGH_HUMIDITY = /datum/biome/jungle/superdeep
		),
		BIOME_HIGHMEDIUM_HEAT = list(
			BIOME_LOW_HUMIDITY = /datum/biome/jungle/superdeep,
			BIOME_LOWMEDIUM_HUMIDITY = /datum/biome/jungle/superdeep,
			BIOME_HIGHMEDIUM_HUMIDITY = /datum/biome/jungle/superdeep,
			BIOME_HIGH_HUMIDITY = /datum/biome/jungle/superdeep
		),
		BIOME_HIGH_HEAT = list(
			BIOME_LOW_HUMIDITY = /datum/biome/jungle/superdeep,
			BIOME_LOWMEDIUM_HUMIDITY = /datum/biome/jungle/superdeep,
			BIOME_HIGHMEDIUM_HUMIDITY = /datum/biome/jungle/superdeep,
			BIOME_HIGH_HUMIDITY = /datum/biome/jungle/superdeep
		)
	)

	var/perlin_zoom = 65

/datum/map_generator/deep_jungle_generator/generate_terrain(list/turfs, area/generate_in)
	. = ..()
	var/humidity_seed = rand(0, 50000)
	var/heat_seed = rand(0, 50000)

	for(var/t in turfs)
		var/turf/gen_turf = t
		var/BIOME_RANDOM_SQUARE_DRIFT = 2
		var/drift_x = (gen_turf.x + rand(-BIOME_RANDOM_SQUARE_DRIFT, BIOME_RANDOM_SQUARE_DRIFT)) / perlin_zoom
		var/drift_y = (gen_turf.y + rand(-BIOME_RANDOM_SQUARE_DRIFT, BIOME_RANDOM_SQUARE_DRIFT)) / perlin_zoom

		var/datum/biome/selected_biome
		var/humidity = text2num(rustg_noise_get_at_coordinates("[humidity_seed]", "[drift_x]", "[drift_y]"))
		var/heat = text2num(rustg_noise_get_at_coordinates("[heat_seed]", "[drift_x]", "[drift_y]"))
		var/heat_level
		var/humidity_level

		switch(heat)
			if(0 to 0.25)
				heat_level = BIOME_LOW_HEAT
			if(0.25 to 0.5)
				heat_level = BIOME_LOWMEDIUM_HEAT
			if(0.5 to 0.75)
				heat_level = BIOME_HIGHMEDIUM_HEAT
			if(0.75 to 1)
				heat_level = BIOME_HIGH_HEAT
		switch(humidity)
			if(0 to 0.25)
				humidity_level = BIOME_LOW_HUMIDITY
			if(0.25 to 0.5)
				humidity_level = BIOME_LOWMEDIUM_HUMIDITY
			if(0.5 to 0.75)
				humidity_level = BIOME_HIGHMEDIUM_HUMIDITY
			if(0.75 to 1)
				humidity_level = BIOME_HIGH_HUMIDITY

		selected_biome = possible_biomes[heat_level][humidity_level]
		selected_biome = SSmapping.biomes[selected_biome]
		selected_biome.generate_turf(gen_turf)
		CHECK_TICK
