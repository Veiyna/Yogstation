#define COOLDOWN_STUN 1200
#define COOLDOWN_DAMAGE 600
#define COOLDOWN_MEME 300
#define COOLDOWN_NONE 100

/obj/item/organ/vocal_cords //organs that are activated through speech with the :x/MODE_KEY_VOCALCORDS channel
	name = "vocal cords"
	icon_state = "appendix"
	visual = FALSE
	process_flags = ORGANIC | SYNTHETIC
	zone = BODY_ZONE_PRECISE_MOUTH
	slot = ORGAN_SLOT_VOICE
	gender = PLURAL
	decay_factor = 0	//we don't want decaying vocal cords to somehow matter or appear on scanners since they don't do anything damaged
	healing_factor = 0
	var/list/spans = null

/obj/item/organ/vocal_cords/proc/does_modify_message() // whether it should be allowed to modify what the player said
	return FALSE

/obj/item/organ/vocal_cords/proc/does_say_message() // whether the vocal cords wish to ASSUME DIRECT CONTROL and speak for themselves
	return FALSE

/obj/item/organ/vocal_cords/proc/modify_message(message) //Returns to /mob/living/say() the new message it ought to say, perhaps with some funky spans or something.
	return

/obj/item/organ/vocal_cords/proc/say_message(message,message_range) //Handles saying the message itself. Returns nothing.
	return

/obj/item/organ/adamantine_resonator
	name = "adamantine resonator"
	desc = "Fragments of adamantine exist in all golems, stemming from their origins as purely magical constructs. These are used to \"hear\" messages from their leaders."
	zone = BODY_ZONE_HEAD
	slot = ORGAN_SLOT_ADAMANTINE_RESONATOR
	process_flags = ORGANIC | SYNTHETIC
	icon_state = "adamantine_resonator"
	visual = FALSE

/obj/item/organ/vocal_cords/adamantine
	name = "adamantine vocal cords"
	desc = "When adamantine resonates, it causes all nearby pieces of adamantine to resonate as well. Adamantine golems use this to broadcast messages to nearby golems."
	actions_types = list(/datum/action/item_action/organ_action/use/adamantine_vocal_cords)
	icon_state = "adamantine_cords"

/datum/action/item_action/organ_action/use/adamantine_vocal_cords/Trigger()
	if(!IsAvailable(feedback = FALSE))
		return
	var/message = input(owner, "Resonate a message to all nearby golems.", "Resonate")
	if(QDELETED(src) || QDELETED(owner) || !message)
		return
	owner.say(".x[message]")

/obj/item/organ/vocal_cords/adamantine/does_modify_message()
	return TRUE

/obj/item/organ/vocal_cords/adamantine/modify_message(message)
	var/msg = span_resonate("[span_name(owner.real_name)] [span_message("resonates, \"[message]\"")]")
	for(var/m in GLOB.player_list)
		if(iscarbon(m))
			var/mob/living/carbon/C = m
			if(C.getorganslot(ORGAN_SLOT_ADAMANTINE_RESONATOR))
				to_chat(C, msg)
		else if(isobserver(m))
			var/link = FOLLOW_LINK(m, owner)
			to_chat(m, "[link] [msg]")
	return message // Kinda weird to do this, but uhhhh... yeah.

//Colossus drop, forces the listeners to obey certain commands
/obj/item/organ/vocal_cords/colossus
	name = "divine vocal cords"
	desc = "They carry the voice of an ancient god."
	icon_state = "voice_of_god"
	actions_types = list(/datum/action/item_action/organ_action/colossus)
	var/next_command = 0
	var/cooldown_mod = 1
	var/base_multiplier = 1
	spans = list("colossus","yell")

/datum/action/item_action/organ_action/colossus
	name = "Voice of God"
	var/obj/item/organ/vocal_cords/colossus/cords = null

/datum/action/item_action/organ_action/colossus/New()
	..()
	cords = target

/datum/action/item_action/organ_action/colossus/IsAvailable(feedback = FALSE)
	if(world.time < cords.next_command)
		return FALSE
	if(!owner)
		return FALSE
	if(isliving(owner))
		var/mob/living/L = owner
		if(!L.can_speak_vocal())
			return FALSE
	if(check_flags & AB_CHECK_CONSCIOUS)
		if(owner.stat)
			return FALSE
	return TRUE

