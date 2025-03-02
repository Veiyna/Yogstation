
//holographic signs and barriers

/obj/structure/holosign
	name = "holo sign"
	icon = 'icons/effects/effects.dmi'
	anchored = TRUE
	max_integrity = 1
	armor = list(MELEE = 0, BULLET = 50, LASER = 50, ENERGY = 50, BOMB = 0, BIO = 0, RAD = 0, FIRE = 20, ACID = 20)
	var/obj/item/holosign_creator/projector
	resistance_flags = FREEZE_PROOF

/obj/structure/holosign/New(loc, source_projector)
	if(source_projector)
		projector = source_projector
		projector.signs += src
	..()

/obj/structure/holosign/Initialize(mapload)
	. = ..()
	alpha = 0
	SSvis_overlays.add_vis_overlay(src, icon, icon_state, ABOVE_MOB_LAYER, plane, dir, add_appearance_flags = RESET_ALPHA) //you see mobs under it, but you hit them like they are above it

/obj/structure/holosign/Destroy()
	if(projector)
		projector.signs -= src
		projector = null
	return ..()

/obj/structure/holosign/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	user.do_attack_animation(src, ATTACK_EFFECT_PUNCH)
	user.changeNext_move(CLICK_CD_MELEE)
	take_damage(5 , BRUTE, MELEE, 1)

/obj/structure/holosign/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			playsound(loc, 'sound/weapons/egloves.ogg', 80, 1)
		if(BURN)
			playsound(loc, 'sound/weapons/egloves.ogg', 80, 1)

/obj/structure/holosign/wetsign
	name = "wet floor sign"
	desc = "The words flicker as if they mean nothing."
	icon = 'icons/effects/effects.dmi'
	icon_state = "holosign"

/obj/structure/holosign/holobanana
	name = "Holographic banana peel"
	desc = "A peel from a projector"
	icon = 'icons/effects/effects.dmi'
	icon_state = "holosign_banana"

/obj/structure/holosign/holobanana/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/slippery, 120, GALOSHES_DONT_HELP)

/obj/structure/holosign/barrier
	name = "holobarrier"
	desc = "A short hard light barrier which can only be passed by walking."
	icon_state = "holosign_sec"
	pass_flags = LETPASSTHROW
	density = TRUE
	max_integrity = 20
	var/allow_walk = 1 //can we pass through it on walk intent

/obj/structure/holosign/barrier/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(.)
		return
	if(mover.pass_flags & (PASSGLASS|PASSTABLE|PASSGRILLE))
		return 1
	if(iscarbon(mover))
		var/mob/living/carbon/C = mover
		if(C.stat)	// Lets not prevent dragging unconscious/dead people.
			return TRUE
		if(allow_walk && C.m_intent == MOVE_INTENT_WALK)
			return 1

/obj/structure/holosign/barrier/wetsign
	name = "wet floor holobarrier"
	desc = "When it says walk it means walk."
	icon = 'icons/effects/effects.dmi'
	icon_state = "holosign"
	var/turf/slippery_floor

/obj/structure/holosign/barrier/wetsign/Initialize(mapload)
	. = ..()
	slippery_floor = get_turf(src)
	if(!slippery_floor?.GetComponent(/datum/component/slippery))
		return INITIALIZE_HINT_QDEL
	RegisterSignal(slippery_floor.GetComponent(/datum/component/slippery), COMSIG_PARENT_QDELETING, PROC_REF(del_self))

/obj/structure/holosign/barrier/wetsign/proc/del_self()
	SIGNAL_HANDLER
	qdel(src)

/obj/structure/holosign/barrier/wetsign/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(istype(mover, /obj/vehicle/ridden/janicart))
		return TRUE
	if(istype(mover, /obj/structure/janitorialcart))
		return TRUE
	if(istype(mover, /obj/structure/mopbucket))
		return TRUE
	if(ishuman(mover))
		var/mob/living/carbon/human/janitor = mover
		if(istype(janitor.shoes, /obj/item/clothing/shoes/galoshes))
			return TRUE

/obj/structure/holosign/barrier/engineering
	icon_state = "holosign_engi"
	flags_1 = RAD_PROTECT_CONTENTS_1 | RAD_NO_CONTAMINATE_1
	rad_insulation = RAD_LIGHT_INSULATION

/obj/structure/holosign/barrier/atmos
	name = "holofirelock"
	desc = "A hard light barrier resembling a firelock. Though it does not prevent solid objects from passing through, gas is kept out."
	icon_state = "holo_firelock"
	density = FALSE
	anchored = TRUE
	CanAtmosPass = ATMOS_PASS_NO
	resistance_flags = FIRE_PROOF | FREEZE_PROOF
	alpha = 150
	flags_1 = RAD_PROTECT_CONTENTS_1 | RAD_NO_CONTAMINATE_1
	rad_insulation = RAD_LIGHT_INSULATION

/obj/structure/holosign/barrier/atmos/Initialize(mapload)
	. = ..()
	air_update_turf(TRUE)

/obj/structure/holosign/barrier/cyborg
	name = "Energy Field"
	desc = "A fragile energy field that blocks movement. Excels at blocking lethal projectiles."
	density = TRUE
	max_integrity = 10
	allow_walk = 0

/obj/structure/holosign/barrier/cyborg/bullet_act(obj/item/projectile/P)
	take_damage((P.damage / 5) , BRUTE, MELEE, 1)	//Doesn't really matter what damage flag it is.
	if(istype(P, /obj/item/projectile/energy/electrode))
		take_damage(10, BRUTE, MELEE, 1)	//Tasers aren't harmful.
	if(istype(P, /obj/item/projectile/beam/disabler))
		take_damage(5, BRUTE, MELEE, 1)	//Disablers aren't harmful.
	return BULLET_ACT_HIT

