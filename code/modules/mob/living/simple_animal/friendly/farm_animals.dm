//goat
/mob/living/simple_animal/hostile/retaliate/goat
	name = "goat"
	desc = "Not known for their pleasant disposition."
	icon_state = "goat"
	icon_living = "goat"
	icon_dead = "goat_dead"
	speak = list("EHEHEHEHEH","eh?")
	speak_emote = list("brays")
	emote_hear = list("brays.")
	emote_see = list("shakes its head.", "stamps a foot.", "glares around.")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 4, /obj/item/clothing/head/yogs/goatpelt = 1)
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "kicks"
	faction = list("goat")
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	attacktext = "kicks"
	attack_sound = 'sound/weapons/punch1.ogg'
	health = 40
	maxHealth = 40
	minbodytemp = 180
	melee_damage_lower = 1
	melee_damage_upper = 2
	attack_vis_effect = ATTACK_EFFECT_KICK
	environment_smash = ENVIRONMENT_SMASH_NONE
	stop_automated_movement_when_pulled = 1
	blood_volume = BLOOD_VOLUME_GENERIC
	var/obj/item/udder/goat/udder = null

	do_footstep = TRUE

/mob/living/simple_animal/hostile/retaliate/goat/Initialize(mapload)
	udder = new()
	. = ..()

/mob/living/simple_animal/hostile/retaliate/goat/Destroy()
	qdel(udder)
	udder = null
	return ..()

/mob/living/simple_animal/hostile/retaliate/goat/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(. && sentience_type != SENTIENCE_BOSS)
		//chance to go crazy and start wacking stuff
		if(!enemies.len && prob(1))
			Retaliate()

		if(enemies.len && prob(10))
			enemies = list()
			LoseTarget()
			src.visible_message(span_notice("[src] calms down."))
	if(stat == CONSCIOUS)
		udder.generateMilk()
		eat_plants()
		if(!pulledby)
			for(var/direction in shuffle(list(1,2,4,8,5,6,9,10)))
				var/step = get_step(src, direction)
				if(step)
					if(locate(/obj/structure/spacevine) in step || locate(/obj/structure/glowshroom) in step)
						Move(step, get_dir(src, step))

/mob/living/simple_animal/hostile/retaliate/goat/Retaliate()
	..()
	src.visible_message(span_danger("[src] gets an evil-looking gleam in [p_their()] eye."))

/mob/living/simple_animal/hostile/retaliate/goat/Move()
	. = ..()
	if(!stat)
		eat_plants()

/mob/living/simple_animal/hostile/retaliate/goat/proc/eat_plants()
	var/eaten = FALSE
	var/obj/structure/spacevine/SV = locate(/obj/structure/spacevine) in loc
	if(SV)
		SV.eat(src)
		eaten = TRUE

	var/obj/structure/glowshroom/GS = locate(/obj/structure/glowshroom) in loc
	if(GS)
		qdel(GS)
		eaten = TRUE

	if(eaten && prob(10))
		say("Nom")

/mob/living/simple_animal/hostile/retaliate/goat/attackby(obj/item/O, mob/user, params)
	if(stat == CONSCIOUS && istype(O, /obj/item/reagent_containers/glass))
		udder.milkAnimal(O, user)
		return 1
	else
		return ..()


/mob/living/simple_animal/hostile/retaliate/goat/AttackingTarget()
	. = ..()
	if(. && isliving(target))
		var/mob/living/L = target
		L.visible_message(span_warning("[src] rams [L]!"))
	if(. && ishuman(target))
		var/mob/living/carbon/human/H = target
		if(istype(H.dna.species, /datum/species/pod))
			var/obj/item/bodypart/NB = pick(H.bodyparts)
			H.visible_message(span_warning("[src] takes a big chomp out of [H]!"), \
								  span_userdanger("[src] takes a big chomp out of your [NB]!"))
			NB.dismember()

/mob/living/simple_animal/hostile/retaliate/goat/pete
	name = "Pete"

