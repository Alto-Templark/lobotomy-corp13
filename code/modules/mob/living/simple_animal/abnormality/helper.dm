/mob/living/simple_animal/hostile/abnormality/helper
	name = "all around helper"
	desc = "A tiny robot with helpful intentions."
	icon = 'ModularTegustation/Teguicons/tegumobs.dmi'
	icon_state = "helper"
	icon_living = "helper"
	maxHealth = 600
	health = 600
	see_in_dark = 10
	rapid_melee = 2
	ranged = TRUE
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	faction = list("hostile")
	attack_sound = 'sound/abnormalities/helper/attack.ogg'
	stat_attack = HARD_CRIT
	melee_damage_lower = 20
	melee_damage_upper = 25
	obj_damage = 250
	speak_emote = list("states")
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	vision_range = 8
	aggro_vision_range = 12
	attack_action_types = list(/datum/action/innate/abnormality_attack/helper_dash)

	can_breach = TRUE
	threat_level = HE_LEVEL
	start_qliphoth = 3
	work_chances = list(
						ABNORMALITY_WORK_INSTINCT = 20,
						ABNORMALITY_WORK_INSIGHT = 30,
						ABNORMALITY_WORK_ATTACHMENT = 40,
						ABNORMALITY_WORK_REPRESSION = 20
						)

	var/charging = FALSE
	var/dash_num = 50
	var/dash_cooldown = 0
	var/dash_cooldown_time = 15 SECONDS
	var/list/been_hit = list() // Don't get hit twice.

/datum/action/innate/abnormality_attack/helper_dash
	name = "Helper Dash"
	icon_icon = 'ModularTegustation/Teguicons/tegumobs.dmi'
	button_icon_state = "helper"
	chosen_message = "<span class='colossus'>You will now dash in that direction.</span>"
	chosen_attack_num = 1

/mob/living/simple_animal/hostile/abnormality/helper/AttackingTarget()
	if(charging)
		return
	return ..()

/mob/living/simple_animal/hostile/abnormality/helper/Move()
	if(charging)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/abnormality/helper/OpenFire()
	if(client)
		switch(chosen_attack)
			if(1)
				helper_dash(target)
		return

	if(dash_cooldown <= world.time)
		helper_dash(target)

/mob/living/simple_animal/hostile/abnormality/helper/update_icon_state()
	if(AIStatus != AI_OFF)
		icon = 'ModularTegustation/Teguicons/64x64.dmi'
		pixel_x = -16
		base_pixel_x = -16
		pixel_y = -16
		base_pixel_y = -16
	else
		icon = initial(icon)
		pixel_x = initial(pixel_x)
		base_pixel_x = initial(base_pixel_x)
		pixel_y = initial(pixel_y)
		base_pixel_y = initial(base_pixel_y)

/mob/living/simple_animal/hostile/abnormality/helper/proc/helper_dash(target)
	if(charging || dash_cooldown > world.time)
		return
	update_icon()
	dash_cooldown = world.time + dash_cooldown_time
	charging = TRUE
	var/dir_to_target = get_dir(get_turf(src), get_turf(target))
	addtimer(CALLBACK(src, .proc/do_dash, dir_to_target, 0), 1.5 SECONDS)
	var/para = TRUE
	if(dir in list(WEST, NORTHWEST, SOUTHWEST))
		para = FALSE
	been_hit = list()
	SpinAnimation(1.5 SECONDS, 1, para)
	playsound(src, 'sound/abnormalities/helper/rise.ogg', 100, 1)

/mob/living/simple_animal/hostile/abnormality/helper/proc/do_dash(move_dir, times_ran)
	var/stop_charge = FALSE
	if(times_ran >= dash_num)
		stop_charge = TRUE
	var/turf/T = get_step(get_turf(src), move_dir)
	if(ismineralturf(T))
		var/turf/closed/mineral/M = T
		M.gets_drilled()
	if(T.density)
		stop_charge = TRUE
	for(var/obj/structure/window/W in T.contents)
		W.obj_destruction("spinning blades")
	for(var/obj/machinery/door/D in T.contents)
		if(D.density)
			D.open(2)
	if(stop_charge)
		playsound(src, 'sound/abnormalities/helper/disable.ogg', 100, 1)
		SLEEP_CHECK_DEATH(5 SECONDS)
		charging = FALSE
		return
	forceMove(T)
	var/para = TRUE
	if(dir in list(WEST, NORTHWEST, SOUTHWEST))
		para = FALSE
	SpinAnimation(2, 1, para)
	playsound(src,"sound/abnormalities/helper/move0[pick(1,2,3)].ogg", rand(80, 120), 1)
	for(var/mob/living/L in range(1, T))
		if(!faction_check_mob(L))
			if(L in been_hit)
				continue
			visible_message("<span class='boldwarning'>[src] runs through [L]!</span>")
			to_chat(L, "<span class='userdanger'>[src] pierces you with their spinning blades!</span>")
			playsound(L, attack_sound, 75, 1)
			var/turf/LT = get_turf(L)
			new /obj/effect/temp_visual/kinetic_blast(LT)
			if(ishuman(L))
				var/mob/living/carbon/human/H = L
				// Ugly code
				var/affecting = get_bodypart(ran_zone(pick(BODY_ZONE_CHEST, BODY_ZONE_PRECISE_L_HAND, BODY_ZONE_PRECISE_R_HAND, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)))
				var/armor = H.run_armor_check(affecting, MELEE, armour_penetration = src.armour_penetration)
				H.apply_damage(60, src.melee_damage_type, affecting, armor, wound_bonus = src.wound_bonus, bare_wound_bonus = src.bare_wound_bonus, sharpness = src.sharpness)
			else
				L.adjustBruteLoss(60)
			if(L.stat >= HARD_CRIT)
				L.gib()
				continue
			if(!(L in been_hit))
				been_hit += L
	addtimer(CALLBACK(src, .proc/do_dash, move_dir, (times_ran + 1)), 1)

/* Work effects */
/mob/living/simple_animal/hostile/abnormality/helper/success_effect(mob/living/carbon/human/user, work_type, pe)
	datum_reference.qliphoth_change(1)
	return

/mob/living/simple_animal/hostile/abnormality/helper/failure_effect(mob/living/carbon/human/user, work_type, pe)
	datum_reference.qliphoth_change(-1)
	return

/mob/living/simple_animal/hostile/abnormality/helper/breach_effect(mob/living/carbon/human/user)
	..()
	update_icon()
	GiveTarget(user)