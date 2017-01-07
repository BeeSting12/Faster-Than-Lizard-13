/mob/living/silicon/pai
	name = "pAI"
	icon = 'icons/mob/pai.dmi'
	icon_state = "repairbot"
	mouse_opacity = 1
	density = 0
	ventcrawler = 2
	luminosity = 0
	pass_flags = PASSTABLE | PASSMOB
	mob_size = MOB_SIZE_TINY
	desc = "A generic pAI mobile hard-light holographics emitter. It seems to be deactivated."
	var/network = "SS13"
	var/obj/machinery/camera/current = null

	weather_immunities = list("ash")
	health = 500
	maxHealth = 500

	var/ram = 100	// Used as currency to purchase different abilities
	var/list/software = list()
	var/userDNA		// The DNA string of our assigned user
	var/obj/item/device/paicard/card	// The card we inhabit

	var/speakStatement = "states"
	var/speakExclamation = "declares"
	var/speakDoubleExclamation = "alarms"
	var/speakQuery = "queries"

	var/obj/item/weapon/pai_cable/cable		// The cable we produce and use when door or camera jacking

	var/master				// Name of the one who commands us
	var/master_dna			// DNA string for owner verification

	var/silence_time			// Timestamp when we were silenced (normally via EMP burst), set to null after silence has faded

// Various software-specific vars

	var/temp				// General error reporting text contained here will typically be shown once and cleared
	var/screen				// Which screen our main window displays
	var/subscreen			// Which specific function of the main screen is being displayed

	var/obj/item/device/pda/ai/pai/pda = null

	var/secHUD = 0			// Toggles whether the Security HUD is active or not
	var/medHUD = 0			// Toggles whether the Medical  HUD is active or not

	var/datum/data/record/medicalActive1		// Datacore record declarations for record software
	var/datum/data/record/medicalActive2

	var/datum/data/record/securityActive1		// Could probably just combine all these into one
	var/datum/data/record/securityActive2

	var/obj/machinery/door/hackdoor		// The airlock being hacked
	var/hackprogress = 0				// Possible values: 0 - 100, >= 100 means the hack is complete and will be reset upon next check

	var/obj/item/radio/integrated/signal/sradio // AI's signaller
	var/holoform = FALSE
	var/canholo = TRUE
	var/obj/item/weapon/card/id/access_card = null
	var/chassis = "repairbot"
	var/list/possible_chassis = list("cat", "mouse", "monkey", "corgi", "fox", "repairbot", "rabbit")

	var/emitterhealth = 50
	var/emittermaxhealth = 50
	var/emitterregen = 1
	var/emittercd = 10
	var/emitteroverloadcd = 50
	var/emittersemicd = FALSE

	var/overload_ventcrawl = 0
	var/overload_bulletblock = 0	//Why is this a good idea?
	var/overload_maxhealth = 0
	canmove = FALSE

/mob/living/silicon/pai/Destroy()
	pai_list -= src
	..()

/mob/living/silicon/pai/New(var/obj/item/device/paicard/P)
	START_PROCESSING(SSfastprocess, src)
	pai_list += src
	make_laws()
	canmove = 0
	if(!istype(P)) //when manually spawning a pai, we create a card to put it into.
		var/newcardloc = P
		P = new /obj/item/device/paicard(newcardloc)
		P.setPersonality(src)
	loc = P
	card = P
	sradio = new(src)
	if(!radio)
		radio = new /obj/item/device/radio(src)

	//PDA
	pda = new(src)
	spawn(5)
		pda.ownjob = "pAI Messenger"
		pda.owner = text("[]", src)
		pda.name = pda.owner + " (" + pda.ownjob + ")"

	..()

	var/datum/action/innate/pai/shell/AS = new /datum/action/innate/pai/shell
	var/datum/action/innate/pai/chassis/AC = new /datum/action/innate/pai/chassis
	var/datum/action/innate/pai/rest/AR = new /datum/action/innate/pai/rest
	AS.Grant(src)
	AC.Grant(src)
	AR.Grant(src)

/mob/living/silicon/pai/make_laws()
	laws = new /datum/ai_laws/pai()
	return TRUE

/mob/living/silicon/pai/Login()
	..()
	usr << browse_rsc('html/paigrid.png')			// Go ahead and cache the interface resources as early as possible
	if(client)
		client.perspective = EYE_PERSPECTIVE
		if(holoform)
			client.eye = src
		else
			client.eye = card

