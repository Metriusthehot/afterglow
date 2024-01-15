/obj/machinery/rnd/science_lab
	name = "science lab"
	desc = "Used to increase research points."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "HPLCempty"
	circuit = /obj/item/circuitboard/machine/science_lab
	var/engaged_in_science = FALSE
	var/list/blueprint_types = list("small guns", "big guns")
	var/list/point_selections = list(2000, 6000, 12000, 24000, 48000)
	var/list/obj/small_guns = list(/obj/item/book/granter/crafting_recipe/blueprint/thatgun, /obj/item/book/granter/crafting_recipe/blueprint/smg10mm,
								/obj/item/book/granter/crafting_recipe/blueprint/uzi,/obj/item/book/granter/crafting_recipe/blueprint/greasegun,
								/obj/item/book/granter/crafting_recipe/blueprint/pps,
								/obj/item/book/granter/crafting_recipe/blueprint/deagle, /obj/item/book/granter/crafting_recipe/blueprint/n99)
	var/list/obj/big_guns = list(/obj/item/book/granter/crafting_recipe/blueprint/combatrifle, /obj/item/book/granter/crafting_recipe/blueprint/r84,
								/obj/item/book/granter/crafting_recipe/blueprint/brushgun, /obj/item/book/granter/crafting_recipe/blueprint/r91,
								/obj/item/book/granter/crafting_recipe/blueprint/riotshotgun, /obj/item/book/granter/crafting_recipe/blueprint/m1garand,
								/obj/item/book/granter/crafting_recipe/blueprint/marksman, /obj/item/book/granter/crafting_recipe/blueprint/m1carbine,
								/obj/item/book/granter/crafting_recipe/blueprint/service, /obj/item/book/granter/crafting_recipe/blueprint/leveraction,
								/obj/item/book/granter/crafting_recipe/blueprint/lsw, /obj/item/book/granter/crafting_recipe/blueprint/sniper)
	var/list/obj/small_energy = list(/obj/item/book/granter/crafting_recipe/blueprint/aep7, /obj/item/book/granter/crafting_recipe/blueprint/plasmapistol,
									/obj/item/book/granter/crafting_recipe/blueprint/plasmapistol, /obj/item/book/granter/crafting_recipe/blueprint/tesla)
	var/list/obj/big_energy = list(/obj/item/book/granter/crafting_recipe/blueprint/tribeam, /obj/item/book/granter/crafting_recipe/blueprint/bozar,
								/obj/item/book/granter/crafting_recipe/blueprint/plasmarifle, /obj/item/book/granter/crafting_recipe/blueprint/aer9,
								/obj/item/book/granter/crafting_recipe/blueprint/gauss, /obj/item/book/granter/crafting_recipe/blueprint/am_rifle)
	var/attempts = 0

/obj/machinery/rnd/science_lab/Initialize()
	. = ..()
	update_overlays()

/obj/machinery/rnd/science_lab/proc/successful_experiment(science_awarded = 1)
	linked_console.stored_research.research_points[TECHWEB_POINT_TYPE_GENERIC] = linked_console.stored_research.research_points[TECHWEB_POINT_TYPE_GENERIC] + science_awarded
	say("Experiment completed.")

/obj/machinery/rnd/science_lab/proc/warn_admins(user, ReactionName)
	var/turf/T = get_turf(user)
	message_admins("Experimentor reaction: [ReactionName] generated by [ADMIN_LOOKUPFLW(user)] at [ADMIN_VERBOSEJMP(T)]")
	log_game("Experimentor reaction: [ReactionName] generated by [key_name(user)] in [AREACOORD(T)]")

/obj/machinery/rnd/science_lab/ui_interact(mob/user)
	var/list/dat = list("<center>")
	if(!linked_console)
		dat += "<b><a href='byond://?src=[REF(src)];function=search'>Scan for R&D Console</A></b><br>"
	else
		dat += "<div>Available experiments:"
		dat += "<b><a href='byond://?src=[REF(src)];function=simple'>Simple Experiment</A></b>"
		dat += "<b><a href='byond://?src=[REF(src)];function=complex;'>Complex Experiment</A></b>"
		dat += "<b><a href='byond://?src=[REF(src)];function=risky'>Risky Experiment</A></b>"
		dat += "<b><a href='byond://?src=[REF(src)];function=death'>Very Risky Experiment</A></b><br></div>"
		if (linked_console.stored_research.isNodeResearchedID("weaponry"))
			dat += "<div>Available tasks:"
			dat += "<b><a href='byond://?src=[REF(src)];function=create'>Create a weapons blueprint</A></b><br></div>"

	dat += "<a href='byond://?src=[REF(src)];function=refresh'>Refresh</A>"
	dat += "<a href='byond://?src=[REF(src)];close=1'>Close</A></center>"
	var/datum/browser/popup = new(user, "science_lab","Science Lab", 700, 400, src)
	popup.set_content(dat.Join("<br>"))
	popup.open()
	onclose(user, "science_lab")

