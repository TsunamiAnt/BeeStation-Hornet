#define EXTERNALREPLYCOUNT 2


//allows right clicking mobs to send an admin PM to their client, forwards the selected mob's client to cmd_admin_pm
/client/proc/cmd_admin_pm_context(mob/M in GLOB.mob_list)
	set category = null
	set name = "Admin PM Mob"
	if(!holder)
		to_chat(src, span_danger("Error: Admin-PM-Context: Only administrators may use this command."), type = MESSAGE_TYPE_ADMINPM)
		return
	if( !ismob(M) || !M.client )
		return
	cmd_admin_pm(M.client,null)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Admin PM Mob") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

//shows a list of clients we could send PMs to, then forwards our choice to cmd_admin_pm
/client/proc/cmd_admin_pm_panel()
	set category = "Admin"
	set name = "Admin PM"
	if(!holder)
		to_chat(src, span_danger("Error: Admin-PM-Panel: Only administrators may use this command."), type = MESSAGE_TYPE_ADMINPM)
		return
	var/list/client/targets[0]
	for(var/client/T)
		if(T.mob)
			if(isnewplayer(T.mob))
				targets["(New Player) - [T]"] = T
			else if(isobserver(T.mob))
				targets["[T.mob.name](Ghost) - [T]"] = T
			else
				targets["[T.mob.real_name](as [T.mob.name]) - [T]"] = T
		else
			targets["(No Mob) - [T]"] = T
	var/target = tgui_input_list(src, "To whom shall we send a message?", "Admin PM", items = sort_list(targets))
	cmd_admin_pm(targets[target],null)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Admin PM") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_ahelp_reply(whom)
	if(prefs.muted & MUTE_ADMINHELP)
		to_chat(src, span_danger("Error: Admin-PM: You are unable to use admin PM-s (muted)."), type = MESSAGE_TYPE_ADMINPM)
		return
	var/client/C
	if(istext(whom))
		if(whom[1] == "@")
			whom = findStealthKey(whom)
		C = GLOB.directory[whom]
	else if(istype(whom, /client))
		C = whom
	if(!C)
		if(holder)
			to_chat(src, span_danger("Error: Admin-PM: Client not found."), type = MESSAGE_TYPE_ADMINPM)
		return

	var/datum/help_ticket/AH = C.current_adminhelp_ticket

	if(AH)
		message_admins("[key_name_admin(src)] has started replying to [key_name_admin(C, 0, 0)]'s admin help.")
	var/msg = tgui_input_text(src, "Message:", "Private message to [C.holder?.fakekey ? "an Administrator" : key_name(C, 0, 0)].", multiline = TRUE) // tgui_input_text encodes by default
	if (!msg)
		message_admins("[key_name_admin(src)] has cancelled their reply to [key_name_admin(C, 0, 0)]'s admin help.")
		return
	cmd_admin_pm(whom, msg, html_encoded = TRUE)
	AH.Claim()

/client/proc/cmd_ahelp_reply_instant(whom, msg, html_encoded = FALSE)
	if(prefs.muted & MUTE_ADMINHELP)
		to_chat(src, span_danger("Error: Admin-PM: You are unable to use admin PM-s (muted)."), type = MESSAGE_TYPE_ADMINPM)
		return
	var/client/C
	if(istext(whom))
		if(whom[1] == "@")
			whom = findStealthKey(whom)
		C = GLOB.directory[whom]
	else if(istype(whom, /client))
		C = whom
	if(!C)
		if(holder)
			to_chat(src, span_danger("Error: Admin-PM: Client not found."), type = MESSAGE_TYPE_ADMINPM)
		return

	if (!msg)
		return
	cmd_admin_pm(whom, msg, html_encoded)