//cow---------------------------------------------------------------------------
/mob/living/simple_animal/cow
	name = "cow"
	desc = "Known for their milk, just don't tip them over."
	icon_state = "cow"
	icon_living = "cow"
	icon_dead = "cow_dead"
	icon_gib = "cow_gib"
	gender = FEMALE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	speak = list("moo?","moo","MOOOOOO")
	speak_emote = list("moos","moos hauntingly")
	emote_hear = list("brays.")
	emote_see = list("shakes its head.")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 6)
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "kicks"
	attacktext = "kicks"
	attack_sound = 'sound/weapons/punch1.ogg'
	health = 50
	maxHealth = 50
	var/obj/item/udder/udder = null
	gold_core_spawnable = FRIENDLY_SPAWN
	blood_volume = BLOOD_VOLUME_GENERIC
	attack_vis_effect = ATTACK_EFFECT_KICK

	do_footstep = TRUE

/mob/living/simple_animal/cow/Initialize(mapload)
	udder = new()
	. = ..()

/mob/living/simple_animal/cow/Destroy()
	qdel(udder)
	udder = null
	return ..()

/mob/living/simple_animal/cow/attackby(obj/item/O, mob/user, params)
	if(stat == CONSCIOUS && istype(O, /obj/item/reagent_containers/glass))
		udder.milkAnimal(O, user)
		return 1
	else
		return ..()

/mob/living/simple_animal/cow/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(stat == CONSCIOUS)
		udder.generateMilk()

/mob/living/simple_animal/cow/attack_hand(mob/living/carbon/M)
	if(!stat && M.a_intent == INTENT_DISARM && icon_state != icon_dead)
		M.visible_message(span_warning("[M] tips over [src]."),
			span_notice("You tip over [src]."))
		to_chat(src, span_userdanger("You are tipped over by [M]!"))
		Paralyze(60, ignore_canstun = TRUE)
		icon_state = icon_dead
		spawn(rand(20,50))
			if(!stat && M)
				icon_state = icon_living
				var/external
				var/internal
				switch(pick(1,2,3,4))
					if(1,2,3)
						var/text = pick("imploringly.", "pleadingly.",
							"with a resigned expression.")
						external = "[src] looks at [M] [text]"
						internal = "You look at [M] [text]"
					if(4)
						external = "[src] seems resigned to its fate."
						internal = "You resign yourself to your fate."
				visible_message(span_notice("[external]"),
					span_revennotice("[internal]"))
	else
		..()

/mob/living/simple_animal/cow/betsy
	name = "Betsy"

//chick------------------------------------------------------------
/mob/living/simple_animal/chick
	name = "\improper chick"
	desc = "Adorable! They make such a racket though."
	icon_state = "chick"
	icon_living = "chick"
	icon_dead = "chick_dead"
	icon_gib = "chick_gib"
	gender = FEMALE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	speak = list("Cherp.","Cherp?","Chirrup.","Cheep!")
	speak_emote = list("cheeps")
	emote_hear = list("cheeps.")
	emote_see = list("pecks at the ground.","flaps its tiny wings.")
	density = FALSE
	speak_chance = 2
	turns_per_move = 2
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 1)
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "kicks"
	attacktext = "kicks"
	health = 3
	maxHealth = 3
	ventcrawler = VENTCRAWLER_ALWAYS
	var/amount_grown = 0
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	mob_size = MOB_SIZE_TINY
	gold_core_spawnable = FRIENDLY_SPAWN

	do_footstep = TRUE

/mob/living/simple_animal/chick/Initialize(mapload)
	. = ..()
	pixel_x = rand(-6, 6)
	pixel_y = rand(0, 10)

/mob/living/simple_animal/chick/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. =..()
	if(!.)
		return
	if(!stat && !ckey)
		amount_grown += rand(1,2)
		if(amount_grown >= 100)
			new /mob/living/simple_animal/chicken(src.loc)
			qdel(src)

