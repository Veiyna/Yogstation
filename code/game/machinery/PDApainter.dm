/obj/machinery/pdapainter
	name = "\improper PDA painter"
	desc = "A PDA painting machine. To use, simply insert your PDA and choose the desired preset paint scheme."
	icon = 'icons/obj/pda.dmi'
	icon_state = "pdapainter"
	density = TRUE
	max_integrity = 200
	var/obj/item/pda/storedpda = null
	var/list/colorlist = list()

/obj/machinery/pdapainter/update_icon_state()
	. = ..()
	if(stat & BROKEN)
		icon_state = "[initial(icon_state)]-broken"
		return

	if(powered())
		icon_state = initial(icon_state)
	else
		icon_state = "[initial(icon_state)]-off"

/obj/machinery/pdapainter/update_overlays()
	. = ..()
	if(stat & BROKEN)
		return
	if(storedpda)
		. += "[initial(icon_state)]-closed"

/obj/machinery/pdapainter/Initialize(mapload)
	. = ..()
	var/list/blocked = list(
		/obj/item/pda/ai/pai,
		/obj/item/pda/ai,
		/obj/item/pda/heads,
		/obj/item/pda/clear,
		/obj/item/pda/syndicate,
		/obj/item/pda/chameleon,
		/obj/item/pda/chameleon/broken)

	for(var/P in typesof(/obj/item/pda) - blocked)
		var/obj/item/pda/D = new P

		//D.name = "PDA Style [colorlist.len+1]" //Gotta set the name, otherwise it all comes up as "PDA"
		D.name = D.icon_state //PDAs don't have unique names, but using the sprite names works.

		src.colorlist += D

/obj/machinery/pdapainter/Destroy()
	QDEL_NULL(storedpda)
	return ..()

/obj/machinery/pdapainter/on_deconstruction()
	if(storedpda)
		storedpda.forceMove(loc)
		storedpda = null

/obj/machinery/pdapainter/contents_explosion(severity, target)
	if(storedpda)
		storedpda.ex_act(severity, target)

/obj/machinery/pdapainter/handle_atom_del(atom/A)
	if(A == storedpda)
		storedpda = null
		update_appearance(UPDATE_ICON)

/obj/machinery/pdapainter/attackby(obj/item/O, mob/user, params)
	if(default_unfasten_wrench(user, O))
		power_change()
		return

	else if(istype(O, /obj/item/pda))
		if(storedpda)
			to_chat(user, span_warning("There is already a PDA inside!"))
			return
		else if(!user.transferItemToLoc(O, src))
			return
		storedpda = O
		O.add_fingerprint(user)
		update_appearance(UPDATE_ICON)

	else if(O.tool_behaviour == TOOL_WELDER && user.a_intent != INTENT_HARM)
		if(stat & BROKEN)
			if(!O.tool_start_check(user, amount=0))
				return
			user.visible_message("[user] is repairing [src].", \
							span_notice("You begin repairing [src]..."), \
							span_italics("You hear welding."))
			if(O.use_tool(src, user, 40, volume=50))
				if(!(stat & BROKEN))
					return
				to_chat(user, span_notice("You repair [src]."))
				stat &= ~BROKEN
				obj_integrity = max_integrity
				update_appearance(UPDATE_ICON)
		else
			to_chat(user, span_notice("[src] does not need repairs."))
	else
		return ..()

/obj/machinery/pdapainter/deconstruct(disassembled = TRUE)
	obj_break()

/obj/machinery/pdapainter/attack_hand(mob/user)
	. = ..()
	if(.)
		return

	if(storedpda)
		var/obj/item/pda/P
		P = input(user, "Select your color!", "PDA Painting") as null|anything in colorlist
		if(!P)
			return
		if(!in_range(src, user))
			return
		if(!storedpda)//is the pda still there?
			return
		storedpda.icon_state = P.icon_state
		storedpda.desc = P.desc
		storedpda.light_color = P.light_color //yogs start - pda flashlight colouring
		storedpda.icon = P.icon // This is to prevent yogs PDAs from being blank when switched to normal PDAs, and the other way around.
		storedpda.update_light() //yogs end - pda flashlight colouring
		ejectpda()

	else
		to_chat(user, span_notice("[src] is empty."))


/obj/machinery/pdapainter/verb/ejectpda()
	set name = "Eject PDA"
	set category = "Object"
	set src in oview(1)

	if(usr.stat || usr.restrained())
		return

	if(storedpda)
		storedpda.forceMove(drop_location())
		storedpda = null
		update_appearance(UPDATE_ICON)
	else
		to_chat(usr, span_warning("[src] is empty!"))
