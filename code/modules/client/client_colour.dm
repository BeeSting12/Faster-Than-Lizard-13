
/*
	Client Colour Priority System By RemieRichards
	A System that gives finer control over which client.colour value to display on screen
	so that the "highest priority" one is always displayed as opposed to the default of
	"whichever was set last is displayed"
*/



/*
	Define subtypes of this datum
*/
/datum/client_colour
	var/colour = "" //Any client.color-valid value
	var/priority = 1 //Since only one client.color can be rendered on screen, we take the one with the highest priority value:
	//eg: "Bloody screen" > "goggles colour" as the former is much more important


/mob
	var/list/client_colours = list()



/*
	Adds an instance of colour_type to the mob's client_colours list
	colour_type - a typepath (subtyped from /datum/client_colour)
*/
/mob/proc/add_client_colour(colour_type)
	if(!ispath(/datum/client_colour))
		return

	var/datum/client_colour/CC = new colour_type()
	client_colours |= CC
	sortTim(client_colours, /proc/cmp_clientcolour_priority)
	update_client_colour()


/*
	Removes an instance of colour_type from the mob's client_colours list
	colour_type - a typepath (subtyped from /datum/client_colour)
*/
/mob/proc/remove_client_colour(colour_type)
	if(!ispath(/datum/client_colour))
		return

	for(var/cc in client_colours)
		var/datum/client_colour/CC = cc
		if(CC.type == colour_type)
			client_colours -= CC
			qdel(CC)
			break
	update_client_colour()


/*
	Resets the mob's client.color to null, and then sets it to the highest priority
	client_colour datum, if one exists
*/
/mob/proc/update_client_colour()
	if(!client)
		return
	client.color = ""
	if(!client_colours.len)
		return
	var/datum/client_colour/CC = client_colours[1]
	if(CC)
		client.color = CC.colour




