var/being_slowed_by_light = FALSE	//used in light brightness code.

/mob/living/silicon/pai/proc/fold_out(force = FALSE)
	if(emitterhealth < 0)
		src << "<span class='warning'>Your holochassis emitters are still too unstable! Please wait for automatic repair.</span>"
		return FALSE

	if(!canholo && !force)
		src << "<span class='warning'>Your master or another force has disabled your holochassis emitters!</span>"
		return FALSE

	if(holoform)
		. = fold_in(force)
		return

	if(emittersemicd)
		src << "<span class='warning'>Error: Holochassis emitters recycling. Please try again later.</span>"
		return FALSE

	emittersemicd = TRUE
	addtimer(src, "emittercool", emittercd)
	canmove = TRUE
	density = TRUE
	if(istype(card.loc, /obj/item/device/pda))
		var/obj/item/device/pda/P = card.loc
		P.pai = null
		P.visible_message("<span class='notice'>[src] ejects itself from [P]!</span>")
	if(istype(card.loc, /mob/living))
		var/mob/living/L = card.loc
		if(!L.unEquip(card))
			src << "<span class='warning'>Error: Unable to expand to mobile form. Chassis is restrained by some device or person.</span>"
			return FALSE
	var/turf/T = get_turf(card)
	forceMove(T)
	card.forceMove(src)
	if(client)
		client.perspective = EYE_PERSPECTIVE
		client.eye = src
	SetLuminosity(0)
	icon_state = "[chassis]"
	visible_message("<span class='boldnotice'>[src] folds out its holochassis emitter and forms a holoshell around itself!</span>")
	holoform = TRUE

/mob/living/silicon/pai/proc/emittercool()
	emittersemicd = FALSE

/mob/living/silicon/pai/proc/fold_in(force = FALSE)
	emittersemicd = TRUE
	if(!force)
		addtimer(src, "emittercool", emittercd)
	else
		addtimer(src, "emittercool", emitteroverloadcd)
	icon_state = "[chassis]"
	if(!holoform)
		. = fold_out(force)
		return
	visible_message("<span class='notice'>[src] deactivates its holochassis emitter and folds back into a compact card!</span>")
	stop_pulling()
	if(client)
		client.perspective = EYE_PERSPECTIVE
		client.eye = card
	var/turf/T = get_turf(src)
	card.forceMove(T)
	forceMove(card)
	canmove = FALSE
	density = FALSE
	SetLuminosity(0)
	holoform = FALSE
	if(resting)
		lay_down()

/mob/living/silicon/pai/proc/choose_chassis()
	var/choice = input(src, "What would you like to use for your holochassis composite?") as null|anything in possible_chassis
	if(!choice)
		return 0
	chassis = choice
	icon_state = "[chassis]"
	if(resting)
		icon_state = "[chassis]_rest"
	src << "<span class='boldnotice'>You switch your holochassis projection composite to [chassis]</span>"

/mob/living/silicon/pai/lay_down()
	..()
	update_resting_icon(resting)

/mob/living/silicon/pai/proc/update_resting_icon(rest)
	if(rest)
		icon_state = "[chassis]_rest"
	else
		icon_state = "[chassis]"
	if(loc != card)
		visible_message("<span class='notice'>[src] [rest? "lays down for a moment..." : "perks up from the ground"]</span>")

/mob/living/silicon/pai/proc/toggle_integrated_light()
	if(!luminosity)
		SetLuminosity(light_power)	//low beam
		src << "<span class='notice'>You enable your integrated light.</span>"
	else if(luminosity == light_power)	//higher beam, at the cost of speed
		if(slowdown < 2)
			slowdown += 1
			being_slowed_by_light = TRUE
		SetLuminosity(light_power*2)
		src << "<span class='notice'>You increase the brightness of your integrated light.</span>"
	else if (luminosity == light_power*2)
		if(being_slowed_by_light)
			slowdown -= 1
			being_slowed_by_light = FALSE
		SetLuminosity(0)
		src << "<span class='notice'>You disable your integrated light.</span>"
	else					//something went VERY FUCKIN' WRONG, YO.
		src << "<span class='warning'>Your internal light seems to be malfunctioning...</span>"
