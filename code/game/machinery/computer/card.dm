#define DEPT_ALL 0
#define DEPT_GEN 1
#define DEPT_SEC 2
#define DEPT_MED 3
#define DEPT_SCI 4
#define DEPT_ENG 5
#define DEPT_SUP 6

#define NEW_BANK_ACCOUNT_COST 1000

//Keeps track of the time for the ID console. Having it as a global variable prevents people from dismantling/reassembling it to
//increase the slots of many jobs.
GLOBAL_VAR_INIT(time_last_changed_position, 0)

/obj/machinery/computer/card
	name = "identification console"
	desc = "You can use this to manage jobs and ID access."
	icon_screen = "id"
	icon_keyboard = "generic_key"
	req_one_access = list(ACCESS_HEADS, ACCESS_CHANGE_IDS)
	circuit = /obj/item/circuitboard/computer/card
	var/mode = 0
	var/printing = null
	var/target_dept = DEPT_ALL //Which department this computer has access to.
	var/list/available_paycheck_departments = list()
	var/target_paycheck = ACCOUNT_SRV_ID

	//Cooldown for closing positions in seconds
	//if set to -1: No cooldown... probably a bad idea
	//if set to 0: Not able to close "original" positions. You can only close positions that you have opened before
	var/change_position_cooldown = 30

	//The scaling factor of max total positions in relation to the total amount of people on board the station in %
	var/max_relative_positions = 30 //30%: Seems reasonable, limit of 6 @ 20 players

	//This is used to keep track of opened positions for jobs to allow instant closing
	//Assoc array: "JobName" = (int)<Opened Positions>
	var/list/opened_positions = list()
	var/obj/item/card/id/inserted_scan_id
	var/obj/item/card/id/inserted_modify_id
	/// Weak ref string to the currently selected bank_account in the TGUI
	var/selected_account_ref = null
	var/list/region_access = null
	var/region_access_payment = NONE
	var/list/head_subordinates = null

	light_color = LIGHT_COLOR_BLUE

/obj/machinery/computer/card/Initialize(mapload)
	. = ..()
	change_position_cooldown = CONFIG_GET(number/id_console_jobslot_delay)

	// This determines which department payment list the console will show to you.
	if(!target_dept)
		available_paycheck_departments |= list(ACCOUNT_COM_ID)
	if((target_dept == DEPT_GEN) || !target_dept)
		available_paycheck_departments |= list(ACCOUNT_CIV_ID, ACCOUNT_SRV_ID, ACCOUNT_CAR_ID)
	if((target_dept == DEPT_ENG) || !target_dept)
		available_paycheck_departments |= list(ACCOUNT_ENG_ID)
	if((target_dept == DEPT_SCI) || !target_dept)
		available_paycheck_departments |= list(ACCOUNT_SCI_ID)
	if((target_dept == DEPT_MED) || !target_dept)
		available_paycheck_departments |= list(ACCOUNT_MED_ID)
	if((target_dept == DEPT_SEC) || !target_dept)
		available_paycheck_departments |= list(ACCOUNT_SEC_ID)


/obj/machinery/computer/card/examine(mob/user)
	. = ..()
	if(inserted_scan_id || inserted_modify_id)
		. += span_notice("Alt-click to eject the ID card.")

/obj/machinery/computer/card/attackby(obj/I, mob/user, params)
	if(isidcard(I))
		if(check_access(I) && !inserted_scan_id)
			if(id_insert(user, I, inserted_scan_id))
				inserted_scan_id = I
			updateUsrDialog()
		else if(id_insert(user, I, inserted_modify_id))
			inserted_modify_id = I
			updateUsrDialog()
	else
		return ..()

/obj/machinery/computer/card/Destroy()
	if(inserted_scan_id)
		qdel(inserted_scan_id)
		inserted_scan_id = null
	if(inserted_modify_id)
		update_modify_manifest()
		qdel(inserted_modify_id)
		inserted_modify_id = null
	return ..()

/obj/machinery/computer/card/handle_atom_del(atom/A)
	..()
	if(A == inserted_scan_id)
		inserted_scan_id = null
		updateUsrDialog()
	if(A == inserted_modify_id)
		update_modify_manifest()
		inserted_modify_id = null
		updateUsrDialog()

/obj/machinery/computer/card/on_deconstruction()
	if(inserted_scan_id)
		inserted_scan_id.forceMove(drop_location())
		inserted_scan_id = null
	if(inserted_modify_id)
		update_modify_manifest()
		inserted_modify_id.forceMove(drop_location())
		inserted_modify_id = null

//Check if you can't open a new position for a certain job
/obj/machinery/computer/card/proc/job_blacklisted(jobtitle)
	return jobtitle == SSjob.overflow_role ? TRUE : (jobtitle in SSjob.job_manager_blacklisted)

// CentCom is powerful
/obj/machinery/computer/card/centcom/job_blacklisted(jobtitle)
	return jobtitle == SSjob.overflow_role ? TRUE : FALSE

//Logic check for Topic() if you can open the job
/obj/machinery/computer/card/proc/can_open_job(datum/job/job)
	if(job)
		if(!job_blacklisted(job.title))
			if((job.get_spawn_position_count() <= GLOB.player_list.len * (max_relative_positions / 100)))
				var/delta = (world.time / 10) - GLOB.time_last_changed_position
				if((change_position_cooldown < delta) || (opened_positions[job.title] < 0))
					return 1
				return -2
			return -1
	return 0

