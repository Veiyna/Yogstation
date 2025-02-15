GLOBAL_LIST_INIT(abductor_gear, subtypesof(/datum/abductor_gear))

/datum/abductor_gear
	/// Name of the gear
	var/name = "Generic Abductor Gear"
	/// Description of the gear
	var/description = "Generic description."
	/// Unique ID of the gear
	var/id = "abductor_generic"
	/// Credit cost of the gear
	var/cost = 1
	/// Build path of the gear itself
	var/build_path = null
	/// Category of the gear
	var/category = "Basic Gear"

/datum/abductor_gear/agent_helmet
	name = "Agent Helmet"
	description = "Abduct with style - spiky style. Prevents digital tracking."
	id = "agent_helmet"
	build_path = /obj/item/clothing/head/helmet/abductor

/datum/abductor_gear/agent_vest
	name = "Agent Vest"
	description = "A vest outfitted with advanced stealth technology. It has two modes - combat and stealth."
	id = "agent_vest"
	build_path = /obj/item/clothing/suit/armor/abductor/vest

/datum/abductor_gear/baton
	name = "Advanced Baton"
	description = "A advanced baton with four modes allowing it to stun, sleep, cuff, and probe victims."
	id = "baton"
	cost = 2
	build_path = /obj/item/abductor/baton

/datum/abductor_gear/posters
	name = "Decorative Poster"
	description = "A poster, to decorate the walls of the Mothership (or even the station) with."
	id = "poster"
	build_path = /obj/item/poster/random_abductor

/datum/abductor_gear/radio_silencer
	name = "Radio Silencer"
	description = "A compact device used to shut down communications equipment."
	id = "radio_silencer"
	build_path = /obj/item/abductor/silencer

/datum/abductor_gear/science_tool
	name = "Science Tool"
	description = "A dual-mode tool for retrieving specimens and scanning appearances. Scanning can be done through cameras."
	id = "science_tool"
	build_path = /obj/item/abductor/gizmo

/datum/abductor_gear/superlingual_matrix
	name = "Superlingual Matrix"
	description = "A mysterious structure that allows for instant communication between users. Pretty impressive until you need to eat something."
	id = "superlingual_matrix"
	build_path = /obj/item/organ/tongue/abductor
	category = "Advanced Gear"

/datum/abductor_gear/mental_interface
	name = "Mental Interface Device"
	description = "A dual-mode tool for directly communicating with sentient brains. It can be used to send a direct message to a target, \
				or to send a command to a test subject with a charged gland."
	id = "mental_interface"
	cost = 2
	build_path = /obj/item/abductor/mind_device
	category = "Advanced Gear"

/datum/abductor_gear/reagent_synthesizer
	name = "Reagent Synthesizer"
	description = "Synthesizes a variety of reagents using proto-matter."
	id = "reagent_synthesizer"
	cost = 2
	build_path = /obj/item/abductor_machine_beacon/chem_dispenser
	category = "Advanced Gear"