///Subtype for any kind of ballistic gun
///This has a shitload of vars on it, and I'm sorry for that, but it does make making new subtypes really easy
/obj/item/gun/ballistic
	desc = "Now comes in flavors like GUN. Uses 10mm ammo, for some reason."
	name = "projectile gun"
	icon_state = "pistol"
	w_class = WEIGHT_CLASS_NORMAL

	///sound when inserting magazine
	var/load_sound = "gun_insert_full_magazine"
	///sound when inserting an empty magazine
	var/load_empty_sound = "gun_insert_empty_magazine"
	///volume of loading sound
	var/load_sound_volume = 40
	///whether loading sound should vary
	var/load_sound_vary = TRUE
	///sound of racking
	var/rack_sound = "gun_slide_lock"
	///volume of racking
	var/rack_sound_volume = 60
	///whether racking sound should vary
	var/rack_sound_vary = TRUE
	///sound of when the bolt is locked back manually
	var/lock_back_sound = "sound/weapons/pistollock.ogg"
	///volume of lock back
	var/lock_back_sound_volume = 60
	///whether lock back varies
	var/lock_back_sound_vary = TRUE
	///Sound of ejecting a magazine
	var/eject_sound = "gun_remove_empty_magazine"
	///sound of ejecting an empty magazine
	var/eject_empty_sound = "gun_remove_full_magazine"
	///volume of ejecting a magazine
	var/eject_sound_volume = 40
	///whether eject sound should vary
	var/eject_sound_vary = TRUE
	///sound of dropping the bolt or releasing a slide
	var/bolt_drop_sound = 'sound/weapons/gun_chamber_round.ogg'
	///volume of bolt drop/slide release
	var/bolt_drop_sound_volume = 60
	///empty alarm sound (if enabled)
	var/empty_alarm_sound = 'sound/weapons/smg_empty_alarm.ogg'
	///empty alarm volume sound
	var/empty_alarm_volume = 70
	///whether empty alarm sound varies
	var/empty_alarm_vary = TRUE

	///Hides the bolt icon.
	var/show_bolt_icon = TRUE
	///Whether the gun will spawn loaded with a magazine
	var/spawnwithmagazine = TRUE
	///Compatible magazines with the gun
	var/mag_type = /obj/item/ammo_box/magazine/m10mm //Removes the need for max_ammo and caliber info
	///What magazine this gun starts with, if null it will just use mag_type
	var/starting_mag_type
	///Whether the sprite has a visible magazine or not
	var/mag_display = FALSE
	///Whether the sprite has a visible ammo display or not
	var/mag_display_ammo = FALSE
	///Whether the sprite has a visible indicator for being empty or not.
	var/empty_indicator = FALSE
	///Whether the gun alarms when empty or not.
	var/empty_alarm = FALSE
	///Whether the gun supports multiple special mag types
	var/special_mags = FALSE
	///Whether the gun is currently alarmed to prevent it from spamming sounds
	var/alarmed = FALSE
	///The bolt type of the gun, affects quite a bit of functionality, see combat.dm defines for bolt types: BOLT_TYPE_STANDARD; BOLT_TYPE_LOCKING; BOLT_TYPE_OPEN; BOLT_TYPE_NO_BOLT
	var/bolt_type = BOLT_TYPE_STANDARD
 	///Used for locking bolt and open bolt guns. Set a bit differently for the two but prevents firing when true for both.
	var/bolt_locked = FALSE
	///Whether the gun has to be racked each shot or not.
	var/semi_auto = TRUE
	///Actual magazine currently contained within the gun
	var/obj/item/ammo_box/magazine/magazine
	///whether the gun ejects the chambered casing
	var/casing_ejector = TRUE
	///Whether the gun has an internal magazine or a detatchable one. Overridden by BOLT_TYPE_NO_BOLT.
	var/internal_magazine = FALSE
	///Phrasing of the bolt in examine and notification messages; ex: bolt, slide, etc.
	var/bolt_wording = "bolt"
	///Phrasing of the magazine in examine and notification messages; ex: magazine, box, etx
	var/magazine_wording = "magazine"
	///Phrasing of the cartridge in examine and notification messages; ex: bullet, shell, dart, etc.
	var/cartridge_wording = "bullet"
	///length between individual racks
	var/rack_delay = 5
	///time of the most recent rack, used for cooldown purposes
	var/recent_rack = 0
	///Whether the gun can be tacloaded by slapping a fresh magazine directly on it
	var/tac_reloads = TRUE //Snowflake mechanic no more.
	///Whether the gun can be sawn off by sawing tools
	var/can_be_sawn_off  = FALSE
	var/reload_say = null

	// stores all types of feedback. Name of feedback + the amount of frames in the animation (must be more than 0) . Add to this list as more feedback is added. 
	var/list/feedback_types = list(
		"fire" = 0,
		"slide_open" = 0,
		"slide_close" = 0,
		"mag_out" = 0,
		"mag_in" = 0
	)
	var/feedback_original_icon = null // stores original slide position icon for feedback system
	var/feedback_firing_icon = null // stores icon of gun while firing
	var/feedback_original_icon_base = null // original base icon without the slide
	var/feedback_fire_slide = FALSE // does the gun slide move back when firing?
	var/feedback_has_recoil = TRUE
	var/feedback_recoil_amount = 1 // angle of recoil .decimal numbers are okay for less recoil as long as its more than 0
	var/feedback_recoil_hold = 0 // the amount the recoil holds before going back. best to set this to 1/4th of the fire time.
	var/feedback_recoil_speed = 2 // the time from recoil to recovery. full time = *4
	var/feedback_recoil_reverse = FALSE // TRUE for clockwise , FALSE for anti-clockwise
	var/feedback_slide_close_move = TRUE // does the slide closing cause the gun to twist clockwise?

	available_attachments = list(
		/obj/item/attachment/scope/simple,
		/obj/item/attachment/scope/holo,
		/obj/item/attachment/scope/infrared,
		/obj/item/attachment/laser_sight,
		/obj/item/attachment/grip/vertical,
	)
	max_attachments = 4
	recoil = 0.3

