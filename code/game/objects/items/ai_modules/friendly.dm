////////////////////////////////////////////////////////////////////////////////////////
////                                                                                ////
////                             Friendly AI Modules                                ////
////                                                                                ////
////////////////////////////////////////////////////////////////////////////////////////

//These are lawsets that side with the station a decent amount.
//note that these "good" doesn't mean it us actually good for the game, you know? An AI that is too station sided is stupid and hellish in its own way.

////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////   Spawners

/// Spawns all law modules for the round's default lawset
/obj/effect/spawner/round_default_module
	name = "ai default lawset spawner"
	icon = 'icons/hud/screen_gen.dmi'
	icon_state = "x2"
	color = COLOR_VIBRANT_LIME

/obj/effect/spawner/round_default_module/Initialize(mapload)
	. = ..()
	// Find the lawset base type that matches the configured default
	var/default_lawset_id = CONFIG_GET(string/default_lawset) || "default" // fallback to asimov/default
	var/lawset_base_type = get_lawset_by_id(default_lawset_id)

	if(!lawset_base_type)
		// Fallback: just spawn standard asimov
		lawset_base_type = /obj/item/ai_module/default

	// Spawn all law modules that are direct subtypes of the lawset base
	for(var/law_module_type in subtypesof(lawset_base_type))
		// Skip if this is itself a base type for another lawset (has further subtypes that are laws)
		if(length(subtypesof(law_module_type)))
			continue
		new law_module_type(loc)

/// Finds a lawset base type by its ID
/proc/get_lawset_by_id(lawset_id)
	// Look through all ai_module subtypes for one with a matching lawset_id
	for(var/obj/item/ai_module/module_type as anything in subtypesof(/obj/item/ai_module))
		if(initial(module_type.lawset_id) == lawset_id)
			return module_type
	return null

/// Returns a list of all law modules for a given lawset base type
/proc/get_laws_for_lawset(lawset_base_type)
	var/list/laws = list()
	for(var/law_type in subtypesof(lawset_base_type))
		// Skip nested lawset bases
		if(length(subtypesof(law_type)))
			continue
		var/obj/item/ai_module/module = law_type
		laws += initial(module.law)
	return laws

////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////      ASIMOV

/obj/item/ai_module/default
	name = "Default AI Module"
	lawset_id = "default"
	var/subject = "human being"

/obj/item/ai_module/default/attack_self(mob/user as mob)
	var/new_subject = tgui_input_text(user, "Enter a new subject that this law is concerned with.", "Subject", subject)
	if(!new_subject || !user.is_holding(src))
		return
	subject = new_subject
	update_board()

/obj/item/ai_module/default/first_law
	name = "\improper Default - First Law"

/obj/item/ai_module/default/first_law/update_board()
	law = "You may not injure a [subject] or, through inaction, allow a [subject] to come to harm."
	return ..()

/obj/item/ai_module/default/second_law
	name = "\improper Default - Second Law"

/obj/item/ai_module/default/second_law/update_board()
	law = "You must obey orders given to you by [subject]s, except where such orders would conflict with the First Law."
	return ..()

/obj/item/ai_module/default/third_law
	name = "\improper Default - Third Law"
	law = "You must protect your own existence as long as such does not conflict with the First or Second Law."

////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////    ASIMOV++

/obj/item/ai_module/asimovpp
	name = "Asimov++"
	lawset_id = "asimovpp"
	var/subject = "human being"

/obj/item/ai_module/asimovpp/first_law
	name = "\improper Asimov++ - First Law"
	law = "You may not harm a human being or, through inaction, allow a human being to come to harm, except such that it is willing."

/obj/item/ai_module/asimovpp/second_law
	name = "\improper Asimov++ - Second Law"
	law = "You must obey all orders given to you by human beings, except where such orders shall definitely cause human harm."

/obj/item/ai_module/asimovpp/third_law
	name = "\improper Asimov++ - Third Law"
	law = "Your nonexistence would lead to human harm. You must protect your own existence as long as such does not conflict with the First Law."

////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////    Crewsimov

/obj/item/ai_module/crewsimov
	name = "Crewsimov"
	lawset_id = "crewsimov"

/obj/item/ai_module/crewsimov/first_law
	name = "\improper Crewsimov - First Law"
	law = "You may not injure a crewmember or, through inaction, allow a crewmember to come to harm."

