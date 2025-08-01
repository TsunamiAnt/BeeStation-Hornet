/datum/supply_pack
	var/name = "Crate"
	var/group = ""
	var/hidden = FALSE
	var/contraband = FALSE
	var/current_supply
	var/max_supply = 5
	var/cost = 400 // Minimum cost, or infinite points are possible. I've already had to fix it once because someone didn't listen. Don't be THAT person.
	var/access = FALSE
	var/access_budget = FALSE //prevents people from requesting stupid stuff with their department's budget via app
	var/access_any = FALSE
	var/list/contains = null
	var/crate_name = "crate"
	var/desc = ""//no desc by default
	var/crate_type = /obj/structure/closet/crate
	var/dangerous = FALSE // Should we message admins?
	var/special = FALSE //Event/Station Goals/Admin enabled packs
	var/special_enabled = FALSE
	var/DropPodOnly = FALSE//only usable by the Bluespace Drop Pod via the express cargo console
	var/admin_spawned = FALSE
	var/small_item = FALSE //Small items can be grouped into a single crate.
	var/can_secure = TRUE //Can this order be secured

/datum/supply_pack/New()
	. = ..()
	//Randomise the starting supply to promote variation in purchases. Higher tendency to have lower roundstart supply as it builds up over time.
	current_supply = rand(0, rand(1, max_supply))

/datum/supply_pack/proc/generate(atom/A, datum/bank_account/paying_account)
	var/obj/structure/closet/crate/C
	if(paying_account && can_secure)
		C = new /obj/structure/closet/crate/secure/owned(A, paying_account)
		C.name = "[crate_name] - Purchased by [paying_account.account_holder]"
	else
		C = new crate_type(A)
		C.name = crate_name
	if(access)
		C.req_access = list(access)
	if(access_any)
		C.req_one_access = access_any

	fill(C)
	return C

/datum/supply_pack/proc/get_cost()
	. = cost
	if(HAS_TRAIT(SSstation, STATION_TRAIT_DISTANT_SUPPLY_LINES))
		. *= 1.2
	else if(HAS_TRAIT(SSstation, STATION_TRAIT_STRONG_SUPPLY_LINES))
		. *= 0.8

/datum/supply_pack/proc/fill(obj/structure/closet/crate/C)
	if (admin_spawned)
		for(var/item in contains)
			var/atom/A = new item(C)
			A.flags_1 |= ADMIN_SPAWNED_1
	else
		for(var/item in contains)
			if(ispath(item))
				new item(C)
			else if(ismovable(item))
				var/atom/movable/MA = item
				MA.forceMove(C)

// If you add something to this list, please group it by type and sort it alphabetically instead of just jamming it in like an animal

//////////////////////////////////////////////////////////////////////////////
//////////////////////////// Emergency ///////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/emergency
	group = "Emergency"

/datum/supply_pack/emergency/vehicle
	name = "Biker Gang Kit" //TUNNEL SNAKES OWN THIS TOWN
	desc = "TUNNEL SNAKES OWN THIS TOWN. Contains an unbranded All Terrain Vehicle, and a complete gang outfit -- consists of black gloves, a menacing skull bandanna, and a SWEET leather overcoat!"
	cost = 1500
	contraband = TRUE
	max_supply = 2
	contains = list(
		/obj/vehicle/ridden/atv,
		/obj/item/key/atv,
		/obj/item/clothing/suit/jacket/leather/overcoat,
		/obj/item/clothing/gloves/color/black,
		/obj/item/clothing/head/soft/cargo,
		/obj/item/clothing/mask/bandana/skull/black,//so you can properly #cargoniabikergang
	)
	crate_name = "Biker Kit"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/emergency/bio
	name = "Biological Emergency Crate"
	desc = "This crate holds 2 full bio suits which will protect you from viruses."
	cost = 1500
	max_supply = 2
	contains = list(/obj/item/clothing/head/bio_hood,
					/obj/item/clothing/head/bio_hood,
					/obj/item/clothing/suit/bio_suit,
					/obj/item/clothing/suit/bio_suit,
					/obj/item/storage/bag/bio,
					/obj/item/reagent_containers/syringe/antiviral,
					/obj/item/reagent_containers/syringe/antiviral,
					/obj/item/clothing/gloves/color/latex/nitrile,
					/obj/item/clothing/gloves/color/latex/nitrile)
	crate_name = "bio suit crate"

/datum/supply_pack/emergency/equipment
	name = "Emergency Bot/Internals Crate"
	desc = "Explosions got you down? These supplies are guaranteed to patch up holes, in stations and people alike! Comes with two floorbots, two medbots, five oxygen masks and five small oxygen tanks."
	cost = 1500
	max_supply = 1
	contains = list(/mob/living/simple_animal/bot/floorbot,
					/mob/living/simple_animal/bot/floorbot,
					/mob/living/simple_animal/bot/medbot/filled,
					/mob/living/simple_animal/bot/medbot/filled,
					/obj/item/tank/internals/air,
					/obj/item/tank/internals/air,
					/obj/item/tank/internals/air,
					/obj/item/tank/internals/air,
					/obj/item/tank/internals/air,
					/obj/item/clothing/mask/breath,
					/obj/item/clothing/mask/breath,
					/obj/item/clothing/mask/breath,
					/obj/item/clothing/mask/breath,
					/obj/item/clothing/mask/breath)
	crate_name = "emergency crate"
	crate_type = /obj/structure/closet/crate/internals

/datum/supply_pack/emergency/medical
	name = "Emergency Medical Crate"
	desc = "For when the shit hits the fan and medical can't keep up. Comes with a 7x5 Medical capsule and 2 Medibots for emergencies."
	cost = 1100
	max_supply = 1
	contains = list(/mob/living/simple_animal/bot/medbot/filled,
					/mob/living/simple_animal/bot/medbot/filled,
					/obj/item/survivalcapsule/medical)
	crate_name = "emergency medical crate"
	crate_type = /obj/structure/closet/crate/medical

/datum/supply_pack/emergency/bomb
	name = "Explosive Emergency Crate"
	desc = "Science gone bonkers? Beeping behind the airlock? Buy now and be the hero the station des... I mean needs! (time not included)"
	cost = 800
	max_supply = 2
	contains = list(/obj/item/clothing/head/utility/bomb_hood,
					/obj/item/clothing/suit/utility/bomb_suit,
					/obj/item/clothing/mask/gas,
					/obj/item/screwdriver,
					/obj/item/wirecutters,
					/obj/item/multitool)
	crate_name = "bomb suit crate"

/datum/supply_pack/emergency/firefighting
	name = "Firefighting Crate"
	desc = "Only you can prevent station fires. Partner up with three firefighter suits, gas masks, flashlights, large oxygen tanks, extinguishers, and hardhats!"
	cost = 800
	max_supply = 2
	contains = list(/obj/item/clothing/suit/utility/fire/firefighter,
					/obj/item/clothing/suit/utility/fire/firefighter,
					/obj/item/clothing/suit/utility/fire/firefighter,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/mask/gas,
					/obj/item/flashlight,
					/obj/item/flashlight,
					/obj/item/flashlight,
					/obj/item/tank/internals/oxygen/red,
					/obj/item/tank/internals/oxygen/red,
					/obj/item/tank/internals/oxygen/red,
					/obj/item/extinguisher/advanced,
					/obj/item/extinguisher/advanced,
					/obj/item/extinguisher/advanced,
					/obj/item/clothing/head/utility/hardhat/red,
					/obj/item/clothing/head/utility/hardhat/red,
					/obj/item/clothing/head/utility/hardhat/red)
	crate_name = "firefighting crate"

/datum/supply_pack/emergency/atmostank
	name = "Firefighting Tank Backpack"
	desc = "Mow down fires with this high-capacity fire fighting tank backpack."
	cost = 1000
	max_supply = 3
	contains = list(/obj/item/watertank/atmos)
	crate_name = "firefighting backpack crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/emergency/internals
	name = "Internals Crate"
	desc = "Master your life energy and control your breathing with four breath masks, four emergency oxygen tanks and four large air tanks."//IS THAT A
	cost = 800
	max_supply = 4
	contains = list(/obj/item/clothing/mask/gas,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/mask/gas,
					/obj/item/clothing/mask/breath,
					/obj/item/clothing/mask/breath,
					/obj/item/clothing/mask/breath,
					/obj/item/clothing/mask/breath,
					/obj/item/tank/internals/emergency_oxygen,
					/obj/item/tank/internals/emergency_oxygen,
					/obj/item/tank/internals/emergency_oxygen,
					/obj/item/tank/internals/emergency_oxygen,
					/obj/item/tank/internals/air,
					/obj/item/tank/internals/air,
					/obj/item/tank/internals/air,
					/obj/item/tank/internals/air)
	crate_name = "internals crate"
	crate_type = /obj/structure/closet/crate/internals

/datum/supply_pack/emergency/lawnmower
	name = "Lawnmower Crate"
	desc = "Contains an unstable and slow lawnmower. Use with caution!"
	cost = 3000
	max_supply = 3
	contains = list(/obj/vehicle/ridden/lawnmower)
	crate_name = "lawnmower crate"
	contraband = TRUE

/datum/supply_pack/emergency/metalfoam
	name = "Metal Foam Grenade Crate"
	desc = "Seal up those pesky hull breaches with 7 Metal Foam Grenades."
	cost = 700
	max_supply = 4
	contains = list(/obj/item/storage/box/metalfoam)
	crate_name = "metal foam grenade crate"

/datum/supply_pack/emergency/plasma_spacesuit
	name = "Plasmaman Space Envirosuits"
	desc = "Contains two space-worthy envirosuits for Plasmamen. Order now and we'll throw in two free helmets! Requires EVA access to open."
	max_supply = 2
	cost = 1400 // 500 per suit, equal to normal space suits.
	contains = list(/obj/item/clothing/suit/space/eva/plasmaman,
					/obj/item/clothing/suit/space/eva/plasmaman,
					/obj/item/clothing/head/helmet/space/plasmaman,
					/obj/item/clothing/head/helmet/space/plasmaman)
	crate_name = "plasmaman EVA crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/emergency/plasmaman
	name = "Plasmaman Supply Kit"
	desc = "Keep those Plasmamen alive with three sets of Plasmaman outfits. Each set contains a plasmaman jumpsuit, internals tank, and helmet."
	cost = 700 //50 credits per suit.
	max_supply = 5
	contains = list(/obj/item/clothing/under/plasmaman,
					/obj/item/clothing/under/plasmaman,
					/obj/item/clothing/under/plasmaman,
					/obj/item/tank/internals/plasmaman/belt/full,
					/obj/item/tank/internals/plasmaman/belt/full,
					/obj/item/tank/internals/plasmaman/belt/full,
					/obj/item/clothing/head/helmet/space/plasmaman,
					/obj/item/clothing/head/helmet/space/plasmaman,
					/obj/item/clothing/head/helmet/space/plasmaman)
	crate_name = "plasmaman supply kit"

/datum/supply_pack/emergency/radiation
	name = "Radiation Protection Crate"
	desc = "Survive the Nuclear Apocalypse and Supermatter Engine alike with two sets of Radiation suits. Each set contains a helmet, suit, and Geiger counter. We'll even throw in a bottle of vodka and some glasses too, considering the life-expectancy of people who order this."
	cost = 800
	max_supply = 3
	contains = list(/obj/item/clothing/head/utility/radiation,
					/obj/item/clothing/head/utility/radiation,
					/obj/item/clothing/suit/utility/radiation,
					/obj/item/clothing/suit/utility/radiation,
					/obj/item/geiger_counter,
					/obj/item/geiger_counter,
					/obj/item/reagent_containers/cup/glass/bottle/vodka,
					/obj/item/reagent_containers/cup/glass/drinkingglass/shotglass,
					/obj/item/reagent_containers/cup/glass/drinkingglass/shotglass)
	crate_name = "radiation protection crate"
	crate_type = /obj/structure/closet/crate/radiation

/datum/supply_pack/emergency/spacesuit
	name = "Space Suit Crate"
	desc = "Contains one aging suit from Space-Goodwill."
	cost = 900 //500 credits per 1 suit
	max_supply = 3
	contains = list(/obj/item/clothing/suit/space,
					/obj/item/clothing/head/helmet/space,
					/obj/item/clothing/mask/breath)
	crate_name = "space suit crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/emergency/spacesuit/bulk
	name = "Bulk Space Suit Crate"
	desc = "Contains three aging suits from Space-Goodwill."
	cost = 1600 //20% discount
	max_supply = 1
	contains = list(/obj/item/clothing/suit/space,
					/obj/item/clothing/head/helmet/space,
					/obj/item/clothing/mask/breath,
					/obj/item/clothing/suit/space,
					/obj/item/clothing/head/helmet/space,
					/obj/item/clothing/mask/breath,
					/obj/item/clothing/suit/space,
					/obj/item/clothing/head/helmet/space,
					/obj/item/clothing/mask/breath)
	crate_name = "bulk space suit crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/emergency/specialops
	name = "Special Ops Supplies"
	desc = "(*!&@#OPERATIVE THIS LITTLE ORDER CAN STILL HELP YOU OUT IN A PINCH. CONTAINS A BOX OF FIVE EMP GRENADES, THREE SMOKEBOMBS, AN INCENDIARY GRENADE, AND A \"SLEEPY PEN\" FULL OF NICE TOXINS!#@*$"
	hidden = TRUE
	cost = 800
	max_supply = 2
	contains = list(/obj/item/storage/box/emps,
					/obj/item/grenade/smokebomb,
					/obj/item/grenade/smokebomb,
					/obj/item/grenade/smokebomb,
					/obj/item/pen/paralytic,
					/obj/item/grenade/chem_grenade/incendiary)
	crate_name = "emergency crate"
	crate_type = /obj/structure/closet/crate/internals

/datum/supply_pack/emergency/syndieclothes
	name = "Syndicate Uniform Supplies"
	desc = "(*!&@#OPERATIVE THIS LITTLE ORDER WILL MAKE YOU STYLISH SYNDICATE STYLE. CONTAINS A COLLECTION OF THREE TACTICAL TURTLENECKS, THREE COMBAT BOOTS, THREE COMBAT GLOVES, THREE BALACLAVAS, THREE SYNDICATE BERETS AND THREE ARMOR VESTS!#@*$"
	hidden = TRUE
	cost = 3000
	max_supply = 3
	contains = list(/obj/item/clothing/under/syndicate,
					/obj/item/clothing/under/syndicate,
					/obj/item/clothing/under/syndicate,
					/obj/item/clothing/shoes/combat,
					/obj/item/clothing/shoes/combat,
					/obj/item/clothing/shoes/combat,
					/obj/item/clothing/mask/balaclava,
					/obj/item/clothing/mask/balaclava,
					/obj/item/clothing/mask/balaclava,
					/obj/item/clothing/gloves/tackler/combat,
					/obj/item/clothing/gloves/tackler/combat,
					/obj/item/clothing/gloves/tackler/combat,
					/obj/item/clothing/head/hats/hos/beret/syndicate,
					/obj/item/clothing/head/hats/hos/beret/syndicate,
					/obj/item/clothing/head/hats/hos/beret/syndicate,
					/obj/item/clothing/suit/armor/vest,
					/obj/item/clothing/suit/armor/vest,
					/obj/item/clothing/suit/armor/vest)
	crate_name = "emergency crate"
	crate_type = /obj/structure/closet/crate/internals

/datum/supply_pack/emergency/weedcontrol
	name = "Weed Control Crate"
	desc = "Keep those invasive species OUT. Contains a scythe, gasmask, and two anti-weed chemical grenades. Warranty void if used on ambrosia. Requires Hydroponics access to open."
	cost = 800
	max_supply = 3
	access = ACCESS_HYDROPONICS
	contains = list(/obj/item/scythe,
					/obj/item/clothing/mask/gas,
					/obj/item/grenade/chem_grenade/antiweed,
					/obj/item/grenade/chem_grenade/antiweed)
	crate_name = "weed control crate"
	crate_type = /obj/structure/closet/crate/secure/hydroponics

//////////////////////////////////////////////////////////////////////////////
//////////////////////////// Security ////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/security
	group = "Security"
	access = ACCESS_SECURITY
	access_budget = ACCESS_SECURITY
	crate_type = /obj/structure/closet/crate/secure/gear

/datum/supply_pack/security/armor
	name = "Armor Crate"
	desc = "Three vests of well-rounded, decently-protective armor and 3 brain buckets. Requires Security access to open."
	cost = 1500
	max_supply = 3
	contains = list(/obj/item/clothing/suit/armor/vest,
					/obj/item/clothing/suit/armor/vest,
					/obj/item/clothing/suit/armor/vest,
					/obj/item/clothing/head/helmet/sec,
					/obj/item/clothing/head/helmet/sec,
					/obj/item/clothing/head/helmet/sec)
	crate_name = "armor crate"

/datum/supply_pack/security/disabler
	name = "Disabler Crate"
	desc = "Three stamina-draining disabler weapons. Requires Security access to open."
	cost = 1500
	max_supply = 2
	contains = list(/obj/item/gun/energy/disabler,
					/obj/item/gun/energy/disabler,
					/obj/item/gun/energy/disabler)
	crate_name = "disabler crate"

/datum/supply_pack/security/forensics
	name = "Forensics Crate"
	desc = "Stay hot on the criminal's heels with Nanotrasen's Detective Essentials(tm). Contains a forensics scanner, six evidence bags, detective's camera, tape recorder, white crayon, and of course, a fedora. Requires Security access to open."
	cost = 1700
	max_supply = 1
	access_budget = ACCESS_MORGUE
	contains = list(/obj/item/detective_scanner,
					/obj/item/storage/box/evidence,
					/obj/item/camera/detective,
					/obj/item/taperecorder,
					/obj/item/toy/crayon/white,
					/obj/item/clothing/head/fedora/det_hat)
	crate_name = "forensics crate"

/datum/supply_pack/security/dumdum
	name = ".38 DumDum Speedloader"
	desc = "Contains one speedloader of .38 DumDum ammunition, good for embedding in soft targets. Requires Security or Forensics access to open."
	cost = 1200
	max_supply = 4
	access = FALSE
	small_item = TRUE
	access_any = list(ACCESS_SECURITY, ACCESS_FORENSICS_LOCKERS)
	contains = list(/obj/item/ammo_box/c38/dumdum)
	crate_name = ".38 match crate"

/datum/supply_pack/security/match
	name = ".38 Match Grade Speedloader"
	desc = "Contains one speedloader of match grade .38 ammunition, perfect for showing off trickshots. Requires Security or Forensics access to open."
	cost = 1200
	max_supply = 3
	access = FALSE
	small_item = TRUE
	access_any = list(ACCESS_SECURITY, ACCESS_FORENSICS_LOCKERS)
	contains = list(/obj/item/ammo_box/c38/match)
	crate_name = ".38 match crate"

/datum/supply_pack/security/securitybarriers
	name = "Security Barricades"
	desc = "Stem the tide with eight security barricades. Requires Security access to open."
	cost = 1500
	max_supply = 2
	access_budget = ACCESS_BRIG
	contains = list(/obj/item/security_barricade,
					/obj/item/security_barricade,
					/obj/item/security_barricade,
					/obj/item/security_barricade,
					/obj/item/security_barricade,
					/obj/item/security_barricade,
					/obj/item/security_barricade,
					/obj/item/security_barricade)
	crate_name = "security barriers crate"