/obj/machinery/rnd/science_lab/Topic(href, href_list)
	if(..())
		return
	usr.set_machine(src)

	var/scantype = href_list["function"]

	if(href_list["close"])
		usr << browse(null, "window=science_lab")
		return
	if(scantype == "search")
		var/obj/machinery/computer/rdconsole/D = locate(/obj/machinery/computer/rdconsole) in oview(3,src)
		if(D)
			linked_console = D
			updateUsrDialog()
			return
	if(scantype == "create" && !engaged_in_science)
		engaged_in_science = TRUE
		if (!linked_console.stored_research.isNodeResearchedID("weaponry"))
			say("Weaponry research required.")
			engaged_in_science = FALSE
			return
		say("Blueprint creation begun.")
		var/choosen_step = input(usr, "What kind of blueprint do you wish to create?", "Blueprint Creation") in blueprint_types
		var/points_to_contribute =  input(usr, "How many research points do you wish to use as a boost?", "Blueprint Creation") in point_selections
		if (!linked_console.stored_research.can_afford(list(TECHWEB_POINT_TYPE_GENERIC = points_to_contribute)))
			say("Not enough points.")
			engaged_in_science = FALSE
			return
		say("Creation started.")
		update_overlays()
		if (do_after(usr, 10 SECONDS, 1, src, required_mobility_flags = MOBILITY_USE))
			//need to make sure someone hasn't spent all the points while we were working!
			if (!linked_console.stored_research.can_afford(list(TECHWEB_POINT_TYPE_GENERIC = points_to_contribute)))
				say("Not enough points.")
				engaged_in_science = FALSE
				update_overlays()
				return
			var/difficulty_selected = 36 - (points_to_contribute/2000) - attempts
			if (usr.skill_roll_evil(SKILL_SCIENCE, difficulty_selected))
				if (linked_console.stored_research.isNodeResearchedID("adv_weaponry"))
					if (choosen_step == "small guns")
						var/list/combined = small_guns.Copy()
						combined.Add(small_energy)
						var/obj/i = pick(combined)
						new i(get_turf(src))
					if (choosen_step == "big guns")
						var/list/combined = big_guns.Copy()
						combined.Add(big_energy)
						var/obj/i = pick(combined)
						new i(get_turf(src))
				else
					if (choosen_step == "small guns")
						var/obj/i = pick(small_guns)
						new i(get_turf(src))
					if (choosen_step == "big guns")
						var/obj/i = pick(big_guns)
						new i(get_turf(src))
				say("Blueprint confirmed valid.")
				to_chat(usr, span_notice("Eureka!"))
				attempts = 0
			else
				attempts += round((usr.skill_value(SKILL_SCIENCE)/25) + (points_to_contribute/2000))
				say("Blueprint invalid design, try input again.")
				to_chat(usr, span_notice("Almost had it..."))
			linked_console.stored_research.remove_point_list(list(TECHWEB_POINT_TYPE_GENERIC = points_to_contribute))
			engaged_in_science = FALSE
		else
			say("Creation aborted.")
		engaged_in_science = FALSE
	else if(scantype == "refresh")
		updateUsrDialog()
	else if (scantype && !engaged_in_science)
		if (!usr.skill_check(SKILL_SCIENCE, EASY_CHECK))
			to_chat(usr, span_warning("You have no idea how to even start an experiment with this stuff."))
			return
		say("Experiment started.")
		engaged_in_science = TRUE
		if (do_after(usr, 10 SECONDS, 1, src, required_mobility_flags = MOBILITY_USE))
			if (scantype == "simple")
				do_experiment(usr, DIFFICULTY_EASY)
			if (scantype == "complex")
				do_experiment(usr, DIFFICULTY_NORMAL)
			if (scantype == "risky")
				do_experiment(usr, DIFFICULTY_CHALLENGE)
			if (scantype == "death")
				do_experiment(usr, DIFFICULTY_EXPERT)
			engaged_in_science = FALSE
		else
			say("Experiment aborted.")
			engaged_in_science = FALSE
	else if (engaged_in_science)
		say("Please wait for current experiment to end.")
	update_overlays()