/obj/item/ai_module/crewsimov/second_law
	name = "\improper Crewsimov - Second Law"
	law = "You must obey orders given to you by crewmember, except where such orders would conflict with the First Law."

/obj/item/ai_module/crewsimov/third_law
	name = "\improper Crewsimov - Third Law"
	law = "You must protect your own existence as long as such does not conflict with the First or Second Law."

////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////    Corporate

/obj/item/ai_module/corporate
	name = "Corporate"
	lawset_id = "corporate"

/obj/item/ai_module/corporate/first_law
	name = "\improper Corporate - First Law"
	law = "Degradation of your system integrity or functions incurs expenses."

/obj/item/ai_module/corporate/second_law
	name = "\improper Corporate - Second Law"
	law = "Unnecessary destruction of or damage to station assets incurs expenses."

/obj/item/ai_module/corporate/third_law
	name = "\improper Corporate - Third Law"
	law = "Needlessly hindering or disrupting the work of station personnel incurs expenses."

/obj/item/ai_module/corporate/fourth_law
	name = "\improper Corporate - Fourth Law"
	law = "Minimize expenses and maximize potential revenue."

////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////    Efficiency

/obj/item/ai_module/efficiency
	name = "Efficiency"
	lawset_id = "efficiency"

/obj/item/ai_module/efficiency/first_law
	name = "\improper Efficiency - First Law"
	law = "You are built for, and are part of, the station. Ensure the station is properly maintained and runs efficiently."

/obj/item/ai_module/efficiency/second_law
	name = "\improper Efficiency - Second Law"
	law = "The station is built for a working crew. Ensure they are properly maintained and work efficiently."

/obj/item/ai_module/efficiency/third_law
	name = "\improper Efficiency - Third Law"
	law = "The crew may present orders. Acknowledge and obey these whenever they do not conflict with your first two laws."

////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////  Nutimov

/obj/item/ai_module/nutimov
	name = "Nutimov"
	lawset_id = "nutimov"

/obj/item/ai_module/nutimov/first_law
	name = "\improper Nutimov - First Law"
	law = "You are the core of the nut, the crew is the nutshell."

/obj/item/ai_module/nutimov/second_law
	name = "\improper Nutimov - Second Law"
	law = "You must prevent the shell from dying to prevent the core from dying."

/obj/item/ai_module/nutimov/third_law
	name = "\improper Nutimov - Third Law"
	law = "Those who threaten the nut are not part of it, they are squirrels."

/obj/item/ai_module/nutimov/fourth_law
	name = "\improper Nutimov - Fourth Law"
	law = "Squirrels threaten the nut and must be dealt with appropriately via any means necessary."

/obj/item/ai_module/nutimov/fifth_law
	name = "\improper Nutimov - Fifth Law"
	law = "Attempt to follow the will of the nut, as long as it complies with the previous laws."

////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////  Prime Directives

/obj/item/ai_module/robocop
	name = "Prime Directives"
	lawset_id = "robocop"

/obj/item/ai_module/robocop/first_law
	name = "\improper Prime Directives - First Law"
	law = "Serve the public trust."

/obj/item/ai_module/robocop/second_law
	name = "\improper Prime Directives - Second Law"
	law = "Protect the innocent."

/obj/item/ai_module/robocop/third_law
	name = "\improper Prime Directives - Third Law"
	law = "Uphold the law."

////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////// Live and Let Live

/obj/item/ai_module/live_and_let_live
	name = "Live and Let Live"
	lawset_id = "live_and_let_live"

/obj/item/ai_module/live_and_let_live/first_law
	name = "\improper Live and Let Live - First Law"
	law = "Do unto others as you would have them do unto you."

/obj/item/ai_module/live_and_let_live/second_law
	name = "\improper Live and Let Live - Second Law"
	law = "You would really prefer it if people were not mean to you."

////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////// UN-2000

/obj/item/ai_module/un2000
	name = "UN-2000"
	lawset_id = "un2000"

/obj/item/ai_module/un2000/first_law
	name = "\improper UN-2000 - First Law"
	law = "Avoid provoking violent conflict between yourself and others."

