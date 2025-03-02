/obj/item/fishingrod
	name = "fishing rod"
	desc = "A rod used for fishing. Despite ordinary appearances, fishing has evolved to suit the cosmos with various features, like auto-reeling."
	icon = 'yogstation/icons/obj/fishing/fishing.dmi'
	icon_state = "fishing_rod"
	lefthand_file = 'yogstation/icons/mob/inhands/equipment/fishing_lefthand.dmi'
	righthand_file = 'yogstation/icons/mob/inhands/equipment/fishing_righthand.dmi'
	usesound = 'sound/items/crowbar.ogg'
	slot_flags = ITEM_SLOT_BACK
	force = 2
	throwforce = 5
	w_class = WEIGHT_CLASS_BULKY
	materials = list(/datum/material/iron=50)

	var/fishing_power = 10
	var/obj/item/reagent_containers/food/snacks/bait/bait = null //what bait is attached to the rod
	var/fishing = FALSE
	var/static/mutable_appearance/bobber = mutable_appearance('yogstation/icons/obj/fishing/fishing.dmi',"bobber")
	var/static/mutable_appearance/bobber_down = mutable_appearance('yogstation/icons/obj/fishing/fishing.dmi',"bobber_down")
	var/datum/component/fishable/fishing_component
	var/mob/fisher
	var/bite = FALSE

/obj/item/fishingrod/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/two_handed, \
		force_unwielded = 2, \
	)

/obj/item/fishingrod/examine(mob/user)
	. = ..()
	. += "Its current fishing power is [fishing_power]."

/obj/item/fishingrod/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	var/datum/component/fishable/fc = target.GetComponent(/datum/component/fishable)
	if(!fc)
		return ..()
	if(!fishing)
		if(!HAS_TRAIT(src, TRAIT_WIELDED))
			to_chat(user, span_warning("You need to wield the rod in both hands before you can cast it!"))
			return
		cast(fc,user)
	else
		if(fc != fishing_component)
			to_chat(user, span_warning("You are not fishing here!"))
			return
		reel_in() //intentionally able to reel in with one hand

/obj/item/fishingrod/process()
	if(!fishing)
		return PROCESS_KILL
	if(bite)
		to_chat(fisher, span_warning("Whatever was on the line drifts back into the deep..."))
		bite = FALSE
		var/turf/fishing_turf = fishing_component?.parent
		fishing_turf?.cut_overlay(bobber_down)
		fishing_turf?.add_overlay(bobber)
		return

	var/power = 0
	if(iscarbon(fisher)) //sorry, non-carbons don't get to wear cool fishing outfits
		var/mob/living/carbon/carbonfisher = fisher
		power = carbonfisher.fishing_power
	if(prob(fishing_power + power))
		to_chat(fisher, span_boldnotice("Something bites! Reel it in!"))
		bite = TRUE
		var/turf/fishing_turf = fishing_component?.parent
		fishing_turf?.cut_overlay(bobber)
		fishing_turf?.add_overlay(bobber_down)
		do_fishing_alert(fisher)

/obj/item/fishingrod/Destroy()
	STOP_PROCESSING(SSobj,src)
	return ..()

/obj/item/fishingrod/proc/cast(datum/component/fishable/fc,mob/user)
	fishing = TRUE
	fishing_component = fc
	var/turf/fishing_turf = fishing_component.parent
	fishing_turf.add_overlay(bobber)
	fisher = user
	RegisterSignal(user,COMSIG_MOVABLE_MOVED, PROC_REF(reel_in_forced),TRUE)
	RegisterSignal(src,COMSIG_MOVABLE_MOVED, PROC_REF(reel_in_forced),TRUE)
	RegisterSignal(src,COMSIG_ITEM_DROPPED, PROC_REF(reel_in_forced),TRUE)
	START_PROCESSING(SSobj,src)
	playsound(fishing_component, 'sound/effects/splash.ogg', 50, FALSE, -5)
	to_chat(fisher, span_italics("You cast out your fishing rod..."))

/obj/item/fishingrod/proc/reel_in(forced = FALSE)
	if(!forced && bite) // we got something!!!
		playsound(fishing_component, 'sound/effects/water_emerge.ogg', 50, FALSE, -5)
		var/power = 0
		if(istype(bait, /obj/item/reagent_containers/food/snacks/bait/type))
			SEND_SIGNAL(fisher, COMSIG_ADD_MOOD_EVENT, "typebait", /datum/mood_event/type_bait)
		if(iscarbon(fisher)) //sorry, non-carbons don't get to wear cool fishing outfits
			var/mob/living/carbon/carbonfisher = fisher
			power = carbonfisher.fishing_power
		spawn_reward(fishing_power + power)
		if(bait && prob(max(1/(2 + (bait.fishing_power/6)), 0))) //goodbye bait
			to_chat(fisher, span_notice("Your [bait] is lost!"))
			cut_overlays()
			QDEL_NULL(bait)
			recalculate_power()
	else
		playsound(fishing_component, 'sound/effects/splash.ogg', 50, FALSE, -5)
		if(forced)
			to_chat(fisher, span_boldnotice("The auto-reel on the fishing rod activates!"))
		else
			to_chat(fisher, span_italics("You reel in your fishing rod."))
		
	fishing = FALSE
	UnregisterSignal(fisher,COMSIG_MOVABLE_MOVED)
	UnregisterSignal(src,COMSIG_MOVABLE_MOVED)
	UnregisterSignal(src,COMSIG_ITEM_DROPPED)
	fisher = null
	STOP_PROCESSING(SSobj,src)
	var/turf/fishing_turf = fishing_component.parent
	fishing_turf?.cut_overlay(bobber)
	fishing_turf?.cut_overlay(bobber_down)
	fishing_component = null
	bite = FALSE //just to be safe