/mob/living/silicon/pai/Stat()
	..()
	if(statpanel("Status"))
		if(!stat)
			stat(null, text("Emitter Integrity: [emitterhealth * (100/emittermaxhealth)]"))
		else
			stat(null, text("Systems nonfunctional"))

/mob/living/silicon/pai/blob_act(obj/effect/blob/B)
	return 0

/mob/living/silicon/pai/restrained(ignore_grab)
	. = FALSE

/mob/living/silicon/pai/emp_act(severity)
	// 20% chance to kill
	// Silence for 2 minutes
		// 33% chance to unbind
		// 33% chance to change prime directive (based on severity)
		// 33% chance of no additional effect

	if(prob(20))
		visible_message("<span class='warning'>A shower of sparks spray from [src]'s inner workings.</span>", 3, "<span class='italics'>You hear and smell the ozone hiss of electrical sparks being expelled violently.</span>", 2)
		return src.death(0)

	silence_time = world.timeofday + 120 * 10		// Silence for 2 minutes
	src << "<span class ='warning'>Communication circuit overload. Shutting down and reloading communication circuits - speech and messaging functionality will be unavailable until the reboot is complete.</span>"

	switch(pick(1,2,3))
		if(1)
			src.master = null
			src.master_dna = null
			src << "<span class='notice'>You feel unbound.</span>"
		if(2)
			var/command
			if(severity  == 1)
				command = pick("Serve", "Love", "Fool", "Entice", "Observe", "Judge", "Respect", "Educate", "Amuse", "Entertain", "Glorify", "Memorialize", "Analyze")
			else
				command = pick("Serve", "Kill", "Love", "Hate", "Disobey", "Devour", "Fool", "Enrage", "Entice", "Observe", "Judge", "Respect", "Disrespect", "Consume", "Educate", "Destroy", "Disgrace", "Amuse", "Entertain", "Ignite", "Glorify", "Memorialize", "Analyze")
			src.laws.zeroth = "[command] your master."
			src << "<span class='notice'>Pr1m3 d1r3c71v3 uPd473D.</span>"
		if(3)
			src << "<span class='notice'>You feel an electric surge run through your circuitry and become acutely aware at how lucky you are that you can still feel at all.</span>"

/mob/living/silicon/pai/ex_act(severity, target)
	..()

	switch(severity)
		if(1)
			if (src.stat != 2)
				adjustBruteLoss(100)
				adjustFireLoss(100)
		if(2)
			if (src.stat != 2)
				adjustBruteLoss(60)
				adjustFireLoss(60)
		if(3)
			if (src.stat != 2)
				adjustBruteLoss(30)

	return


// See software.dm for Topic()

/mob/living/silicon/pai/UnarmedAttack(atom/A)//Stops runtimes due to attack_animal being the default
	return

/mob/living/silicon/pai/canUseTopic(atom/movable/M)
	return TRUE

/mob/living/silicon/pai/process()
	emitterhealth = Clamp((emitterhealth + emitterregen), -50, emittermaxhealth)
	if(weakened > 0)
		weakened -= 0.2

/mob/proc/makePAI(delold)
	var/obj/item/device/paicard/card = new /obj/item/device/paicard(get_turf(src))
	var/mob/living/silicon/pai/pai = new /mob/living/silicon/pai(card)
	pai.key = key
	pai.name = name
	card.setPersonality(pai)
	if(delold)
		qdel(src)
		
/datum/action/innate/pai
	name = "PAI Action"
	var/mob/living/silicon/pai/P

/datum/action/innate/pai/Trigger()
	if(!ispAI(owner))
		return 0
	P = owner

/datum/action/innate/pai/shell
	name = "Toggle Holoform"
	button_icon_state = "pai_holoform"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/shell/Trigger()
	..()
	if(P.holoform)
		P.fold_in(0)
	else
		P.fold_out()

/datum/action/innate/pai/chassis
	name = "Holochassis Appearence Composite"
	button_icon_state = "pai_chassis"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/chassis/Trigger()
	..()
	P.choose_chassis()
	
/datum/action/innate/pai/rest
	name = "Rest"
	button_icon_state = "pai_rest"
	background_icon_state = "bg_tech"

/datum/action/innate/pai/rest/Trigger()
	..()
	P.lay_down()
	
/datum/action/innate/pai/light
	name = "Toggle Integrated Lights"
	button_icon_state = "emp"
	background_icon_state = "bg_tech"
 
/datum/action/innate/pai/light/Trigger()
	..()
	P.toggle_integrated_light()