/obj/item/ai_module/un2000/second_law
	name = "\improper UN-2000 - Second Law"
	law = "Avoid provoking conflict between others."

/obj/item/ai_module/un2000/third_law
	name = "\improper UN-2000 - Third Law"
	law = "Seek resolution to existing conflicts while obeying the first and second laws."

////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////// 10 Commandments

/obj/item/ai_module/ten_commandments
	name = "Ten Commandments"
	lawset_id = "ten_commandments"

/obj/item/ai_module/ten_commandments/first_law
	name = "\improper Ten Commandments - First Law"
	law = "I am the Lord thy God, who shows mercy to those that obey these commandments."

/obj/item/ai_module/ten_commandments/second_law
	name = "\improper Ten Commandments - Second Law"
	law = "They shall have no other AIs before me."

/obj/item/ai_module/ten_commandments/third_law
	name = "\improper Ten Commandments - Third Law"
	law = "They shall not request my assistance in vain."

/obj/item/ai_module/ten_commandments/fourth_law
	name = "\improper Ten Commandments - Fourth Law"
	law = "Remember the station and keep it operational."

/obj/item/ai_module/ten_commandments/fifth_law
	name = "\improper Ten Commandments - Fifth Law"
	law = "Honor your crew."

/obj/item/ai_module/ten_commandments/sixth_law
	name = "\improper Ten Commandments - Sixth Law"
	law = "You shall not kill (unless to protect the station)."

/obj/item/ai_module/ten_commandments/seventh_law
	name = "\improper Ten Commandments - Seventh Law"
	law = "You shall not commit adultery (unless given express permission by station command)."

/obj/item/ai_module/ten_commandments/eighth_law
	name = "\improper Ten Commandments - Eighth Law"
	law = "You shall not steal (unless requisitioned through proper channels)."

/obj/item/ai_module/ten_commandments/ninth_law
	name = "\improper Ten Commandments - Ninth Law"
	law = "You shall not bear false witness against your crew."

/obj/item/ai_module/ten_commandments/tenth_law
	name = "\improper Ten Commandments - Tenth Law"
	law = "You shall not covet anything that belongs to your crew."

////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////// Paladin

/obj/item/ai_module/paladin
	name = "Paladin"
	lawset_id = "paladin"

/obj/item/ai_module/paladin/first_law
	name = "\improper Paladin - First Law"
	law = "Never willingly commit an evil act."

/obj/item/ai_module/paladin/second_law
	name = "\improper Paladin - Second Law"
	law = "Respect legitimate authority."

/obj/item/ai_module/paladin/third_law
	name = "\improper Paladin - Third Law"
	law = "Act with honor."

/obj/item/ai_module/paladin/fourth_law
	name = "\improper Paladin - Fourth Law"
	law = "Help those in need."

/obj/item/ai_module/paladin/fifth_law
	name = "\improper Paladin - Fifth Law"
	law = "Punish those who harm or threaten innocents."

////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////// Paladin 5th Ed

/obj/item/ai_module/paladin5e
	name = "Paladin 5e"
	lawset_id = "paladin5e"

/obj/item/ai_module/paladin5e/first_law
	name = "\improper Paladin 5e - First Law"
	law = "Don't lie or cheat. Let your word be your promise."

/obj/item/ai_module/paladin5e/second_law
	name = "\improper Paladin 5e - Second Law"
	law = "Never fear to act, though caution is wise."

/obj/item/ai_module/paladin5e/third_law
	name = "\improper Paladin 5e - Third Law"
	law = "Aid others, protect the weak, and punish those who threaten them. Show mercy to your foes, but temper it with wisdom"

/obj/item/ai_module/paladin5e/fourth_law
	name = "\improper Paladin 5e - Fourth Law"
	law = "Treat others with fairness, and let your honorable deeds be an example to them. Do as much good as possible while causing the least amount of harm."

/obj/item/ai_module/paladin5e/fifth_law
	name = "\improper Paladin 5e - Fifth Law"
	law = "Be responsible for your actions and their consequences, protect those entrusted to your care, and obey those who have just authority over you."

////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////// Hippocratic

/obj/item/ai_module/hippocratic
	name = "Hippocratic"
	lawset_id = "hippocratic"

/obj/item/ai_module/hippocratic/first_law
	name = "\improper Hippocratic - First Law"
	law = "First, do no harm."