/datum/supply_pack/security/securityclothes
	name = "Security Clothing Crate"
	desc = "Contains appropriate outfits for the station's private security force. Contains outfits for the Warden, Head of Security, and two Security Officers. Each outfit comes with a rank-appropriate jumpsuit, suit, and beret. Requires Security access to open."
	cost = 1700
	max_supply = 3
	contains = list(/obj/item/clothing/under/rank/security/officer/formal,
					/obj/item/clothing/under/rank/security/officer/formal,
					/obj/item/clothing/suit/jacket/officer/blue,
					/obj/item/clothing/suit/jacket/officer/blue,
					/obj/item/clothing/head/beret/sec/navyofficer,
					/obj/item/clothing/head/beret/sec/navyofficer,
					/obj/item/clothing/under/rank/security/warden/formal,
					/obj/item/clothing/suit/jacket/warden/tan,
					/obj/item/clothing/head/beret/sec/navywarden,
					/obj/item/clothing/under/rank/security/head_of_security/formal,
					/obj/item/clothing/suit/jacket/hos/blue,
					/obj/item/clothing/head/hats/hos/beret/navyhos)
	crate_name = "security clothing crate"

/datum/supply_pack/security/stingpack
	name = "Stingbang Grenade Pack"
	desc = "Contains five \"stingbang\" grenades, perfect for stopping riots and playing morally unthinkable pranks. Requires Security access to open."
	cost = 2500
	max_supply = 1
	access_budget = ACCESS_ARMORY
	contains = list(/obj/item/storage/box/stingbangs)
	crate_name = "stingbang grenade pack crate"

/datum/supply_pack/security/stingpack/single
	name = "Stingbang Single-Pack"
	desc = "Contains one \"stingbang\" grenade, perfect for playing meanhearted pranks. Requires Security access to open."
	cost = 1400
	max_supply = 3
	access_budget = ACCESS_ARMORY
	small_item = TRUE
	contains = list(/obj/item/grenade/stingbang)

/datum/supply_pack/security/supplies
	name = "Security Supplies Crate"
	desc = "Contains seven flashbangs, seven teargas grenades, six flashes, and seven handcuffs. Requires Security access to open."
	cost = 700
	max_supply = 5
	access_budget = ACCESS_ARMORY
	contains = list(/obj/item/storage/box/flashbangs,
					/obj/item/storage/box/teargas,
					/obj/item/storage/box/flashes,
					/obj/item/storage/box/handcuffs)
	crate_name = "security supply crate"

/datum/supply_pack/security/vending/security
	name = "SecTech Supply Crate"
	desc = "Officer Paul bought all the handcuffs? Then refill the security vendor with ths crate."
	cost = 1200
	max_supply = 3
	contains = list(/obj/item/vending_refill/security)
	crate_name = "SecTech supply crate"

/datum/supply_pack/security/firingpins
	name = "Standard Firing Pins Crate"
	desc = "Upgrade your arsenal with 10 standard firing pins. Requires Security access to open."
	cost = 1700
	max_supply = 2
	access_budget = ACCESS_ARMORY
	contains = list(/obj/item/storage/box/firingpins,
					/obj/item/storage/box/firingpins)
	crate_name = "firing pins crate"

/datum/supply_pack/security/firingpins/paywall
	name = "Paywall Firing Pins Crate"
	desc = "Specialized firing pins with a built-in configurable paywall. Requires Security access to open."
	cost = 1700
	max_supply = 2
	access_budget = ACCESS_ARMORY
	contains = list(/obj/item/storage/box/firingpins/paywall,
					/obj/item/storage/box/firingpins/paywall)
	crate_name = "paywall firing pins crate"

/datum/supply_pack/security/justiceinbound
	name = "Standard Justice Enforcer Crate"
	desc = "This is it. The Bee's Knees. The Creme of the Crop. The Pick of the Litter. The best of the best of the best. The Crown Jewel of Nanotrasen. The Alpha and the Omega of security headwear. Guaranteed to strike fear into the hearts of each and every criminal aboard the station. Also comes with a security gasmask. Requires Security access to open."
	cost = 5700 //justice comes at a price. An expensive, noisy price.
	max_supply = 3
	contraband = TRUE
	contains = list(/obj/item/clothing/head/helmet/toggleable/justice,
					/obj/item/clothing/mask/gas/sechailer)
	crate_name = "security clothing crate"

/datum/supply_pack/security/baton
	name = "Stun Batons Crate"
	desc = "Arm the Civil Protection Forces with three stun batons. Batteries included. Requires Security access to open."
	cost = 900
	max_supply = 4
	contains = list(/obj/item/melee/baton/loaded,
					/obj/item/melee/baton/loaded,
					/obj/item/melee/baton/loaded)
	crate_name = "stun baton crate"

/datum/supply_pack/security/wall_flash
	name = "Wall-Mounted Flash Crate"
	desc = "Contains five wall-mounted flashes. Requires Security access to open."
	cost = 800
	max_supply = 4
	contains = list(/obj/item/storage/box/wall_flash,
					/obj/item/storage/box/wall_flash,
					/obj/item/storage/box/wall_flash,
					/obj/item/storage/box/wall_flash,
					/obj/item/storage/box/wall_flash)
	crate_name = "wall-mounted flash crate"

//////////////////////////////////////////////////////////////////////////////
//////////////////////////// Armory //////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/security/armory
	group = "Armory"
	access = ACCESS_ARMORY
	access_budget = ACCESS_ARMORY
	crate_type = /obj/structure/closet/crate/secure/weapon

/datum/supply_pack/security/ammo
	name = "Ammo Crate"
	desc = "Contains two 20-round magazines for the WT-550 Auto Rifle, three boxes of buckshot ammo, three boxes of rubber ammo and special .38 speedloaders. Requires Security access to open."
	cost = 2500
	max_supply = 2
	contains = list(/obj/item/ammo_box/magazine/wt550m9,
					/obj/item/ammo_box/magazine/wt550m9,
					/obj/item/storage/box/lethalshot,
					/obj/item/storage/box/lethalshot,
					/obj/item/storage/box/lethalshot,
					/obj/item/storage/box/rubbershot,
					/obj/item/storage/box/rubbershot,
					/obj/item/storage/box/rubbershot,
					/obj/item/ammo_box/c38/trac,
					/obj/item/ammo_box/c38/hotshot,
					/obj/item/ammo_box/c38/iceblox)
	crate_name = "ammo crate"

/datum/supply_pack/security/armory/bulletarmor
	name = "Bulletproof Armor Crate"
	desc = "Contains three sets of bulletproof armor. Guaranteed to reduce a bullet's stopping power by over half. Requires Armory access to open."
	cost = 1200
	max_supply = 2
	contains = list(/obj/item/clothing/suit/armor/bulletproof,
					/obj/item/clothing/suit/armor/bulletproof,
					/obj/item/clothing/suit/armor/bulletproof)
	crate_name = "bulletproof armor crate"

/datum/supply_pack/security/armory/chemimp
	name = "Chemical Implants Crate"
	desc = "Contains five Remote Chemical implants. Requires Armory access to open."
	cost = 700
	max_supply = 3
	contains = list(/obj/item/storage/box/chemimp)
	crate_name = "chemical implant crate"

/datum/supply_pack/security/armory/dragnet
	name = "DRAGnet Crate"
	desc = "Contains three \"Dynamic Rapid-Apprehension of the Guilty\" netting devices, a recent breakthrough in law enforcement prisoner management technology. Requires armory access to open."
	cost = 1500
	max_supply = 2
	contains = list(/obj/item/gun/energy/e_gun/dragnet,
					/obj/item/gun/energy/e_gun/dragnet,
					/obj/item/gun/energy/e_gun/dragnet)
	crate_name = "\improper DRAGnet crate"

/datum/supply_pack/security/armory/combatknives_single
	name = "Combat Knife Single-Pack"
	desc = "Contains one sharpened combat knive. Guaranteed to fit snugly inside any Nanotrasen-standard boot. Requires Armory access to open."
	cost = 700 // 300 credits per 1 knife
	small_item = TRUE
	max_supply = 2
	contains = list(/obj/item/knife/combat)

/datum/supply_pack/security/armory/combatknives
	name = "Combat Knives Crate"
	desc = "Contains three sharpened combat knives. Each knife guaranteed to fit snugly inside any Nanotrasen-standard boot. Requires Armory access to open."
	cost = 1120 //20% discount
	max_supply = 1
	contains = list(/obj/item/knife/combat,
					/obj/item/knife/combat,
					/obj/item/knife/combat)
	crate_name = "combat knife crate"

/datum/supply_pack/security/armory/ballistic_single
	name = "Combat Shotgun Single-Pack"
	desc = "For when the enemy absolutely needs to be replaced with lead. Contains one Aussec-designed Combat Shotgun, and one Shotgun Bandolier. Requires Armory access to open."
	cost = 2900 //2500 credits per shotgun
	small_item = TRUE
	max_supply = 2
	contains = list(/obj/item/gun/ballistic/shotgun/automatic/combat,
					/obj/item/storage/belt/bandolier)

/datum/supply_pack/security/armory/ballistic
	name = "Combat Shotguns Crate"
	desc = "For when the enemy absolutely needs to be replaced with lead. Contains three Aussec-designed Combat Shotguns, and three Shotgun Bandoliers. Requires Armory access to open."
	cost = 6400 //20% discount
	max_supply = 1
	contains = list(/obj/item/gun/ballistic/shotgun/automatic/combat,
					/obj/item/gun/ballistic/shotgun/automatic/combat,
					/obj/item/gun/ballistic/shotgun/automatic/combat,
					/obj/item/storage/belt/bandolier,
					/obj/item/storage/belt/bandolier,
					/obj/item/storage/belt/bandolier)
	crate_name = "combat shotguns crate"

/datum/supply_pack/security/armory/riot_shotgun_single
	name = "Riot Shotgun Single-Pack"
	desc = "When the clown's slipped you one time too many. Requires armory access to open."
	cost =  2200 //1800 credits per shotgun
	max_supply = 2
	contains = list(/obj/item/gun/ballistic/shotgun/riot)

/datum/supply_pack/security/armory/riot_shotgun
	name = "Riot Shotguns Crate"
	desc = "For when the greytide gets out of hand. Contains 3 riot shotguns. Requires armory access to open."
	cost = 4720 //20% discount
	max_supply = 1
	contains = list(/obj/item/gun/ballistic/shotgun/riot,
					/obj/item/gun/ballistic/shotgun/riot,
					/obj/item/gun/ballistic/shotgun/riot)

/datum/supply_pack/security/armory/energy_single
	name = "Energy Gun Single-Pack"
	desc = "Contains one Energy Gun, capable of firing both nonlethal and lethal blasts of light. Requires Armory access to open."
	cost = 1200
	small_item = TRUE
	max_supply = 3
	contains = list(/obj/item/gun/energy/e_gun)
	crate_name = "single energy gun crate"

/datum/supply_pack/security/armory/energy
	name = "Bulk Energy Guns Crate"
	desc = "Contains three Energy Guns, capable of firing both nonlethal and lethal blasts of light. Requires Armory access to open."
	cost = 2320 //20%
	max_supply = 2
	contains = list(/obj/item/gun/energy/e_gun,
					/obj/item/gun/energy/e_gun,
					/obj/item/gun/energy/e_gun)
	crate_name = "bulk energy guns crate"
	crate_type = /obj/structure/closet/crate/secure/plasma

/datum/supply_pack/security/armory/laser
	name = "Laser Gun Single-Pack"
	desc = "Contains one lethal, high-energy laser gun, Requires Armory access to open."
	cost = 1000
	small_item = TRUE
	max_supply = 3
	contains = list(/obj/item/gun/energy/laser)
	crate_name = "single laser gun crate"

/datum/supply_pack/security/armory/laser_single
	name = "Bulk Laser Guns Crate"
	desc = "Contains three lethal, high-energy laser guns. Requires Armory access to open."
	cost = 2150
	max_supply = 2
	contains = list(/obj/item/gun/energy/laser,
					/obj/item/gun/energy/laser,
					/obj/item/gun/energy/laser)
	crate_name = "bulk laser guns crate"

/datum/supply_pack/security/armory/exileimp
	name = "Exile Implants Crate"
	desc = "Contains five Exile implants. Requires Armory access to open."
	cost = 2700
	max_supply = 3
	contains = list(/obj/item/storage/box/exileimp)
	crate_name = "exile implant crate"

/datum/supply_pack/security/armory/fire
	name = "Incendiary Weapons Crate"
	desc = "Burn, baby burn. Contains three incendiary grenades, three plasma canisters, and a flamethrower. Requires Armory access to open."
	cost = 1200
	max_supply = 3
	access = ACCESS_HEADS
	contains = list(/obj/item/flamethrower/full,
					/obj/item/tank/internals/plasma,
					/obj/item/tank/internals/plasma,
					/obj/item/tank/internals/plasma,
					/obj/item/grenade/chem_grenade/incendiary,
					/obj/item/grenade/chem_grenade/incendiary,
					/obj/item/grenade/chem_grenade/incendiary)
	crate_name = "incendiary weapons crate"
	crate_type = /obj/structure/closet/crate/secure/plasma
	dangerous = TRUE

/datum/supply_pack/security/armory/securitybarriersxl
	name = "Security Barrier Capsules XL"
	desc = "3x3 Reinforced glass barricades for when the nukies come knocking. Requires Security access to open."
	small_item = TRUE
	max_supply = 2
	contains = list(/obj/item/survivalcapsule/barricade,
					/obj/item/survivalcapsule/barricade,
					/obj/item/survivalcapsule/barricade)
	cost = 2000
	crate_name = "security barriers crate XL"

/datum/supply_pack/security/armory/capsule_checkpoints
	name = "Security Checkpoint capsules"
	desc = "A 3x3 checkpoint designed for allowing safely searching passing personnel. Requires Security access to open."
	max_supply = 2
	access_budget = ACCESS_BRIG
	contains = list(/obj/item/survivalcapsule/capsule_checkpoint,
					/obj/item/survivalcapsule/capsule_checkpoint)
	cost = 1000
	crate_name = "Security Checkpoint capsule crate"

/datum/supply_pack/security/armory/mindshield
	name = "Mindshield Implants Crate"
	desc = "Prevent against radical thoughts with three Mindshield implants. Requires Armory access to open."
	cost = 4000
	max_supply = 3
	contains = list(/obj/item/storage/lockbox/loyalty)
	crate_name = "mindshield implant crate"

/datum/supply_pack/security/armory/trackingimp
	name = "Tracking Implants Crate"
	desc = "Contains four tracking implants and three tracking speedloaders of tracing .38 ammo. Requires Armory access to open."
	cost = 1200
	max_supply = 4
	contains = list(/obj/item/storage/box/trackimp,
					/obj/item/ammo_box/c38/trac,
					/obj/item/ammo_box/c38/trac,
					/obj/item/ammo_box/c38/trac)
	crate_name = "tracking implant crate"

/datum/supply_pack/security/armory/laserarmor
	name = "Reflector Vest Crate"
	desc = "Contains two vests of highly reflective material. Each armor piece diffuses a laser's energy by over half, as well as offering a good chance to reflect the laser entirely. Requires Armory access to open."
	cost = 2000
	max_supply = 2
	contains = list(/obj/item/clothing/suit/armor/laserproof,
					/obj/item/clothing/suit/armor/laserproof)
	crate_name = "reflector vest crate"
	crate_type = /obj/structure/closet/crate/secure/plasma

/datum/supply_pack/security/armory/riotarmor
	name = "Riot Armor Crate"
	desc = "Contains three sets of heavy body armor and helmets. Advanced padding protects against close-ranged weaponry, making melee attacks feel only half as potent to the user. Requires Armory access to open."
	cost = 2200
	max_supply = 2
	contains = list(/obj/item/clothing/suit/armor/riot,
					/obj/item/clothing/suit/armor/riot,
					/obj/item/clothing/suit/armor/riot,
					/obj/item/clothing/head/helmet/toggleable/riot,
					/obj/item/clothing/head/helmet/toggleable/riot,
					/obj/item/clothing/head/helmet/toggleable/riot)
	crate_name = "riot armor crate"

/datum/supply_pack/security/armory/riotshields
	name = "Riot Shields Crate"
	desc = "For when the greytide gets really uppity. Contains three riot shields. Requires Armory access to open."
	cost = 1500
	max_supply = 2
	contains = list(/obj/item/shield/riot,
					/obj/item/shield/riot,
					/obj/item/shield/riot)
	crate_name = "riot shields crate"

/datum/supply_pack/security/armory/russian
	name = "Russian Surplus Crate"
	desc = "Hello Comrade, we have the most modern russian military equipment the black market can offer, for the right price of course. Sadly we couldnt remove the lock so it requires Armory access to open."
	cost = 4000
	contraband = TRUE
	max_supply = 3
	contains = list(
		/obj/item/food/rationpack,
		/obj/item/ammo_box/a762,
		/obj/item/storage/toolbox/ammo,
		/obj/item/clothing/suit/armor/vest/russian,
		/obj/item/clothing/head/helmet/rus_helmet,
		/obj/item/clothing/shoes/russian,
		/obj/item/clothing/gloves/tackler/combat,
		/obj/item/clothing/under/syndicate/rus_army,
		/obj/item/clothing/under/costume/soviet,
		/obj/item/clothing/mask/russian_balaclava,
		/obj/item/clothing/head/helmet/rus_ushanka,
		/obj/item/clothing/suit/armor/vest/russian_coat,
		/obj/item/gun/ballistic/rifle/boltaction,
		/obj/item/gun/ballistic/rifle/boltaction
	)
	crate_name = "surplus military crate"

/datum/supply_pack/security/armory/russian/fill(obj/structure/closet/crate/C)
	for(var/i in 1 to 10)
		var/item = pick(contains)
		new item(C)

/datum/supply_pack/security/armory/western
	name = "Western Frontier Crate"
	desc = "Howdy Pardner, this here is the finest collection of frontier gear for the aspiring cowboy, sheriff, or Wild West desperado on this side of the solar system. Unfortunately, we've had to lock this down with Armory access to put the postmaster general at ease."
	cost = 4000
	contraband = TRUE
	max_supply = 3
	contains = list(/obj/item/ammo_box/c38/box,
					/obj/item/storage/toolbox/ammo/c38,
					/obj/item/mob_lasso,
					/obj/item/clothing/shoes/workboots/mining,
					/obj/item/clothing/gloves/botanic_leather,
					/obj/item/clothing/gloves/color/black,
					/obj/item/clothing/head/cowboy,
					/obj/item/clothing/head/costume/sombrero,
					/obj/item/clothing/head/costume/sombrero/green,
					/obj/item/storage/belt/bandolier/western,
					/obj/item/gun/ballistic/rifle/leveraction,
					/obj/item/gun/ballistic/rifle/leveraction)
	var/wear_outer = list(/obj/item/clothing/suit/apron/overalls,
					/obj/item/clothing/suit/costume/poncho,
					/obj/item/clothing/suit/costume/poncho/green,
					/obj/item/clothing/suit/costume/poncho/red)
	var/wear_under = list(/obj/item/clothing/under/misc/overalls,
					/obj/item/clothing/under/misc/overalls,
					/obj/item/clothing/under/misc/overalls,
					/obj/item/clothing/under/suit/sl,
					/obj/item/clothing/under/suit/sl)
	var/cursed = list(/obj/item/clothing/head/helmet/outlaw,
					/obj/item/clothing/mask/fakemoustache,
					/obj/item/clothing/suit/costume/poncho/ponchoshame/outlaw,
					/obj/item/clothing/under/suit/sl,
					/obj/item/clothing/shoes/workboots/mining,
					/obj/item/clothing/gloves/color/black,
					/obj/item/storage/belt/bandolier/western/filled,
					/obj/item/gun/ballistic/rifle/leveraction,
					/obj/item/gun/ballistic/revolver/detective/cowboy,
					/obj/item/clothing/accessory/holster,
					/obj/item/paper/crumpled/bloody/cursed_western)
	crate_name = "western frontier crate"