/obj/item/gun/ballistic/Initialize(mapload)
	. = ..()
	feedback_original_icon_base = icon_state
	if (bolt_type == BOLT_TYPE_LOCKING)
		feedback_original_icon = "[icon_state]_bolt"
		feedback_firing_icon = "[feedback_original_icon]_locked"
	else if(!feedback_firing_icon)
		feedback_firing_icon = feedback_original_icon_base
	if (!spawnwithmagazine)
		bolt_locked = TRUE
		update_appearance(UPDATE_ICON)
		return
	if (!magazine)
		if (!starting_mag_type)
			magazine = new mag_type(src)
		else
			magazine = new starting_mag_type(src)
	chamber_round()
	update_appearance(UPDATE_ICON)

/obj/item/gun/ballistic/proc/feedback(type) // checks to see if gun has that feedback type enabled then commences the animation
	if(feedback_types[type])
		feedback_commence(type, feedback_types[type])

/obj/item/gun/ballistic/proc/feedback_commence(type, frames)
	if(!type || !frames)
		return
	update_appearance(UPDATE_OVERLAYS)
	var/list/added_overlays = list()
	if(type == "fire")
		added_overlays += feedback_fire_slide ? add_overlay(feedback_firing_icon) : add_overlay(feedback_original_icon)
		DabAnimation(speed = feedback_recoil_speed, angle = ((rand(25,50)) * feedback_recoil_amount), direction = (feedback_recoil_reverse ? 2 : 3), hold_seconds = feedback_recoil_hold)
	else if(bolt_type == BOLT_TYPE_LOCKING)
		if(type == "slide_close") // cause the gun to move clockwise if slide is closed
			DabAnimation(speed = feedback_recoil_speed, angle = ((rand(20,25)) * feedback_recoil_amount), direction = 2)
	if(type != "fire")
		added_overlays += add_overlay("[feedback_original_icon_base]_[type]") // actual animation
	sleep(frames)
	cut_overlays(added_overlays)
	update_appearance(UPDATE_OVERLAYS)

/obj/item/gun/ballistic/update_icon_state()
	if(QDELETED(src))
		return
	. = ..()
	if(current_skin)
		icon_state = "[unique_reskin[current_skin]][sawn_off ? "_sawn" : ""]"
	else
		icon_state = "[initial(icon_state)][sawn_off ? "_sawn" : ""]"