/datum/action/item_action/organ_action/colossus/Trigger()
	. = ..()
	if(!IsAvailable(feedback = FALSE))
		if(world.time < cords.next_command)
			to_chat(owner, span_notice("You must wait [DisplayTimeText(cords.next_command - world.time)] before Speaking again."))
		return
	var/command = input(owner, "Speak with the Voice of God", "Command")
	if(QDELETED(src) || QDELETED(owner))
		return
	if(!command)
		return
	owner.say(".x[command]")

/obj/item/organ/vocal_cords/colossus/does_say_message()
	if(world.time < next_command)
		to_chat(owner, span_notice("You must wait [DisplayTimeText(next_command - world.time)] before Speaking again."))
		return FALSE
	if(!owner)
		return FALSE
	return TRUE

/obj/item/organ/vocal_cords/colossus/say_message(message,message_range)
	playsound(get_turf(owner), 'sound/magic/clockwork/invoke_general.ogg', 300, 1, 5)
	var/cooldown = voice_of_god(uppertext(message), owner, spans, base_multiplier,FALSE,TRUE,TRUE,message_range)
	next_command = world.time + (cooldown * cooldown_mod)

//////////////////////////////////////
///////////VOICE OF GOD///////////////
//////////////////////////////////////

/proc/voice_of_god(message, mob/living/user, list/span_list, base_multiplier = 1, include_speaker = FALSE, message_admins = TRUE, forced_span = FALSE, max_range = 8)
	var/cooldown = 0

	if(!user || !user.can_speak(message) || user.stat)
		return 0 //no cooldown

	var/log_message = uppertext(message)
	if(!forced_span)
		if(iscultist(user))
			span_list = list("narsiesmall")
		else if (is_servant_of_ratvar(user))
			span_list = list("ratvar")
	if(!span_list || !span_list.len)
		span_list = list()

	if(!user.say(message, spans = span_list, sanitize = FALSE)) // If we failed to speak
		return 0

	var/list/mob/living/listeners = list()
	for(var/mob/living/L in get_hearers_in_view(max_range, user))
		if(L.can_hear() && !L.anti_magic_check(FALSE, TRUE) && L.stat != DEAD)
			if(L == user && !include_speaker)
				continue
			if(ishuman(L))
				var/mob/living/carbon/human/H = L
				if(istype(H.ears, /obj/item/clothing/ears/earmuffs))
					continue
			listeners += L

	if(!listeners.len)
		cooldown = COOLDOWN_NONE
		return cooldown

	var/power_multiplier = base_multiplier

	if(user.mind)
		//Chaplains are very good at speaking with the voice of god
		if(user.mind.assigned_role == "Chaplain")
			power_multiplier *= 2
		//Command staff has authority
		if(IS_COMMAND(user))
			power_multiplier *= 1.4
		//I AM THE LAW
		if(IS_SECURITY(user))
			power_multiplier *= 1.2
		//Why are you speaking
		if(user.mind.assigned_role == "Mime")
			power_multiplier *= 0.5

	//Cultists are closer to their gods and are more powerful, but they'll give themselves away
	if(iscultist(user) || is_servant_of_ratvar(user) || IS_HERETIC(user))
		power_multiplier *= 2

	//Try to check if the speaker specified a name or a job to focus on
	var/list/specific_listeners = list()
	var/found_string = null

	//Get the proper job titles
	message = lowertext(message)
	message = get_full_job_name(message)

	for(var/V in listeners)
		var/mob/living/L = V
		var/datum/antagonist/devil/devilinfo = is_devil(L)
		if(devilinfo && findtext(message, devilinfo.truename))
			var/start = findtext(message, devilinfo.truename)
			listeners = list(L) //Devil names are unique.
			power_multiplier *= 5 //if you're a devil and god himself addressed you, you fucked up
			//Cut out the name so it doesn't trigger commands
			message = copytext(message, 1, start) + copytext(message, start + length(devilinfo.truename))
			break
		else if(findtext(message, L.real_name, 1, length(L.real_name) + 1))
			specific_listeners += L //focus on those with the specified name
			//Cut out the name so it doesn't trigger commands
			found_string = L.real_name

		else if(findtext(message, L.first_name(), 1, length(L.first_name()) + 1))
			specific_listeners += L //focus on those with the specified name
			//Cut out the name so it doesn't trigger commands
			found_string = L.first_name()

		else if(L.mind && L.mind.assigned_role && findtext(message, L.mind.assigned_role, 1, length(L.mind.assigned_role) + 1))
			specific_listeners += L //focus on those with the specified job
			//Cut out the job so it doesn't trigger commands
			found_string = L.mind.assigned_role

	if(specific_listeners.len)
		listeners = specific_listeners
		power_multiplier *= (1 + (1/specific_listeners.len)) //2x on a single guy, 1.5x on two and so on
		message = copytext(message, length(found_string) + 1)

	var/static/regex/narsian_words = regex("praise narsie|praise nar-sie|praise nar'sie") //why is it spelled so many ways can you KEEP IT CONSISTENT PLEASE
	var/static/regex/ratvarian_words = regex("hail ratvar|honor ratvar|honour ratvar|purge all untruths") //bri'ish spelling
	var/static/regex/knockdown_words = regex("drop|fall|trip|knockdown|kneel|lie|get down")
	var/static/regex/vomit_words = regex("vomit|throw up|sick")
	var/static/regex/silence_words = regex("shut up|silence|be silent|ssh|quiet|hush")
	var/static/regex/hallucinate_words = regex("see the truth|hallucinate|the truth is out there")
	var/static/regex/wakeup_words = regex("wake up|awaken")
	var/static/regex/heal_words = regex("live|heal|survive|mend|life|heroes never die|rest")
	var/static/regex/hurt_words = regex("die|suffer|hurt|pain|death|kill|judgement|thy end is now|crush") // THY END IS NOW
	var/static/regex/bleed_words = regex("bleed|blood")
	var/static/regex/burn_words = regex("burn|ignite|fire|flame")
	var/static/regex/hot_words = regex("heat|hot|hell")
	var/static/regex/cold_words = regex("cold|cool|chill|freeze|ice|winter") // WHAT'S COOLER THAN BEING COOL
	var/static/regex/repulse_words = regex("shoo|go away|leave me alone|begone|flee|fus ro dah|get away|repulse")
	var/static/regex/attract_words = regex("come here|come to me|get over here|attract")
	var/static/regex/whoareyou_words = regex("who are you|say your name|state your name|identify|who goes there")
	var/static/regex/saymyname_words = regex("say my name|who am i|whoami")
	var/static/regex/knockknock_words = regex("knock knock")
	var/static/regex/move_words = regex("move|walk")
	var/static/regex/left_words = regex("left|west|port")
	var/static/regex/right_words = regex("right|east|starboard")
	var/static/regex/up_words = regex("up|north|fore")
	var/static/regex/down_words = regex("down|south|aft")
	var/static/regex/walk_words = regex("slow down")
	var/static/regex/run_words = regex("run")
	var/static/regex/helpintent_words = regex("help|hug")
	var/static/regex/disarmintent_words = regex("disarm")
	var/static/regex/grabintent_words = regex("grab")
	var/static/regex/harmintent_words = regex("harm|fight|punch")
	var/static/regex/throwmode_words = regex("throw|catch")
	var/static/regex/flip_words = regex("flip|rotate|revolve|roll|somersault")
	var/static/regex/speak_words = regex("speak|say something")
	var/static/regex/getup_words = regex("get up")
	var/static/regex/sit_words = regex("sit")
	var/static/regex/stand_words = regex("stand")
	var/static/regex/dance_words = regex("dance")
	var/static/regex/jump_words = regex("jump")
	var/static/regex/salute_words = regex("salute")
	var/static/regex/deathgasp_words = regex("play dead")
	var/static/regex/clap_words = regex("clap|applaud")
	var/static/regex/honk_words = regex("ho+nk") //hooooooonk
	var/static/regex/multispin_words = regex("like a record baby|right round|spin")

	var/i = 0

	//PRAISE NAR-SIE
	if(findtext(message, narsian_words) && iscultist(user))
		cooldown = COOLDOWN_DAMAGE
		for(var/V in listeners)
			var/mob/living/L = V
			if(iscultist(L))
				L.heal_overall_damage(10 * power_multiplier, 10 * power_multiplier)
			if(is_servant_of_ratvar(L) && ishuman(L))
				var/mob/living/carbon/human/H = L
				var/obj/item/bodypart/BP = pick(H.bodyparts)
				BP.generic_bleedstacks += 5 * power_multiplier

	//HAIL RATVAR
	else if(findtext(message, narsian_words) && is_servant_of_ratvar(user))
		cooldown = COOLDOWN_DAMAGE
		for(var/V in listeners)
			var/mob/living/L = V
			if(is_servant_of_ratvar(L))
				L.heal_overall_damage(10 * power_multiplier, 10 * power_multiplier)
			if(iscultist(L))
				L.adjust_fire_stacks(1 * power_multiplier)
				L.ignite_mob()

	//KNOCKDOWN
	else if(findtext(message, knockdown_words))
		cooldown = COOLDOWN_STUN
		for(var/V in listeners)
			var/mob/living/L = V
			L.set_resting(TRUE)

	//VOMIT
	else if((findtext(message, vomit_words)))
		cooldown = COOLDOWN_STUN
		for(var/mob/living/carbon/C in listeners)
			C.vomit(10 * power_multiplier, distance = power_multiplier, stun = FALSE)

	//SILENCE
	else if((findtext(message, silence_words)))
		cooldown = COOLDOWN_STUN
		if(user.mind && (user.mind.assigned_role == "Curator" || user.mind.assigned_role == "Mime"))
			power_multiplier *= 3
		for(var/mob/living/carbon/C in listeners)
			C.silent += (10 * power_multiplier)

	//HALLUCINATE
	else if((findtext(message, hallucinate_words)))
		cooldown = COOLDOWN_MEME
		for(var/mob/living/carbon/C in listeners)
			new /datum/hallucination/delusion(C, TRUE, null,150 * power_multiplier,0)

	//WAKE UP
	else if((findtext(message, wakeup_words)))
		cooldown = COOLDOWN_DAMAGE
		for(var/V in listeners)
			var/mob/living/L = V
			L.SetSleeping(0)

	//HEAL
	else if((findtext(message, heal_words)))
		cooldown = COOLDOWN_DAMAGE
		for(var/V in listeners)
			var/mob/living/L = V
			L.heal_overall_damage(10 * power_multiplier, 10 * power_multiplier)

	//BRUTE DAMAGE
	else if((findtext(message, hurt_words)))
		cooldown = COOLDOWN_DAMAGE
		for(var/V in listeners)
			var/mob/living/L = V
			var/damage_applied = 15 * power_multiplier
			if(ismegafauna(L) || istype(L, /mob/living/simple_animal/hostile/asteroid))
				damage_applied *= 24
			else if(L.mind?.has_martialart(MARTIALART_ULTRAVIOLENCE))
				damage_applied *= 2 // DIE!
			L.apply_damage(damage_applied, def_zone = BODY_ZONE_CHEST, wound_bonus=CANT_WOUND)

	//BLEED
	else if((findtext(message, bleed_words)))
		cooldown = COOLDOWN_DAMAGE
		for(var/mob/living/carbon/human/H in listeners)
			var/obj/item/bodypart/BP = pick(H.bodyparts)
			BP.generic_bleedstacks += 5 * power_multiplier

	//FIRE
	else if((findtext(message, burn_words)))
		cooldown = COOLDOWN_DAMAGE
		for(var/V in listeners)
			var/mob/living/L = V
			L.adjust_fire_stacks(1 * power_multiplier)
			L.ignite_mob()

	//HOT
	else if((findtext(message, hot_words)))
		cooldown = COOLDOWN_DAMAGE
		for(var/V in listeners)
			var/mob/living/L = V
			L.adjust_bodytemperature(50 * power_multiplier)

	//COLD
	else if((findtext(message, cold_words)))
		cooldown = COOLDOWN_DAMAGE
		for(var/V in listeners)
			var/mob/living/L = V
			L.adjust_bodytemperature(-50 * power_multiplier)

	//REPULSE
	else if((findtext(message, repulse_words)))
		cooldown = COOLDOWN_DAMAGE
		for(var/V in listeners)
			var/mob/living/L = V
			var/throwtarget = get_edge_target_turf(user, get_dir(user, get_step_away(L, user)))
			L.throw_at(throwtarget, 3 * power_multiplier, 1 * power_multiplier)

	//ATTRACT
	else if((findtext(message, attract_words)))
		cooldown = COOLDOWN_DAMAGE
		for(var/V in listeners)
			var/mob/living/L = V
			L.throw_at(get_step_towards(user,L), 3 * power_multiplier, 1 * power_multiplier)

	//WHO ARE YOU?
	else if((findtext(message, whoareyou_words)))
		cooldown = COOLDOWN_MEME
		for(var/V in listeners)
			var/mob/living/L = V
			var/text = ""
			if(is_devil(L))
				var/datum/antagonist/devil/devilinfo = is_devil(L)
				text = devilinfo.truename
			else
				text = L.real_name
			addtimer(CALLBACK(L, /atom/movable/proc/say, text), 5 * i)
			i++

	//SAY MY NAME
	else if((findtext(message, saymyname_words)))
		cooldown = COOLDOWN_MEME
		for(var/V in listeners)
			var/mob/living/L = V
			addtimer(CALLBACK(L, /atom/movable/proc/say, user.name), 5 * i)
			i++

	//KNOCK KNOCK
	else if((findtext(message, knockknock_words)))
		cooldown = COOLDOWN_MEME
		for(var/V in listeners)
			var/mob/living/L = V
			addtimer(CALLBACK(L, /atom/movable/proc/say, "Who's there?"), 5 * i)
			i++

	//MOVE
	else if((findtext(message, move_words)))
		cooldown = COOLDOWN_MEME
		var/direction
		if(findtext(message, up_words))
			direction = NORTH
		else if(findtext(message, down_words))
			direction = SOUTH
		else if(findtext(message, left_words))
			direction = WEST
		else if(findtext(message, right_words))
			direction = EAST
		for(var/iter in 1 to 5 * power_multiplier)
			for(var/V in listeners)
				var/mob/living/L = V
				addtimer(CALLBACK(GLOBAL_PROC, PROC_REF(_step), L, direction? direction : pick(GLOB.cardinals)), 10 * (iter - 1))

	//WALK
	else if((findtext(message, walk_words)))
		cooldown = COOLDOWN_MEME
		for(var/V in listeners)
			var/mob/living/L = V
			if(L.m_intent != MOVE_INTENT_WALK)
				L.toggle_move_intent()

	//RUN
	else if((findtext(message, run_words)))
		cooldown = COOLDOWN_MEME
		for(var/V in listeners)
			var/mob/living/L = V
			if(L.m_intent != MOVE_INTENT_RUN)
				L.toggle_move_intent()

	//HELP INTENT
	else if((findtext(message, helpintent_words)))
		cooldown = COOLDOWN_MEME
		for(var/mob/living/carbon/human/H in listeners)
			addtimer(CALLBACK(H, /mob/verb/a_intent_change, INTENT_HELP), i * 2)
			addtimer(CALLBACK(H, /mob/proc/click_random_mob), i * 2)
			i++

	//DISARM INTENT
	else if((findtext(message, disarmintent_words)))
		cooldown = COOLDOWN_MEME
		for(var/mob/living/carbon/human/H in listeners)
			addtimer(CALLBACK(H, /mob/verb/a_intent_change, INTENT_DISARM), i * 2)
			addtimer(CALLBACK(H, /mob/proc/click_random_mob), i * 2)
			i++

	//GRAB INTENT
	else if((findtext(message, grabintent_words)))
		cooldown = COOLDOWN_MEME
		for(var/mob/living/carbon/human/H in listeners)
			addtimer(CALLBACK(H, /mob/verb/a_intent_change, INTENT_GRAB), i * 2)
			addtimer(CALLBACK(H, /mob/proc/click_random_mob), i * 2)
			i++

	//HARM INTENT
	else if((findtext(message, harmintent_words)))
		cooldown = COOLDOWN_MEME
		for(var/mob/living/carbon/human/H in listeners)
			addtimer(CALLBACK(H, /mob/verb/a_intent_change, INTENT_HARM), i * 2)
			addtimer(CALLBACK(H, /mob/proc/click_random_mob), i * 2)
			i++

	//THROW/CATCH
	else if((findtext(message, throwmode_words)))
		cooldown = COOLDOWN_MEME
		for(var/mob/living/carbon/C in listeners)
			C.throw_mode_on()

	//FLIP
	else if((findtext(message, flip_words)))
		cooldown = COOLDOWN_MEME
		for(var/V in listeners)
			var/mob/living/L = V
			L.emote("flip")

	//SPEAK
	else if((findtext(message, speak_words)))
		cooldown = COOLDOWN_MEME
		for(var/V in listeners)
			var/mob/living/L = V
			addtimer(CALLBACK(L, /atom/movable/proc/say, pick_list_replacements(BRAIN_DAMAGE_FILE, "brain_damage")), 5 * i)
			i++

	//GET UP
	else if((findtext(message, getup_words)))
		cooldown = COOLDOWN_DAMAGE //because stun removal
		for(var/V in listeners)
			var/mob/living/L = V
			L.set_resting(FALSE)
			L.SetAllImmobility(0)

	//SIT
	else if((findtext(message, sit_words)))
		cooldown = COOLDOWN_MEME
		for(var/V in listeners)
			var/mob/living/L = V
			for(var/obj/structure/chair/chair in get_turf(L))
				chair.buckle_mob(L)
				break

	//STAND UP
	else if((findtext(message, stand_words)))
		cooldown = COOLDOWN_MEME
		for(var/V in listeners)
			var/mob/living/L = V
			if(L.buckled && istype(L.buckled, /obj/structure/chair))
				L.buckled.unbuckle_mob(L)

	//DANCE
	else if((findtext(message, dance_words)))
		cooldown = COOLDOWN_MEME
		for(var/V in listeners)
			var/mob/living/L = V
			addtimer(CALLBACK(L, TYPE_PROC_REF(/mob/living, emote), "dance"), 5 * i)
			i++

	//JUMP
	else if((findtext(message, jump_words)))
		cooldown = COOLDOWN_MEME
		for(var/V in listeners)
			var/mob/living/L = V
			if(prob(25))
				addtimer(CALLBACK(L, /atom/movable/proc/say, "HOW HIGH?!!"), 5 * i)
			addtimer(CALLBACK(L, TYPE_PROC_REF(/mob/living, emote), "jump"), 5 * i)
			i++

	//SALUTE
	else if((findtext(message, salute_words)))
		cooldown = COOLDOWN_MEME
		for(var/V in listeners)
			var/mob/living/L = V
			addtimer(CALLBACK(L, TYPE_PROC_REF(/mob/living, emote), "salute"), 5 * i)
			i++

	//PLAY DEAD
	else if((findtext(message, deathgasp_words)))
		cooldown = COOLDOWN_MEME
		for(var/V in listeners)
			var/mob/living/L = V
			addtimer(CALLBACK(L, TYPE_PROC_REF(/mob/living, emote), "deathgasp"), 5 * i)
			i++

	//PLEASE CLAP
	else if((findtext(message, clap_words)))
		cooldown = COOLDOWN_MEME
		for(var/V in listeners)
			var/mob/living/L = V
			addtimer(CALLBACK(L, TYPE_PROC_REF(/mob/living, emote), "clap"), 5 * i)
			i++

	//HONK
	else if((findtext(message, honk_words)))
		cooldown = COOLDOWN_MEME
		addtimer(CALLBACK(GLOBAL_PROC, PROC_REF(playsound), get_turf(user), 'sound/items/bikehorn.ogg', 300, 1), 25)
		if(user.mind && user.mind.assigned_role == "Clown")
			for(var/mob/living/carbon/C in listeners)
				C.slip(140 * power_multiplier)
			cooldown = COOLDOWN_MEME

	//RIGHT ROUND
	else if((findtext(message, multispin_words)))
		cooldown = COOLDOWN_MEME
		for(var/V in listeners)
			var/mob/living/L = V
			L.SpinAnimation(speed = 10, loops = 5)

	else
		cooldown = COOLDOWN_NONE

	if(message_admins)
		message_admins("[ADMIN_LOOKUPFLW(user)] has said '[log_message]' with a Voice of God, affecting [english_list(listeners)], with a power multiplier of [power_multiplier].")
	log_game("[key_name(user)] has said '[log_message]' with a Voice of God, affecting [english_list(listeners)], with a power multiplier of [power_multiplier].")
	SSblackbox.record_feedback("tally", "voice_of_god", 1, log_message)

	return cooldown


#undef COOLDOWN_STUN
#undef COOLDOWN_DAMAGE
#undef COOLDOWN_MEME
#undef COOLDOWN_NONE