//takes input from cmd_admin_pm_context, cmd_admin_pm_panel or /client/Topic and sends them a PM.
//Fetching a message if needed. src is the sender and C is the target client
/client/proc/cmd_admin_pm(whom, msg, html_encoded = FALSE)
	if(prefs.muted & MUTE_ADMINHELP)
		to_chat(src, span_danger("Error: Admin-PM: You are unable to use admin PM-s (muted)."), type = MESSAGE_TYPE_ADMINPM)
		return

	if(!holder && !current_adminhelp_ticket)	//no ticket? https://www.youtube.com/watch?v=iHSPf6x1Fdo
		to_chat(src, span_danger("You can no longer reply to this ticket, please open another one by using the Adminhelp verb if need be."), type = MESSAGE_TYPE_ADMINPM)
		to_chat(src, span_notice("Message: [msg]"), type = MESSAGE_TYPE_ADMINPM)
		return

	var/client/recipient
	var/external = 0
	if(istext(whom))
		if(whom[1] == "@")
			whom = findStealthKey(whom)
		if(whom == "IRCKEY")
			external = 1
		else
			recipient = GLOB.directory[whom]
	else if(istype(whom, /client))
		recipient = whom

	if(external)
		if(!externalreplyamount)	//to prevent people from spamming irc/discord
			return
		if(!msg)
			msg = tgui_input_text(src, "Message:", "Private message to Administrator", multiline = TRUE)
			html_encoded = TRUE
		if(!msg)
			return
		if(holder)
			to_chat(src, span_danger("Error: Use the admin IRC/Discord channel, nerd."), type = MESSAGE_TYPE_ADMINPM)
			return


	else
		if(!recipient)
			if(holder)
				to_chat(src, span_danger("Error: Admin-PM: Client not found."), type = MESSAGE_TYPE_ADMINPM)
				if(msg)
					to_chat(src, msg)
				return
			else if(msg) // you want to continue if there's no message instead of returning now
				current_adminhelp_ticket.MessageNoRecipient(msg, sanitized = html_encoded)
				return

		//get message text, limit it's length.and clean/escape html
		if(!msg)
			msg = tgui_input_text(src,"Message:", "Private message to [recipient.holder?.fakekey ? "an Administrator" : key_name(recipient, 0, 0)].", multiline = TRUE)
			if(!msg)
				return
			// we need to not HTML encode again or you get &#39;s instead of 's
			html_encoded = TRUE

			if(prefs.muted & MUTE_ADMINHELP)
				to_chat(src, span_danger("Error: Admin-PM: You are unable to use admin PM-s (muted)."), type = MESSAGE_TYPE_ADMINPM)
				return

			if(!recipient)
				if(holder)
					to_chat(src, span_danger("Error: Admin-PM: Client not found."), type = MESSAGE_TYPE_ADMINPM)
				else
					current_adminhelp_ticket.MessageNoRecipient(msg, sanitized = html_encoded)
				return

	if (src.handle_spam_prevention(msg,MUTE_ADMINHELP))
		return

	//clean the message if it's not sent by a high-rank admin
	if(external || !check_rights(R_SERVER|R_DEBUG, FALSE))//no sending html to the poor bots
		msg = sanitize_simple(msg)
		if(!html_encoded)
			msg = html_encode(msg)
		msg = trim(msg, MAX_MESSAGE_LEN)
		if(!msg)
			return

	var/rawmsg = msg

	if(holder)
		msg = emoji_parse(msg)

	var/keywordparsedmsg = keywords_lookup(msg)

	if(external)
		to_chat(src, span_notice("PM to-<b>Admins</b>: [span_linkify("[rawmsg]")]"), type = MESSAGE_TYPE_ADMINPM)
		var/datum/help_ticket/AH = admin_ticket_log(src, "<font color='red'>Reply PM from-<b>[key_name(src, TRUE, TRUE)] to <i>External</i>: [keywordparsedmsg]</font>")
		externalreplyamount--
		send2tgs("[AH ? "#[AH.id] " : ""]Reply: [ckey]", rawmsg)
	else
		if(recipient.holder)
			if(holder)	//both are admins
				to_chat(recipient, span_danger("Admin PM from-<b>[key_name(src, recipient, 1)]</b>: [span_linkify("[keywordparsedmsg]")]"), type = MESSAGE_TYPE_ADMINPM)
				to_chat(src, span_notice("Admin PM to-<b>[key_name(recipient, src, 1)]</b>: [span_linkify("[keywordparsedmsg]")]"), type = MESSAGE_TYPE_ADMINPM)

				//omg this is dumb, just fill in both their tickets
				admin_ticket_log(src, keywordparsedmsg, key_name(src, recipient, 1), key_name(recipient, src, 1), color="teal", isSenderAdmin = TRUE, safeSenderLogged = TRUE)
				if(recipient != src)	//reeee
					admin_ticket_log(recipient, keywordparsedmsg, key_name(src, recipient, 1), key_name(recipient, src, 1), color="teal", isSenderAdmin = TRUE, safeSenderLogged = TRUE)

			else		//recipient is an admin but sender is not
				var/replymsg = "Reply PM from-<b>[key_name(src, recipient, 1)]</b>: [span_linkify("[keywordparsedmsg]")]"
				admin_ticket_log(src, keywordparsedmsg, key_name(src, recipient, 1), null, "white", isSenderAdmin = TRUE, safeSenderLogged = TRUE)
				to_chat(recipient, span_danger("[replymsg]"), type = MESSAGE_TYPE_ADMINPM)
				to_chat(src, span_notice("PM to-<b>Admins</b>: [span_linkify("[msg]")]"), type = MESSAGE_TYPE_ADMINPM)

			//play the receiving admin the adminhelp sound (if they have them enabled)
			if(recipient.prefs.read_player_preference(/datum/preference/toggle/sound_adminhelp))
				SEND_SOUND(recipient, sound('sound/effects/adminhelp.ogg'))

		else
			if(holder)	//sender is an admin but recipient is not. Do BIG RED TEXT
				if(!recipient.current_adminhelp_ticket)
					var/datum/help_ticket/admin/ticket = new(recipient)
					ticket.Create(msg, sanitized = html_encoded, is_bwoink = TRUE)

				to_chat(recipient, "<font color='red' size='4'><b>-- Administrator private message --</b></font>", type = MESSAGE_TYPE_ADMINPM)
				to_chat(recipient, span_adminsay("Admin PM from-<b>[key_name(src, recipient, 0)]</b>: [span_linkify("[msg]")]"), type = MESSAGE_TYPE_ADMINPM)
				to_chat(recipient, span_adminsay("<i>Click on the administrator's name to reply.</i>"), type = MESSAGE_TYPE_ADMINPM)
				to_chat(src, span_notice("Admin PM to-<b>[key_name(recipient, src, 1)]</b>: [span_linkify("[msg]")]"), type = MESSAGE_TYPE_ADMINPM)

				admin_ticket_log(recipient, keywordparsedmsg, key_name_admin(src), null, "purple", safeSenderLogged = TRUE)

				//always play non-admin recipients the adminhelp sound
				SEND_SOUND(recipient, sound('sound/effects/adminhelp.ogg'))

				//AdminPM popup for ApocStation and anybody else who wants to use it. Set it with POPUP_ADMIN_PM in config.txt ~Carn
				if(CONFIG_GET(flag/popup_admin_pm))
					spawn()	//so we don't hold the caller proc up
						var/sender = src
						var/sendername
						if(holder.fakekey)
							sendername = holder.fakekey
						else
							sendername = key
						var/reply = tgui_input_text(recipient, msg, "Admin PM from-[sendername]", "", multiline = TRUE)		//show message and await a reply. tgui_input_text encodes by default.
						if(recipient && reply)
							if(sender)
								recipient.cmd_admin_pm(sender, reply, html_encoded = TRUE) // sender is still about, let's reply to them.
							else
								adminhelp(reply)													//sender has left, adminhelp instead
						return

			else		//neither are admins
				to_chat(src, span_danger("Error: Admin-PM: Non-admin to non-admin PM communication is forbidden."), type = MESSAGE_TYPE_ADMINPM)
				return

	if(external)
		log_admin_private("PM: [key_name(src)]->External: [rawmsg]")
		for(var/client/X in GLOB.admins)
			to_chat(X, span_notice("<B>PM: [key_name(src, X, 0)]-&gt;External:</B> [keywordparsedmsg]"))
	else
		window_flash(recipient, ignorepref = TRUE)
		log_admin_private("PM: [key_name(src)]->[key_name(recipient)]: [rawmsg]")
		//we don't use message_admins here because the sender/receiver might get it too
		for(var/client/X in GLOB.admins)
			if(X.key!=key && X.key!=recipient.key)	//check client/X is an admin and isn't the sender or recipient
				to_chat(X, span_notice("<B>PM: [key_name(src, X, 0)]-&gt;[key_name(recipient, X, 0)]:</B> [keywordparsedmsg]"), type = MESSAGE_TYPE_ADMINPM)



#define TGS_AHELP_USAGE "Usage: ticket <close|resolve|icissue|reject|reopen \[ticket #\]|list>"
/proc/TgsPm(target,msg,sender)
	target = ckey(target)
	var/client/C = GLOB.directory[target]

	var/datum/help_ticket/ticket = C ? C.current_adminhelp_ticket : GLOB.ahelp_tickets.CKey2ActiveTicket(target)
	var/compliant_msg = trim(LOWER_TEXT(msg))
	var/tgs_tagged = "[sender](TGS/External)"
	var/list/splits = splittext(compliant_msg, " ")
	if(splits.len && splits[1] == "ticket")
		if(splits.len < 2)
			return TGS_AHELP_USAGE
		switch(splits[2])
			if("close")
				if(ticket)
					ticket.Close(tgs_tagged)
					return "Ticket #[ticket.id] successfully closed"
			if("resolve")
				if(ticket)
					ticket.Resolve(tgs_tagged)
					return "Ticket #[ticket.id] successfully resolved"
			if("icissue")
				if(ticket && istype(ticket, /datum/help_ticket/admin))
					var/datum/help_ticket/admin/a_ticket = ticket
					a_ticket.ICIssue(tgs_tagged)
					return "Ticket #[ticket.id] successfully marked as IC issue"
			if("reject")
				if(ticket)
					ticket.Reject(tgs_tagged)
					return "Ticket #[ticket.id] successfully rejected"
			if("reopen")
				if(ticket)
					return "Error: [target] already has ticket #[ticket.id] open"
				var/fail = splits.len < 3 ? null : -1
				if(!isnull(fail))
					fail = text2num(splits[3])
				if(isnull(fail))
					return "Error: No/Invalid ticket id specified. [TGS_AHELP_USAGE]"
				var/datum/help_ticket/AH = GLOB.ahelp_tickets.TicketByID(fail)
				if(!AH)
					return "Error: Ticket #[fail] not found"
				if(AH.initiator_ckey != target)
					return "Error: Ticket #[fail] belongs to [AH.initiator_ckey]"
				AH.Reopen(tgs_tagged)
				return "Ticket #[ticket.id] successfully reopened"
			if("list")
				var/list/tickets = GLOB.ahelp_tickets.TicketsByCKey(target)
				if(!tickets.len)
					return "None"
				. = ""
				for(var/I in tickets)
					var/datum/help_ticket/AH = I
					if(.)
						. += ", "
					if(AH == ticket)
						. += "Active: "
					. += "#[AH.id]"
				return
			else
				return TGS_AHELP_USAGE
		return "Error: Ticket could not be found"

	var/static/stealthkey
	var/adminname = CONFIG_GET(flag/show_irc_name) ? tgs_tagged : "Administrator"

	if(!C)
		return "Error: No client"

	if(!stealthkey)
		stealthkey = GenTgsStealthKey()

	msg = sanitize(copytext_char(msg, 1, MAX_MESSAGE_LEN))
	if(!msg)
		return "Error: No message"

	message_admins("External message from [sender] to [key_name_admin(C)] : [msg]")
	log_admin_private("External PM: [sender] -> [key_name(C)] : [msg]")
	msg = emoji_parse(msg)

	to_chat(C, "<font color='red' size='4'><b>-- Administrator private message --</b></font>", type = MESSAGE_TYPE_ADMINPM)
	to_chat(C, span_adminsay("Admin PM from-<b><a href='byond://?priv_msg=[stealthkey]'>[adminname]</A></b>: [msg]"), allow_linkify = TRUE, type = MESSAGE_TYPE_ADMINPM)
	to_chat(C, span_adminsay("<i>Click on the administrator's name to reply.</i>"), type = MESSAGE_TYPE_ADMINPM)

	admin_ticket_log(C, msg, adminname, null, "cyan", isSenderAdmin = TRUE, safeSenderLogged = TRUE)

	window_flash(C, ignorepref = TRUE)
	//always play non-admin recipients the adminhelp sound
	SEND_SOUND(C, 'sound/effects/adminhelp.ogg')

	C.externalreplyamount = EXTERNALREPLYCOUNT

	return "Message Successful"

/proc/GenTgsStealthKey()
	var/num = (rand(0,1000))
	var/i = 0
	while(i == 0)
		i = 1
		for(var/P in GLOB.stealthminID)
			if(num == GLOB.stealthminID[P])
				num++
				i = 0
	var/stealth = "@[num2text(num)]"
	GLOB.stealthminID["IRCKEY"] = stealth
	return	stealth

#undef EXTERNALREPLYCOUNT

#undef TGS_AHELP_USAGE