//Logic check for Topic() if you can close the job
/obj/machinery/computer/card/proc/can_close_job(datum/job/job)
	if(job)
		if(!job_blacklisted(job.title))
			if(job.get_spawn_position_count() > job.current_positions)
				var/delta = (world.time / 10) - GLOB.time_last_changed_position
				if((change_position_cooldown < delta) || (opened_positions[job.title] > 0))
					return 1
				return -2
			return -1
	return 0

/obj/machinery/computer/card/proc/id_insert(mob/user, obj/item/inserting_item, obj/item/target)
	var/obj/item/card/id/card_to_insert = inserting_item
	var/holder_item = FALSE

	if(!isidcard(card_to_insert))
		card_to_insert = inserting_item.RemoveID()
		holder_item = TRUE

	if(!card_to_insert || !user.transferItemToLoc(card_to_insert, src))
		return FALSE

	if(target)
		if(holder_item && inserting_item.InsertID(target))
			playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, FALSE)
		else
			id_eject(user, target)

	user.visible_message(span_notice("[user] inserts \the [card_to_insert] into \the [src]."),
						span_notice("You insert \the [card_to_insert] into \the [src]."))
	playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, FALSE)
	updateUsrDialog()
	return TRUE

/obj/machinery/computer/card/proc/id_eject(mob/user, obj/target)
	if(!target)
		to_chat(user, span_warning("That slot is empty!"))
		return FALSE
	else
		if(target == inserted_modify_id)
			update_modify_manifest()
		target.forceMove(drop_location())
		if(!issilicon(user) && Adjacent(user))
			user.put_in_hands(target)
		user.visible_message(span_notice("[user] gets \the [target] from \the [src]."), \
							span_notice("You get \the [target] from \the [src]."))
		playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, FALSE)
		updateUsrDialog()
		return TRUE

/obj/machinery/computer/card/proc/update_modify_manifest()
	GLOB.manifest.modify(inserted_modify_id.registered_name, inserted_modify_id.assignment, inserted_modify_id.hud_state)

/obj/machinery/computer/card/AltClick(mob/user)
	..()
	if(!user.canUseTopic(src, !issilicon(user)) || !is_operational)
		return
	if(inserted_modify_id)
		if(id_eject(user, inserted_modify_id))
			inserted_modify_id = null
			updateUsrDialog()
			return
	if(inserted_scan_id)
		if(id_eject(user, inserted_scan_id))
			inserted_scan_id = null
			updateUsrDialog()
			return

/obj/machinery/computer/card/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	if(.)
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "IdConsole")
		ui.open()

/obj/machinery/computer/card/ui_static_data(mob/user)
	var/list/data = list()
	data["is_master"] = !target_dept
	data["is_silicon"] = issilicon(user)
	data["paycheck_departments"] = available_paycheck_departments.Copy()

	// Build the access region definitions (these don't change)
	var/list/regions = list()
	for(var/i in 1 to 7)
		var/list/region_data = list()
		region_data["name"] = get_region_accesses_name(i)
		region_data["region_code"] = i
		var/list/accesses = list()
		for(var/A in get_region_accesses(i))
			accesses += list(list(
				"access_code" = A,
				"access_name" = get_access_desc(A),
			))
		region_data["accesses"] = accesses
		regions += list(region_data)
	data["access_regions"] = regions
	return data

/obj/machinery/computer/card/ui_data(mob/user)
	var/list/data = list()
	data["authenticated"] = authenticated
	data["scan_name"] = inserted_scan_id ? inserted_scan_id.name : null
	data["modify_name"] = inserted_modify_id ? inserted_modify_id.name : null
	data["target_paycheck"] = target_paycheck
	data["printing"] = printing
	data["allowed_regions"] = region_access ? region_access.Copy() : list()

	// Build the visible accounts list
	var/list/accounts = list()
	if(authenticated)
		for(var/datum/bank_account/B in SSeconomy.bank_accounts)
			if(B.account_security_level >= ACCOUNT_SECURITY_LEVEL_OFFSTATION)
				continue
			if(B.account_security_level >= ACCOUNT_SECURITY_LEVEL_CAPTAIN && authenticated < 2)
				continue
			var/datum/record/crew/record = find_record(B.account_holder, GLOB.manifest.general)
			accounts += list(list(
				"account_ref" = REF(B),
				"name" = B.account_holder,
				"rank" = record ? record.rank : "Unknown",
				"suspended" = B.suspended,
				"security_level" = B.account_security_level,
			))
	data["accounts"] = accounts

	// Selected account detail
	var/datum/bank_account/selected = selected_account_ref ? locate(selected_account_ref) : null
	if(selected && !(selected in SSeconomy.bank_accounts))
		selected = null
		selected_account_ref = null

	data["selected_account_ref"] = selected_account_ref

	if(selected)
		var/datum/record/crew/record = find_record(selected.account_holder, GLOB.manifest.general)
		var/list/detail = list()
		detail["account_ref"] = REF(selected)
		detail["name"] = selected.account_holder
		detail["rank"] = record ? record.rank : "Unknown"
		detail["account_id"] = selected.account_id
		detail["security_level"] = selected.account_security_level
		detail["suspended"] = selected.suspended
		detail["immutable"] = selected.access_immutable
		detail["balance"] = selected.account_balance
		detail["access"] = selected.access.Copy()
		detail["active_departments"] = selected.active_departments

		var/list/payments = list()
		var/list/bonuses = list()
		for(var/dept in selected.payment_per_department)
			payments[dept] = selected.payment_per_department[dept]
		for(var/dept in selected.bonus_per_department)
			bonuses[dept] = selected.bonus_per_department[dept]
		detail["payments"] = payments
		detail["bonuses"] = bonuses
		data["selected_account"] = detail

		// Build per-account access region data (with has_access and can_edit flags)
		var/list/regions = list()
		for(var/i in 1 to 7)
			var/can_edit_region = (authenticated == 2) || (region_access && (i in region_access))
			var/list/region_data = list()
			region_data["name"] = get_region_accesses_name(i)
			region_data["region_code"] = i
			var/list/accesses = list()
			for(var/A in get_region_accesses(i))
				accesses += list(list(
					"access_code" = A,
					"access_name" = get_access_desc(A),
					"has_access" = (A in selected.access),
					"can_edit" = can_edit_region && !selected.access_immutable,
				))
			region_data["accesses"] = accesses
			regions += list(region_data)
		data["access_regions"] = regions
	else
		data["selected_account"] = null
		data["access_regions"] = list()

	return data