/obj/item/gun/ballistic/update_overlays()
	if(QDELETED(src))
		return
	. = ..()
	if(show_bolt_icon)
		if (bolt_type == BOLT_TYPE_LOCKING)
			. += "[icon_state]_bolt[bolt_locked ? "_locked" : ""]"
		if (bolt_type == BOLT_TYPE_OPEN && bolt_locked)
			. += "[icon_state]_bolt"

	if (suppressed)
		. += "[icon_state]_[suppressed.icon_state]"
	if (enloudened)
		. += "[icon_state]_[enloudened.icon_state]"

	if(!chambered && empty_indicator)
		. += "[icon_state]_empty"

	if(!magazine || internal_magazine || !mag_display)
		return

	if(special_mags)
		. += "[icon_state]_mag_[initial(magazine.icon_state)]"
		if(mag_display_ammo && !magazine.ammo_count())
			. += "[icon_state]_mag_empty"
		return

	. += "[icon_state]_mag"
	if(!mag_display_ammo)
		return

	var/capacity_number = 0
	switch(get_ammo() / magazine.max_ammo)
		if(1 to INFINITY) //cause we can have one in the chamber.
			capacity_number = 100
		if(0.8 to 1)
			capacity_number = 80
		if(0.6 to 0.8)
			capacity_number = 60
		if(0.4 to 0.6)
			capacity_number = 40
		if(0.2 to 0.4)
			capacity_number = 20
	if (capacity_number)
		. += "[icon_state]_mag_[capacity_number]"


/obj/item/gun/ballistic/process_chamber(empty_chamber = TRUE, from_firing = TRUE, chamber_next_round = TRUE)
	var/obj/item/ammo_casing/AC = chambered //Find chambered round
	if(!semi_auto && from_firing)
		if(istype(AC) && CHECK_BITFIELD(AC.casing_flags, CASINGFLAG_FORCE_CLEAR_CHAMBER))
			chambered = null
		return
	if(istype(AC)) //there's a chambered round
		if(CHECK_BITFIELD(AC.casing_flags, CASINGFLAG_FORCE_CLEAR_CHAMBER) && from_firing)
			chambered = null
		else if(casing_ejector || !from_firing)
			AC.forceMove(drop_location()) //Eject casing onto ground.
			AC.bounce_away(TRUE)
			chambered = null
		else if(empty_chamber)
			chambered = null
	if (chamber_next_round && (magazine?.max_ammo > 1))
		chamber_round()

///Used to chamber a new round and eject the old one
/obj/item/gun/ballistic/proc/chamber_round(keep_bullet = FALSE)
	if (chambered || !magazine)
		return
	if (magazine.ammo_count())
		chambered = magazine.get_round(keep_bullet || bolt_type == BOLT_TYPE_NO_BOLT)
		if (bolt_type != BOLT_TYPE_OPEN)
			chambered.forceMove(src)

///updates a bunch of racking related stuff and also handles the sound effects and the like
/obj/item/gun/ballistic/proc/rack(mob/user = null)
	if (bolt_type == BOLT_TYPE_NO_BOLT) //If there's no bolt, nothing to rack
		return
	if (weapon_weight != WEAPON_LIGHT) //Can't rack it if the weapon doesn't permit dual-wielding and your off-hand is full
		if (user.get_inactive_held_item())
			to_chat(user, span_warning("You cannot rack the [bolt_wording] of \the [src] while your other hand is full!"))
			return
	if (bolt_type == BOLT_TYPE_OPEN)
		if(!bolt_locked)	//If it's an open bolt, racking again would do nothing
			if (user)
				to_chat(user, span_notice("\The [src]'s [bolt_wording] is already cocked!"))
			return
		bolt_locked = FALSE
	if (user)
		to_chat(user, span_notice("You rack the [bolt_wording] of \the [src]."))
	process_chamber(!chambered, FALSE)
	if (bolt_type == BOLT_TYPE_LOCKING && !chambered)
		bolt_locked = TRUE
		playsound(src, lock_back_sound, lock_back_sound_volume, lock_back_sound_vary)
		feedback("slide_open")
	else
		playsound(src, rack_sound, rack_sound_volume, rack_sound_vary)
		feedback("slide_close")
	update_appearance(UPDATE_ICON)