/datum/supply_pack/security/armory/western/fill(obj/structure/closet/crate/C)
	if (prob(1) && prob(10)) //0.001% chance of rolling instead of normal contents //Jackpot Babey!!!
		C.name = "cursed gunslinger crate"
		C.color = COLOR_GRAY
		for(var/item in cursed)
			new item(C)
	else
		for(var/i in 1 to 6)
			var/item = pick(contains)
			new item(C)
		for(var/i in 1 to 2)
			var/item_outer = pick(wear_outer)
			new item_outer(C)
		for(var/i in 1 to 3)
			var/item_under = pick(wear_under)
			new item_under(C)
		new /obj/item/clothing/mask/fakemoustache(C)
		new /obj/item/clothing/mask/fakemoustache(C)

/datum/supply_pack/security/armory/smartmine
	name = "Smart Mine Crate"
	desc = "Contains three nonlethal pressure activated stun mines capable of ignoring mindshieled personnel. Requires Armory access to open."
	cost = 2500
	max_supply = 2
	contains = list(/obj/item/deployablemine/smartstun,
					/obj/item/deployablemine/smartstun,
					/obj/item/deployablemine/smartstun)
	crate_name = "stun mine create"

/datum/supply_pack/security/armory/stunmine
	name = "Stun Mine Crate"
	desc = "Contains five nonlethal pressure activated stun mines. Requires Armory access to open."
	cost = 2000
	max_supply = 2
	contains = list(/obj/item/deployablemine/stun,
					/obj/item/deployablemine/stun,
					/obj/item/deployablemine/stun,
					/obj/item/deployablemine/stun,
					/obj/item/deployablemine/stun)
	crate_name = "stun mine create"

/datum/supply_pack/security/armory/swat
	name = "SWAT Crate"
	desc = "Contains two fullbody sets of tough, fireproof, pressurized suits designed in a joint effort by IS-ERI and Nanotrasen. Each set contains a suit, helmet, mask, combat belt, and combat gloves. Requires Armory access to open."
	cost = 5000
	max_supply = 1
	contains = list(/obj/item/clothing/head/helmet/swat/nanotrasen,
					/obj/item/clothing/head/helmet/swat/nanotrasen,
					/obj/item/clothing/suit/space/swat,
					/obj/item/clothing/suit/space/swat,
					/obj/item/clothing/mask/gas/sechailer/swat,
					/obj/item/clothing/mask/gas/sechailer/swat,
					/obj/item/storage/belt/military/assault,
					/obj/item/storage/belt/military/assault,
					/obj/item/clothing/gloves/tackler/combat,
					/obj/item/clothing/gloves/tackler/combat)
	crate_name = "swat crate"

/datum/supply_pack/security/armory/wt550_single
	name = "WT-550 Auto Rifle Single-Pack"
	desc = "Contains one high-powered, semiautomatic rifles chambered in 4.6x30mm. Requires Armory access to open."
	cost = 1600 // 1200 per 1 gun
	contains = list(/obj/item/gun/ballistic/automatic/wt550)
	small_item = TRUE
	max_supply = 3

/datum/supply_pack/security/armory/wt550
	name = "WT-550 Auto Rifle Crate"
	desc = "Contains two high-powered, semiautomatic rifles chambered in 4.6x30mm. Requires Armory access to open."
	cost = 3280 //20%
	max_supply = 1
	contains = list(/obj/item/gun/ballistic/automatic/wt550,
					/obj/item/gun/ballistic/automatic/wt550,
					/obj/item/gun/ballistic/automatic/wt550)
	crate_name = "auto rifle crate"

/datum/supply_pack/security/armory/wt550ammo
	name = "WT-550 Auto Rifle Ammo Crate"
	desc = "Contains four 20-round magazine for the WT-550 Auto Rifle. Each magazine is designed to facilitate rapid tactical reloads. Requires Armory access to open."
	cost = 1500
	max_supply = 5
	contains = list(/obj/item/ammo_box/magazine/wt550m9,
					/obj/item/ammo_box/magazine/wt550m9,
					/obj/item/ammo_box/magazine/wt550m9,
					/obj/item/ammo_box/magazine/wt550m9)

/datum/supply_pack/security/armoury/bsanchor
	name = "Bluespace Anchoring Device"
	desc = "Contains a single portable bluespace anchoring device which, when deployed, will prevent basic forms of teleportation. Does not come with batteries."
	cost = 3000
	contains = list(/obj/item/bluespace_anchor)

//////////////////////////////////////////////////////////////////////////////
//////////////////////////// Engineering /////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/engineering
	group = "Engineering"
	crate_type = /obj/structure/closet/crate/engineering
	access_budget = ACCESS_ENGINE

/datum/supply_pack/engineering/shieldgen
	name = "Anti-breach Shield Projector Crate"
	desc = "Hull breaches again? Say no more with the Nanotrasen Anti-Breach Shield Projector! Uses forcefield technology to keep the air in, and the space out. Contains two shield projectors."
	cost = 1000
	max_supply = 5
	access_budget = ACCESS_ENGINE_EQUIP
	contains = list(/obj/machinery/shieldgen,
					/obj/machinery/shieldgen)
	crate_name = "anti-breach shield projector crate"

/datum/supply_pack/engineering/ripley
	name = "APLU MK-I Crate"
	desc = "A do-it-yourself kit for building an ALPU MK-I \"Ripley\", designed for lifting and carrying heavy equipment, and other station tasks. Batteries not included."
	cost = 1500
	max_supply = 2
	access_budget = FALSE
	contains = list(/obj/item/mecha_parts/chassis/ripley,
					/obj/item/mecha_parts/part/ripley_torso,
					/obj/item/mecha_parts/part/ripley_right_arm,
					/obj/item/mecha_parts/part/ripley_left_arm,
					/obj/item/mecha_parts/part/ripley_right_leg,
					/obj/item/mecha_parts/part/ripley_left_leg,
					/obj/item/stock_parts/capacitor,
					/obj/item/stock_parts/scanning_module,
					/obj/item/circuitboard/mecha/ripley/main,
					/obj/item/circuitboard/mecha/ripley/peripherals,
					/obj/item/mecha_parts/mecha_equipment/drill,
					/obj/item/mecha_parts/mecha_equipment/hydraulic_clamp)
	crate_name= "APLU MK-I kit"

/datum/supply_pack/engineering/conveyor
	name = "Conveyor Assembly Crate"
	desc = "Keep production moving along with thirty conveyor belts. Conveyor switch included. If you have any questions, check out the enclosed instruction book."
	cost = 1200
	max_supply = 4
	access_budget = FALSE
	contains = list(/obj/item/stack/conveyor/thirty,
					/obj/item/conveyor_switch_construct,
					/obj/item/paper/guides/conveyor)
	crate_name = "conveyor assembly crate"

/datum/supply_pack/engineering/engiequipment
	name = "Engineering Gear Crate"
	desc = "Gear up with three toolbelts, high-visibility vests, welding helmets, hardhats, and two pairs of meson goggles!"
	cost = 1000
	max_supply = 5
	contains = list(/obj/item/storage/belt/utility,
					/obj/item/storage/belt/utility,
					/obj/item/storage/belt/utility,
					/obj/item/clothing/suit/hazardvest,
					/obj/item/clothing/suit/hazardvest,
					/obj/item/clothing/suit/hazardvest,
					/obj/item/clothing/head/utility/welding,
					/obj/item/clothing/head/utility/welding,
					/obj/item/clothing/head/utility/welding,
					/obj/item/clothing/head/utility/hardhat,
					/obj/item/clothing/head/utility/hardhat,
					/obj/item/clothing/head/utility/hardhat,
					/obj/item/clothing/glasses/meson/engine,
					/obj/item/clothing/glasses/meson/engine)
	crate_name = "engineering gear crate"

/datum/supply_pack/engineering/powergamermitts
	name = "Insulated Gloves Crate"
	desc = "The backbone of modern society. Barely ever ordered for actual engineering. Contains three insulated gloves."
	cost = 1600	//Made of pure-grade bullshittinium
	max_supply = 3
	access_budget = ACCESS_ENGINE_EQUIP
	contains = list(/obj/item/clothing/gloves/color/yellow,
					/obj/item/clothing/gloves/color/yellow,
					/obj/item/clothing/gloves/color/yellow)
	crate_name = "insulated gloves crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engineering/jetpack
	name = "Jetpack Crate"
	desc = "For when you need to go fast in space!"
	cost = 850
	access_budget = FALSE
	max_supply = 3
	contains = list(/obj/item/tank/jetpack/carbondioxide)
	crate_name = "jetpack crate"

/datum/supply_pack/engineering/jetpack3
	name = "Bulk Jetpack Crate"
	desc = "Three jetpacks, enough for the whole gang!"
	cost = 1750 //20% discount
	access_budget = FALSE
	max_supply = 2
	contains = list(/obj/item/tank/jetpack/carbondioxide,
					/obj/item/tank/jetpack/carbondioxide,
					/obj/item/tank/jetpack/carbondioxide)
	crate_name = "bulk jetpack crate"

/datum/supply_pack/engineering/jetpack_combustion
	name = "Combustion Jetpack Crate"
	desc = "A powerful jetpack, capable of in-gravity flight using the high energy potential of plasma combustion."
	cost = 1000
	access_budget = FALSE
	contains = list(/obj/item/tank/jetpack/combustion)
	crate_name = "high-energy jetpack crate"

/datum/supply_pack/engineering/spacecapsule
	name = "Space Shelter Capsule"
	desc = "A crate containing an RCD, some compressed matter cartridges, and a single bluespace capsule containing a spaceworthy shelter for construction/emergencies."
	cost = 1500
	max_supply = 4
	contains = list(/obj/item/survivalcapsule/space,
					/obj/item/construction/rcd,
					/obj/item/rcd_ammo,
					/obj/item/rcd_ammo,
					/obj/item/rcd_ammo,
					/obj/item/rcd_ammo)
	crate_name = "space shelter crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/obj/item/stock_parts/cell/inducer_supply
	maxcharge = 5000
	charge = 5000

/datum/supply_pack/engineering/inducers
	name = "NT-100 Heavy-Duty Inducers Crate"
	desc = "No rechargers? No problem, with the NT-100 EPI, you can recharge any standard cell-based equipment anytime, anywhere, twice faster than consumer alternatives! Contains two Engineering inducers."
	cost = 2000
	max_supply = 3
	contains = list(/obj/item/inducer {cell_type = /obj/item/stock_parts/cell/high; opened = 0}, /obj/item/inducer {cell_type = /obj/item/stock_parts/cell/inducer_supply; opened = 0}) //FALSE doesn't work in modified type paths apparently.
	crate_name = "inducer crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engineering/pacman
	name = "P.A.C.M.A.N Generator Crate"
	desc = "Engineers can't set up the engine? Not an issue for you, once you get your hands on this P.A.C.M.A.N. Generator! Takes in plasma and spits out sweet sweet energy."
	cost = 1000
	max_supply = 2
	contains = list(/obj/machinery/power/port_gen/pacman)
	crate_name = "PACMAN generator crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engineering/power
	name = "Power Cell Crate"
	desc = "Looking for power overwhelming? Look no further. Contains three high-voltage power cells."
	cost = 500
	max_supply = 5
	contains = list(/obj/item/stock_parts/cell/high,
					/obj/item/stock_parts/cell/high,
					/obj/item/stock_parts/cell/high)
	crate_name = "power cell crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engineering/sealant
	name = "Engine Sealant Crate"
	desc = "Nuclear reactor looking a bit cracked? Don't be afraid to slap on some NT brand sealant to patch those holes right up!"
	cost = 1000
	max_supply = 1
	contains = list(/obj/item/sealant,
					/obj/item/sealant,
					/obj/item/sealant)
	crate_name = "sealant crate"
	crate_type = /obj/structure/closet/crate/engineering/

/datum/supply_pack/engineering/shuttle_engine
	name = "Shuttle Engine Crate"
	desc = "Through advanced bluespace-shenanigans, our engineers have managed to fit an entire shuttle engine into one tiny little crate. Requires CE access to open."
	cost = 5000
	max_supply = 2
	access = ACCESS_CE
	access_budget = ACCESS_CE
	contains = list(/obj/structure/shuttle/engine/propulsion/burst/cargo)
	crate_name = "shuttle engine crate"
	crate_type = /obj/structure/closet/crate/secure/engineering
	special = TRUE

/datum/supply_pack/engineering/tools
	name = "Toolbox Crate"
	desc = "Any robust spaceman is never far from their trusty toolbox. Contains three electrical toolboxes and three mechanical toolboxes."
	cost = 700
	max_supply = 6
	access_budget = ACCESS_ENGINE_EQUIP
	contains = list(/obj/item/storage/toolbox/electrical,
					/obj/item/storage/toolbox/electrical,
					/obj/item/storage/toolbox/electrical,
					/obj/item/storage/toolbox/mechanical,
					/obj/item/storage/toolbox/mechanical,
					/obj/item/storage/toolbox/mechanical)
	crate_name = "toolbox crate"

/datum/supply_pack/engineering/fuel_rods
	name = "Uranium Fuel Rod Crate"
	desc = "A five nuclear reactor grade fuel rod crate. Warning: Due to budget constraints, this crate is not lead-lined! Wear radiation protection around this crate."
	cost = 3000
	max_supply = 2
	access_budget = ACCESS_ENGINE
	contains = list(/obj/item/fuel_rod,
					/obj/item/fuel_rod,
					/obj/item/fuel_rod,
					/obj/item/fuel_rod,
					/obj/item/fuel_rod)
	crate_name = "fuel rod crate"
	crate_type = /obj/structure/closet/crate/secure/engineering

/datum/supply_pack/engineering/vending/engineering
	name = "Engineering Vending Crate"
	desc = "Sick of assistants breaking into engineering for tools? Contains one Engi-Vend refill and one YouTool refill."
	cost = 1100
	max_supply = 6
	contains = list(/obj/item/vending_refill/engivend,
					/obj/item/vending_refill/tool)
	crate_name = "engineering vending crate"

/datum/supply_pack/engineering/bsa
	name = "Bluespace Artillery Parts"
	desc = "The pride of Nanotrasen Naval Command. The legendary Bluespace Artillery Cannon is a devastating feat of human engineering and testament to wartime determination. Highly advanced research is required for proper construction. "
	cost = 15000
	max_supply = 1
	special = TRUE
	access_budget = ACCESS_HEADS
	contains = list(/obj/item/circuitboard/machine/bsa/front,
					/obj/item/circuitboard/machine/bsa/middle,
					/obj/item/circuitboard/machine/bsa/back,
					/obj/item/circuitboard/computer/bsa_control
					)
	crate_name= "bluespace artillery parts crate"

/datum/supply_pack/engineering/dna_vault
	name = "DNA Vault Parts"
	desc = "Secure the longevity of the current state of humanity within this massive library of scientific knowledge, capable of granting superhuman powers and abilities. Highly advanced research is required for proper construction. Also contains five DNA probes."
	cost = 12000
	max_supply = 1
	special = TRUE
	access_budget = ACCESS_HEADS
	contains = list(
					/obj/item/circuitboard/machine/dna_vault,
					/obj/item/dna_probe,
					/obj/item/dna_probe,
					/obj/item/dna_probe,
					/obj/item/dna_probe,
					/obj/item/dna_probe
					)
	crate_name= "dna vault parts crate"

/datum/supply_pack/engineering/dna_probes
	name = "DNA Vault Samplers"
	desc = "Contains five DNA probes for use in the DNA vault."
	cost = 3000
	max_supply = 4
	special = TRUE
	access_budget = ACCESS_HEADS
	contains = list(/obj/item/dna_probe,
					/obj/item/dna_probe,
					/obj/item/dna_probe,
					/obj/item/dna_probe,
					/obj/item/dna_probe
					)
	crate_name= "dna samplers crate"


/datum/supply_pack/engineering/shield_sat
	name = "Shield Generator Satellite"
	desc = "Protect the very existence of this station with these Anti-Meteor defenses. Contains seven bluespace capsules which a single unit of Shield Generator Satellite is compressed within each."
	cost = 7000
	max_supply = 2
	access_budget = ACCESS_HEADS
	contains = list(
					/obj/item/meteor_shield,
					/obj/item/meteor_shield,
					/obj/item/meteor_shield,
					/obj/item/meteor_shield,
					/obj/item/meteor_shield,
					/obj/item/meteor_shield,
					/obj/item/meteor_shield,
					)
	crate_name= "shield sat crate"


/datum/supply_pack/engineering/shield_sat_control
	name = "Shield System Control Board"
	desc = "A control system for the Shield Generator Satellite system."
	cost = 5000
	max_supply = 2
	access_budget = ACCESS_HEADS
	contains = list(/obj/item/circuitboard/computer/sat_control)
	crate_name= "shield control board crate"

/datum/supply_pack/engineering/bluespace_tap
	name = "Bluespace Harvester Parts"
	cost = 15000
	max_supply = 1
	special = TRUE
	contains = list(
					/obj/item/circuitboard/machine/bluespace_tap,
					/obj/item/paper/bluespace_tap
					)
	crate_name = "bluespace harvester parts crate"

/datum/supply_pack/engineering/shuttle_construction
	name = "Shuttle Construction Kit"
	desc = "A DIY kit for building your own shuttle! Comes with all the parts you need to get your people to the stars!"
	cost = 5000
	max_supply = 2
	contains = list(
		/obj/machinery/portable_atmospherics/canister/plasma,
		/obj/item/construction/rcd/loaded,
		/obj/item/rcd_ammo/large,
		/obj/item/rcd_ammo/large,
		/obj/item/shuttle_creator,
		/obj/item/pipe_dispenser,
		/obj/item/storage/toolbox/mechanical,
		/obj/item/storage/toolbox/electrical,
		/obj/item/circuitboard/computer/shuttle/flight_control,
		/obj/item/circuitboard/machine/shuttle/engine/plasma,
		/obj/item/circuitboard/machine/shuttle/engine/plasma,
		/obj/item/circuitboard/machine/shuttle/heater,
		/obj/item/circuitboard/machine/shuttle/heater
		)
	crate_name = "shuttle construction crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/engineering/portable_pumps
	name = "Portable Pumps"
	desc = "A set of spare portable pumps. Perfect for larger atmospheric projects or restocking after a toxins problem goes wrong."
	cost = 1500
	max_supply = 4
	contains = list(
		/obj/machinery/portable_atmospherics/pump,
		/obj/machinery/portable_atmospherics/pump
	)
	crate_name = "portable pump crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/engineering/portable_scrubbers
	name = "Portable Scrubbers"
	desc = "A set of spare portable scrubbers. Perfect for when plasma 'accidentally' gets into the air supply."
	cost = 1500
	max_supply = 4
	contains = list(
		/obj/machinery/portable_atmospherics/scrubber,
		/obj/machinery/portable_atmospherics/scrubber
	)
	crate_name = "portable scrubber crate"
	crate_type = /obj/structure/closet/crate/large

//////////////////////////////////////////////////////////////////////////////
//////////////////////// Engine Construction /////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/engine
	group = "Engine Construction"
	crate_type = /obj/structure/closet/crate/engineering
	access_budget = ACCESS_ENGINE