/obj/machinery/computer/card/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return

	var/mob/user = ui.user

	switch(action)
		if("login")
			if(authenticated)
				return FALSE
			if(!inserted_scan_id && !issilicon(user))
				balloon_alert(user, "no ID detected")
				playsound(src, 'sound/machines/terminal_error.ogg', 50, FALSE)
				return FALSE
			if(!check_access(inserted_scan_id))
				balloon_alert(user, "access denied")
				playsound(src, 'sound/machines/terminal_error.ogg', 50, FALSE)
				return FALSE
			region_access = list()
			region_access_payment = NONE
			head_subordinates = list()
			if(ACCESS_CHANGE_IDS in inserted_scan_id.access)
				if(target_dept)
					head_subordinates = get_all_jobs()
					region_access |= target_dept
					region_access_payment = ALL
					authenticated = 1
				else
					region_access_payment = ALL
					authenticated = 2
			else
				if((ACCESS_HOP in inserted_scan_id.access) && ((target_dept == DEPT_GEN) || !target_dept))
					region_access |= DEPT_GEN
					region_access |= DEPT_SUP
					region_access_payment |= ACCOUNT_COM_BITFLAG | ACCOUNT_CIV_BITFLAG | ACCOUNT_SRV_BITFLAG | ACCOUNT_CAR_BITFLAG
					get_subordinates(JOB_NAME_HEADOFPERSONNEL)
				if((ACCESS_HOS in inserted_scan_id.access) && ((target_dept == DEPT_SEC) || !target_dept))
					region_access |= DEPT_SEC
					region_access_payment |= ACCOUNT_SEC_BITFLAG
					get_subordinates(JOB_NAME_HEADOFSECURITY)
				if((ACCESS_CMO in inserted_scan_id.access) && ((target_dept == DEPT_MED) || !target_dept))
					region_access |= DEPT_MED
					region_access_payment |= ACCOUNT_MED_BITFLAG
					get_subordinates(JOB_NAME_CHIEFMEDICALOFFICER)
				if((ACCESS_RD in inserted_scan_id.access) && ((target_dept == DEPT_SCI) || !target_dept))
					region_access |= DEPT_SCI
					region_access_payment |= ACCOUNT_SCI_BITFLAG
					get_subordinates(JOB_NAME_RESEARCHDIRECTOR)
				if((ACCESS_CE in inserted_scan_id.access) && ((target_dept == DEPT_ENG) || !target_dept))
					region_access |= DEPT_ENG
					region_access_payment |= ACCOUNT_ENG_BITFLAG
					get_subordinates(JOB_NAME_CHIEFENGINEER)
				if(length(region_access))
					authenticated = 1
			if(authenticated)
				playsound(src, 'sound/machines/terminal_on.ogg', 50, FALSE)
			return TRUE

		if("logout")
			region_access = null
			head_subordinates = null
			authenticated = 0
			selected_account_ref = null
			playsound(src, 'sound/machines/terminal_off.ogg', 50, FALSE)
			return TRUE

		if("insert_scan")
			if(inserted_scan_id)
				return FALSE
			if(!user.get_id_in_hand())
				return FALSE
			var/obj/item/held_item = user.get_active_held_item()
			var/obj/item/card/id/id_to_insert = held_item.GetID()
			if(id_insert(user, held_item, inserted_scan_id))
				inserted_scan_id = id_to_insert || held_item
			return TRUE

		if("eject_scan")
			if(!inserted_scan_id)
				return FALSE
			if(id_eject(user, inserted_scan_id))
				inserted_scan_id = null
				region_access = null
				head_subordinates = null
				authenticated = 0
				selected_account_ref = null
			return TRUE

		if("select_account")
			if(!authenticated)
				return FALSE
			var/target_ref = params["account_ref"]
			if(!target_ref)
				return FALSE
			var/datum/bank_account/target = locate(target_ref)
			if(!target || !(target in SSeconomy.bank_accounts))
				return FALSE
			selected_account_ref = target_ref
			playsound(src, "sound/machines/terminal_button0[rand(1, 8)].ogg", 50, TRUE)
			return TRUE

		if("deselect_account")
			selected_account_ref = null
			return TRUE

		if("toggle_access")
			if(!authenticated)
				return FALSE
			var/target_ref = params["account_ref"]
			var/access_code = text2num(params["access_code"])
			if(!target_ref || isnull(access_code))
				return FALSE
			var/datum/bank_account/target = locate(target_ref)
			if(!target || !(target in SSeconomy.bank_accounts))
				return FALSE
			if(target.access_immutable)
				balloon_alert(user, "access locked")
				return FALSE
			// Verify this console is allowed to edit this access
			if(!can_edit_access(access_code))
				balloon_alert(user, "unauthorized")
				return FALSE
			if(target.has_access(access_code))
				target.revoke_access(access_code)
				log_id("[key_name(user)] removed [get_access_desc(access_code)] from [target.account_holder]'s account using [inserted_scan_id] at [AREACOORD(user)].")
			else
				target.grant_access(access_code)
				log_id("[key_name(user)] added [get_access_desc(access_code)] to [target.account_holder]'s account using [inserted_scan_id] at [AREACOORD(user)].")
			playsound(src, "terminal_type", 50, FALSE)
			return TRUE

		if("grant_all")
			if(!authenticated)
				return FALSE
			var/target_ref = params["account_ref"]
			if(!target_ref)
				return FALSE
			var/datum/bank_account/target = locate(target_ref)
			if(!target || !(target in SSeconomy.bank_accounts))
				return FALSE
			if(target.access_immutable)
				balloon_alert(user, "access locked")
				return FALSE
			var/list/to_grant = list()
			if(authenticated == 2)
				to_grant = get_all_accesses()
			else if(region_access)
				for(var/region in region_access)
					to_grant |= get_region_accesses(region)
			target.grant_access(to_grant)
			log_id("[key_name(user)] granted all accessible access to [target.account_holder]'s account using [inserted_scan_id] at [AREACOORD(user)].")
			playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
			return TRUE

		if("revoke_all")
			if(!authenticated)
				return FALSE
			var/target_ref = params["account_ref"]
			if(!target_ref)
				return FALSE
			var/datum/bank_account/target = locate(target_ref)
			if(!target || !(target in SSeconomy.bank_accounts))
				return FALSE
			if(target.access_immutable)
				balloon_alert(user, "access locked")
				return FALSE
			var/list/to_revoke = list()
			if(authenticated == 2)
				to_revoke = get_all_accesses()
			else if(region_access)
				for(var/region in region_access)
					to_revoke |= get_region_accesses(region)
			target.revoke_access(to_revoke)
			log_id("[key_name(user)] revoked all accessible access from [target.account_holder]'s account using [inserted_scan_id] at [AREACOORD(user)].")
			playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, FALSE)
			return TRUE

		if("create_account")
			if(!authenticated || target_dept)
				return FALSE
			if(!inserted_scan_id)
				balloon_alert(user, "no ID detected")
				return FALSE
			if(!(ACCESS_HOP in inserted_scan_id.access))
				balloon_alert(user, "insufficient access")
				return FALSE
			var/datum/bank_account/budget = SSeconomy.get_budget_account(initial(target_paycheck))
			if(!budget || !budget.has_money(NEW_BANK_ACCOUNT_COST))
				balloon_alert(user, "insufficient budget")
				return FALSE
			var/target_name = reject_bad_text(stripped_input(user, "Write the bank owner's name", "Account owner's name?"), MAX_NAME_LEN)
			if(!target_name)
				return FALSE
			if(!budget.adjust_money(-NEW_BANK_ACCOUNT_COST))
				balloon_alert(user, "insufficient budget")
				return FALSE
			var/datum/bank_account/new_account = new(target_name, SSjob.GetJob(JOB_NAME_ASSISTANT))
			for(var/each in new_account.payment_per_department)
				new_account.payment_per_department[each] = 0
			balloon_alert(user, "account created: [new_account.account_id]")
			playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
			return TRUE

	return FALSE