///Drops the bolt from a locked position
/obj/item/gun/ballistic/proc/drop_bolt(mob/user = null)
	playsound(src, bolt_drop_sound, bolt_drop_sound_volume, FALSE)
	if (user)
		to_chat(user, span_notice("You drop the [bolt_wording] of \the [src]."))
	bolt_locked = FALSE
	feedback("slide_close")
	chamber_round()
	update_appearance(UPDATE_ICON)

///Handles all the logic needed for magazine insertion
/obj/item/gun/ballistic/proc/insert_magazine(mob/user, obj/item/ammo_box/magazine/AM, display_message = TRUE)
	if(!istype(AM, mag_type))
		to_chat(user, span_warning("\The [AM] doesn't seem to fit into \the [src]..."))
		return FALSE
	if(user.transferItemToLoc(AM, src))
		if(reload_say && AM.ammo_count() && !get_ammo(FALSE, FALSE))
			user.say(reload_say, forced = "reloading")
		magazine = AM
		if (display_message)
			to_chat(user, span_notice("You load a new [magazine_wording] into \the [src]."))
		playsound(src, load_empty_sound, load_sound_volume, load_sound_vary)
		feedback("mag_in")
		if (bolt_type == BOLT_TYPE_OPEN && !bolt_locked)
			chamber_round(TRUE)
		update_appearance(UPDATE_ICON)
		return TRUE
	else
		to_chat(user, span_warning("You cannot seem to get \the [src] out of your hands!"))
		return FALSE

///Handles all the logic of magazine ejection, if tac_load is set that magazine will be tacloaded in the place of the old eject
/obj/item/gun/ballistic/proc/eject_magazine(mob/user, display_message = TRUE, obj/item/ammo_box/magazine/tac_load = null)
	if(bolt_type == BOLT_TYPE_OPEN)
		chambered = null
	if(!tac_load)
		if (magazine.ammo_count())
			playsound(src, load_sound, load_sound_volume, load_sound_vary)
		else
			playsound(src, load_empty_sound, load_sound_volume, load_sound_vary)
		feedback("mag_out")
	magazine.forceMove(drop_location())
	var/obj/item/ammo_box/magazine/old_mag = magazine
	if (tac_load)
		if (insert_magazine(user, tac_load, FALSE))
			to_chat(user, span_notice("You perform a tactical reload on \the [src]."))
			playsound(src, load_empty_sound, load_sound_volume, load_sound_vary)
			feedback("mag_out")
			playsound(src, load_sound, load_sound_volume, load_sound_vary)
			feedback("mag_in")
		else
			feedback("mag_out")
			to_chat(user, span_warning("You dropped the old [magazine_wording], but the new one doesn't fit. How embarassing."))
			magazine = null
	else
		magazine = null
	user.put_in_hands(old_mag)
	old_mag.update_appearance(UPDATE_ICON)
	if (display_message)
		to_chat(user, span_notice("You pull the [magazine_wording] out of \the [src]."))
	update_appearance(UPDATE_ICON)

/obj/item/gun/ballistic/can_shoot()
	return chambered

/obj/item/gun/ballistic/attackby(obj/item/A, mob/user, params)
	. = ..()
	if (.)
		return
	if (!internal_magazine && istype(A, /obj/item/ammo_box/magazine))
		var/obj/item/ammo_box/magazine/AM = A
		if (!magazine)
			insert_magazine(user, AM)
		else
			if (tac_reloads)
				eject_magazine(user, FALSE, AM)
			else
				to_chat(user, span_notice("There's already a [magazine_wording] in \the [src]."))
		return
	if ((istype(A, /obj/item/ammo_casing) || istype(A, /obj/item/ammo_box)) && !istype(A, /obj/item/ammo_box/no_direct))
		if (bolt_type == BOLT_TYPE_NO_BOLT || internal_magazine)
			if (chambered && !chambered.BB)
				chambered.forceMove(drop_location())
				chambered = null
			var/can_reload_say = !get_ammo(FALSE, FALSE)
			var/num_loaded = magazine.attempt_load(A, user, params, TRUE)
			if (num_loaded)
				to_chat(user, span_notice("You load [num_loaded] [cartridge_wording]\s into \the [src]."))
				playsound(src, load_sound, load_sound_volume, load_sound_vary)
				if(can_reload_say)
					user.say(reload_say, forced = "reloading")
				if (chambered == null && bolt_type == BOLT_TYPE_NO_BOLT)
					chamber_round()
				A.update_appearance(UPDATE_ICON)
				update_appearance(UPDATE_ICON)
			return
	if(istype(A, /obj/item/suppressor))
		var/obj/item/suppressor/S = A
		if(!can_suppress)
			to_chat(user, span_warning("You can't seem to figure out how to fit [S] on [src]!"))
			return
		if(!user.is_holding(src))
			to_chat(user, span_notice("You need be holding [src] to fit [S] to it!"))
			return
		if(suppressed || enloudened)
			to_chat(user, span_warning("[src] already has a barrel attachment!"))
			return
		if(user.transferItemToLoc(A, src))
			to_chat(user, span_notice("You screw \the [S] onto \the [src]."))
			install_suppressor(A)
			return
	if(istype(A, /obj/item/enloudener))
		var/obj/item/enloudener/E = A
		if(!user.is_holding(src))
			to_chat(user, span_notice("You need be holding [src] to fit [E] to it!"))
			return
		if(suppressed || enloudened)
			to_chat(user, span_warning("[src] already has a barrel attachment!"))
			return
		if(user.transferItemToLoc(A, src))
			to_chat(user, span_notice("You screw \the [E] onto \the [src]."))
			install_enloudener(A)
			return
	if (can_be_sawn_off)
		if (sawoff(user, A))
			return
	return FALSE