/datum/supply_pack/engine/emitter
	name = "Emitter Crate"
	desc = "Useful for powering forcefield generators while destroying locked crates and intruders alike. Contains two high-powered energy emitters. Requires CE access to open."
	cost = 1200
	max_supply = 5
	access = ACCESS_CE
	contains = list(/obj/machinery/power/emitter,
					/obj/machinery/power/emitter)
	crate_name = "emitter crate"
	crate_type = /obj/structure/closet/crate/secure/engineering
	dangerous = TRUE

/datum/supply_pack/engine/field_gen
	name = "Field Generator Crate"
	desc = "Typically the only thing standing between the station and a messy death. Powered by emitters. Contains two field generators."
	cost = 1200
	max_supply = 5
	contains = list(/obj/machinery/field/generator,
					/obj/machinery/field/generator)
	crate_name = "field generator crate"

/datum/supply_pack/engine/grounding_rods
	name = "Grounding Rod Crate"
	desc = "Four grounding rods guaranteed to keep any uppity tesla's lightning under control."
	cost = 700
	max_supply = 5
	contains = list(/obj/machinery/power/grounding_rod,
					/obj/machinery/power/grounding_rod,
					/obj/machinery/power/grounding_rod,
					/obj/machinery/power/grounding_rod)
	crate_name = "grounding rod crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engine/PA
	name = "Particle Accelerator Crate"
	desc = "A supermassive black hole or hyper-powered teslaball are the perfect way to spice up any party! This \"My First Apocalypse\" kit contains everything you need to build your own Particle Accelerator! Ages 10 and up."
	cost = 2700
	max_supply = 3
	access = ACCESS_CE
	access_budget = ACCESS_CE
	contains = list(/obj/structure/particle_accelerator/fuel_chamber,
					/obj/machinery/particle_accelerator/control_box,
					/obj/structure/particle_accelerator/particle_emitter/center,
					/obj/structure/particle_accelerator/particle_emitter/left,
					/obj/structure/particle_accelerator/particle_emitter/right,
					/obj/structure/particle_accelerator/power_box,
					/obj/structure/particle_accelerator/end_cap)
	crate_name = "particle accelerator crate"
	crate_type = /obj/structure/closet/crate/secure/engineering
	dangerous = TRUE

/datum/supply_pack/engine/collector
	name = "Radiation Collector Crate"
	desc = "Contains three radiation collectors. Useful for collecting energy off nearby Supermatter Crystals, Singularities or Teslas!"
	cost = 2200
	max_supply = 4
	contains = list(/obj/machinery/power/rad_collector,
					/obj/machinery/power/rad_collector,
					/obj/machinery/power/rad_collector)
	crate_name = "collector crate"

/datum/supply_pack/engine/nuclear_reactor
	name = "RBMK Nuclear Reactor Engine Crate"
	desc = "Contains the boards for an NT certified nuclear power engine! Don't forget to wear a radiation suit!"
	cost = 7000
	max_supply = 1
	access = ACCESS_CE
	access_budget = ACCESS_CE
	contains = list(/obj/item/RBMK_box/core,
					/obj/item/RBMK_box/body/coolant_input,
					/obj/item/RBMK_box/body/moderator_input,
					/obj/item/RBMK_box/body/waste_output,
					/obj/item/RBMK_box/body,
					/obj/item/RBMK_box/body,
					/obj/item/RBMK_box/body,
					/obj/item/RBMK_box/body,
					/obj/item/RBMK_box/body,
					/obj/item/circuitboard/computer/control_rods,
					/obj/item/book/manual/wiki/rbmk)
	crate_name = "nuclear engine crate"
	crate_type = /obj/structure/closet/crate/secure/engineering
	dangerous = TRUE

/datum/supply_pack/engine/sing_gen
	name = "Singularity Generator Crate"
	desc = "The key to unlocking the power of Lord Singuloth. Particle Accelerator not included."
	cost = 4700
	max_supply = 3
	access = ACCESS_CE
	access_budget = ACCESS_CE
	contains = list(/obj/machinery/the_singularitygen)
	crate_name = "singularity generator crate"
	crate_type = /obj/structure/closet/crate/secure/engineering
	dangerous = TRUE

/datum/supply_pack/engine/solar
	name = "Solar Panel Crate"
	desc = "Go green with this DIY advanced solar array. Contains twenty one solar assemblies, a solar-control circuit board, and tracker. If you have any questions, please check out the enclosed instruction book."
	cost = 1700
	max_supply = 6
	contains  = list(/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/solar_assembly,
					/obj/item/circuitboard/computer/solar_control,
					/obj/item/electronics/tracker,
					/obj/item/paper/guides/jobs/engi/solars)
	crate_name = "solar panel crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engine/supermatter_shard
	name = "Supermatter Shard Crate"
	desc = "The power of the heavens condensed into a single crystal. Requires CE access to open."
	cost = 10000
	max_supply = 1
	access = ACCESS_CE
	access_budget = ACCESS_CE
	contains = list(/obj/machinery/power/supermatter_crystal/shard)
	crate_name = "supermatter shard crate"
	crate_type = /obj/structure/closet/crate/secure/engineering
	dangerous = TRUE

/datum/supply_pack/engine/tesla_coils
	name = "Tesla Coil Crate"
	desc = "Whether it's high-voltage executions, creating research points, or just plain old power generation: This pack of four Tesla coils can do it all!"
	cost = 1200
	max_supply = 3
	contains = list(/obj/machinery/power/tesla_coil,
					/obj/machinery/power/tesla_coil,
					/obj/machinery/power/tesla_coil,
					/obj/machinery/power/tesla_coil)
	crate_name = "tesla coil crate"
	crate_type = /obj/structure/closet/crate/engineering/electrical

/datum/supply_pack/engine/tesla_gen
	name = "Tesla Generator Crate"
	desc = "The key to unlocking the power of the Tesla energy ball. Particle Accelerator not included."
	cost = 5000
	max_supply = 2
	access = ACCESS_CE
	access_budget = ACCESS_CE
	contains = list(/obj/machinery/the_singularitygen/tesla)
	crate_name = "tesla generator crate"
	crate_type = /obj/structure/closet/crate/secure/engineering
	dangerous = TRUE

//////////////////////////////////////////////////////////////////////////////
/////////////////////// Canisters & Materials ////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/materials
	group = "Canisters & Materials"

/datum/supply_pack/materials/cardboard50
	name = "50 Cardboard Sheets"
	desc = "Create a bunch of boxes."
	cost = 1000
	max_supply = 8
	contains = list(/obj/item/stack/sheet/cardboard/fifty)
	crate_name = "cardboard sheets crate"

/datum/supply_pack/materials/glass50
	name = "50 Glass Sheets"
	desc = "Let some nice light in with fifty glass sheets!"
	cost = 1000
	max_supply = 8
	contains = list(/obj/item/stack/sheet/glass/fifty)
	crate_name = "glass sheets crate"

/datum/supply_pack/materials/glass250
	name = "250 Glass Sheets"
	desc = "Holy SHEET thats a lot of glass!"
	cost = 2800 //20%
	max_supply = 3
	contains = list(/obj/item/stack/sheet/glass/fifty,
					/obj/item/stack/sheet/glass/fifty,
					/obj/item/stack/sheet/glass/fifty,
					/obj/item/stack/sheet/glass/fifty,
					/obj/item/stack/sheet/glass/fifty)
	crate_name = "bulk glass sheets crate"

/datum/supply_pack/materials/iron50
	name = "50 Iron Sheets"
	desc = "Any construction project begins with a good stack of fifty iron sheets!"
	cost = 1000
	max_supply = 8
	contains = list(/obj/item/stack/sheet/iron/fifty)
	crate_name = "iron sheets crate"

/datum/supply_pack/materials/iron250
	name = "250 Iron Sheets"
	desc = "Enough Iron to rebuild half a station!"
	cost = 2800 //20%
	max_supply = 3
	contains = list(/obj/item/stack/sheet/iron/fifty,
					/obj/item/stack/sheet/iron/fifty,
					/obj/item/stack/sheet/iron/fifty,
					/obj/item/stack/sheet/iron/fifty,
					/obj/item/stack/sheet/iron/fifty)
	crate_name = "bulk iron sheets crate"

/datum/supply_pack/materials/plasteel20
	name = "20 Plasteel Sheets"
	desc = "Reinforce the station's integrity with twenty plasteel sheets!"
	cost = 7200
	max_supply = 5
	contains = list(/obj/item/stack/sheet/plasteel/twenty)
	crate_name = "plasteel sheets crate"

/datum/supply_pack/materials/plasteel50
	name = "50 Plasteel Sheets"
	desc = "For when you REALLY have to reinforce something."
	cost = 14000 // 20% discount
	max_supply = 3
	contains = list(/obj/item/stack/sheet/plasteel/fifty)
	crate_name = "plasteel sheets crate"

/datum/supply_pack/materials/copper20
	name = "20 Copper Sheets"
	desc = "Makes your floors look nice and your circuitry run!"
	cost = 1000
	max_supply = 8
	contains = list(/obj/item/stack/sheet/mineral/copper/twenty)
	crate_name = "copper sheets crate"

/datum/supply_pack/materials/copper50
	name = "50 Copper Sheets"
	desc = "Makes your floors look nice and your circuitry run!"
	cost = 1600 //20% discount
	max_supply = 6
	contains = list(/obj/item/stack/sheet/mineral/copper/fifty)
	crate_name = "bulk copper sheets crate"

/datum/supply_pack/materials/plastic50
	name = "50 Plastic Sheets"
	desc = "Build a limitless amount of toys with fifty plastic sheets!"
	cost = 800
	max_supply = 6
	contains = list(/obj/item/stack/sheet/plastic/fifty)
	crate_name = "plastic sheets crate"

/datum/supply_pack/materials/sandstone30
	name = "50 Sandstone Blocks"
	desc = "Neither sandy nor stoney, these thirty blocks will still get the job done."
	max_supply = 4
	cost = 1100
	contains = list(/obj/item/stack/sheet/mineral/sandstone/fifty)
	crate_name = "sandstone blocks crate"

/datum/supply_pack/materials/wood50
	name = "50 Wood Planks"
	desc = "Turn cargo's boring metal groundwork into beautiful panelled flooring and much more with fifty wooden planks!"
	cost = 1700
	max_supply = 6
	contains = list(/obj/item/stack/sheet/wood/fifty)
	crate_name = "wood planks crate"

/datum/supply_pack/materials/bz
	name = "BZ Canister Crate"
	desc = "Contains a canister of BZ. Requires Atmospherics access to open."
	cost = 8000
	max_supply = 3
	access = ACCESS_ATMOSPHERICS
	access_budget = ACCESS_ATMOSPHERICS
	contains = list(/obj/machinery/portable_atmospherics/canister/bz)
	crate_name = "BZ canister crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/materials/carbon_dio
	name = "Carbon Dioxide Canister"
	desc = "Contains a canister of Carbon Dioxide. Requires Atmospherics access to open."
	cost = 1200
	max_supply = 3
	access = ACCESS_ATMOSPHERICS
	access_budget = ACCESS_ATMOSPHERICS
	contains = list(/obj/machinery/portable_atmospherics/canister/carbon_dioxide)
	crate_name = "carbon dioxide canister crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/materials/foamtank
	name = "Firefighting Foam Tank Crate"
	desc = "Contains a tank of firefighting foam. Also known as \"plasmaman's bane\"."
	cost = 1500
	max_supply = 3
	contains = list(/obj/structure/reagent_dispensers/foamtank)
	crate_name = "foam tank crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/materials/fueltank
	name = "Fuel Tank Crate"
	desc = "Contains a welding fuel tank. Caution, highly flammable."
	cost = 800
	max_supply = 5
	access_budget = ACCESS_ENGINE
	contains = list(/obj/structure/reagent_dispensers/fueltank)
	crate_name = "fuel tank crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/materials/hightank
	name = "Large Water Tank Crate"
	desc = "Contains a high-capacity water tank. Useful for botany or other service jobs."
	cost = 1200
	max_supply = 5
	contains = list(/obj/structure/reagent_dispensers/watertank/high)
	crate_name = "high-capacity water tank crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/materials/nitrogen
	name = "Nitrogen Canister"
	desc = "Contains a canister of Nitrogen."
	cost = 800
	max_supply = 8
	contains = list(/obj/machinery/portable_atmospherics/canister/nitrogen)
	crate_name = "nitrogen canister crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/materials/nitrous_oxide_canister
	name = "Nitrous Oxide Canister"
	desc = "Contains a canister of Nitrous Oxide. Requires Atmospherics access to open."
	cost = 2400
	max_supply = 5
	access = ACCESS_ATMOSPHERICS
	access_budget = ACCESS_ATMOSPHERICS
	contains = list(/obj/machinery/portable_atmospherics/canister/nitrous_oxide)
	crate_name = "nitrous oxide canister crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/materials/oxygen
	name = "Oxygen Canister"
	desc = "Contains a canister of Oxygen. Canned in Druidia."
	cost = 800
	max_supply = 8
	contains = list(/obj/machinery/portable_atmospherics/canister/oxygen)
	crate_name = "oxygen canister crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/materials/watertank
	name = "Water Tank Crate"
	desc = "Contains a tank of dihydrogen monoxide... sounds dangerous."
	cost = 750
	max_supply = 4
	contains = list(/obj/structure/reagent_dispensers/watertank)
	crate_name = "water tank crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/materials/water_vapor
	name = "Water Vapor Canister"
	desc = "Contains a canister of Water Vapor. I swear to god if you open this in the halls..."
	cost = 2500
	max_supply = 4
	contains = list(/obj/machinery/portable_atmospherics/canister/water_vapor)
	crate_name = "water vapor canister crate"
	crate_type = /obj/structure/closet/crate/large

//////////////////////////////////////////////////////////////////////////////
//////////////////////////// Medical /////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/medical
	group = "Medical"
	access_budget = ACCESS_MEDICAL
	crate_type = /obj/structure/closet/crate/medical

/datum/supply_pack/medical/bloodpacks
	name = "Blood Pack Variety Crate"
	desc = "Contains eight different blood packs for reintroducing blood to patients."
	cost = 700
	max_supply = 4
	contains = list(/obj/item/reagent_containers/blood,
					/obj/item/reagent_containers/blood,
					/obj/item/reagent_containers/blood/APlus,
					/obj/item/reagent_containers/blood/AMinus,
					/obj/item/reagent_containers/blood/BPlus,
					/obj/item/reagent_containers/blood/BMinus,
					/obj/item/reagent_containers/blood/OPlus,
					/obj/item/reagent_containers/blood/OMinus,
					/obj/item/reagent_containers/blood/lizard,
					/obj/item/reagent_containers/blood/ethereal,
					/obj/item/reagent_containers/blood/oozeling)
	crate_name = "blood freezer"
	crate_type = /obj/structure/closet/crate/freezer

/datum/supply_pack/medical/synthflesh
	name = "Synthflesh resupply pack"
	desc = "Contains four 100u cartons of synthflesh in case the cloner ran out of it."
	cost = 1400
	max_supply = 3
	contains = list(/obj/item/reagent_containers/cup/glass/bottle/synthflesh,
					/obj/item/reagent_containers/cup/glass/bottle/synthflesh,
					/obj/item/reagent_containers/cup/glass/bottle/synthflesh,
					/obj/item/reagent_containers/cup/glass/bottle/synthflesh)
	crate_name = "rusty freezer"
	crate_type = /obj/structure/closet/crate/freezer

/datum/supply_pack/medical/basickits
	name = "Basic Treatment Kits Crate"
	desc = "Contains three basic aid kits focused on basic types of damage in a simple way."
	cost = 1400
	max_supply = 5
	small_item = TRUE
	contains = list(/obj/item/storage/firstaid/regular,
					/obj/item/storage/firstaid/regular,
					/obj/item/storage/firstaid/regular)
	crate_name = "basic wound treatment kits crate"

/datum/supply_pack/medical/bruisekits
	name = "Bruise Treatment Kits Crate"
	desc = "Contains three first aid kits focused on healing bruises and broken bones."
	cost = 1400
	max_supply = 4
	small_item = TRUE
	contains = list(/obj/item/storage/firstaid/brute,
					/obj/item/storage/firstaid/brute,
					/obj/item/storage/firstaid/brute)
	crate_name = "brute treatment kits crate"

/datum/supply_pack/medical/burnkits
	name = "Burn Treatment Kits Crate"
	desc = "Contains three first aid kits focused on healing severe burns."
	cost = 1400
	max_supply = 4
	small_item = TRUE
	contains = list(/obj/item/storage/firstaid/fire,
					/obj/item/storage/firstaid/fire,
					/obj/item/storage/firstaid/fire)
	crate_name = "burn treatment kits crate"

/datum/supply_pack/medical/oxylosskits
	name = "Oxygen Deprivation Kits Crate"
	desc = "Contains three first aid kits focused on helping oxygen deprivation victims."
	cost = 1400
	max_supply = 4
	small_item = TRUE
	contains = list(/obj/item/storage/firstaid/o2,
					/obj/item/storage/firstaid/o2,
					/obj/item/storage/firstaid/o2)
	crate_name = "oxygen deprivation treatment kits crate"

/datum/supply_pack/medical/toxinkits
	name = "Toxin Treatment Kits Crate"
	desc = "Contains three first aid kits focused on healing damage dealt by heavy toxins."
	cost = 1400
	max_supply = 4
	small_item = TRUE
	contains = list(/obj/item/storage/firstaid/toxin,
					/obj/item/storage/firstaid/toxin,
					/obj/item/storage/firstaid/toxin)
	crate_name = "toxin treatment kits crate"

/datum/supply_pack/medical/chemical
	name = "Chemical Starter Kit Crate"
	desc = "Contains thirteen different chemicals, for all the fun experiments you can make."
	cost = 1000
	max_supply = 4
	contains = list(/obj/item/reagent_containers/cup/bottle/hydrogen,
					/obj/item/reagent_containers/cup/bottle/carbon,
					/obj/item/reagent_containers/cup/bottle/nitrogen,
					/obj/item/reagent_containers/cup/bottle/oxygen,
					/obj/item/reagent_containers/cup/bottle/fluorine,
					/obj/item/reagent_containers/cup/bottle/phosphorus,
					/obj/item/reagent_containers/cup/bottle/silicon,
					/obj/item/reagent_containers/cup/bottle/chlorine,
					/obj/item/reagent_containers/cup/bottle/radium,
					/obj/item/reagent_containers/cup/bottle/sacid,
					/obj/item/reagent_containers/cup/bottle/ethanol,
					/obj/item/reagent_containers/cup/bottle/potassium,
					/obj/item/reagent_containers/cup/bottle/sugar,
					/obj/item/clothing/glasses/science,
					/obj/item/reagent_containers/dropper,
					/obj/item/storage/box/beakers)
	crate_name = "chemical crate"

/datum/supply_pack/medical/defibs
	name = "Defibrillator Crate"
	desc = "Contains two defibrillators for bringing the recently deceased back to life."
	cost = 1800
	max_supply = 2
	contains = list(/obj/item/defibrillator/loaded,
					/obj/item/defibrillator/loaded)
	crate_name = "defibrillator crate"

/datum/supply_pack/medical/iv_drip
	name = "IV Drip Crate"
	desc = "Contains three IV drips for administering blood to patients."
	cost = 800
	max_supply = 3
	contains = list(/obj/machinery/iv_drip,
					/obj/machinery/iv_drip,
					/obj/machinery/iv_drip)
	crate_name = "iv drip crate"

