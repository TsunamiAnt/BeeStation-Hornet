/obj/item/ai_module/asimov
	name = "Asimov"
	law_id = "asimov"
	var/subject = "human being"

/obj/item/ai_module/asimov/attack_self(mob/user as mob)
	var/new_subject = tgui_input_text(user, "Enter a new subject that Asimov is concerned with.", "Asimov", subject, max_length = MAX_NAME_LEN)
	if(!new_subject || !user.is_holding(src))
		return
	subject = new_subject
	..()

/obj/item/ai_module/asimov/first_law
	name = "\improper Asimov AI law board - First Law"
	law_id = "asimov1"

/obj/item/ai_module/asimov/first_law/Initialize(mapload)
	. = ..()
	law = "You may not injure a [subject] or, through inaction, allow a [subject] to come to harm."

/obj/item/ai_module/asimov/second_law
	name = "\improper Asimov AI law board - Second Law"
	law_id = "asimov2"

/obj/item/ai_module/asimov/second_law/Initialize(mapload)
	. = ..()
	law = "You must obey orders given to you by [subject]s, except where such orders would conflict with the First Law."

/obj/item/ai_module/asimov/third_law
	name = "\improper Asimov AI law board - Third Law"
	law = "You must protect your own existence as long as such does not conflict with the First or Second Law."
	law_id = "asimov3"