/obj/item/gun/ballistic/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	if (sawn_off)
		bonus_spread += SAWN_OFF_ACC_PENALTY
	. = ..()

///Installs a new suppressor, assumes that the suppressor is already in the contents of src
/obj/item/gun/ballistic/proc/install_suppressor(obj/item/suppressor/S)
	suppressed = S
	w_class += S.w_class //so pistols do not fit in pockets when suppressed
	update_appearance(UPDATE_ICON)

/obj/item/gun/ballistic/proc/install_enloudener(obj/item/enloudener/E)
	enloudened = E
	update_appearance(UPDATE_ICON)

/obj/item/gun/ballistic/AltClick(mob/user)
	if (unique_reskin && !current_skin && user.canUseTopic(src, BE_CLOSE, NO_DEXTERY))
		reskin_obj(user)
		return
	if(loc == user)
		if(suppressed && can_unsuppress)
			if(!user.is_holding(src))
				return ..()
			to_chat(user, span_notice("You unscrew \the [suppressed.name] from \the [src]."))
			user.put_in_hands(suppressed)
			w_class -= suppressed.w_class
			suppressed = null
			update_appearance(UPDATE_ICON)
			return
		if(enloudened && can_unsuppress)
			if(!user.is_holding(src))
				return ..()
			to_chat(user, span_notice("You unscrew \the [enloudened.name] from \the [src]."))
			user.put_in_hands(enloudened)
			w_class -= enloudened.w_class
			enloudened = null
			update_appearance(UPDATE_ICON)
			return

///Prefire empty checks for the bolt drop
/obj/item/gun/ballistic/proc/prefire_empty_checks()
	if (!chambered && !get_ammo())
		if (bolt_type == BOLT_TYPE_OPEN && !bolt_locked)
			bolt_locked = TRUE
			playsound(src, bolt_drop_sound, bolt_drop_sound_volume)
			update_appearance(UPDATE_ICON)

///postfire empty checks for bolt locking and sound alarms
/obj/item/gun/ballistic/proc/postfire_empty_checks()
	if (!chambered && !get_ammo())
		if (!alarmed && empty_alarm)
			playsound(src, empty_alarm_sound, empty_alarm_volume, empty_alarm_vary)
			alarmed = TRUE
			update_appearance(UPDATE_ICON)
		if (bolt_type == BOLT_TYPE_LOCKING)
			if(!bolt_locked)
				feedback("slide_open")
			bolt_locked = TRUE
			update_appearance(UPDATE_ICON)

/obj/item/gun/ballistic/afterattack()
	prefire_empty_checks()
	. = ..() //The gun actually firing
	if(can_shoot() && recent_shoot + 5 > world.time)
		feedback("fire")
	postfire_empty_checks()

//ATTACK HAND IGNORING PARENT RETURN VALUE
/obj/item/gun/ballistic/attack_hand(mob/user)
	if(!internal_magazine && loc == user && user.is_holding(src) && magazine)
		eject_magazine(user)
		return
	return ..()