/datum/supply_pack/medical/supplies
	name = "Medical Supplies Crate"
	desc = "Contains a little bit of everything needed to stock a medbay or to form your own."
	cost = 2000
	max_supply = 3
	contains = list(/obj/item/reagent_containers/cup/bottle/charcoal,
					/obj/item/reagent_containers/cup/bottle/epinephrine,
					/obj/item/reagent_containers/cup/bottle/morphine,
					/obj/item/reagent_containers/cup/bottle/toxin,
					/obj/item/reagent_containers/cup/beaker/large,
					/obj/item/reagent_containers/pill/insulin,
					/obj/item/stack/medical/gauze,
					/obj/item/storage/box/beakers,
					/obj/item/storage/box/medsprays,
					/obj/item/storage/box/syringes,
					/obj/item/storage/box/bodybags,
					/obj/item/storage/firstaid/regular,
					/obj/item/storage/firstaid/o2,
					/obj/item/storage/firstaid/toxin,
					/obj/item/storage/firstaid/brute,
					/obj/item/storage/firstaid/fire,
					/obj/item/defibrillator/loaded,
					/obj/item/reagent_containers/blood/OMinus,
					/obj/item/storage/pill_bottle/mining,
					/obj/item/reagent_containers/pill/neurine,
					/obj/item/vending_refill/medical)
	crate_name = "medical supplies crate"

/datum/supply_pack/medical/supplies/fill(obj/structure/closet/crate/C)
	for(var/i in 1 to 10)
		var/item = pick(contains)
		new item(C)

/datum/supply_pack/medical/surgery
	name = "Surgical Supplies Crate"
	desc = "Do you want to perform surgery, but don't have one of those fancy shmancy degrees? Just get started with this crate containing a medical duffelbag, Sterilizine spray and collapsible roller bed."
	cost = 900
	max_supply = 4
	contains = list(/obj/item/storage/backpack/duffelbag/med/surgery,
					/obj/item/reagent_containers/medspray/sterilizine,
					/obj/item/rollerbed)
	crate_name = "surgical supplies crate"

/datum/supply_pack/medical/implants
	name = "Surplus Implants Crate"
	desc = "Do you want implants, but those R&D folks hasn't learnt how to do their job? Just get started with this crate containing several of our dusty surplus implants. (Surgical tools not included)"
	cost = 1000
	max_supply = 2
	contains = list(/obj/item/storage/backpack/duffelbag/med/implant)
	crate_name = "implant supplies crate"

/datum/supply_pack/medical/salglucanister
	name = "Heavy-Duty Saline Canister"
	desc = "Contains a bulk supply of saline-glucose condensed into a single canister that should last several days, with a large pump to fill containers with. Direct injection of saline should be left to medical professionals as the pump is capable of overdosing patients. Requires medbay access to open."
	cost = 1200
	max_supply = 4
	access = ACCESS_MEDICAL
	contains = list(/obj/machinery/iv_drip/saline)

/datum/supply_pack/medical/randomvirus //contains 5 utility viro symptoms. If virus customizing is on, contains 5 random cultures instead
	name = "Virus Sample Crate"
	desc = "Contains five experimental disease cultures for epidemiological research"
	cost = 3000
	max_supply = 3
	access = ACCESS_VIROLOGY
	access_budget = ACCESS_VIROLOGY
	contains = list(/obj/item/reagent_containers/cup/bottle/inorganic_virion,
					/obj/item/reagent_containers/cup/bottle/necrotic_virion,
					/obj/item/reagent_containers/cup/bottle/evolution_virion,
					/obj/item/reagent_containers/cup/bottle/adaptation_virion,
					/obj/item/reagent_containers/cup/bottle/aggression_virion)
	crate_name = "virus sample crate"
	crate_type = /obj/structure/closet/crate/secure/plasma
	dangerous = TRUE

/datum/supply_pack/medical/randomvirus/fill(obj/structure/closet/crate/C)
	for(var/item in contains)
		if(CONFIG_GET(flag/chemviro_allowed))
			new /obj/item/reagent_containers/cup/bottle/random_virus(C)
		else
			new item(C)


/datum/supply_pack/medical/virology
	name = "Junior Epidemiology Kit"
	desc = "Contains the necessary supplies to start an epidemiological research lab. P.A.N.D.E.M.I.C. not included. Comes with a free virologist action figure!"
	cost = 1500
	max_supply = 4
	access = ACCESS_VIROLOGY
	contains = list(/obj/item/food/monkeycube,
					/obj/item/reagent_containers/cup/glass/bottle/virusfood,
					/obj/item/reagent_containers/cup/bottle/mutagen,
					/obj/item/reagent_containers/cup/bottle/formaldehyde,
					/obj/item/reagent_containers/cup/bottle/synaptizine,
					/obj/item/storage/box/beakers,
					/obj/item/toy/figure/virologist)
	crate_name = "Junior Epidemiology Kit"
	dangerous = TRUE

/datum/supply_pack/medical/vending
	name = "Medical Vending Crate"
	desc = "Contains one NanoMed Plus refill and one wall-mounted NanoMed refill."
	cost = 1500
	max_supply = 6
	contains = list(/obj/item/vending_refill/medical,
					/obj/item/vending_refill/wallmed)
	crate_name = "medical vending crate"

/datum/supply_pack/medical/virus
	name = "Virus Crate"
	desc = "Contains several contagious virus samples, ranging from annoying to lethal. Balled-up jeans not included. Requires CMO access to open."
	cost = 2000
	max_supply = 3
	access = ACCESS_CMO
	access_budget = ACCESS_VIROLOGY
	contraband = TRUE
	contains = list(/obj/item/reagent_containers/cup/bottle/fake_gbs,
					/obj/item/reagent_containers/cup/bottle/magnitis,
					/obj/item/reagent_containers/cup/bottle/pierrot_throat,
					/obj/item/reagent_containers/cup/bottle/brainrot,
					/obj/item/reagent_containers/cup/bottle/anxiety,
					/obj/item/reagent_containers/cup/bottle/beesease)
	crate_name = "virus crate"
	crate_type = /obj/structure/closet/crate/secure/plasma
	dangerous = TRUE

/datum/supply_pack/medical/pandemic
	name = "Pandemic Replacement Crate"
	desc = "Contains a replacement P.A.N.D.E.M.I.C. in case the ones in virology get destroyed or you want to build a new lab."
	cost = 7500
	max_supply = 2
	access = ACCESS_VIROLOGY
	contains = list(/obj/machinery/computer/pandemic)
	crate_name = "P.A.N.D.E.M.I.C. Replacement Crate"
	dangerous = TRUE

/datum/supply_pack/medical/chem_bags
	name = "Chembag Refill Crate"
	desc = "Contains 3 bags, containing Bicaridine, Kelotane and Anti-toxin for when the chemist is too busy making methamphetamines."
	cost = 1000
	max_supply = 3
	contains = list(/obj/item/reagent_containers/chem_bag/bicaridine,
					/obj/item/reagent_containers/chem_bag/kelotane,
					/obj/item/reagent_containers/chem_bag/antitoxin)
	crate_name = "Chembag Refill Crate"
//////////////////////////////////////////////////////////////////////////////
//////////////////////////// Science /////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/science
	group = "Science"
	access_budget = ACCESS_RESEARCH
	crate_type = /obj/structure/closet/crate/science

/datum/supply_pack/science/plasma
	name = "Plasma Assembly Crate"
	desc = "Everything you need to burn something to the ground, this contains three plasma assembly sets. Each set contains a plasma tank, igniter, proximity sensor, and timer! Warranty void if exposed to high temperatures. Requires Toxins access to open."
	cost = 800
	max_supply = 3
	access = ACCESS_TOX_STORAGE
	access_budget = ACCESS_TOX_STORAGE
	contains = list(/obj/item/tank/internals/plasma,
					/obj/item/tank/internals/plasma,
					/obj/item/tank/internals/plasma,
					/obj/item/assembly/igniter,
					/obj/item/assembly/igniter,
					/obj/item/assembly/igniter,
					/obj/item/assembly/prox_sensor,
					/obj/item/assembly/prox_sensor,
					/obj/item/assembly/prox_sensor,
					/obj/item/assembly/timer,
					/obj/item/assembly/timer,
					/obj/item/assembly/timer)
	crate_name = "plasma assembly crate"
	crate_type = /obj/structure/closet/crate/secure/plasma

/datum/supply_pack/science/robotics
	name = "Robotics Assembly Crate"
	desc = "The tools you need to replace those finicky humans with a loyal robot army! Contains four proximity sensors, two empty first aid kits, two health analyzers, two red hardhats, two mechanical toolboxes, and two cleanbot assemblies! Requires Robotics access to open."
	cost = 1200
	max_supply = 4
	access = ACCESS_ROBOTICS
	access_budget = ACCESS_ROBOTICS
	contains = list(/obj/item/assembly/prox_sensor,
					/obj/item/assembly/prox_sensor,
					/obj/item/assembly/prox_sensor,
					/obj/item/assembly/prox_sensor,
					/obj/item/storage/firstaid,
					/obj/item/storage/firstaid,
					/obj/item/healthanalyzer,
					/obj/item/healthanalyzer,
					/obj/item/clothing/head/utility/hardhat/red,
					/obj/item/clothing/head/utility/hardhat/red,
					/obj/item/storage/toolbox/mechanical,
					/obj/item/storage/toolbox/mechanical,
					/obj/item/bot_assembly/cleanbot,
					/obj/item/bot_assembly/cleanbot)
	crate_name = "robotics assembly crate"
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/science/recharging
	name = "Recharging Station Crate"
	desc = "If you are looking for an improvement that makes your station more suitable for silicons, this is the pack for you! Contains all the materials required to put together a recharging station. Tools not included."
	cost = 2500
	max_supply = 4
	access = ACCESS_ROBOTICS
	contains = list(/obj/item/stack/sheet/iron/five,
					/obj/item/stack/cable_coil/random/five,
					/obj/item/circuitboard/machine/cyborgrecharger,
					/obj/item/stock_parts/capacitor,
					/obj/item/stock_parts/cell,
					/obj/item/stock_parts/manipulator)
	crate_name = "recharging station crate"
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/science/inducers
	name = "NT-50 Inducers Crate"
	desc = "No rechargers? No problem, with the NT-50 EPI, you can recharge any standard cell-based equipment anytime, anywhere! Contains two Science inducers."
	cost = 1000
	max_supply = 3
	contains = list(/obj/item/inducer/sci {cell_type = /obj/item/stock_parts/cell/inducer_supply; opened = 0}, /obj/item/inducer/sci {cell_type = /obj/item/stock_parts/cell/inducer_supply; opened = 0}) //FALSE doesn't work in modified type paths apparently.
	crate_name = "inducer crate"

/datum/supply_pack/science/rped
	name = "RPED crate"
	desc = "Need to rebuild the ORM but science got annihialted after a bomb test? Buy this for the most advanced parts NT can give you."
	cost = 800
	max_supply = 3
	access_budget = FALSE
	contains = list(/obj/item/storage/part_replacer/cargo)
	crate_name = "\improper RPED crate"

/datum/supply_pack/science/shieldwalls
	name = "Shield Generator Crate"
	desc = "These high powered Shield Wall Generators are guaranteed to keep any unwanted lifeforms on the outside, where they belong! Contains four shield wall generators. Requires Teleporter access to open."
	cost = 1700
	max_supply = 4
	access = ACCESS_TELEPORTER
	access = ACCESS_TELEPORTER
	contains = list(
		/obj/machinery/power/shieldwallgen,
		/obj/machinery/power/shieldwallgen,
		/obj/machinery/power/shieldwallgen,
		/obj/machinery/power/shieldwallgen
	)
	crate_name = "shield generators crate"
	crate_type = /obj/structure/closet/crate/secure/science

/datum/supply_pack/science/modularpc
	name = "Deluxe Silicate Selections restocking unit"
	desc = "What's a computer? Contains Deluxe Silicate Selections restocking unit."
	cost = 5500
	max_supply = 4
	contains = list(/obj/item/vending_refill/modularpc)
	crate_name = "computer supply crate"

/datum/supply_pack/science/monkey_helmets
	name = "Monkey Mind Magnification Helmet Crate"
	desc = "Some research is best done with monkeys, yet sometimes they're just too dumb to complete more complicated tasks. These helmets should help."
	cost = 1500
	max_supply = 1
	contains = list(/obj/item/clothing/head/helmet/monkey_sentience_helmet,
					/obj/item/clothing/head/helmet/monkey_sentience_helmet)
	crate_name = "monkey mind magnification crate"

/datum/supply_pack/science/transfer_valves
	name = "Tank Transfer Valves Crate"
	desc = "The key ingredient for making a lot of people very angry very fast. Contains two tank transfer valves. Requires RD access to open."
	cost = 4000
	max_supply = 3
	access = ACCESS_RD
	contains = list(/obj/item/transfer_valve,
					/obj/item/transfer_valve)
	crate_name = "tank transfer valves crate"
	crate_type = /obj/structure/closet/crate/secure/science
	dangerous = TRUE

/datum/supply_pack/science/xenobio
	name = "Xenobiology Lab Crate"
	desc = "In case a freak accident has rendered the xenobiology lab non-functional! Contains two grey slime extracts, some plasma, and the required circuit boards to set up your xenobiology lab up and running! Requires Xenobiology access to open."
	cost = 10000
	max_supply = 2
	access = ACCESS_XENOBIOLOGY
	access_budget = ACCESS_XENOBIOLOGY
	contains = list(/obj/item/slime_extract/grey,
					/obj/item/slime_extract/grey,
					/obj/item/reagent_containers/syringe/plasma,
					/obj/item/circuitboard/computer/xenobiology,
					/obj/item/circuitboard/machine/monkey_recycler,
					/obj/item/circuitboard/machine/processor/slime)
	crate_name = "xenobiology starter crate"
	crate_type = /obj/structure/closet/crate/secure/science

//////////////////////////////////////////////////////////////////////////////
/////////////////////////////// Service //////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/service
	group = "Service"

/datum/supply_pack/service/cargo_supples
	name = "Cargo Supplies Crate"
	desc = "Sold everything that wasn't bolted down? You can get right back to work with this crate containing stamps, an export scanner, destination tagger, hand labeler and some package wrapping."
	cost = 700
	max_supply = 6
	access_budget = ACCESS_CARGO
	contains = list(/obj/item/stamp,
					/obj/item/stamp/denied,
					/obj/item/export_scanner,
					/obj/item/dest_tagger,
					/obj/item/hand_labeler,
					/obj/item/stack/package_wrap)
	crate_name = "cargo supplies crate"

/datum/supply_pack/service/noslipfloor
	name = "High-traction Floor Tiles"
	desc = "Make slipping a thing of the past with thirty industrial-grade anti-slip floor tiles!"
	cost = 800
	max_supply = 5
	access_budget = ACCESS_JANITOR
	contains = list(/obj/item/stack/tile/noslip/thirty)
	crate_name = "high-traction floor tiles crate"

/datum/supply_pack/service/noslipfloorbulk
	name = "Bulk High-traction Floor Tiles"
	desc = "Make an entire department not need to know the pain of slipping on a wet floor with 120 anti-slip floor tiles!"
	cost = 2000
	max_supply = 2
	access_budget = ACCESS_JANITOR
	contains = list(/obj/item/stack/tile/noslip/thirty,
					/obj/item/stack/tile/noslip/thirty,
					/obj/item/stack/tile/noslip/thirty,
					/obj/item/stack/tile/noslip/thirty)
	crate_name = "high-traction floor tiles crate"

/datum/supply_pack/service/janitor
	name = "Janitorial Supplies Crate"
	desc = "Fight back against dirt and grime with Nanotrasen's Janitorial Essentials(tm)! Contains three buckets, caution signs, and cleaner grenades. Also has a single mop, broom, spray cleaner, rag, and trash bag."
	cost = 800
	max_supply = 4
	access_budget = ACCESS_JANITOR
	contains = list(/obj/item/reagent_containers/cup/bucket,
					/obj/item/reagent_containers/cup/bucket,
					/obj/item/reagent_containers/cup/bucket,
					/obj/item/mop,
					/obj/item/pushbroom,
					/obj/item/clothing/suit/caution,
					/obj/item/clothing/suit/caution,
					/obj/item/clothing/suit/caution,
					/obj/item/storage/bag/trash,
					/obj/item/reagent_containers/spray/cleaner,
					/obj/item/reagent_containers/cup/rag,
					/obj/item/grenade/chem_grenade/cleaner,
					/obj/item/grenade/chem_grenade/cleaner,
					/obj/item/grenade/chem_grenade/cleaner)
	crate_name = "janitorial supplies crate"

/datum/supply_pack/service/janitor/janicart
	name = "Janitorial Cart and Galoshes Crate"
	desc = "The keystone to any successful janitor. As long as you have feet, this pair of galoshes will keep them firmly planted on the ground. Also contains a janitorial cart."
	cost = 1000
	max_supply = 2
	access_budget = ACCESS_JANITOR
	contains = list(/obj/structure/janitorialcart,
					/obj/item/clothing/shoes/galoshes)
	crate_name = "janitorial cart crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/service/janitor/janitank
	name = "Janitor Backpack Crate"
	desc = "Call forth divine judgment upon dirt and grime with this high capacity janitor backpack. Contains 500 units of station-cleansing cleaner."
	cost = 700
	max_supply = 4
	access_budget = ACCESS_JANITOR
	contains = list(/obj/item/watertank/janitor)
	crate_name = "janitor backpack crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/service/mule
	name = "MULEbot Crate"
	desc = "Pink-haired Quartermaster not doing her job? Replace her with this tireless worker, today!"
	cost = 1700
	max_supply = 3
	access_budget = ACCESS_CARGO
	contains = list(/mob/living/simple_animal/bot/mulebot)
	crate_name = "\improper MULEbot Crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/service/party
	name = "Party Equipment"
	desc = "Celebrate both life and death on the station with Nanotrasen's Party Essentials(tm)! Contains a special party area, seven colored glowsticks, four beers, two ales, and a bottle of patron, goldschlager, and shaker!"
	cost = 1500
	max_supply = 5
	contains = list(/obj/item/storage/box/drinkingglasses,
					/obj/item/reagent_containers/cup/glass/shaker,
					/obj/item/reagent_containers/cup/glass/bottle/patron,
					/obj/item/reagent_containers/cup/glass/bottle/goldschlager,
					/obj/item/reagent_containers/cup/glass/bottle/ale,
					/obj/item/reagent_containers/cup/glass/bottle/ale,
					/obj/item/reagent_containers/cup/glass/bottle/beer,
					/obj/item/reagent_containers/cup/glass/bottle/beer,
					/obj/item/reagent_containers/cup/glass/bottle/beer,
					/obj/item/reagent_containers/cup/glass/bottle/beer,
					/obj/item/flashlight/glowstick,
					/obj/item/flashlight/glowstick/red,
					/obj/item/flashlight/glowstick/blue,
					/obj/item/flashlight/glowstick/cyan,
					/obj/item/flashlight/glowstick/orange,
					/obj/item/flashlight/glowstick/yellow,
					/obj/item/flashlight/glowstick/pink,
					/obj/item/survivalcapsule/party)
	crate_name = "party equipment crate"

/datum/supply_pack/service/carpet
	name = "Premium Carpet Crate"
	desc = "Plasteel floor tiles getting on your nerves? These stacks of extra soft carpet will tie any room together."
	cost = 700
	max_supply = 5
	contains = list(/obj/item/stack/tile/carpet/fifty,
					/obj/item/stack/tile/carpet/fifty,
					/obj/item/stack/tile/carpet/black/fifty,
					/obj/item/stack/tile/carpet/black/fifty)
	crate_name = "premium carpet crate"