/obj/structure/holosign/barrier/medical
	name = "\improper PENLITE holobarrier"
	desc = "A holobarrier that uses biometrics to detect human viruses. Denies passing to personnel with easily-detected, malicious viruses. Good for quarantines."
	icon_state = "holo_medical"
	alpha = 125 //lazy :)
	var/force_allaccess = FALSE
	var/buzzcd = 0

/obj/structure/holosign/barrier/medical/examine(mob/user)
	. = ..()
	. += span_notice("The biometric scanners are <b>[force_allaccess ? "off" : "on"]</b>.")

/obj/structure/holosign/barrier/medical/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(force_allaccess)
		return TRUE
	if(ishuman(mover))
		return CheckHuman(mover)

/obj/structure/holosign/barrier/medical/Bumped(atom/movable/AM)
	. = ..()
	icon_state = "holo_medical"
	if(ishuman(AM) && !CheckHuman(AM))
		if(buzzcd < world.time)
			playsound(get_turf(src),'sound/machines/buzz-sigh.ogg',65,TRUE,4)
			buzzcd = (world.time + 60)
		icon_state = "holo_medical-deny"

/obj/structure/holosign/barrier/medical/proc/CheckHuman(mob/living/carbon/human/sickboi)
	var/threat = sickboi.check_virus()
	if(get_disease_severity_value(threat) > get_disease_severity_value(DISEASE_SEVERITY_MINOR))
		return FALSE
	return TRUE

/obj/structure/holosign/barrier/medical/attack_hand(mob/living/user)
	if(CanPass(user) && user.a_intent == INTENT_HELP)
		force_allaccess = !force_allaccess
		to_chat(user, span_warning("You [force_allaccess ? "deactivate" : "activate"] the biometric scanners.")) //warning spans because you can make the station sick!
	else
		return ..()

/obj/structure/holobed
	name = "holobed"
	desc = "A first aid holobeds that slow down the metabolism of those laying on it and provides a sterile environment for surgery."
	icon = 'icons/obj/surgery.dmi'
	icon_state = "opmat_holo"
	anchored = TRUE
	can_buckle = TRUE
	density = FALSE
	buckle_lying = 90
	max_integrity = 1
	layer = BELOW_OBJ_LAYER
	var/obj/item/holosign_creator/projector
	var/atom/movable/occupant = null
	var/stasis = TRUE

/obj/structure/holobed/New(loc, source_projector)
	if(source_projector)
		projector = source_projector
		projector.signs += src
	..()

/obj/structure/holobed/Destroy()
	if(projector)
		projector.signs -= src
		projector = null
	return ..()

/obj/structure/holobed/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/surgery_bed, \
		success_chance = 0.95, \
	)

/obj/structure/holobed/examine(mob/user)
	. = ..()
	. += span_notice("The lifeform stasis field is <b>[stasis ? "on" : "off"]</b>.")

/obj/structure/holosign/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	playsound(loc, 'sound/weapons/egloves.ogg', 80, 1)

/obj/structure/holobed/update_icon_state()
	. = ..()
	icon_state = "[initial(icon_state)][stasis ? "" : "_off"]"

/obj/structure/holobed/AltClick(mob/living/user)
	if(user.a_intent == INTENT_HELP)
		stasis = !stasis
		handle_stasis(occupant)
		update_appearance(UPDATE_ICON)
		to_chat(user, span_warning("You [stasis ? "activate" : "deactivate"] the stasis field."))

/obj/structure/holobed/Exited(atom/movable/AM, atom/newloc)
	handle_stasis(AM)
	. = ..()

/obj/structure/holobed/proc/handle_stasis(mob/living/target)
	if(target == occupant && stasis)
		if(!target.has_status_effect(STATUS_EFFECT_STASIS))
			target.apply_status_effect(STATUS_EFFECT_STASIS, null, TRUE, 1)
	else
		if(istype(target) && target.has_status_effect(STATUS_EFFECT_STASIS))
			target.remove_status_effect(STATUS_EFFECT_STASIS)

/obj/structure/holobed/post_buckle_mob(mob/living/L)
	occupant = L
	handle_stasis(L)

/obj/structure/holobed/post_unbuckle_mob(mob/living/L)
	if(L == occupant)
		occupant = null
	handle_stasis(L)

/obj/structure/holosign/barrier/cyborg/hacked
	name = "Charged Energy Field"
	desc = "A powerful energy field that blocks movement. Energy arcs off it."
	max_integrity = 20
	var/shockcd = 0

/obj/structure/holosign/barrier/cyborg/hacked/bullet_act(obj/item/projectile/P)
	take_damage(P.damage, BRUTE, MELEE, 1)	//Yeah no this doesn't get projectile resistance.
	return BULLET_ACT_HIT

/obj/structure/holosign/barrier/cyborg/hacked/proc/cooldown()
	shockcd = FALSE

/obj/structure/holosign/barrier/cyborg/hacked/attack_hand(mob/living/user)
	. = ..()
	if(.)
		return
	if(!shockcd)
		if(ismob(user))
			var/mob/living/M = user
			M.electrocute_act(15,"Energy Barrier", safety=1)
			shockcd = TRUE
			addtimer(CALLBACK(src, PROC_REF(cooldown)), 5)

/obj/structure/holosign/barrier/cyborg/hacked/Bumped(atom/movable/AM)
	if(shockcd)
		return

	if(!ismob(AM))
		return

	var/mob/living/M = AM
	M.electrocute_act(15,"Energy Barrier", safety=1)
	shockcd = TRUE
	addtimer(CALLBACK(src, PROC_REF(cooldown)), 5)