/mob/living/simple_animal/chick/holo/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	..()
	amount_grown = 0

//chicken----------------------------------------------------------
/mob/living/simple_animal/chicken
	name = "\improper chicken"
	desc = "Hopefully the eggs are good this season."
	gender = FEMALE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	icon_state = "chicken_brown"
	icon_living = "chicken_brown"
	icon_dead = "chicken_brown_dead"
	speak = list("Cluck!","BWAAAAARK BWAK BWAK BWAK!","Bwaak bwak.")
	speak_emote = list("clucks","croons")
	emote_hear = list("clucks.")
	emote_see = list("pecks at the ground.","flaps its wings viciously.")
	density = FALSE
	speak_chance = 2
	turns_per_move = 3
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/chicken = 2)
	var/egg_type = /obj/item/reagent_containers/food/snacks/egg
	var/food_type = /obj/item/reagent_containers/food/snacks/grown
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "kicks"
	attacktext = "kicks"
	health = 15
	maxHealth = 15
	ventcrawler = VENTCRAWLER_ALWAYS
	var/eggsleft = 0
	var/eggsFertile = TRUE
	var/body_color
	var/icon_prefix = "chicken"
	pass_flags = PASSTABLE | PASSMOB
	mob_size = MOB_SIZE_SMALL
	var/list/feedMessages = list("It clucks happily.","It clucks happily.")
	var/list/layMessage = EGG_LAYING_MESSAGES
	var/list/validColors = list("brown","black","white")
	gold_core_spawnable = FRIENDLY_SPAWN
	var/static/chicken_count = 0

	do_footstep = TRUE

/mob/living/simple_animal/chicken/Initialize(mapload)
	. = ..()
	if(!body_color)
		body_color = pick(validColors)
	icon_state = "[icon_prefix]_[body_color]"
	icon_living = "[icon_prefix]_[body_color]"
	icon_dead = "[icon_prefix]_[body_color]_dead"
	pixel_x = rand(-6, 6)
	pixel_y = rand(0, 10)
	++chicken_count

/mob/living/simple_animal/chicken/Destroy()
	--chicken_count
	return ..()

/mob/living/simple_animal/chicken/attackby(obj/item/O, mob/user, params)
	if(istype(O, food_type)) //feedin' dem chickens
		if(!stat && eggsleft < 8)
			var/feedmsg = "[user] feeds [O] to [name]! [pick(feedMessages)]"
			user.visible_message(feedmsg)
			qdel(O)
			eggsleft += rand(1, 4)
		else
			to_chat(user, span_warning("[name] doesn't seem hungry!"))
	else
		..()

/mob/living/simple_animal/chicken/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. =..()
	if(!.)
		return
	if((!stat && prob(3) && eggsleft > 0) && egg_type)
		visible_message(span_alertalien("[src] [pick(layMessage)]"))
		eggsleft--
		var/obj/item/E = new egg_type(get_turf(src))
		E.pixel_x = rand(-6,6)
		E.pixel_y = rand(-6,6)
		if(eggsFertile)
			if(chicken_count < MAX_CHICKENS && prob(25))
				START_PROCESSING(SSobj, E)

/obj/item/reagent_containers/food/snacks/egg/var/amount_grown = 0
/obj/item/reagent_containers/food/snacks/egg/process(delta_time)
	if(isturf(loc))
		amount_grown += rand(1,2) * delta_time
		if(amount_grown >= 200)
			visible_message("[src] hatches with a quiet cracking sound.")
			new /mob/living/simple_animal/chick(get_turf(src))
			STOP_PROCESSING(SSobj, src)
			qdel(src)
	else
		STOP_PROCESSING(SSobj, src)