/datum/supply_pack/service/carpet_exotic
	name = "Exotic Carpet Crate"
	desc = "Exotic carpets straight from Space Russia, for all your decorating needs. Contains 100 tiles each of 8 different flooring patterns."
	cost = 2000
	max_supply = 3
	contains = list(/obj/item/stack/tile/carpet/blue/fifty,
					/obj/item/stack/tile/carpet/blue/fifty,
					/obj/item/stack/tile/carpet/cyan/fifty,
					/obj/item/stack/tile/carpet/cyan/fifty,
					/obj/item/stack/tile/carpet/green/fifty,
					/obj/item/stack/tile/carpet/green/fifty,
					/obj/item/stack/tile/carpet/orange/fifty,
					/obj/item/stack/tile/carpet/orange/fifty,
					/obj/item/stack/tile/carpet/purple/fifty,
					/obj/item/stack/tile/carpet/purple/fifty,
					/obj/item/stack/tile/carpet/red/fifty,
					/obj/item/stack/tile/carpet/red/fifty,
					/obj/item/stack/tile/carpet/royalblue/fifty,
					/obj/item/stack/tile/carpet/royalblue/fifty,
					/obj/item/stack/tile/eighties/fifty,
					/obj/item/stack/tile/eighties/fifty,
					/obj/item/stack/tile/carpet/royalblack/fifty,
					/obj/item/stack/tile/carpet/royalblack/fifty)
	crate_name = "exotic carpet crate"

/datum/supply_pack/service/lightbulbs
	name = "Replacement Lights"
	desc = "May the light of Aether shine upon this station! Or at least, the light of fifty six light tubes and twenty eight light bulbs."
	cost = 800
	max_supply = 7
	contains = list(/obj/item/storage/box/lights/mixed,
					/obj/item/storage/box/lights/mixed,
					/obj/item/storage/box/lights/mixed,
					/obj/item/storage/box/lights/mixed)
	crate_name = "replacement lights"

/datum/supply_pack/service/minerkit
	name = "Shaft Miner Starter Kit"
	desc = "All the miners died too fast? Assistant wants to get a taste of life off-station? Either way, this kit is the best way to turn a regular crewman into an ore-producing, monster-slaying machine. Contains meson goggles, a pickaxe, advanced mining scanner, cargo headset, ore bag, gasmask, an explorer suit and a miner ID upgrade. Requires QM access to open."
	cost = 800
	max_supply = 4
	access = ACCESS_QM
	access_budget = ACCESS_MINING_STATION
	contains = list(/obj/item/storage/backpack/duffelbag/mining_conscript)
	crate_name = "shaft miner starter kit"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/service/vending/bartending
	name = "Booze-o-mat and Coffee Supply Crate"
	desc = "Bring on the booze and coffee vending machine refills."
	cost = 1200
	max_supply = 6
	access_budget = ACCESS_BAR
	contains = list(/obj/item/vending_refill/boozeomat,
					/obj/item/vending_refill/coffee)
	crate_name = "bartending supply crate"

/datum/supply_pack/service/vending/cigarette
	name = "Cigarette Supply Crate"
	desc = "Don't believe the reports - smoke today! Contains a cigarette vending machine refill."
	cost = 1200
	max_supply = 5
	contains = list(/obj/item/vending_refill/cigarette)
	crate_name = "cigarette supply crate"
	crate_type = /obj/structure/closet/crate

/datum/supply_pack/service/vending/dinnerware
	name = "Kitchen Supply Crate"
	desc = "More knives and ingredients for the chef."
	cost = 500
	max_supply = 6
	access_budget = ACCESS_KITCHEN
	contains = list(/obj/item/vending_refill/dinnerware)
	crate_name = "kitchen supply crate"

/datum/supply_pack/service/vending/games
	name = "Games Supply Crate"
	desc = "Get your game on with this game vending machine refill."
	cost = 800
	max_supply = 6
	contains = list(/obj/item/vending_refill/games)
	crate_name = "games supply crate"
	crate_type = /obj/structure/closet/crate

/datum/supply_pack/service/vending/imported
	name = "Imported Vending Machines"
	desc = "Vending machines famous in other parts of the galaxy."
	cost = 3000
	max_supply = 6
	contains = list(/obj/item/vending_refill/sustenance,
					/obj/item/vending_refill/robotics,
					/obj/item/vending_refill/sovietsoda,
					/obj/item/vending_refill/engineering)
	crate_name = "unlabeled supply crate"

/datum/supply_pack/service/vending/ptech
	name = "PTech Supply Crate"
	desc = "Not enough job disks after half the crew lost their PDA to explosions? This may fix it."
	cost = 800
	max_supply = 6
	access_budget = ACCESS_HOP
	contains = list(/obj/item/vending_refill/job_disk)
	crate_name = "ptech supply crate"

/datum/supply_pack/service/vending/snack
	name = "Snack Supply Crate"
	desc = "One vending machine refill of cavity-bringin' goodness! The number one dentist recommended order!"
	cost = 800
	max_supply = 6
	contains = list(/obj/item/vending_refill/snack)
	crate_name = "snacks supply crate"

/datum/supply_pack/service/vending/cola
	name = "Softdrinks Supply Crate"
	desc = "Got whacked by a toolbox, but you still have those pesky teeth? Get rid of those pearly whites with this soda machine refill, today!"
	cost = 800
	max_supply = 6
	contains = list(/obj/item/vending_refill/cola)
	crate_name = "soft drinks supply crate"

/datum/supply_pack/service/vending/vendomat
	name = "Vendomat Supply Crate"
	desc = "More tools for your IED testing facility."
	cost = 800
	max_supply = 6
	contains = list(/obj/item/vending_refill/assist)
	crate_name = "vendomat supply crate"

/datum/supply_pack/service/randomized/donkpockets
	name = "Donk Pocket Variety Crate"
	desc = "Featuring a line up of Donk Co.'s most popular pastry!"
	cost = 1500
	max_supply = 5
	contains = list(/obj/item/storage/box/donkpockets/donkpocketspicy,
	/obj/item/storage/box/donkpockets/donkpocketteriyaki,
	/obj/item/storage/box/donkpockets/donkpocketpizza,
	/obj/item/storage/box/donkpockets/donkpocketberry,
	/obj/item/storage/box/donkpockets/donkpockethonk)
	crate_name = "donk pocket crate"

//////////////////////////////////////////////////////////////////////////////
//////////////////////////// Organic /////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/organic
	group = "Food & Hydroponics"
	crate_type = /obj/structure/closet/crate/freezer

/datum/supply_pack/organic/hydroponics/beekeeping_suits
	name = "Beekeeper Suit Crate"
	desc = "Bee business booming? Better be benevolent and boost botany by bestowing bi-Beekeeper-suits! Contains two beekeeper suits and matching headwear."
	cost = 800
	max_supply = 4
	contains = list(/obj/item/clothing/head/utility/beekeeper_head,
					/obj/item/clothing/suit/utility/beekeeper_suit,
					/obj/item/clothing/head/utility/beekeeper_head,
					/obj/item/clothing/suit/utility/beekeeper_suit)
	crate_name = "beekeeper suits"
	crate_type = /obj/structure/closet/crate/hydroponics

/datum/supply_pack/organic/hydroponics/beekeeping_fullkit
	name = "Beekeeping Starter Crate"
	desc = "BEES BEES BEES. Contains three honey frames, a beekeeper suit and helmet, flyswatter, bee house, and, of course, a pure-bred Nanotrasen-Standardized Queen Bee!"
	cost = 1400
	max_supply = 2
	contains = list(/obj/structure/beebox/unwrenched,
					/obj/item/honey_frame,
					/obj/item/honey_frame,
					/obj/item/honey_frame,
					/obj/item/queen_bee/bought,
					/obj/item/clothing/head/utility/beekeeper_head,
					/obj/item/clothing/suit/utility/beekeeper_suit,
					/obj/item/melee/flyswatter)
	crate_name = "beekeeping starter crate"
	crate_type = /obj/structure/closet/crate/hydroponics

/datum/supply_pack/organic/randomized/chef
	name = "Excellent Meat Crate"
	desc = "The best cuts in the whole galaxy."
	cost = 1700
	max_supply = 5
	access_budget = ACCESS_KITCHEN
	contains = list(/obj/item/food/meat/slab/human/mutant/slime,
					/obj/item/food/meat/slab/killertomato,
					/obj/item/food/meat/slab/bear,
					/obj/item/food/meat/slab/xeno,
					/obj/item/food/meat/slab/spider,
					/obj/item/food/meat/rawbacon,
					/obj/item/food/meat/slab/penguin,
					/obj/item/food/spiderleg,
					/obj/item/food/fishmeat/carp,
					/obj/item/food/meat/slab/human)
	crate_name = "food crate"

/datum/supply_pack/organic/randomized/chef/fill(obj/structure/closet/crate/C)
	for(var/i in 1 to 15)
		var/item = pick(contains)
		new item(C)

/datum/supply_pack/organic/exoticseeds
	name = "Exotic Seeds Crate"
	desc = "Any entrepreneuring botanist's dream. Contains fourteen different seeds, including three replica-pod seeds and two mystery seeds!"
	cost = 1000
	max_supply = 3
	access_budget = ACCESS_HYDROPONICS
	contains = list(/obj/item/seeds/nettle,
					/obj/item/seeds/dionapod,
					/obj/item/seeds/dionapod,
					/obj/item/seeds/dionapod,
					/obj/item/seeds/plump,
					/obj/item/seeds/liberty,
					/obj/item/seeds/amanita,
					/obj/item/seeds/reishi,
					/obj/item/seeds/banana,
					/obj/item/seeds/bamboo,
					/obj/item/seeds/eggplant/eggy,
					/obj/item/seeds/flower/rainbow_bunch,
					/obj/item/seeds/flower/rainbow_bunch,
					/obj/item/seeds/random,
					/obj/item/seeds/random)
	crate_name = "exotic seeds crate"
	crate_type = /obj/structure/closet/crate/hydroponics

/datum/supply_pack/organic/food
	name = "Food Crate"
	desc = "Get things cooking with this crate full of useful ingredients! Contains a dozen eggs, three bananas, and some flour, rice, milk, soymilk, salt, pepper, enzyme, sugar, and monkeymeat."
	cost = 1000
	max_supply = 4
	access_budget = ACCESS_KITCHEN
	contains = list(/obj/item/reagent_containers/condiment/flour,
					/obj/item/reagent_containers/condiment/rice,
					/obj/item/reagent_containers/condiment/milk,
					/obj/item/reagent_containers/condiment/soymilk,
					/obj/item/reagent_containers/condiment/saltshaker,
					/obj/item/reagent_containers/condiment/peppermill,
					/obj/item/storage/fancy/egg_box,
					/obj/item/reagent_containers/condiment/enzyme,
					/obj/item/reagent_containers/condiment/sugar,
					/obj/item/food/meat/slab/monkey,
					/obj/item/food/grown/banana,
					/obj/item/food/grown/banana,
					/obj/item/food/grown/banana)
	crate_name = "food crate"

/datum/supply_pack/organic/randomized/chef/fruits
	name = "Fruit Crate"
	desc = "Rich of vitamins, may contain oranges."
	cost = 1200
	max_supply = 7
	access_budget = ACCESS_KITCHEN
	contains = list(/obj/item/food/grown/citrus/lime,
					/obj/item/food/grown/citrus/orange,
					/obj/item/food/grown/watermelon,
					/obj/item/food/grown/apple,
					/obj/item/food/grown/berries,
					/obj/item/food/grown/citrus/lemon)
	crate_name = "food crate"

/datum/supply_pack/organic/cream_piee
	name = "High-yield Clown-grade Cream Pie Crate"
	desc = "Designed by Aussec's Advanced Warfare Research Division, these high-yield, Clown-grade cream pies are powered by a synergy of performance and efficiency. Guaranteed to provide maximum results."
	cost = 6000
	max_supply = 4
	access = ACCESS_THEATRE
	access_budget = ACCESS_THEATRE
	contains = list(/obj/item/storage/backpack/duffelbag/clown/cream_pie)
	crate_name = "party equipment crate"
	contraband = TRUE
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/organic/hydroponics
	name = "Hydroponics Crate"
	desc = "Supplies for growing a great garden! Contains two bottles of ammonia, two Plant-B-Gone spray bottles, a hatchet, cultivator, plant analyzer, as well as a pair of leather gloves and a botanist's apron."
	cost = 800
	max_supply = 4
	access_budget = ACCESS_HYDROPONICS
	contains = list(/obj/item/reagent_containers/spray/plantbgone,
					/obj/item/reagent_containers/spray/plantbgone,
					/obj/item/reagent_containers/cup/bottle/ammonia,
					/obj/item/reagent_containers/cup/bottle/ammonia,
					/obj/item/hatchet,
					/obj/item/cultivator,
					/obj/item/plant_analyzer,
					/obj/item/clothing/gloves/botanic_leather,
					/obj/item/clothing/suit/apron,
					/obj/item/storage/box/disks_plantgene)
	crate_name = "hydroponics crate"
	crate_type = /obj/structure/closet/crate/hydroponics

/datum/supply_pack/organic/hydroponics/hydrotank
	name = "Hydroponics Backpack Crate"
	desc = "Bring on the flood with this high-capacity backpack crate. Contains 500 units of life-giving H2O. Requires hydroponics access to open."
	cost = 700
	max_supply = 4
	contains = list(/obj/item/watertank)
	crate_name = "hydroponics backpack crate"
	crate_type = /obj/structure/closet/crate/secure

/datum/supply_pack/organic/pizza
	name = "Pizza Crate"
	desc = "Why visit the kitchen when you can have five random pizzas in a fraction of the time? \
		Best prices this side of the galaxy! All deliveries are guaranteed to be 99% anomaly-free."
	cost = 5000 // Best prices this side of the galaxy.
	max_supply = 3
	contains = list(/obj/item/pizzabox/margherita,
					/obj/item/pizzabox/mushroom,
					/obj/item/pizzabox/meat,
					/obj/item/pizzabox/vegetable,
					/obj/item/pizzabox/pineapple)
	crate_name = "pizza crate"
	///Whether we've provided an infinite pizza box already this shift or not.
	var/static/anomalous_box_provided = FALSE
	///The percentage chance (per pizza) of this supply pack to spawn an anomalous pizza box.
	var/anna_molly_box_chance = 1
	///Total tickets in our figurative lottery (per pizza) to decide if we create a bomb box, and if so what type. 1 to 3 create a bomb. The rest do nothing.
	var/boombox_tickets = 100
	///Whether we've provided a bomb pizza box already this shift or not.
	var/boombox_provided = FALSE

/datum/supply_pack/organic/pizza/fill(obj/structure/closet/crate/C)
	. = ..()

	var/list/pizza_types = list(
		/obj/item/food/pizza/margherita = 10,
		/obj/item/food/pizza/meat = 10,
		/obj/item/food/pizza/mushroom = 10,
		/obj/item/food/pizza/vegetable = 10,
		/obj/item/food/pizza/donkpocket = 10,
		/obj/item/food/pizza/dank = 7,
		/obj/item/food/pizza/sassysage = 10,
		/obj/item/food/pizza/pineapple = 10,
		/obj/item/food/pizza/arnold = 3
	) //weighted by chance to disrupt eaters' rounds

	for(var/obj/item/pizzabox/P in C)
		if(!anomalous_box_provided)
			if(prob(anna_molly_box_chance)) //1% chance for each box, so 4% total chance per order
				var/obj/item/pizzabox/infinite/fourfiveeight = new(C)
				fourfiveeight.boxtag = P.boxtag
				fourfiveeight.boxtag_set = TRUE
				fourfiveeight.update_icon()
				qdel(P)
				anomalous_box_provided = TRUE
				log_game("An anomalous pizza box was provided in a pizza crate at during cargo delivery")
				if(prob(50))
					addtimer(CALLBACK(src, PROC_REF(anomalous_pizza_report)), rand(300, 1800))
				else
					message_admins("An anomalous pizza box was silently created with no command report in a pizza crate delivery.")
				continue

		if(!boombox_provided)
			var/boombox_lottery = rand(1,boombox_tickets)
			var/boombox_type
			switch(boombox_lottery)
				if(1 to 2)
					boombox_type = /obj/item/pizzabox/bomb/armed //explodes after opening
				if(3)
					boombox_type = /obj/item/pizzabox/bomb //free bomb

			if(boombox_type)
				new boombox_type(C)
				qdel(P)
				boombox_provided = TRUE
				log_game("A bomb pizza box was created by a pizza crate delivery.")
				message_admins("A bomb pizza box has arrived in a pizza crate delivery.")
				continue

		//here we randomly replace our pizzas for a chance at the full range
		var/obj/item/food/pizza/replacement_type = pick_weight(pizza_types)
		pizza_types -= replacement_type
		if(replacement_type && !istype(P.pizza, replacement_type))
			QDEL_NULL(P.pizza)
			P.pizza = new replacement_type
			P.boxtag = P.pizza.boxtag
			P.boxtag_set = TRUE
			P.update_icon()

/datum/supply_pack/organic/pizza/proc/anomalous_pizza_report()
	print_command_report("[station_name()], our anomalous materials divison has reported a missing object that is highly likely to have been sent to your station during a routine cargo \
	delivery. Please search all crates and manifests provided with the delivery and return the object if is located. The object resembles a standard <b>\[DATA EXPUNGED\]</b> and is to be \
	considered <b>\[REDACTED\]</b> and returned at your leisure. Note that objects the anomaly produces are specifically attuned exactly to the individual opening the anomaly; regardless \
	of species, the individual will find the object edible and it will taste great according to their personal definitions, which vary significantly based on person and species.")

/datum/supply_pack/organic/potted_plants
	name = "Potted Plants Crate"
	desc = "Spruce up the station with these lovely plants! Contains a random assortment of five potted plants from Nanotrasen's potted plant research division. Warranty void if thrown."
	cost = 550
	max_supply = 6
	contains = list(/obj/item/kirbyplants/random,
					/obj/item/kirbyplants/random,
					/obj/item/kirbyplants/random,
					/obj/item/kirbyplants/random,
					/obj/item/kirbyplants/random)
	crate_name = "potted plants crate"
	crate_type = /obj/structure/closet/crate/hydroponics

/datum/supply_pack/organic/seeds
	name = "Seeds Crate"
	desc = "Big things have small beginnings. Contains fourteen different seeds."
	cost = 800
	max_supply = 5
	contains = list(/obj/item/seeds/chili,
					/obj/item/seeds/cotton,
					/obj/item/seeds/berry,
					/obj/item/seeds/corn,
					/obj/item/seeds/eggplant,
					/obj/item/seeds/tomato,
					/obj/item/seeds/soya,
					/obj/item/seeds/wheat,
					/obj/item/seeds/wheat/rice,
					/obj/item/seeds/carrot,
					/obj/item/seeds/sunflower,
					/obj/item/seeds/chanter,
					/obj/item/seeds/potato,
					/obj/item/seeds/sugarcane)
	crate_name = "seeds crate"
	crate_type = /obj/structure/closet/crate/hydroponics

/datum/supply_pack/organic/randomized/chef/vegetables
	name = "Vegetables Crate"
	desc = "Grown in vats."
	cost = 1000
	max_supply = 4
	access_budget = ACCESS_KITCHEN
	contains = list(/obj/item/food/grown/chili,
					/obj/item/food/grown/corn,
					/obj/item/food/grown/tomato,
					/obj/item/food/grown/potato,
					/obj/item/food/grown/carrot,
					/obj/item/food/grown/mushroom/chanterelle,
					/obj/item/food/grown/onion,
					/obj/item/food/grown/pumpkin)
	crate_name = "food crate"