/obj/item/gun/ballistic/attack_self(mob/living/user)
	if(!internal_magazine && magazine)
		if(!magazine.ammo_count())
			eject_magazine(user)
			return
	if(bolt_type == BOLT_TYPE_NO_BOLT)
		chambered = null
		var/num_unloaded = 0
		for(var/obj/item/ammo_casing/CB in get_ammo_list(FALSE, TRUE))
			CB.forceMove(drop_location())
			CB.bounce_away(FALSE, NONE)
			num_unloaded++
		if (num_unloaded)
			to_chat(user, span_notice("You unload [num_unloaded] [cartridge_wording]\s from [src]."))
			playsound(user, eject_sound, eject_sound_volume, eject_sound_vary)
			update_appearance(UPDATE_ICON)
		else
			to_chat(user, span_warning("[src] is empty!"))
		return
	if(bolt_type == BOLT_TYPE_LOCKING && bolt_locked)
		drop_bolt(user)
		return
	if (recent_rack > world.time)
		return
	recent_rack = world.time + rack_delay
	rack(user)
	return


/obj/item/gun/ballistic/examine(mob/user)
	. = ..()
	var/count_chambered = !(bolt_type == BOLT_TYPE_NO_BOLT || bolt_type == BOLT_TYPE_OPEN)
	. += "It has [get_ammo(count_chambered)] round\s remaining."
	if (!chambered)
		. += "It does not seem to have a round chambered."
	if (bolt_locked)
		. += "The [bolt_wording] is locked back and needs to be released before firing."
	if (suppressed)
		if(can_unsuppress)
			. += "It has a [suppressed.name] attached that can be removed with <b>alt+click</b>."
		else
			. += "It has a <b>suppressor</b> built into the barrel."
	if (enloudened)
		if(can_unsuppress)
			. += "It has a [enloudened.name] attached that can be removed with <b>alt+click</b>."
		else
			. += "It has a <b>enloudener</b> built into the barrel."
			

/obj/item/gun/ballistic/verb/set_reload()
	set name = "Set Reload Speech"
	set category = "Object"
	set desc = "Activate to set what is said with the gun when tactically reloading."
	if(usr.incapacitated())
		return
	var/input = stripped_input(usr,"What do you want to say when reloading with [src]? Cancel to disable reload speech.", ,reload_say, MAX_NAME_LEN)
	input = replacetext(input, "*", "")
	if(input)
		reload_say = input
		log_game("[usr] has set the reload speech on [src] to [reload_say]")

/obj/item/gun/ballistic/proc/get_ammo(countchambered = TRUE, countempties = TRUE)
	var/boolets = 0 //mature var names for mature people
	if (chambered && countchambered)
		boolets++
	if (magazine)
		boolets += magazine.ammo_count(countempties)
	return boolets

///gets a list of every bullet in the gun
/obj/item/gun/ballistic/proc/get_ammo_list(countchambered = TRUE, drop_all = FALSE)
	var/list/rounds = list()
	if(chambered && countchambered)
		rounds.Add(chambered)
		if(drop_all)
			chambered = null
	rounds.Add(magazine.ammo_list(drop_all))
	return rounds

#define BRAINS_BLOWN_THROW_RANGE 3
#define BRAINS_BLOWN_THROW_SPEED 1
/obj/item/gun/ballistic/suicide_act(mob/user)
	var/obj/item/organ/brain/B = user.getorganslot(ORGAN_SLOT_BRAIN)
	if (B && chambered && chambered.BB && can_trigger_gun(user) && !chambered.BB.nodamage)
		user.visible_message(span_suicide("[user] is putting the barrel of [src] in [user.p_their()] mouth.  It looks like [user.p_theyre()] trying to commit suicide!"))
		sleep(2.5 SECONDS)
		if(user.is_holding(src))
			var/turf/T = get_turf(user)
			process_fire(user, user, FALSE, null, BODY_ZONE_HEAD)
			user.visible_message(span_suicide("[user] blows [user.p_their()] brain[user.p_s()] out with [src]!"))
			var/turf/target = get_ranged_target_turf(user, turn(user.dir, 180), BRAINS_BLOWN_THROW_RANGE)
			B.Remove(user)
			B.forceMove(T)
			var/datum/callback/gibspawner = CALLBACK(GLOBAL_PROC, /proc/spawn_atom_to_turf, /obj/effect/gibspawner/generic, B, 1, FALSE, user)
			B.throw_at(target, BRAINS_BLOWN_THROW_RANGE, BRAINS_BLOWN_THROW_SPEED, callback=gibspawner)
			return(BRUTELOSS)
		else
			user.visible_message(span_suicide("[user] panics and starts choking to death!"))
			return(OXYLOSS)
	else
		user.visible_message(span_suicide("[user] is pretending to blow [user.p_their()] brain[user.p_s()] out with [src]! It looks like [user.p_theyre()] trying to commit suicide!</b>"))
		playsound(src, dry_fire_sound, 30, TRUE)
		return (OXYLOSS)