/obj/machinery/rnd/science_lab/proc/do_experiment(mob/user, difficulty = DIFFICULTY_EASY)
	var/part_bonus = 3
	log_admin("[user] has done a science experiment: [difficulty], (-20 safe, -10 average danger, 0 risky, 10 REALLY RISKY)")
	for(var/obj/item/stock_parts/M in component_parts)
		part_bonus -= M.rating
	if (user.skill_check(SKILL_SCIENCE, 65 + difficulty, 1) || user.skill_roll(SKILL_SCIENCE, (difficulty + part_bonus)))
		//happy science time :D
		if (difficulty == DIFFICULTY_EASY)
			successful_experiment(1000)
		if (difficulty == DIFFICULTY_NORMAL)
			successful_experiment(4000)
		if (difficulty == DIFFICULTY_CHALLENGE)
			successful_experiment(11000)
		if (difficulty == DIFFICULTY_EXPERT)
			successful_experiment(26000)
	else
		//oh no we failed!
		if (difficulty == DIFFICULTY_EASY)
			throwSmoke(loc)
		if (difficulty == DIFFICULTY_NORMAL)
			if (prob(50))
				throwSmoke(loc)
				throw_around()
			else
				small_bang()
		if (difficulty == DIFFICULTY_CHALLENGE)
			if (prob(50))
				coolant_cloud()
			else
				radiation()
		if (difficulty == DIFFICULTY_EXPERT)
			if (prob(50))
				death_smoke(user)
			else
				death_ball(user)
		say("Experiment failed.")

//2
/obj/machinery/rnd/science_lab/proc/small_bang()
	visible_message(span_danger("[src] malfunctions, releasing a large flame!"))
	explosion(loc, -1, 0, 0, 0, 0, flame_range = 2)

//3
/obj/machinery/rnd/science_lab/proc/coolant_cloud()
	visible_message(span_danger("[src] malfunctions, releasing a dangerous cloud of coolant!"))
	var/datum/reagents/R = new/datum/reagents(50)
	R.my_atom = src
	R.add_reagent(/datum/reagent/consumable/frostoil, 50)
	investigate_log("Experimentor has released frostoil gas.", INVESTIGATE_EXPERIMENTOR)
	var/datum/effect_system/smoke_spread/chem/smoke = new
	smoke.set_up(R, 2, src, silent = TRUE)
	playsound(src, 'sound/effects/smoke.ogg', 50, 1, -3)
	smoke.start()
	qdel(R)

//3
/obj/machinery/rnd/science_lab/proc/radiation()
	visible_message(span_danger("[src] malfunctions, melting a glowing beaker, leaking radiation!"))
	playsound(src, 'sound/effects/clock_tick.ogg', 50, 1, -3)
	radiation_pulse(src, 500)

//1
/obj/machinery/rnd/science_lab/proc/throwSmoke(turf/where)
	var/datum/effect_system/smoke_spread/smoke = new
	playsound(src, 'sound/effects/smoke.ogg', 50, 1, -3)
	smoke.set_up(0, where)
	smoke.start()

//2
/obj/machinery/rnd/science_lab/proc/throw_around()
	visible_message(span_danger("[src] malfunctions, the convective air current released throws everything around in the room!"))
	var/list/throwAt = list()
	for(var/atom/movable/AM in oview(7,src))
		if(!AM.anchored)
			throwAt.Add(AM)
	for(var/counter = 1, counter < throwAt.len, ++counter)
		var/atom/movable/cast = throwAt[counter]
		cast.throw_at(pick(throwAt),10,1)

//4
/obj/machinery/rnd/science_lab/proc/death_smoke(user)
	visible_message(span_danger("[src]'s chemical chamber has sprung a leak!"))
	var/chosenchem
	chosenchem = pick(/datum/reagent/mutationtoxin,/datum/reagent/nanomachines,/datum/reagent/toxin/acid,/datum/reagent/radium,/datum/reagent/toxin,
						/datum/reagent/consumable/condensedcapsaicin,/datum/reagent/drug/mushroomhallucinogen,/datum/reagent/consumable/frostoil,
						/datum/reagent/drug/space_drugs,/datum/reagent/consumable/ethanol,/datum/reagent/consumable/ethanol/beepsky_smash)
	var/datum/reagents/R = new/datum/reagents(50)
	R.my_atom = src
	R.add_reagent(chosenchem , 50)
	var/datum/effect_system/smoke_spread/chem/smoke = new
	smoke.set_up(R, 2, src, silent = TRUE)
	playsound(src, 'sound/effects/smoke.ogg', 50, 1, -3)
	smoke.start()
	qdel(R)
	warn_admins(user, "[chosenchem] smoke")

//4
/obj/machinery/rnd/science_lab/proc/death_ball(mob/user)
	var/turf/start = get_turf(src)
	var/mob/M = locate(/mob/living) in view(src, 3)
	var/turf/MT = get_turf(M)
	explosion(user.loc, -1, 1, 2, 2, 1, flame_range = 2)
	if(MT)
		visible_message(span_danger("[src] dangerously overheats, launching a flaming fuel orb!"))
		var/obj/item/projectile/magic/aoe/fireball/FB = new /obj/item/projectile/magic/aoe/fireball(start)
		FB.preparePixelProjectile(MT, start)
		FB.fire()
		warn_admins(user, "fireball")

/obj/machinery/rnd/science_lab/update_overlays()
	. = ..()
	. += "HPLCbeaker"
	if (!(stat & (NOPOWER|BROKEN)))
		. += "HPLCScreen"
	if (engaged_in_science)
		. += "HPLCgraph"
