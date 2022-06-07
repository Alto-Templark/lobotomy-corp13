/datum/abnormality
	var/name = "Abnormality"
	var/desc = "An abnormality of unknown type."
	/// The threat level of the abnormality
	var/threat_level = ZAYIN_LEVEL
	/// Current state of the qliphoth
	var/qliphoth_meter = 0
	/// Maximum level of qliphoth. If 0 or below - it has no effects
	var/qliphoth_meter_max = 0
	/// Path of the mob it contains
	var/mob/living/simple_animal/hostile/abnormality/abno_path
	/// Reference to current mob, if alive
	var/mob/living/simple_animal/hostile/abnormality/current
	/// Reference to respawn landmark
	var/obj/effect/landmark/abnormality_spawn/landmark

	/// Available work types with their success chances and performing time. Used in console
	var/list/available_work = list(
							ABNORMALITY_WORK_INSTINCT = 50,
							ABNORMALITY_WORK_INSIGHT = 40,
							ABNORMALITY_WORK_ATTACHMENT = 30,
							ABNORMALITY_WORK_REPRESSION = 20
							)
	/// How much PE it produces. Also responsible for work time
	var/max_boxes = 0
	/// How much PE you have to produce for success.
	var/success_boxes = 0

/datum/abnormality/New(obj/effect/landmark/abnormality_spawn/new_landmark, mob/living/simple_animal/hostile/abnormality/new_type = null)
	if(!istype(new_landmark))
		CRASH("Abnormality datum was created without reference to landmark.")
	if(!ispath(new_type))
		CRASH("Abnormality datum was created without a path to the mob.")
	landmark = new_landmark
	abno_path = new_type
	name = initial(abno_path.name)
	desc = initial(abno_path.desc)
	RespawnAbno()

/datum/abnormality/proc/RespawnAbno()
	if(!ispath(abno_path))
		CRASH("Abnormality tried to respawn a mob, but had no path.")
	if(!istype(landmark))
		CRASH("Couldn't respawn an abnormality [initial(abno_path.name)] due to missing landmark.")
	if(istype(current))
		return
	var/turf/T = get_turf(landmark)
	current = new abno_path(T)
	current.datum_reference = src
	current.toggle_ai(AI_OFF)
	current.status_flags |= GODMODE
	threat_level = current.threat_level
	qliphoth_meter_max = current.start_qliphoth
	qliphoth_meter = qliphoth_meter_max
	max_boxes = threat_level * 6
	success_boxes = round(max_boxes * 0.75)
	available_work = current.work_chances

/datum/abnormality/proc/work_complete(mob/living/carbon/human/user, work_type, pe)
	var/attribute_type = WORK_TO_ATTRIBUTE[work_type]
	var/maximum_attribute_level = min(120, threat_level * 24)
	var/attribute_given = round(2 + clamp((maximum_attribute_level / get_attribute_level(user, attribute_type)), 0, 4))
	adjust_attribute_level(user, attribute_type, attribute_given)
	current.work_complete(user, work_type, pe, success_boxes) // Cross-referencing gone wrong
	SSlobotomy_corp.AdjustBoxes(pe)

/datum/abnormality/proc/qliphoth_change(amount, user)
	qliphoth_meter = clamp(qliphoth_meter + amount, 0, qliphoth_meter_max)
	if((qliphoth_meter_max > 0) && (qliphoth_meter <= 0))
		current?.zero_qliphoth(user)