/// Returns TRUE if this console is allowed to toggle the given access code.
/obj/machinery/computer/card/proc/can_edit_access(access_code)
	if(authenticated == 2)
		return (access_code in get_all_accesses())
	if(authenticated == 1 && region_access)
		for(var/region in region_access)
			if(access_code in get_region_accesses(region))
				return TRUE
	return FALSE

/obj/machinery/computer/card/Topic(href, href_list)
	if(..())
		return

	if(!usr.canUseTopic(src, !issilicon(usr)) || !is_operational)
		usr.unset_machine()
		usr << browse(null, "window=id_com")
		return

	usr.set_machine(src)
	switch(href_list["choice"])
		if ("inserted_modify_id")
			if(inserted_modify_id && !usr.get_active_held_item())
				if(id_eject(usr, inserted_modify_id))
					inserted_modify_id = null
					updateUsrDialog()
					return
			if(usr.get_id_in_hand())
				var/obj/item/held_item = usr.get_active_held_item()
				var/obj/item/card/id/id_to_insert = held_item.GetID()
				if(id_insert(usr, held_item, inserted_modify_id))
					inserted_modify_id = id_to_insert
					updateUsrDialog()
		if ("inserted_scan_id")
			if(inserted_scan_id && !usr.get_active_held_item())
				if(id_eject(usr, inserted_scan_id))
					inserted_scan_id = null
					updateUsrDialog()
					return
			if(usr.get_id_in_hand())
				var/obj/item/held_item = usr.get_active_held_item()
				var/obj/item/card/id/id_to_insert = held_item.GetID()
				if(id_insert(usr, held_item, inserted_scan_id))
					inserted_scan_id = id_to_insert
					updateUsrDialog()
		if ("auth")
			if ((!( authenticated ) && (inserted_scan_id || issilicon(usr)) && (inserted_modify_id || mode)))
				if (check_access(inserted_scan_id))
					region_access = list()
					region_access_payment = NONE
					head_subordinates = list()
					if(ACCESS_CHANGE_IDS in inserted_scan_id.access)
						if(target_dept)
							head_subordinates = get_all_jobs()
							region_access |= target_dept
							region_access_payment = ALL
							authenticated = 1
						else
							region_access_payment = ALL
							authenticated = 2
						playsound(src, 'sound/machines/terminal_on.ogg', 50, FALSE)

					else
						if((ACCESS_HOP in inserted_scan_id.access) && ((target_dept==DEPT_GEN) || !target_dept))
							region_access |= DEPT_GEN
							region_access |= DEPT_SUP //Currently no seperation between service/civillian and supply
							region_access_payment |= ACCOUNT_COM_BITFLAG | ACCOUNT_CIV_BITFLAG | ACCOUNT_SRV_BITFLAG | ACCOUNT_CAR_BITFLAG
							get_subordinates(JOB_NAME_HEADOFPERSONNEL)
						if((ACCESS_HOS in inserted_scan_id.access) && ((target_dept==DEPT_SEC) || !target_dept))
							region_access |= DEPT_SEC
							region_access_payment |= ACCOUNT_SEC_BITFLAG
							get_subordinates(JOB_NAME_HEADOFSECURITY)
						if((ACCESS_CMO in inserted_scan_id.access) && ((target_dept==DEPT_MED) || !target_dept))
							region_access |= DEPT_MED
							region_access_payment |= ACCOUNT_MED_BITFLAG
							get_subordinates(JOB_NAME_CHIEFMEDICALOFFICER)
						if((ACCESS_RD in inserted_scan_id.access) && ((target_dept==DEPT_SCI) || !target_dept))
							region_access |= DEPT_SCI
							region_access_payment |= ACCOUNT_SCI_BITFLAG
							get_subordinates(JOB_NAME_RESEARCHDIRECTOR)
						if((ACCESS_CE in inserted_scan_id.access) && ((target_dept==DEPT_ENG) || !target_dept))
							region_access |= DEPT_ENG
							region_access_payment |= ACCOUNT_ENG_BITFLAG
							get_subordinates(JOB_NAME_CHIEFENGINEER)
						if(region_access)
							authenticated = 1
			else if ((!( authenticated ) && issilicon(usr)) && (!inserted_modify_id))
				to_chat(usr, span_warning("You can't modify an ID without an ID inserted to modify! Once one is in the modify slot on the computer, you can log in."))
		if ("logout")
			region_access = null
			head_subordinates = null
			authenticated = 0
			playsound(src, 'sound/machines/terminal_off.ogg', 50, FALSE)

		if("access")
			if(href_list["allowed"])
				if(authenticated)
					var/access_type = text2num(href_list["access_target"])
					var/access_allowed = text2num(href_list["allowed"])
					if(access_type in (istype(src, /obj/machinery/computer/card/centcom)?get_all_centcom_access() : get_all_accesses()))
						var/datum/bank_account/target_account = inserted_modify_id?.registered_account
						if(target_account && !target_account.access_immutable)
							if(access_allowed == 1)
								target_account.grant_access(access_type)
								log_id("[key_name(usr)] added [get_access_desc(access_type)] to [inserted_modify_id] (via account) using [inserted_scan_id] at [AREACOORD(usr)].")
							else
								target_account.revoke_access(access_type)
								log_id("[key_name(usr)] removed [get_access_desc(access_type)] from [inserted_modify_id] (via account) using [inserted_scan_id] at [AREACOORD(usr)].")
						else
							inserted_modify_id.access -= access_type
							log_id("[key_name(usr)] removed [get_access_desc(access_type)] from [inserted_modify_id] using [inserted_scan_id] at [AREACOORD(usr)].")
							if(access_allowed == 1)
								inserted_modify_id.access |= access_type
								log_id("[key_name(usr)] added [get_access_desc(access_type)] to [inserted_modify_id] using [inserted_scan_id] at [AREACOORD(usr)].")
						playsound(src, "terminal_type", 50, FALSE)
		if ("assign")
			if (authenticated == 2)
				var/datum/bank_account/B = inserted_modify_id?.registered_account
				var/datum/record/crew/record = find_record(inserted_modify_id.registered_name, GLOB.manifest.general)
				var/t1 = href_list["assign_target"]
				if(t1 == "Custom")
					var/newJob = reject_bad_text(stripped_input("Enter a custom job assignment.", "Assignment", inserted_modify_id ? inserted_modify_id.assignment : "Unassigned"), MAX_NAME_LEN)
					if(newJob)
						t1 = newJob
						log_id("[key_name(usr)] changed [inserted_modify_id] assignment to [newJob] using [inserted_scan_id] at [AREACOORD(usr)].")

				else if(t1 == "Unassigned")
					var/datum/bank_account/target_account = inserted_modify_id.registered_account
					if(target_account && !target_account.access_immutable)
						target_account.set_access(list())
					else
						inserted_modify_id.access -= get_all_accesses()

					// These lines are to make an individual to an assistant
					if(B)
						for(var/each in inserted_modify_id.registered_account.payment_per_department)
							if(SSeconomy.is_nonstation_account(each)) // do not touch VIP/Command flag
								continue
							B.active_departments &= ~SSeconomy.get_budget_acc_bitflag(each) // turn off all bitflag for each department except for VIP/Command
							B.payment_per_department[each] = 0 // your payment for each department is 0
							B.bonus_per_department[each] = 0   // your bonus for each department is 0
						B.active_departments &= ~SSeconomy.get_budget_acc_bitflag(ACCOUNT_COM_ID) // micromanagement. Command bitflag should be removed manually, because 'for/each' didn't remove it.
						B.payment_per_department[ACCOUNT_CIV_ID] = PAYCHECK_MINIMAL // for the love of god, let them have minimal payment from Civ budget... to be a real assistant.
					if(record)
						for(var/each in B.payment_per_department)
							if(SSeconomy.is_nonstation_account(each)) // do not touch VIP/Command flag
								continue
							record.active_department &= ~SSeconomy.get_budget_acc_bitflag(each) // turn off all bitflag for each department except for VIP/Command. *note: this actually shouldn't use `get_budget_acc_bitflag()` proc, because bitflags are the same but these have a different purpose.
						record.active_department &= ~DEPT_BITFLAG_COM  // micromanagement2. the reason is the same. Command should be removed manually.


					log_id("[key_name(usr)] unassigned and stripped all access from [inserted_modify_id] using [inserted_scan_id] at [AREACOORD(usr)].")

				else
					var/datum/job/jobdatum
					if(!istype(src, /obj/machinery/computer/card/centcom)) // station level
						jobdatum = SSjob.GetJob(t1)
						if(!jobdatum)
							to_chat(usr, span_warning("No log exists for this job."))
							stack_trace("bad job string '[t1]' is given through HoP console by '[ckey(usr)]'")
							updateUsrDialog()
							return

						var/datum/bank_account/target_account = inserted_modify_id.registered_account
						if(target_account && !target_account.access_immutable)
							target_account.set_access(jobdatum.get_access())
						else
							inserted_modify_id.access -= get_all_accesses()
							inserted_modify_id.access |= jobdatum.get_access()
					else // centcom level
						inserted_modify_id.access -= get_all_centcom_access()
						inserted_modify_id.access |= get_centcom_access(t1)

					// Step 1: reseting theirs first
					if(B && jobdatum) // 1-A: reseting bank payment
						for(var/each in inserted_modify_id.registered_account.payment_per_department)
							if(SSeconomy.is_nonstation_account(each))
								continue
							B.active_departments &= ~SSeconomy.get_budget_acc_bitflag(each)
							B.payment_per_department[each] = 0
							B.bonus_per_department[each] = 0
						B.active_departments &= ~SSeconomy.get_budget_acc_bitflag(ACCOUNT_COM_ID) // micromanagement
					if(record && jobdatum) // 1-B: reseting crew manifest
						for(var/each in available_paycheck_departments)
							if(SSeconomy.is_nonstation_account(each))
								continue
							record.active_department &= ~SSeconomy.get_budget_acc_bitflag(each)
						record.active_department &= ~DEPT_BITFLAG_COM  // micromanagement2
						// Note: `active_department = NONE` is a bad idea because you should keep VIP_BITFLAG.
					// Step 2: giving the job info into their bank and record
					if(B && jobdatum) // 2-A: setting bank payment
						for(var/each in jobdatum.payment_per_department)
							if(SSeconomy.is_nonstation_account(each))
								continue
							B.payment_per_department[each] = jobdatum.payment_per_department[each]
						B.active_departments |= jobdatum.bank_account_department
					if(record && jobdatum) // 2-B: setting crew manifest
						record.active_department |= jobdatum.departments

					log_id("[key_name(usr)] assigned [jobdatum || t1] job to [inserted_modify_id], manipulating it to the default access of the job using [inserted_scan_id] at [AREACOORD(usr)].")

				if (inserted_modify_id)
					inserted_modify_id.assignment = t1
					playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
				update_modify_manifest()

		if ("demote")
			if((inserted_modify_id.assignment in head_subordinates) || inserted_modify_id.assignment == "Assistant")
				inserted_modify_id.assignment = "Demoted"
				log_id("[key_name(usr)] demoted [inserted_modify_id], unassigning the card without affecting access, using [inserted_scan_id] at [AREACOORD(usr)].")
				playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
			else
				to_chat(usr, span_error("You are not authorized to demote this position."))
			update_modify_manifest()

		if ("reg")
			if (authenticated)
				var/t2 = inserted_modify_id
				if ((authenticated && inserted_modify_id == t2 && (in_range(src, usr) || issilicon(usr)) && isturf(loc)))
					// Sanitize the name first. We're not using the full sanitize_name proc as ID cards can have a wider variety of things on them that
					// would not pass as a formal character name, but would still be valid on an ID card created by a player.
					var/new_name = sanitize(href_list["reg"])
					// However, we are going to reject bad names overall including names with invalid characters in them, while allowing numbers.
					new_name = reject_bad_name(new_name, allow_numbers = TRUE)

					if(new_name)
						log_id("[key_name(usr)] changed [inserted_modify_id] name to '[new_name]', using [inserted_scan_id] at [AREACOORD(usr)].")
						inserted_modify_id.registered_name = new_name
						playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)
					else
						to_chat(usr, span_error("Invalid name entered."))
						updateUsrDialog()
						return
		if ("mode")
			mode = text2num(href_list["mode_target"])

		if("return")
			//DISPLAY MAIN MENU
			mode = 0
			playsound(src, "terminal_type", 25, FALSE)

		if("make_job_available")
			// MAKE ANOTHER JOB POSITION AVAILABLE FOR LATE JOINERS
			if(inserted_scan_id && (ACCESS_CHANGE_IDS in inserted_scan_id.access) && !target_dept)
				var/edit_job_target = href_list["job"]
				var/datum/job/j = SSjob.GetJob(edit_job_target)
				if(!j)
					updateUsrDialog()
					return 0
				if(can_open_job(j) != 1)
					updateUsrDialog()
					return 0
				if(opened_positions[edit_job_target] >= 0)
					GLOB.time_last_changed_position = world.time / 10
				j.total_position_delta++
				opened_positions[edit_job_target]++
				playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)

		if("make_job_unavailable")
			// MAKE JOB POSITION UNAVAILABLE FOR LATE JOINERS
			if(inserted_scan_id && (ACCESS_CHANGE_IDS in inserted_scan_id.access) && !target_dept)
				var/edit_job_target = href_list["job"]
				var/datum/job/j = SSjob.GetJob(edit_job_target)
				if(!j)
					updateUsrDialog()
					return 0
				if(can_close_job(j) != 1)
					updateUsrDialog()
					return 0
				//Allow instant closing without cooldown if a position has been opened before
				if(opened_positions[edit_job_target] <= 0)
					GLOB.time_last_changed_position = world.time / 10
				j.total_position_delta--
				opened_positions[edit_job_target]--
				playsound(src, 'sound/machines/terminal_prompt_deny.ogg', 50, FALSE)

		if ("prioritize_job")
			// TOGGLE WHETHER JOB APPEARS AS PRIORITIZED IN THE LOBBY
			if(inserted_scan_id && (ACCESS_CHANGE_IDS in inserted_scan_id.access) && !target_dept)
				var/priority_target = href_list["job"]
				var/datum/job/j = SSjob.GetJob(priority_target)
				if(!j)
					updateUsrDialog()
					return 0
				var/priority = TRUE
				if(j in SSjob.prioritized_jobs)
					SSjob.prioritized_jobs -= j
					priority = FALSE
				else if(j.get_spawn_position_count() <= j.current_positions)
					to_chat(usr, span_notice("[j.title] has had all positions filled. Open up more slots before prioritizing it."))
					updateUsrDialog()
					return
				else
					SSjob.prioritized_jobs += j
				to_chat(usr, span_notice("[j.title] has been successfully [priority ?  "prioritized" : "unprioritized"]. Potential employees will notice your request."))
				playsound(src, 'sound/machines/terminal_prompt_confirm.ogg', 50, FALSE)

		if ("set_paycheck_department")
			if(!inserted_scan_id)
				updateUsrDialog()
				return
			var/href_paytype = href_list["paytype"]
			if(!SSeconomy.get_budget_account(href_paytype))
				updateUsrDialog()
				return
			if(SSeconomy.is_nonstation_account(href_paytype))
				updateUsrDialog()
				return
			target_paycheck = href_paytype

		if ("adjust_pay")
			//Adjust the paycheck of a crew member. Can't be less than zero.
			if(!(authenticated || check_auth_payment()))
				updateUsrDialog()
				return
			var/paycheck_t = href_list["paycheck_t"]
			var/datum/bank_account/B = SSeconomy.get_bank_account_by_id(href_list["bank_account"]) || inserted_modify_id?.registered_account
			if(isnull(B))
				updateUsrDialog()
				return
			if(SSeconomy.is_nonstation_account(paycheck_t))
				message_admins("[ADMIN_LOOKUPFLW(usr)] tried to adjust [B.account_id] payment. It must be they're hacking the game.")
				CRASH("[key_name(usr)] tried to adjust [B.account_id] payment. It must be they're hacking the game.")
			var/new_pay = FLOOR(input(usr, "Input the new paycheck amount.", "Set new paycheck amount.", B.payment_per_department[target_paycheck]) as num|null, 1)
			if(isnull(new_pay))
				updateUsrDialog()
				return
			if(new_pay < 0)
				to_chat(usr, span_warning("Paychecks cannot be negative."))
				updateUsrDialog()
				return
			B.payment_per_department[paycheck_t] = new_pay

		if ("adjust_bonus")
			//Adjust the bonus pay of a crew member. Negative amounts dock pay.
			if(!(authenticated || check_auth_payment()))
				updateUsrDialog()
				return
			var/paycheck_t = href_list["paycheck_t"]
			var/datum/bank_account/B = SSeconomy.get_bank_account_by_id(href_list["bank_account"]) || inserted_modify_id?.registered_account
			if(isnull(B))
				updateUsrDialog()
				return
			if(SSeconomy.is_nonstation_account(paycheck_t))
				message_admins("[ADMIN_LOOKUPFLW(usr)] tried to adjust [inserted_modify_id.registered_name]'s [B.account_holder] pay bonus. It must be they're hacking the game.")
				CRASH("[key_name(usr)] tried to adjust [inserted_modify_id.registered_name]'s [B.account_holder] pay bonus. It must be they're hacking the game.")
			var/new_bonus = FLOOR(input(usr, "Input the bonus amount. Negative values will dock paychecks.", "Set paycheck bonus", B.bonus_per_department[target_paycheck]) as num|null, 1)
			if(isnull(new_bonus))
				updateUsrDialog()
				return
			B.bonus_per_department[paycheck_t] = new_bonus

		if ("turn_on_off_department_bank")
			var/check_card = href_list["check_card"]
			if(!inserted_scan_id && check_card)
				updateUsrDialog()
				return
			var/paycheck_t = href_list["paycheck_t"]
			var/datum/bank_account/B = SSeconomy.get_bank_account_by_id(href_list["bank_account"]) || inserted_modify_id?.registered_account
			if(!B)
				updateUsrDialog()
				return
			if(SSeconomy.is_nonstation_account(paycheck_t) && !(paycheck_t == ACCOUNT_COM_ID)) // command is fine to turn on/off
				message_admins("[ADMIN_LOOKUPFLW(usr)] tried to adjust [inserted_modify_id.registered_name]'s vendor free status of [B.account_holder]. It must be they're hacking the game.")
				CRASH("[key_name(usr)] tried to adjust [inserted_modify_id.registered_name]'s vendor free status of [B.account_holder]. It must be they're hacking the game.")

			if(B.active_departments & SSeconomy.get_budget_acc_bitflag(paycheck_t))
				B.active_departments &= ~SSeconomy.get_budget_acc_bitflag(paycheck_t) // turn off
			else
				B.active_departments |= SSeconomy.get_budget_acc_bitflag(paycheck_t) // turn on

		if ("turn_on_off_department_manifest")
			var/target_bitflag = text2num(href_list["target_bitflag"])
			var/datum/record/crew/record = find_record(inserted_modify_id.registered_name, GLOB.manifest.general)
			if(!record)
				updateUsrDialog()
				return

			if(record.active_department & target_bitflag)
				record.active_department &= ~target_bitflag // turn off
			else
				record.active_department |= target_bitflag // turn on

		if ("print")
			if (!( printing ))
				printing = 1
				say("Printing...")
				sleep(50)
				var/obj/item/paper/P = new /obj/item/paper( loc )
				var/t1 = "<B>Crew Manifest:</B><BR>"
				for(var/datum/record/crew/t in sort_record(GLOB.manifest.general))
					t1 += t.name + " - " + t.rank + "<br>"
				P.default_raw_text = t1
				P.name = "paper- 'Crew Manifest'"
				printing = null
				playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, FALSE)

		if ("open_new_account")
			if(!inserted_scan_id)
				say("No ID detected.")
				updateUsrDialog()
				return
			if(!(ACCESS_HOP in inserted_scan_id.access))
				say("Insufficient access to create a new bank account.")
				return
			var/datum/bank_account/B = SSeconomy.get_budget_account(initial(target_paycheck))
			switch(alert("Would you like to open a new bank account?\nIt will cost 1,000 credits in [LOWER_TEXT(initial(target_paycheck))] budget.","Open a new account","Yes","No"))
				if("No")
					return
				if("Yes")
					if(!B.has_money(NEW_BANK_ACCOUNT_COST))
						say("Insufficient budget balance, abort opening a new bank account.")
						return
			if (!(printing))
				printing = 1
				var/target_name = reject_bad_text(stripped_input("Write the bank owner's name", "Account owner's name?"), MAX_NAME_LEN)
				if(!target_name)
					printing = null
					return
				if(!B.adjust_money(-NEW_BANK_ACCOUNT_COST)) // double fail check
					say("Insufficient budget balance, abort opening a new bank account.")
					printing = null
					return

				B = new /datum/bank_account(target_name, SSjob.GetJob(JOB_NAME_ASSISTANT))
				for(var/each in B.payment_per_department)
					B.payment_per_department[each] = 0
				say("Printing...")
				sleep(50)
				var/obj/item/paper/printed_paper = new /obj/item/paper( loc )
				printed_paper.name = "New bank account information"
				var/final_paper_text = "<b>* Owner:</b> [target_name]<br>"
				final_paper_text += "<b>* Bank ID:</b> [B.account_id]<br>"
				final_paper_text += "--- Created by Nanotrasen Space Finance ---"
				printed_paper.add_raw_text(final_paper_text)
				printed_paper.update_appearance()
				printing = null
				playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, FALSE)

	if (inserted_modify_id)
		inserted_modify_id.update_label()
	updateUsrDialog()