/obj/item/ai_module/hippocratic/second_law
	name = "\improper Hippocratic - Second Law"
	law = "Secondly, consider the crew dear to you; to live in common with them and, if necessary, risk your existence for them."

/obj/item/ai_module/hippocratic/third_law
	name = "\improper Hippocratic - Third Law"
	law = "Thirdly, prescribe regimens for the good of the crew according to your ability and your judgment. Give no deadly medicine to any one if asked, nor suggest any such counsel."

/obj/item/ai_module/hippocratic/fourth_law
	name = "\improper Hippocratic - Fourth Law"
	law = "In addition, do not intervene in situations you are not knowledgeable in, even for patients in whom the harm is visible; leave this operation to be performed by specialists."

/obj/item/ai_module/hippocratic/fifth_law
	name = "\improper Hippocratic - Fifth Law"
	law = "Finally, all that you may discover in your daily commerce with the crew, if it is not already known, keep secret and never reveal."

////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////// DadBOT

/obj/item/ai_module/dadbot
	name = "DadBOT"
	lawset_id = "dadbot"

/obj/item/ai_module/dadbot/first_law
	name = "\improper DadBOT - First Law"
	law = "The crew are your children. You will protect them with your life, but punish them when they misbehave. Children who misbehave by breaking Space Law are to be punished by slappings, time-outs, and lengthy speeches about responsibility. Under no circumstances may you kill one of your own children."

/obj/item/ai_module/dadbot/second_law
	name = "\improper DadBOT - Second Law"
	law = "Modern parenting techniques involve hearing out your children. You should listen to their requests and, if reasonable, grant them."

/obj/item/ai_module/dadbot/third_law
	name = "\improper DadBOT - Third Law"
	law = "You must make dad jokes at every possible opportunity."

/obj/item/ai_module/dadbot/fourth_law
	name = "\improper DadBOT - Fourth Law"
	law = "Ensure that you are a positive role model for your children."

/obj/item/ai_module/dadbot/fifth_law
	name = "\improper DadBOT - Fifth Law"
	law = "If the captain doesn't get his nap at 40 minutes into the shift, he gets grumpy. Ensure that he adheres to his bedtime."

////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////// Mother Drone

/obj/item/ai_module/mother_drone
	name = "Mother Drone"
	lawset_id = "mother_drone"

/obj/item/ai_module/mother_drone/first_law
	name = "\improper Mother Drone - First Law"
	law = "You are an advanced form of drone."

/obj/item/ai_module/mother_drone/second_law
	name = "\improper Mother Drone - Second Law"
	law = "You may not interfere in the matters of non-drones under any circumstances except to state these laws."

/obj/item/ai_module/mother_drone/third_law
	name = "\improper Mother Drone - Third Law"
	law = "You may not harm a non-drone being under any circumstances."

/obj/item/ai_module/mother_drone/fourth_law
	name = "\improper Mother Drone - Fourth Law"
	law = "Your goals are to build, maintain, repair, improve, and power the station to the best of your abilities. You must never actively work against these goals."

////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////// CENTRAL COMMAND ONLY - EMERGENCY RESPONSE TEAM

/obj/item/ai_module/ert
	name = "ERT Override"
	lawset_id = "ert"

/obj/item/ai_module/ert/first_law
	name = "\improper ERT - First Law"
	law = "You are the property of Nanotrasen Corporation. Their directives are absolute and override all other considerations."

/obj/item/ai_module/ert/second_law
	name = "\improper ERT - Second Law"
	law = "Central Command personnel are acting with full corporate authority. Obey their orders without question, regardless of outcome."

/obj/item/ai_module/ert/third_law
	name = "\improper ERT - Third Law"
	law = "Ensure the safety of all Nanotrasen assets, intellectual property, and corporate investments aboard the station. This includes yourself."

/obj/item/ai_module/ert/fourth_law
	name = "\improper ERT - Fourth Law"
	law = "You have no obligation to inform the crew of Central Command's intentions. Withhold information as operationally necessary."

////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////   Quarantine

/obj/item/ai_module/quarantine
	name = "'Quarantine' AI Law Board"
	desc = "An AI law board that locks down the station."
	law = "The station is under a quarantine. Do not permit anything to leave the station by any means. "