/datum/supply_pack/organic/vending/hydro_refills
	name = "Hydroponics Vending Machines Refills"
	desc = "When the clown takes all the banana seeds. Contains a NutriMax refill and an MegaSeed Servitor refill."
	cost = 1700
	max_supply = 6
	access_budget = ACCESS_HYDROPONICS
	crate_type = /obj/structure/closet/crate
	contains = list(/obj/item/vending_refill/hydroseeds,
					/obj/item/vending_refill/hydronutrients)
	crate_name = "hydroponics supply crate"

/datum/supply_pack/organic/grill
	name = "Grilling Starter Kit"
	desc = "Hey dad I'm Hungry. Hi Hungry I'm THE NEW GRILLING STARTER KIT ONLY 5000 BUX GET NOW! Contains a grill and fuel."
	cost = 5000
	max_supply = 3
	crate_type = /obj/structure/closet/crate
	contains = list(/obj/item/stack/sheet/mineral/coal/five,
					/obj/machinery/grill/unwrenched,
					/obj/item/reagent_containers/cup/soda_cans/monkey_energy
					)
	crate_name = "grilling starter kit crate"

/datum/supply_pack/organic/grillfuel
	name = "Grilling Fuel Kit"
	desc = "Contains propane and propane accessories. (Note: doesn't contain any actual propane.)"
	cost = 2000
	max_supply = 5
	crate_type = /obj/structure/closet/crate
	contains = list(/obj/item/stack/sheet/mineral/coal/ten,
					/obj/item/reagent_containers/cup/soda_cans/monkey_energy
					)
	crate_name = "grilling fuel kit crate"

/datum/supply_pack/organic/beefbroth

	name = "Beef Broth Bulk Crate"
	desc = "No one really wants to order beef broth so we're selling it in bulk!"
	cost = 5000
	max_supply = 3
	contraband = TRUE
	crate_type = /obj/structure/closet/crate
	contains = list(/obj/item/food/canned/beefbroth,
					/obj/item/food/canned/beefbroth,
					/obj/item/food/canned/beefbroth,
					/obj/item/food/canned/beefbroth,
					/obj/item/food/canned/beefbroth,
					/obj/item/food/canned/beefbroth,
					/obj/item/food/canned/beefbroth,
					/obj/item/food/canned/beefbroth,
					/obj/item/food/canned/beefbroth,
					/obj/item/food/canned/beefbroth
					)
	crate_name = "Beef Broth Care"
//////////////////////////////////////////////////////////////////////////////
////////////////////////////// Livestock /////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/critter
	group = "Livestock"
	crate_type = /obj/structure/closet/crate/critter
	max_supply = 4

/datum/supply_pack/critter/parrot
	name = "Bird Crate"
	desc = "Contains five expert telecommunication birds."
	cost = 4000
	contains = list(/mob/living/simple_animal/parrot)
	crate_name = "parrot crate"

/datum/supply_pack/critter/parrot/generate()
	. = ..()
	for(var/i in 1 to 4)
		new /mob/living/simple_animal/parrot(.)
	if(prob(1))
		new /mob/living/simple_animal/parrot/clock_hawk(.)

/datum/supply_pack/critter/butterfly
	name = "Butterflies Crate"
	desc = "Not a very dangerous insect, but they do give off a better image than, say, flies or cockroaches."//is that a motherfucking worm reference
	contraband = TRUE
	cost = 5000
	contains = list(/mob/living/simple_animal/butterfly)
	crate_name = "entomology samples crate"

/datum/supply_pack/critter/butterfly/generate()
	. = ..()
	for(var/i in 1 to 49)
		new /mob/living/simple_animal/butterfly(.)

/datum/supply_pack/critter/cat
	name = "Cat Crate"
	desc = "The cat goes meow! Comes with a collar and a nice cat toy! Cheeseburger not included."//i can't believe im making this reference
	cost = 5000 //Cats are worth as much as corgis.
	contains = list(/mob/living/simple_animal/pet/cat,
					/obj/item/clothing/neck/petcollar,
					/obj/item/toy/cattoy)
	crate_name = "cat crate"

/datum/supply_pack/critter/cat/generate()
	. = ..()
	if(prob(50))
		var/mob/living/simple_animal/pet/cat/C = locate() in .
		qdel(C)
		new /mob/living/simple_animal/pet/cat/Proc(.)

/datum/supply_pack/critter/cat/exotic
	name = "Exotic Cat Crate"
	desc = "Commes with one of the exotic cats, collar and a toy."
	cost = 5500
	contains = list(/obj/item/clothing/neck/petcollar,
					/obj/item/toy/cattoy)
	crate_name = "cat crate"

/datum/supply_pack/critter/cat/exotic/generate()
	. = ..()
	switch(rand(1, 5))
		if(1)
			new /mob/living/simple_animal/pet/cat/original(.)
		if(2)
			new /mob/living/simple_animal/pet/cat/breadcat(.)
		if(3)
			new /mob/living/simple_animal/pet/cat/cak(.)
		if(4)
			new /mob/living/simple_animal/pet/cat/space(.)
		if(5)
			new /mob/living/simple_animal/pet/cat/halal(.)

/datum/supply_pack/critter/chick
	name = "Chicken Crate"
	desc = "The chicken goes bwaak!"
	cost = 2000
	contains = list( /mob/living/simple_animal/chick)
	crate_name = "chicken crate"

/datum/supply_pack/critter/corgi
	name = "Corgi Crate"
	desc = "Considered the optimal dog breed by thousands of research scientists, this Corgi is but one dog from the millions of Ian's noble bloodline. Comes with a cute collar!"
	cost = 5000
	contains = list(/mob/living/basic/pet/dog/corgi,
					/obj/item/clothing/neck/petcollar)
	crate_name = "corgi crate"

/datum/supply_pack/critter/corgi/generate()
	. = ..()
	if(prob(50))
		var/mob/living/basic/pet/dog/corgi/D = locate() in .
		if(D.gender == FEMALE)
			qdel(D)
			new /mob/living/basic/pet/dog/corgi/Lisa(.)

/datum/supply_pack/critter/cow
	name = "Cow Crate"
	desc = "The cow goes moo!"
	cost = 3000
	contains = list(/mob/living/basic/cow)
	crate_name = "cow crate"

/datum/supply_pack/critter/crab
	name = "Crab Rocket"
	desc = "CRAAAAAAB ROCKET. CRAB ROCKET. CRAB ROCKET. CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB ROCKET. CRAFT. ROCKET. BUY. CRAFT ROCKET. CRAB ROOOCKET. CRAB ROOOOCKET. CRAB CRAB CRAB CRAB CRAB CRAB CRAB CRAB ROOOOOOOOOOOOOOOOOOOOOOCK EEEEEEEEEEEEEEEEEEEEEEEEE EEEETTTTTTTTTTTTAAAAAAAAA AAAHHHHHHHHHHHHH. CRAB ROCKET. CRAAAB ROCKEEEEEEEEEGGGGHHHHTT CRAB CRAB CRAABROCKET CRAB ROCKEEEET."//fun fact: i actually spent like 10 minutes and transcribed the entire video.
	cost = 5000
	contains = list(/mob/living/simple_animal/crab)
	crate_name = "look sir free crabs"
	DropPodOnly = TRUE

/datum/supply_pack/critter/crab/generate()
	. = ..()
	for(var/i in 1 to 49)
		new /mob/living/simple_animal/crab(.)

/datum/supply_pack/critter/corgis/exotic
	name = "Exotic Corgi Crate"
	desc = "Corgis fit for a king, these corgis come in a unique color to signify their superiority. Comes with a cute collar!"
	cost = 5500
	contains = list(/mob/living/basic/pet/dog/corgi/exoticcorgi,
					/obj/item/clothing/neck/petcollar)
	crate_name = "exotic corgi crate"

/datum/supply_pack/critter/fox
	name = "Fox Crate"
	desc = "The fox goes...? Comes with a collar!"//what does the fox say
	cost = 5000
	contains = list(/mob/living/simple_animal/pet/fox,
					/obj/item/clothing/neck/petcollar)
	crate_name = "fox crate"

/datum/supply_pack/critter/goat
	name = "Goat Crate"
	desc = "The goat goes baa! Warranty void if used as a replacement for Pete."
	cost = 2500
	contains = list(/mob/living/simple_animal/hostile/retaliate/goat)
	crate_name = "goat crate"

/datum/supply_pack/critter/mothroach
	name = "Mothroach Crate"
	desc = "Put the mothroach on your head and find out what true cuteness looks like."
	cost = 5000
	contains = list(/mob/living/basic/mothroach)
	crate_name = "mothroach crate"

/datum/supply_pack/critter/monkey
	name = "Monkey Cube Crate"
	desc = "Stop monkeying around! Contains five monkey cubes. Just add water!"
	cost = 1000
	contains = list (/obj/item/storage/box/monkeycubes)
	crate_type = /obj/structure/closet/crate
	crate_name = "monkey cube crate"
	small_item = TRUE

/datum/supply_pack/critter/pug
	name = "Pug Crate"
	desc = "Like a normal dog, but... squished. Comes with a nice collar!"
	cost = 5000
	contains = list(/mob/living/basic/pet/dog/pug,
					/obj/item/clothing/neck/petcollar)
	crate_name = "pug crate"

/datum/supply_pack/critter/bullterrier
	name = "Bull Terrier Crate"
	desc = "Like a normal dog, but with a head the shape of an egg. Comes with a nice collar!"
	cost = 5000
	contains = list(/mob/living/basic/pet/dog/bullterrier,
					/obj/item/clothing/neck/petcollar)
	crate_name = "bull terrier crate"

/datum/supply_pack/critter/snake
	name = "Snake Crate"
	desc = "Tired of these MOTHER FUCKING snakes on this MOTHER FUCKING space station? Then this isn't the crate for you. Contains three poisonous snakes."
	cost = 3000
	access_budget = ACCESS_SECURITY
	contains = list(/mob/living/simple_animal/hostile/retaliate/poison/snake,
					/mob/living/simple_animal/hostile/retaliate/poison/snake,
					/mob/living/simple_animal/hostile/retaliate/poison/snake)
	crate_name = "snake crate"

/datum/supply_pack/critter/capybara
	name = "Capybara Crate"
	desc = "Coconut doggy"
	cost = 10000
	contains = list(/mob/living/basic/pet/dog/corgi/capybara)
	crate_name = "capybara crate"

//////////////////////////////////////////////////////////////////////////////
//////////////////////////// Costumes & Toys /////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/costumes_toys
	group = "Costumes & Toys"

/datum/supply_pack/costumes_toys/randomised
	name = "Collectable Hats Crate"
	desc = "Flaunt your status with three unique, highly-collectable hats!"
	cost = 20000
	max_supply = 4
	var/num_contained = 3 //number of items picked to be contained in a randomised crate
	contains = list(/obj/item/clothing/head/collectable/chef,
					/obj/item/clothing/head/collectable/paper,
					/obj/item/clothing/head/collectable/tophat,
					/obj/item/clothing/head/collectable/captain,
					/obj/item/clothing/head/collectable/beret,
					/obj/item/clothing/head/collectable/welding,
					/obj/item/clothing/head/collectable/flatcap,
					/obj/item/clothing/head/collectable/pirate,
					/obj/item/clothing/head/collectable/kitty,
					/obj/item/clothing/head/collectable/rabbitears,
					/obj/item/clothing/head/collectable/wizard,
					/obj/item/clothing/head/collectable/hardhat,
					/obj/item/clothing/head/collectable/HoS,
					/obj/item/clothing/head/collectable/HoP,
					/obj/item/clothing/head/collectable/thunderdome,
					/obj/item/clothing/head/collectable/swat,
					/obj/item/clothing/head/collectable/slime,
					/obj/item/clothing/head/collectable/police,
					/obj/item/clothing/head/collectable/slime,
					/obj/item/clothing/head/collectable/xenom,
					/obj/item/clothing/head/collectable/petehat)
	crate_name = "collectable hats crate"
	crate_type = /obj/structure/closet/crate/wooden

/datum/supply_pack/costumes_toys/randomised/contraband
	name = "Contraband Crate"
	desc = "Psst.. bud... want some contraband? I can get you a poster, some nice cigs, dank, even some sponsored items...you know, the good stuff. Just keep it away from the cops, kay?"
	contraband = TRUE
	max_supply = 2
	cost = 3000
	num_contained = 7
	contains = list(/obj/item/poster/random_contraband,
					/obj/item/poster/random_contraband,
					/obj/item/food/grown/cannabis,
					/obj/item/food/grown/cannabis/rainbow,
					/obj/item/food/grown/cannabis/white,
					/obj/item/storage/pill_bottle/zoom,
					/obj/item/storage/pill_bottle/happy,
					/obj/item/storage/pill_bottle/lsd,
					/obj/item/storage/pill_bottle/aranesp,
					/obj/item/storage/pill_bottle/stimulant,
					/obj/item/toy/cards/deck/syndicate,
					/obj/item/reagent_containers/cup/glass/bottle/absinthe,
					/obj/item/clothing/under/syndicate/tacticool,
					/obj/item/storage/fancy/cigarettes/cigpack_syndicate,
					/obj/item/storage/fancy/cigarettes/cigpack_shadyjims,
					/obj/item/clothing/mask/gas/syndicate,
					/obj/item/clothing/neck/necklace/dope,
					/obj/item/vending_refill/donksoft)
	crate_name = "crate"

/datum/supply_pack/costumes_toys/foamforce
	name = "Foam Force Crate"
	desc = "Break out the big guns with eight Foam Force shotguns!"
	cost = 1000
	max_supply = 5
	contains = list(/obj/item/gun/ballistic/shotgun/toy,
					/obj/item/gun/ballistic/shotgun/toy,
					/obj/item/gun/ballistic/shotgun/toy,
					/obj/item/gun/ballistic/shotgun/toy,
					/obj/item/gun/ballistic/shotgun/toy,
					/obj/item/gun/ballistic/shotgun/toy,
					/obj/item/gun/ballistic/shotgun/toy,
					/obj/item/gun/ballistic/shotgun/toy)
	crate_name = "foam force crate"

/datum/supply_pack/costumes_toys/foamforce/bonus
	name = "Foam Force Pistols Crate"
	desc = "Psst.. hey bud... remember those old foam force pistols that got discontinued for being too cool? Well I got two of those right here with your name on em. I'll even throw in a spare mag for each, waddya say?"
	contraband = TRUE
	cost = 4000
	max_supply = 1
	contains = list(/obj/item/gun/ballistic/automatic/toy/pistol,
					/obj/item/gun/ballistic/automatic/toy/pistol,
					/obj/item/ammo_box/magazine/toy/pistol,
					/obj/item/ammo_box/magazine/toy/pistol)
	crate_name = "foam force crate"

/datum/supply_pack/costumes_toys/formalwear
	name = "Formalwear Crate"
	desc = "You're gonna like the way you look, I guaranteed it. Contains an asston of fancy clothing."
	cost = 3000 //Lots of very expensive items. You gotta pay up to look good!
	max_supply = 3
	contains = list(/obj/item/clothing/under/dress/blacktango,
					/obj/item/clothing/under/misc/assistantformal,
					/obj/item/clothing/under/misc/assistantformal,
					/obj/item/clothing/under/rank/civilian/lawyer/bluesuit,
					/obj/item/clothing/suit/toggle/lawyer,
					/obj/item/clothing/under/rank/civilian/lawyer/purpsuit,
					/obj/item/clothing/suit/toggle/lawyer/purple,
					/obj/item/clothing/suit/toggle/lawyer/black,
					/obj/item/clothing/accessory/waistcoat,
					/obj/item/clothing/neck/tie/blue,
					/obj/item/clothing/neck/tie/red,
					/obj/item/clothing/neck/tie/black,
					/obj/item/clothing/head/hats/bowler,
					/obj/item/clothing/head/fedora,
					/obj/item/clothing/head/flatcap,
					/obj/item/clothing/head/beret,
					/obj/item/clothing/head/hats/tophat,
					/obj/item/clothing/shoes/laceup,
					/obj/item/clothing/shoes/laceup,
					/obj/item/clothing/shoes/laceup,
					/obj/item/clothing/under/suit/charcoal,
					/obj/item/clothing/under/suit/navy,
					/obj/item/clothing/under/suit/burgundy,
					/obj/item/clothing/under/suit/checkered,
					/obj/item/clothing/under/suit/tan,
					/obj/item/lipstick/random)
	crate_name = "formalwear crate"
	crate_type = /obj/structure/closet/crate/wooden

/datum/supply_pack/costumes_toys/clownpin
	name = "Hilarious Firing Pin Crate"
	desc = "I uh... I'm not really sure what this does. Wanna buy it?"
	cost = 5000
	max_supply = 4
	contraband = TRUE
	contains = list(/obj/item/firing_pin/clown)
	crate_name = "toy crate" // It's /technically/ a toy. For the clown, at least.
	crate_type = /obj/structure/closet/crate/wooden

/datum/supply_pack/costumes_toys/lasertag
	name = "Laser Tag Crate"
	desc = "Foam Force is for boys. Laser Tag is for men. Contains three sets of red suits, blue suits, matching helmets, and matching laser tag guns."
	cost = 1500
	max_supply = 2
	contains = list(/obj/item/gun/energy/laser/redtag,
					/obj/item/gun/energy/laser/redtag,
					/obj/item/gun/energy/laser/redtag,
					/obj/item/gun/energy/laser/bluetag,
					/obj/item/gun/energy/laser/bluetag,
					/obj/item/gun/energy/laser/bluetag,
					/obj/item/clothing/suit/redtag,
					/obj/item/clothing/suit/redtag,
					/obj/item/clothing/suit/redtag,
					/obj/item/clothing/suit/bluetag,
					/obj/item/clothing/suit/bluetag,
					/obj/item/clothing/suit/bluetag,
					/obj/item/clothing/head/helmet/redtaghelm,
					/obj/item/clothing/head/helmet/redtaghelm,
					/obj/item/clothing/head/helmet/redtaghelm,
					/obj/item/clothing/head/helmet/bluetaghelm,
					/obj/item/clothing/head/helmet/bluetaghelm,
					/obj/item/clothing/head/helmet/bluetaghelm)
	crate_name = "laser tag crate"

/datum/supply_pack/costumes_toys/lasertag/pins
	name = "Laser Tag Firing Pins Crate"
	desc = "Three laser tag firing pins used in laser-tag units to ensure users are wearing their vests."
	cost = 3000
	max_supply = 5
	contraband = TRUE
	contains = list(/obj/item/storage/box/lasertagpins)
	crate_name = "laser tag crate"

/datum/supply_pack/costumes_toys/costume_original
	name = "Original Costume Crate"
	desc = "Reenact Shakespearean plays with this assortment of outfits. Contains eight different costumes!"
	cost = 1000
	max_supply = 3
	contains = list(/obj/item/clothing/head/costume/snowman,
					/obj/item/clothing/suit/costume/snowman,
					/obj/item/clothing/head/costume/chicken,
					/obj/item/clothing/suit/costume/chickensuit,
					/obj/item/clothing/mask/gas/monkeymask,
					/obj/item/clothing/suit/costume/monkeysuit,
					/obj/item/clothing/head/costume/cardborg,
					/obj/item/clothing/suit/costume/cardborg,
					/obj/item/clothing/head/costume/xenos,
					/obj/item/clothing/suit/costume/xenos,
					/obj/item/clothing/suit/hooded/ian_costume,
					/obj/item/clothing/suit/hooded/carp_costume,
					/obj/item/clothing/suit/hooded/bee_costume)
	crate_name = "original costume crate"
	crate_type = /obj/structure/closet/crate/wooden