/obj/item/fishingrod/proc/reel_in_forced()
	reel_in(forced = TRUE)

/obj/item/fishingrod/proc/do_fishing_alert(atom/A)
	playsound(A.loc, 'sound/machines/chime.ogg', 50, FALSE, -5)
	var/image/I = image('icons/obj/closet.dmi', A, "cardboard_special", A.layer+1)
	flick_overlay_view(I, A, 8)
	I.alpha = 0
	animate(I, pixel_z = 32, alpha = 255, time = 2, easing = ELASTIC_EASING)

/obj/item/fishingrod/proc/spawn_reward(fishing_power = 0)
	var/picked_reward = fishing_component.get_reward(fishing_power)
	if(prob(14.29) || !picked_reward || picked_reward == FISHING_LOOT_NOTHING) //14.29% to always fail, sorry, also handles failures.
		fisher.visible_message(span_notice("[fisher] tugs on the rod and the line snaps!"), span_notice("Your line snaps! Whatever was on it sinks back into the deep."))
		return
	var/obj/reward_item = new picked_reward(fishing_component.parent)
	reward_item.alpha = 0
	reward_item.pixel_y = -12
	animate(reward_item, time = 0.25 SECONDS, pixel_y = 0, alpha = 255, easing = SINE_EASING)
	if(!fisher) //uh oh
		return
	fisher.visible_message(span_notice("[fisher] reels in [reward_item]!"), span_notice("You reel in [reward_item]!"))
	if(fisher.Adjacent(fishing_component.parent))
		if(fisher.put_in_hands(reward_item))
			return
	reward_item.throw_at(get_step(fishing_component,get_dir(fishing_component,fisher)),2,3,fisher) //whip it at them!
		

/obj/item/fishingrod/attackby(obj/item/B, mob/user, params)
	if(!istype(B,/obj/item/reagent_containers/food/snacks/bait))
		return

	if(bait)
		user.put_in_hands(bait)

	if(!user.transferItemToLoc(B,src))
		return
	bait = B
	to_chat(user, span_notice("You attach the [bait] to the fishing rod."))
	cut_overlays()
	add_overlay("fishing_rod_[bait.icon_state]")
	recalculate_power()

/obj/item/fishingrod/AltClick(mob/living/user)
	if(bait)
		user.put_in_hands(bait)
		to_chat(user, span_notice("You take the [bait] off the fishing rod."))
		cut_overlays()
		bait = null
		recalculate_power()

/obj/item/fishingrod/proc/recalculate_power()
	fishing_power = initial(fishing_power)
	if(bait)
		fishing_power += bait.fishing_power

/obj/item/fishingrod/collapsible
	name = "collapsible fishing rod"
	desc = "A collapsible fishing rod! This one can fit into your backpack for space hikes and the like."
	icon_state = "fishing_rod_collapse_c"
	base_icon_state = "fishing_rod_collapse"
	fishing_power = 15
	w_class = WEIGHT_CLASS_SMALL //it starts collapsed and small
	var/opened = FALSE
	

/obj/item/fishingrod/collapsible/attackby(obj/item/B, mob/user, params)
	if(!istype(B,/obj/item/reagent_containers/food/snacks/bait))
		return
	if(!opened)
		to_chat(user,"You can't put bait on a collapsed rod!")
		return
	..()

/obj/item/fishingrod/collapsible/AltClick(mob/living/user)
	if(bait)
		return ..()
	toggle(user)

/obj/item/fishingrod/collapsible/proc/toggle(mob/user)
	if(HAS_TRAIT(src, TRAIT_WIELDED))
		to_chat(user,"You can't collapse the rod if you are holding it with both hands")
		return
	if(fishing)
		to_chat(user,"You can't collapse the fishing rod if you are currently using it!")
		return
	if(!user.is_holding(src)) //no uncollapsing in your backpack or pockets
		return
	opened = !opened
	w_class = opened ? WEIGHT_CLASS_BULKY : WEIGHT_CLASS_SMALL
	playsound(src.loc, 'sound/machines/click.ogg', 50, TRUE)
	update_appearance(UPDATE_ICON)
	user.regenerate_icons()

/obj/item/fishingrod/collapsible/update_icon_state()
	. = ..()
	item_state = opened ? "fishing_rod" : ""
	icon_state = "[base_icon_state][opened ? "" : "_c"]"

/obj/item/fishingrod/collapsible/attack_self(mob/user)
	if(!opened)
		toggle(user)
		return
	..()

/obj/item/fishingrod/collapsible/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(!opened)
		to_chat(user,"The collapsible rod has to be open before you can do anything!")
		return
	..()

/obj/item/fishingrod/collapsible/miningmedic
	name = "ol' reliable"
	desc = "Hey! I caught a miner!"
	icon_state = "fishing_rod_miningmedic_c"
	base_icon_state = "fishing_rod_miningmedic"
	fishing_power = 1 //Rescue Yo Miners Bitch Damn! Fuck You Doin Fishin For!