#undef BRAINS_BLOWN_THROW_SPEED
#undef BRAINS_BLOWN_THROW_RANGE

GLOBAL_LIST_INIT(gun_saw_types, typecacheof(list(
	/obj/item/circular_saw,
	/obj/item/gun/energy/plasmacutter,
	/obj/item/melee/transforming/energy,
	/obj/item/melee/chainsaw,
	/obj/item/nullrod/claymore/chainsaw_sword,
	/obj/item/nullrod/chainsaw,
	/obj/item/mounted_chainsaw)))

///Handles all the logic of sawing off guns,
/obj/item/gun/ballistic/proc/sawoff(mob/user, obj/item/saw)
	if(!saw.is_sharp() || !is_type_in_typecache(saw, GLOB.gun_saw_types)) //needs to be sharp. Otherwise turned off eswords can cut this.
		return
	if(sawn_off)
		to_chat(user, span_warning("\The [src] is already shortened!"))
		return
	if(bayonet)
		to_chat(user, span_warning("You cannot saw-off \the [src] with \the [bayonet] attached!"))
		return
	user.changeNext_move(CLICK_CD_MELEE)
	user.visible_message("[user] begins to shorten \the [src].", span_notice("You begin to shorten \the [src]..."))

	//if there's any live ammo inside the gun, makes it go off
	if(blow_up(user))
		user.visible_message(span_danger("\The [src] goes off!"), span_danger("\The [src] goes off in your face!"))
		return

	if(do_after(user, 3 SECONDS, src))
		if(sawn_off)
			return
		user.visible_message("[user] shortens \the [src]!", span_notice("You shorten \the [src]."))
		name = "sawn-off [src.name]"
		desc = sawn_desc
		w_class = WEIGHT_CLASS_NORMAL
		item_state = "gun"
		slot_flags &= ~ITEM_SLOT_BACK	//you can't sling it on your back
		slot_flags |= ITEM_SLOT_BELT		//but you can wear it on your belt (poorly concealed under a trenchcoat, ideally)
		recoil = SAWN_OFF_RECOIL
		sawn_off = TRUE
		update_appearance(UPDATE_ICON)
		return TRUE

///used for sawing guns, causes the gun to fire without the input of the user
/obj/item/gun/ballistic/proc/blow_up(mob/user)
	. = FALSE
	for(var/obj/item/ammo_casing/AC in magazine.stored_ammo)
		if(AC.BB)
			process_fire(user, user, FALSE)
			. = TRUE


/obj/item/suppressor
	name = "suppressor"
	desc = "A syndicate small-arms suppressor for maximum espionage."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "suppressor"
	w_class = WEIGHT_CLASS_TINY
	var/break_chance = 0 // Chance per shot for the suppressor to fall apart

/obj/item/suppressor/makeshift
	name = "makeshift suppressor"
	desc = "A poorly made small-arms suppressor for above average espionage on a budget."
	icon_state = "suppressor_makeshift"
	w_class = WEIGHT_CLASS_SMALL
	break_chance = 10

/obj/item/suppressor/specialoffer
	name = "cheap suppressor"
	desc = "A foreign knock-off suppressor, it feels flimsy, cheap, and brittle. Still fits most weapons."
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "suppressor"

/obj/item/enloudener
	name = "bikehorn \"suppressor\""
	desc = "Advanced clown research has found that guns that honk shoot harder, faster and more accurately. (They don't)"
	icon = 'icons/obj/guns/projectile.dmi'
	icon_state = "bikehorn"
	w_class = WEIGHT_CLASS_TINY
	var/enloudened_sound = 'sound/items/bikehorn.ogg'