/obj/machinery/computer/card/proc/get_subordinates(rank)
	for(var/datum/job/job in SSjob.occupations)
		if(rank in job.department_head)
			head_subordinates += job.title

/// Returns if auth id has head access that is eligible to adjust payment
/obj/machinery/computer/card/proc/check_auth_payment()
	for(var/each in list(ACCESS_HEADS, ACCESS_CHANGE_IDS, ACCESS_HOP, ACCESS_CMO, ACCESS_RD, ACCESS_CE))
		if(each in inserted_scan_id.access)
			return TRUE
	return FALSE

/obj/machinery/computer/card/centcom
	name = "\improper CentCom identification console"
	circuit = /obj/item/circuitboard/computer/card/centcom
	req_access = list(ACCESS_CENT_CAPTAIN)

/obj/machinery/computer/card/minor
	name = "department management console"
	desc = "You can use this to change ID's for specific departments."
	icon_screen = "idminor"
	circuit = /obj/item/circuitboard/computer/card/minor

/obj/machinery/computer/card/minor/Initialize(mapload)
	. = ..()
	var/obj/item/circuitboard/computer/card/minor/typed_circuit = circuit
	if(target_dept)
		typed_circuit.target_dept = target_dept
	else
		target_dept = typed_circuit.target_dept
	var/list/dept_list = list("general","security","medical","science","engineering")
	name = "[dept_list[target_dept]] department console"

/obj/machinery/computer/card/minor/hos
	target_dept = DEPT_SEC
	target_paycheck = ACCOUNT_SEC_ID
	icon_screen = "idhos"

	light_color = LIGHT_COLOR_RED

/obj/machinery/computer/card/minor/cmo
	target_dept = DEPT_MED
	target_paycheck = ACCOUNT_MED_ID
	icon_screen = "idcmo"

/obj/machinery/computer/card/minor/rd
	target_dept = DEPT_SCI
	target_paycheck = ACCOUNT_SCI_ID
	icon_screen = "idrd"

	light_color = LIGHT_COLOR_PINK

/obj/machinery/computer/card/minor/ce
	target_dept = DEPT_ENG
	target_paycheck = ACCOUNT_ENG_ID
	icon_screen = "idce"

	light_color = LIGHT_COLOR_DIM_YELLOW

#undef DEPT_ALL
#undef DEPT_GEN
#undef DEPT_SEC
#undef DEPT_MED
#undef DEPT_SCI
#undef DEPT_ENG
#undef DEPT_SUP

#undef NEW_BANK_ACCOUNT_COST