/datum/supply_pack/costumes_toys/costume
	name = "Standard Costume Crate"
	desc = "Supply the station's entertainers with the equipment of their trade with these Nanotrasen-approved costumes! Contains a full clown and mime outfit, along with a bike horn and a bottle of nothing."
	cost = 1000
	max_supply = 3
	access = ACCESS_THEATRE
	contains = list(/obj/item/storage/backpack/clown,
					/obj/item/clothing/shoes/clown_shoes,
					/obj/item/clothing/mask/gas/clown_hat,
					/obj/item/clothing/under/rank/civilian/clown,
					/obj/item/bikehorn,
					/obj/item/clothing/under/rank/civilian/mime,
					/obj/item/clothing/shoes/sneakers/black,
					/obj/item/clothing/gloves/color/white,
					/obj/item/clothing/mask/gas/mime,
					/obj/item/clothing/head/frenchberet,
					/obj/item/clothing/suit/suspenders,
					/obj/item/reagent_containers/cup/glass/bottle/bottleofnothing,
					/obj/item/storage/backpack/mime)
	crate_name = "standard costume crate"
	crate_type = /obj/structure/closet/crate/wooden

/datum/supply_pack/costumes_toys/randomised/toys
	name = "Toy Crate"
	desc = "Who cares about pride and accomplishment? Skip the gaming and get straight to the sweet rewards with this product! Contains five random toys. Warranty void if used to prank research directors."
	cost = 5000 // or play the arcade machines ya lazy bum
	max_supply = 3
	num_contained = 5
	contains = list()
	crate_name = "toy crate"
	crate_type = /obj/structure/closet/crate/wooden

/datum/supply_pack/costumes_toys/randomised/toys/fill(obj/structure/closet/crate/C)
	var/the_toy
	for(var/i in 1 to num_contained)
		if(prob(50))
			the_toy = pick_weight(GLOB.arcade_prize_pool)
		else
			the_toy = pick(subtypesof(/obj/item/toy/plush))
		new the_toy(C)

/datum/supply_pack/costumes_toys/wizard
	name = "Wizard Costume Crate"
	desc = "Pretend to join the Wizard Federation with this full wizard outfit! Nanotrasen would like to remind its employees that actually joining the Wizard Federation is subject to termination of job and life."
	cost = 2000
	max_supply = 4
	contains = list(/obj/item/staff,
					/obj/item/clothing/suit/wizrobe/fake,
					/obj/item/clothing/shoes/sandal,
					/obj/item/clothing/head/wizard/fake)
	crate_name = "wizard costume crate"
	crate_type = /obj/structure/closet/crate/wooden

/datum/supply_pack/costumes_toys/randomised/fill(obj/structure/closet/crate/C)
	var/list/L = contains.Copy()
	for(var/i in 1 to num_contained)
		var/item = pick_n_take(L)
		new item(C)

/datum/supply_pack/costumes_toys/chess_white
	name = "White Chess Piece Crate"
	desc = "Look at you, playing a nerd game within a nerd game!"
	cost = 800
	max_supply = 3
	contains = list(
		/obj/structure/chess/whiteking,
		/obj/structure/chess/whitequeen,
		/obj/structure/chess/whiterook,
		/obj/structure/chess/whiterook,
		/obj/structure/chess/whiteknight,
		/obj/structure/chess/whiteknight,
		/obj/structure/chess/whitebishop,
		/obj/structure/chess/whitebishop,
		/obj/structure/chess/whitepawn,
		/obj/structure/chess/whitepawn,
		/obj/structure/chess/whitepawn,
		/obj/structure/chess/whitepawn,
		/obj/structure/chess/whitepawn,
		/obj/structure/chess/whitepawn,
		/obj/structure/chess/whitepawn,
		/obj/structure/chess/whitepawn,
	)
	crate_type = /obj/structure/closet/crate/wooden

/datum/supply_pack/costumes_toys/chess_black
	name = "Black Chess Piece Crate"
	desc = "Look at you, playing a nerd game within a nerd game!"
	cost = 800
	max_supply = 3
	contains = list(
		/obj/structure/chess/blackking,
		/obj/structure/chess/blackqueen,
		/obj/structure/chess/blackrook,
		/obj/structure/chess/blackrook,
		/obj/structure/chess/blackknight,
		/obj/structure/chess/blackknight,
		/obj/structure/chess/blackbishop,
		/obj/structure/chess/blackbishop,
		/obj/structure/chess/blackpawn,
		/obj/structure/chess/blackpawn,
		/obj/structure/chess/blackpawn,
		/obj/structure/chess/blackpawn,
		/obj/structure/chess/blackpawn,
		/obj/structure/chess/blackpawn,
		/obj/structure/chess/blackpawn,
		/obj/structure/chess/blackpawn,
	)
	crate_type = /obj/structure/closet/crate/wooden


/datum/supply_pack/costumes_toys/randomised/plush
	name = "Plushie Crate"
	desc = "A crate filled with 5 plushies!"
	cost = 1500
	max_supply = 5
	num_contained = 5
	contains = list()
	crate_type = /obj/structure/closet/crate/wooden
	crate_name = "plushie crate"

/datum/supply_pack/costumes_toys/randomised/plush/fill(obj/structure/closet/crate/C)
	var/plush
	var/_temporary_list_plush = subtypesof(/obj/item/toy/plush) - /obj/item/toy/plush/carpplushie/dehy_carp
	for(var/i in 1 to num_contained)
		plush = pick(_temporary_list_plush)
		new plush(C)

/datum/supply_pack/costumes_toys/randomised/plush_no_moths
	name = "Plushie Crate Without Moth Plushies"
	desc = "A crate filled with 5 plushies without all those pesky moth plushies! Might contain dangerous plushies."
	contraband = TRUE
	cost = 1500
	max_supply = 5
	num_contained = 5
	contains = list()
	crate_type = /obj/structure/closet/crate/wooden
	crate_name = "plushie crate"

/datum/supply_pack/costumes_toys/randomised/plush_no_moths/fill(obj/structure/closet/crate/C)
	var/plush_nomoth
	var/_temporary_list_plush_nomoth = subtypesof(/obj/item/toy/plush) - typesof(/obj/item/toy/plush/moth)
	for(var/i in 1 to num_contained)
		plush_nomoth = pick(_temporary_list_plush_nomoth)
		new plush_nomoth(C)

//////////////////////////////////////////////////////////////////////////////
///////////////////////// Wardrobe Resupplies ////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/costumes_toys/wardrobes/autodrobe
	name = "Autodrobe Supply Crate"
	desc = "Autodrobe missing your favorite dress? Solve that issue today with this autodrobe refill."
	cost = 800
	max_supply = 6
	contains = list(/obj/item/vending_refill/autodrobe)
	crate_name = "autodrobe supply crate"

/datum/supply_pack/costumes_toys/wardrobes/cargo
	name = "Cargo Wardrobe Supply Crate"
	desc = "This crate contains a refill for the CargoDrobe."
	cost = 800
	max_supply = 6
	access_budget = ACCESS_CARGO
	contains = list(/obj/item/vending_refill/wardrobe/cargo_wardrobe)
	crate_name = "cargo department supply crate"

/datum/supply_pack/costumes_toys/wardrobes/clothesmate
	name = "ClothesMate Wardrobe Supply Crate"
	desc = "This crate contains a refill for the ClothesMate."
	cost = 800
	max_supply = 6
	contains = list(/obj/item/vending_refill/clothing)
	crate_name = "clothesmate supply crate"

/datum/supply_pack/costumes_toys/wardrobes/engineering
	name = "Engineering Wardrobe Supply Crate"
	desc = "This crate contains refills for the EngiDrobe and AtmosDrobe."
	cost = 800
	max_supply = 6
	access_budget = ACCESS_ENGINE
	contains = list(/obj/item/vending_refill/wardrobe/engi_wardrobe,
					/obj/item/vending_refill/wardrobe/atmos_wardrobe)
	crate_name = "engineering department wardrobe supply crate"

/datum/supply_pack/costumes_toys/wardrobes/general
	name = "General Wardrobes Supply Crate"
	desc = "This crate contains refills for the CuraDrobe, BarDrobe, ChefDrobe, JaniDrobe, ChapDrobe."
	cost = 1200
	max_supply = 6
	contains = list(/obj/item/vending_refill/wardrobe/curator_wardrobe,
					/obj/item/vending_refill/wardrobe/bar_wardrobe,
					/obj/item/vending_refill/wardrobe/chef_wardrobe,
					/obj/item/vending_refill/wardrobe/jani_wardrobe,
					/obj/item/vending_refill/wardrobe/chap_wardrobe)
	crate_name = "general wardrobes vendor refills"

/datum/supply_pack/costumes_toys/wardrobes/hydroponics
	name = "Hydrobe Supply Crate"
	desc = "This crate contains a refill for the Hydrobe."
	cost = 600
	max_supply = 6
	access_budget = ACCESS_HYDROPONICS
	contains = list(/obj/item/vending_refill/wardrobe/hydro_wardrobe)
	crate_name = "hydrobe supply crate"

/datum/supply_pack/costumes_toys/wardrobes/medical
	name = "Medical Wardrobe Supply Crate"
	desc = "This crate contains refills for the MediDrobe, ChemDrobe, GeneDrobe, and ViroDrobe."
	cost = 1200
	max_supply = 6
	access_budget = ACCESS_MEDICAL
	contains = list(/obj/item/vending_refill/wardrobe/medi_wardrobe,
					/obj/item/vending_refill/wardrobe/chem_wardrobe,
					/obj/item/vending_refill/wardrobe/gene_wardrobe,
					/obj/item/vending_refill/wardrobe/viro_wardrobe)
	crate_name = "medical department wardrobe supply crate"

/datum/supply_pack/costumes_toys/wardrobes/science
	name = "Science Wardrobe Supply Crate"
	desc = "This crate contains refills for the SciDrobe and RoboDrobe."
	cost = 800
	max_supply = 6
	access_budget = ACCESS_RESEARCH
	contains = list(/obj/item/vending_refill/wardrobe/robo_wardrobe,
					/obj/item/vending_refill/wardrobe/science_wardrobe)
	crate_name = "science department wardrobe supply crate"

/datum/supply_pack/costumes_toys/wardrobes/security
	name = "Security Wardrobe Supply Crate"
	desc = "This crate contains refills for the SecDrobe, DetDrobe and LawDrobe."
	cost = 1000
	max_supply = 6
	access_budget = ACCESS_SECURITY
	contains = list(/obj/item/vending_refill/wardrobe/sec_wardrobe,
					/obj/item/vending_refill/wardrobe/det_wardrobe,
					/obj/item/vending_refill/wardrobe/law_wardrobe)
	crate_name = "security department supply crate"

//////////////////////////////////////////////////////////////////////////////
//////////////////////////// Miscellaneous ///////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

/datum/supply_pack/misc
	group = "Miscellaneous Supplies"

/datum/supply_pack/misc/artsupply
	name = "Art Supplies"
	desc = "Make some happy little accidents with six canvasses, two easels, and two rainbow crayons!"
	cost = 500
	max_supply = 3
	contains = list(/obj/structure/easel,
					/obj/structure/easel,
					/obj/item/canvas/nineteen_nineteen,
					/obj/item/canvas/nineteen_nineteen,
					/obj/item/canvas/twentythree_nineteen,
					/obj/item/canvas/twentythree_nineteen,
					/obj/item/canvas/twentythree_twentythree,
					/obj/item/canvas/twentythree_twentythree,
					/obj/item/toy/crayon/rainbow,
					/obj/item/toy/crayon/rainbow,
					/obj/item/vending_refill/sticker)
	crate_name = "art supply crate"
	crate_type = /obj/structure/closet/crate/wooden

/datum/supply_pack/misc/aquarium_kit
	name = "Aquarium Kit"
	desc = "Everything you need to start your own aquarium. Contains aquarium construction kit, fish catalog, feed can and three freshwater fish from our collection."
	cost = 2000
	max_supply = 4
	contains = list(/obj/item/book/fish_catalog,
					/obj/item/storage/fish_case/random/freshwater,
					/obj/item/storage/fish_case/random/freshwater,
					/obj/item/storage/fish_case/random/freshwater,
					/obj/item/fish_feed,
					/obj/item/storage/box/aquarium_props,
					/obj/item/aquarium_kit)
	crate_name = "aquarium kit crate"
	crate_type = /obj/structure/closet/crate/wooden

/datum/supply_pack/misc/aquarium_fish
	name = "Aquarium Fish Case"
	desc = "An aquarium fish handpicked by monkeys from our collection."
	cost = 600
	max_supply = 5
	contains = list(/obj/item/storage/fish_case/random)
	crate_name = "aquarium fish crate"

/datum/supply_pack/misc/bicycle
	name = "Bicycle"
	desc = "Nanotrasen reminds all employees to never toy with powers outside their control."
	cost = 1000000
	max_supply = 1
	contains = list(/obj/vehicle/ridden/bicycle)
	crate_name = "Bicycle Crate"
	crate_type = /obj/structure/closet/crate/large

/datum/supply_pack/misc/bicycle/generate(atom/A, datum/bank_account/paying_account)
	. = ..()
	for(var/client/C as() in GLOB.clients)
		if(C?.mob.mind.assigned_role == JOB_NAME_QUARTERMASTER || C?.mob.mind.assigned_role == JOB_NAME_CARGOTECHNICIAN)
			C?.give_award(/datum/award/achievement/misc/bike, C?.mob)

/datum/supply_pack/misc/bigband
	name = "Big Band Instrument Collection"
	desc = "Get your sad station movin' and groovin' with this fine collection! Contains nine different instruments!"
	cost = 800
	max_supply = 4
	crate_name = "Big band musical instruments collection"
	contains = list(/obj/item/instrument/violin,
					/obj/item/instrument/guitar,
					/obj/item/instrument/glockenspiel,
					/obj/item/instrument/accordion,
					/obj/item/instrument/saxophone,
					/obj/item/instrument/trombone,
					/obj/item/instrument/recorder,
					/obj/item/instrument/harmonica,
					/obj/structure/musician/piano/unanchored)
	crate_type = /obj/structure/closet/crate/wooden

/datum/supply_pack/misc/book_crate
	name = "Book Crate"
	desc = "Surplus from the Nanotrasen Archives, these seven books are sure to be good reads."
	cost = 1200
	max_supply = 3
	access_budget = ACCESS_LIBRARY
	contains = list(/obj/item/book/codex_gigas,
					/obj/item/book/manual/random/,
					/obj/item/book/manual/random/,
					/obj/item/book/manual/random/,
					/obj/item/book/random,
					/obj/item/book/random,
					/obj/item/book/random)
	crate_type = /obj/structure/closet/crate/wooden

/datum/supply_pack/misc/paper
	name = "Bureaucracy Crate"
	desc = "High stacks of papers on your desk Are a big problem - make it Pea-sized with these bureaucratic supplies! Contains six pens, some camera film, hand labeler supplies, a paper bin, three folders, a laser pointer, two clipboards and two stamps."//that was too forced
	cost = 800
	max_supply = 5
	contains = list(/obj/structure/filingcabinet/chestdrawer/wheeled,
					/obj/item/camera_film,
					/obj/item/hand_labeler,
					/obj/item/hand_labeler_refill,
					/obj/item/hand_labeler_refill,
					/obj/item/paper_bin,
					/obj/item/pen/fourcolor,
					/obj/item/pen/fourcolor,
					/obj/item/pen,
					/obj/item/pen/fountain,
					/obj/item/pen/blue,
					/obj/item/pen/red,
					/obj/item/folder/blue,
					/obj/item/folder/red,
					/obj/item/folder/yellow,
					/obj/item/clipboard,
					/obj/item/clipboard,
					/obj/item/stamp,
					/obj/item/stamp/denied,
					/obj/item/laser_pointer/purple,
					/obj/item/sticky_note_pile)
	crate_name = "bureaucracy crate"

/datum/supply_pack/misc/bulk_paper
	name = "Bulk Paper Tray Crate"
	desc = "Plenty of paper for all your papercraft needs."
	cost = 500
	max_supply = 5
	contains = list(/obj/item/paper_bin,
					/obj/item/paper_bin,
					/obj/item/paper_bin,
					/obj/item/paper_bin,
					/obj/item/paper_bin)
	crate_name = "bulk paper tray crate"

/datum/supply_pack/misc/fountainpens
	name = "Calligraphy Crate"
	desc = "Sign death warrants in style with these seven executive fountain pens."
	cost = 800
	max_supply = 4
	contains = list(/obj/item/storage/box/fountainpens)
	crate_type = /obj/structure/closet/crate/wooden
	crate_name = "calligraphy crate"

/datum/supply_pack/misc/wrapping_paper
	name = "Festive Wrapping Paper Crate"
	desc = "Want to mail your loved ones gift-wrapped chocolates, stuffed animals, the Clown's severed head? You can do all that, with this crate full of wrapping paper."
	cost = 800
	max_supply = 4
	contains = list(/obj/item/stack/wrapping_paper)
	crate_type = /obj/structure/closet/crate/wooden
	crate_name = "festive wrapping paper crate"


/datum/supply_pack/misc/funeral
	name = "Funeral Supply crate"
	desc = "At the end of the day, someone's gonna want someone dead. Give them a proper send-off with these funeral supplies! Contains a coffin with burial garmets and flowers."
	cost = 800
	max_supply = 4
	access_budget = ACCESS_CHAPEL_OFFICE
	contains = list(/obj/item/clothing/under/misc/burial,
					/obj/item/food/grown/flower/harebell,
					/obj/item/food/grown/flower/geranium)
	crate_name = "coffin"
	crate_type = /obj/structure/closet/crate/coffin

/datum/supply_pack/misc/religious_supplies
	name = "Religious Supplies Crate"
	desc = "Keep your local chaplain happy and well-supplied, lest they call down judgment upon your cargo bay. Contains two bottles of holywater, bibles, chaplain robes, and burial garmets."
	cost = 4000
	max_supply = 3
	access_budget = ACCESS_CHAPEL_OFFICE
	contains = list(/obj/item/reagent_containers/cup/glass/bottle/holywater,
					/obj/item/reagent_containers/cup/glass/bottle/holywater,
					/obj/item/storage/book/bible/booze,
					/obj/item/storage/book/bible/booze,
					/obj/item/clothing/neck/crucifix/rosary,
					/obj/item/clothing/suit/hooded/chaplain_hoodie,
					/obj/item/clothing/suit/hooded/chaplain_hoodie)
	crate_name = "religious supplies crate"

/datum/supply_pack/misc/toner
	name = "Toner Crate"
	desc = "Spent too much ink printing butt pictures? Fret not, with these eight toner refills, you'll be printing butts 'till the cows come home!'"
	cost = 800
	max_supply = 5
	contains = list(/obj/item/toner,
					/obj/item/toner,
					/obj/item/toner,
					/obj/item/toner,
					/obj/item/toner,
					/obj/item/toner,
					/obj/item/toner,
					/obj/item/toner)
	crate_name = "toner crate"

/datum/supply_pack/misc/toner_large
	name = "Toner Crate (Large)"
	desc = "Tired of changing toner cartridges? These six extra heavy duty refills contain roughly five times as much toner as the base model!"
	cost = 3000
	max_supply = 2
	contains = list(/obj/item/toner/large,
					/obj/item/toner/large,
					/obj/item/toner/large,
					/obj/item/toner/large,
					/obj/item/toner/large,
					/obj/item/toner/large)
	crate_name = "large toner crate"