//sheep--------------------------------------------------------
/mob/living/simple_animal/sheep
	name = "sheep"
	desc = "It's so fluffy!"
	icon_state = "sheep"
	icon_living = "sheep"
	icon_dead = "sheep_dead"
	gender = FEMALE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	speak = list("baa?","baa","BAAAAAA")
	speak_emote = list("bleats")
	emote_hear = list("brays.")
	emote_see = list("nibbles at the ground.")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 4)
	response_help  = "pets"
	response_disarm = "gently pushes aside"
	response_harm   = "kicks"
	attacktext = "kicks"
	attack_sound = 'sound/weapons/punch1.ogg'
	health = 40
	maxHealth = 40
	var/obj/item/udder/sheep/udder = null
	var/shaved = FALSE
	gold_core_spawnable = FRIENDLY_SPAWN
	blood_volume = BLOOD_VOLUME_GENERIC

	do_footstep = TRUE

/mob/living/simple_animal/sheep/Initialize(mapload)
	udder = new()
	. = ..()

/mob/living/simple_animal/sheep/Destroy()
	QDEL_NULL(udder)
	return ..()

/mob/living/simple_animal/sheep/attackby(obj/item/O, mob/user, params)
	if(stat == CONSCIOUS && istype(O, /obj/item/reagent_containers/glass))
		udder.milkAnimal(O, user)
		return TRUE
	else
		return ..()

/mob/living/simple_animal/sheep/Life(seconds_per_tick = SSMOBS_DT, times_fired)
	. = ..()
	if(stat == CONSCIOUS)
		udder.generateMilk()

/mob/living/simple_animal/sheep/attackby(obj/item/O, mob/user, params)
	if (istype(O, /obj/item/razor))
		if(shaved)
			to_chat(user, span_warning("The sheep doesn't have enough wool, try again later..."))
			return
		user.visible_message("[user] starts to shave [src] using \the [O].", span_notice("You start to shave [src] using \the [O]..."))
		if(do_after(user, 5 SECONDS, src))
			if(shaved)
				user.visible_message("[src] has already been shaved!")
				return
			user.visible_message("[user] shaves some wool off [src] using \the [O].", span_notice("You shave some wool off [src] using \the [O]."))
			playsound(loc, 'sound/items/welder2.ogg', 20, 1)
			shaved = TRUE
			icon_living = "sheep_sheared"
			icon_dead = "sheep_sheared_dead"
			new /obj/item/stack/sheet/wool(get_turf(src), 8)
			if(stat == CONSCIOUS)
				icon_state = icon_living
			else
				icon_state = icon_dead
			addtimer(CALLBACK(src, PROC_REF(generateWool)), 3 MINUTES)

		return
	..()

/mob/living/simple_animal/sheep/proc/generateWool()
	if(stat == CONSCIOUS)
		shaved = FALSE
		icon_living = "sheep"
		icon_dead = "sheep_dead"
		icon_state = icon_living

/mob/living/simple_animal/sheep/shawn
	name = "shawn"

//udder---------------------------------------
/obj/item/udder
	name = "udder"
	var/milktype = /datum/reagent/consumable/milk

/obj/item/udder/sheep
	name = "sheep udder"
	milktype = /datum/reagent/consumable/milk/sheep

/obj/item/udder/goat
	name = "goat udder"
	milktype = /datum/reagent/consumable/milk/goat

/obj/item/udder/Initialize(mapload)
	create_reagents(50)
	reagents.add_reagent(milktype, 20)
	. = ..()

/obj/item/udder/proc/generateMilk()
	if(prob(5))
		reagents.add_reagent(milktype, rand(5, 10))

/obj/item/udder/proc/milkAnimal(obj/O, mob/user)
	var/obj/item/reagent_containers/glass/G = O
	if(G.reagents.total_volume >= G.volume)
		to_chat(user, span_danger("[O] is full."))
		return
	var/transfered = reagents.trans_to(O, rand(5,10))
	if(transfered)
		user.visible_message("[user] milks [src] using \the [O].", span_notice("You milk [src] using \the [O]."))
	else
		to_chat(user, span_danger("The udder is dry. Wait a bit longer..."))
