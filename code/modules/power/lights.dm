// The Lighting System
//
// Consists of light fixtures (/obj/machinery/light) and light tube/bulb items (/obj/item/light)

// status values shared between lighting fixtures and items
#define LIGHT_OK 0
#define LIGHT_EMPTY 1
#define LIGHT_BROKEN 2
#define LIGHT_BURNED 3

#define LIGHT_ON_DELAY_LOWER 1 SECONDS
#define LIGHT_ON_DELAY_UPPER 3 SECONDS

#define MAXIMUM_SAFE_BACKUP_CHARGE 600
#define EMERGENCY_LIGHT_POWER_USE 0.5

/**
  * # Light fixture frame
  *
  * Incomplete light tube fixture
  *
  * Becomes a [Light fixture] when completed
  */
/obj/machinery/light_construct
	name = "light fixture frame"
	desc = "A light fixture under construction."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "tube-construct-stage1"
	anchored = TRUE
	layer = 5
	max_integrity = 200
	armor = list(MELEE = 50, BULLET = 10, LASER = 10, ENERGY = 0, BOMB = 0, RAD = 0, FIRE = 80, ACID = 50)
	/// Construction stage (1 = Empty frame | 2 = Wired frame | 3 = Completed frame)
	var/stage = 1
	/// Light bulb type
	var/fixture_type = "tube"
	/// How many metal sheets get given after deconstruction
	var/sheets_refunded = 2
	/// Holder for the completed fixture
	var/obj/machinery/light/newlight = null

/obj/machinery/light_construct/Initialize(mapload, ndir, building)
	. = ..()
	if(fixture_type == "bulb")
		icon_state = "bulb-construct-stage1"

/obj/machinery/light_construct/examine(mob/user)
	. = ..()
	if(get_dist(user, src) <= 2)
		switch(stage)
			if(1)
				. += "<span class='notice'>It's an empty frame <b>bolted</b> to the wall. It needs to be <i>wired</i>.</span>"
			if(2)
				. += "<span class='notice'>The frame is <b>wired</b>, but the casing's cover is <i>unscrewed</i>.</span>"
			if(3)
				. += "<span class='notice'>The casing is <b>screwed</b> shut.</span>"

/obj/machinery/light_construct/wrench_act(mob/living/user, obj/item/I)
	. = TRUE
	switch(stage)
		if(1)
			to_chat(user, "<span class='notice'>You begin to dismantle [src].</span>")
			if(!I.use_tool(src, user, 30, volume = I.tool_volume))
				return
			new /obj/item/stack/sheet/metal(get_turf(loc), sheets_refunded)
			TOOL_DISMANTLE_SUCCESS_MESSAGE
			qdel(src)
		if(2)
			to_chat(user, "<span class='warning'>You have to remove the wires first.</span>")
		if(3)
			to_chat(user, "<span class='warning'>You have to unscrew the case first.</span>")

/obj/machinery/light_construct/wirecutter_act(mob/living/user, obj/item/I)
	if(stage != 2)
		return
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	. = TRUE
	stage = 1
	switch(fixture_type)
		if("tube")
			icon_state = "tube-construct-stage1"
		if("bulb")
			icon_state = "bulb-construct-stage1"
	new /obj/item/stack/cable_coil(get_turf(loc), 1, paramcolor = COLOR_RED)
	WIRECUTTER_SNIP_MESSAGE

/obj/machinery/light_construct/screwdriver_act(mob/living/user, obj/item/I)
	if(stage != 2)
		return
	. = TRUE
	if(!I.use_tool(src, user, 0, volume = I.tool_volume))
		return
	switch(fixture_type)
		if("tube")
			icon_state = "tube-empty"
		if("bulb")
			icon_state = "bulb-empty"
	stage = 3
	user.visible_message("<span class='notice'>[user] closes [src]'s casing.</span>", \
		"<span class='notice'>You close [src]'s casing.</span>", "<span class='notice'>You hear a screwdriver.</span>")

	switch(fixture_type)
		if("tube")
			newlight = new /obj/machinery/light/built(loc)
		if("bulb")
			newlight = new /obj/machinery/light/small/built(loc)
	newlight.setDir(dir)
	transfer_fingerprints_to(newlight)
	qdel(src)

/obj/machinery/light_construct/attackby(obj/item/W, mob/living/user, params)
	add_fingerprint(user)
	if(istype(W, /obj/item/stack/cable_coil))
		if(stage != 1)
			return
		var/obj/item/stack/cable_coil/coil = W
		coil.use(1)
		switch(fixture_type)
			if("tube")
				icon_state = "tube-construct-stage2"
			if("bulb")
				icon_state = "bulb-construct-stage2"
		stage = 2
		playsound(loc, coil.usesound, 50, 1)
		user.visible_message("<span class='notice'>[user.name] adds wires to [src].</span>", \
			"<span class='notice'>You add wires to [src].</span>", "<span class='notice'>You hear a noise.</span>")
		return

	return ..()

/obj/machinery/light_construct/blob_act(obj/structure/blob/B)
	if(B && B.loc == loc)
		qdel(src)

/obj/machinery/light_construct/deconstruct(disassembled = TRUE)
	if(!(flags & NODECONSTRUCT))
		new /obj/item/stack/sheet/metal(loc, sheets_refunded)
	qdel(src)

/**
  * # Small light fixture frame
  *
  * Incomplete light bulb fixture
  *
  * Becomes a [Small light fixture] when completed
  */
/obj/machinery/light_construct/small
	name = "small light fixture frame"
	desc = "A small light fixture under construction."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "bulb-construct-stage1"
	anchored = TRUE
	layer = 5
	stage = 1
	fixture_type = "bulb"
	sheets_refunded = 1


/**
  * # Light fixture
  *
  * The standard light tube fixture
  */
/obj/machinery/light
	name = "light fixture"
	desc = "Industrial-grade light fixture for brightening up dark corners of the station."
	icon = 'icons/obj/lighting.dmi'
	icon_state = "tube1"
	glow_icon_state = "tube"
	exposure_icon_state = "cone"
	anchored = TRUE
	layer = 5
	max_integrity = 100
	power_state = ACTIVE_POWER_USE
	idle_power_consumption = 2  //when in low power mode
	active_power_consumption = 20 //when in full power mode
	power_channel = PW_CHANNEL_LIGHTING //Lights are calc'd via area so they dont need to be in the machine list
	var/base_state = "tube" // Base description and icon_state
	/// Is the light on or off?
	var/on = FALSE
	/// Is the light currently turning on?
	var/turning_on = FALSE
	/// If the light state has changed since the last 'update()', also update the power requirements
	var/light_state = FALSE
	/// How much power does it use?
	var/static_power_used = 0
	/// Light range (Also used in power calculation)
	var/brightness_range = 8
	/// Light intensity
	var/brightness_power = 1
	/// Light colour when on
	var/brightness_color = "#FFFFFF"
	/// Light fixture status (LIGHT_OK | LIGHT_EMPTY | LIGHT_BURNED | LIGHT_BROKEN)
	var/status = LIGHT_OK
	/// Is the light currently flickering?
	var/flickering = FALSE
	/// Was this light extinguished with an antag ability? Used to ovveride flicker events
	var/extinguished = FALSE

	/// Item type of the light bulb
	var/light_type = /obj/item/light/tube
	/// Type of light bulb that goes into the fixture
	var/fitting = "tube"
	/// How many times has the light been switched on/off? (This is used to calc the probability the light burns out)
	var/switchcount = 0
	/// Is the light rigged to explode?
	var/rigged = FALSE
	/// Materials the light is made of
	var/lightmaterials = list(MAT_GLASS = 200)

	/// Currently in night shift mode?
	var/nightshift_enabled = FALSE
	/// Allowed to be switched to night shift mode?
	var/nightshift_allowed = TRUE
	/// Light range when in night shift mode
	var/nightshift_light_range = 8
	/// Light intensity when in night shift mode
	var/nightshift_light_power = 0.45
	/// The colour of the light while it's in night shift mode
	var/nightshift_light_color = "#FFDDCC"
	/// The colour of the light while it's in emergency mode
	var/bulb_emergency_colour = "#FF3232"

	var/emergency_mode = FALSE	// if true, the light is in emergency mode
	var/fire_mode = FALSE // if true, the light swaps over to emergency colour
	var/no_emergency = FALSE	// if true, this light cannot ever have an emergency mode

/**
  * # Small light fixture
  *
  * The smaller light bulb fixture
  */
/obj/machinery/light/small
	icon_state = "bulb1"
	desc = "A compact and cheap light fixture, perfect for keeping maintenance tunnels appropriately spooky."
	fitting = "bulb"
	glow_icon_state = "bulb"
	exposure_icon_state = "circle"
	base_state = "bulb"
	brightness_range = 4
	brightness_color = "#a0a080"
	nightshift_light_range = 4
	light_type = /obj/item/light/bulb

/obj/machinery/light/spot
	name = "spotlight"
	light_type = /obj/item/light/tube/large
	brightness_range = 12
	brightness_power = 4

/obj/machinery/light/built/Initialize(mapload)
	status = LIGHT_EMPTY
	..()

/obj/machinery/light/small/built/Initialize(mapload)
	status = LIGHT_EMPTY
	..()

// create a new lighting fixture
/obj/machinery/light/Initialize(mapload)
	. = ..()

	if(is_station_level(z))
		RegisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGE_PLANNED, PROC_REF(on_security_level_change_planned))
		RegisterSignal(SSsecurity_level, COMSIG_SECURITY_LEVEL_CHANGED, PROC_REF(on_security_level_update))

	var/area/A = get_area(src)
	if(A && !A.requires_power)
		on = TRUE

	switch(fitting)
		if("tube")
			brightness_range = 8
			if(prob(2))
				break_light_tube(TRUE)
		if("bulb")
			brightness_range = 4
			brightness_color = "#a0a080"
			if(prob(5))
				break_light_tube(TRUE)
	update(FALSE, TRUE, FALSE)

/obj/machinery/light/proc/on_security_level_change_planned(datum/source, previous_level_number, new_level_number)
	SIGNAL_HANDLER

	if(status != LIGHT_OK)
		return

	if(new_level_number == SEC_LEVEL_EPSILON)
		fire_mode = FALSE
		emergency_mode = TRUE
		on = FALSE
		INVOKE_ASYNC(src, PROC_REF(update), FALSE)

/obj/machinery/light/proc/on_security_level_update(datum/source, previous_level_number, new_level_number)
	SIGNAL_HANDLER

	if(status != LIGHT_OK || !has_power())
		return

	if(new_level_number >= SEC_LEVEL_EPSILON)
		fire_mode = TRUE
		emergency_mode = TRUE
		on = FALSE
	else
		fire_mode = FALSE
		emergency_mode = FALSE
		on = TRUE

	INVOKE_ASYNC(src, PROC_REF(update), FALSE)

/obj/machinery/light/Destroy()
	var/area/A = get_area(src)
	if(A)
		on = FALSE
	return ..()

/obj/machinery/light/update_icon_state()
	switch(status)		// set icon_states
		if(LIGHT_OK)
			if(emergency_mode || fire_mode)
				icon_state = "[base_state]_emergency"
			else
				icon_state = "[base_state][on]"
		if(LIGHT_EMPTY)
			icon_state = "[base_state]-empty"
			on = FALSE
		if(LIGHT_BURNED)
			icon_state = "[base_state]-burned"
			on = FALSE
		if(LIGHT_BROKEN)
			icon_state = "[base_state]-broken"
			on = FALSE

/obj/machinery/light/update_overlays()
	. = ..()
	underlays.Cut()

	if(status != LIGHT_OK || !on || !turning_on)
		return
	if(nightshift_enabled || emergency_mode || fire_mode || turning_on)
		underlays += emissive_appearance(icon, "[base_state]_emergency_lightmask")
	else
		underlays += emissive_appearance(icon, "[base_state]_lightmask")

/**
  * Updates the light's 'on' state and power consumption based on [/obj/machinery/light/var/on].
  *
  * Arguments:
  * * trigger - Should this update check if the light will explode/burn out.
  * * instant - Will the lightbulb turn on instantly, or after a short delay.
  * * play_sound - Will the lightbulb play a sound when it's turned on.
  */
/obj/machinery/light/proc/update(trigger = TRUE, instant = FALSE, play_sound = TRUE)
	var/area/current_area = get_area(src)
	UnregisterSignal(current_area.powernet, COMSIG_POWERNET_POWER_CHANGE)
	switch(status)
		if(LIGHT_BROKEN, LIGHT_BURNED, LIGHT_EMPTY)
			on = FALSE
	emergency_mode = FALSE
	if(fire_mode)
		set_emergency_lights()
	if(on) // Turning on
		extinguished = FALSE
		if(instant)
			_turn_on(trigger, play_sound)
		else if(!turning_on)
			turning_on = TRUE
			addtimer(CALLBACK(src, PROC_REF(_turn_on), trigger, play_sound), rand(LIGHT_ON_DELAY_LOWER, LIGHT_ON_DELAY_UPPER))
	else if(!turned_off())
		set_emergency_lights()
	else // Turning off
		change_power_mode(IDLE_POWER_USE)
		set_light(0)
	update_icon()
	active_power_consumption = (brightness_range * 10)
	if(on != light_state) // Light was turned on/off, so update the power usage
		light_state = on
		if(on)
			static_power_used = brightness_range * 20 //20W per unit of luminosity
			add_static_power(PW_CHANNEL_LIGHTING, static_power_used)
		else
			remove_static_power(PW_CHANNEL_LIGHTING, static_power_used)


/**
  * The actual proc to turn on the lightbulb.
  *
  * Private proc, do not call directly. Use [/obj/machinery/light/proc/update] instead.
  *
  * Sets the light power, range, and colour based on environmental conditions such as night shift and fire alarms.
  * Also handles light bulbs burning out and exploding if `trigger` is `TRUE`.
  */
/obj/machinery/light/proc/_turn_on(trigger, play_sound = TRUE)
	PRIVATE_PROC(TRUE)
	if(QDELETED(src))
		return
	turning_on = FALSE
	if(!on)
		return
	var/BR = brightness_range
	var/PO = brightness_power
	var/CO = brightness_color
	if(color)
		CO = color
	if(emergency_mode)
		CO = bulb_emergency_colour
	else if(nightshift_enabled)
		BR = nightshift_light_range
		PO = nightshift_light_power
		if(!color)
			CO = nightshift_light_color
	if(light && (BR == light.light_range) && (PO == light.light_power) && (CO == light.light_color))
		return // Nothing's changed here

	switchcount++
	if(trigger && (status == LIGHT_OK))
		if(rigged)
			log_admin("LOG: Rigged light explosion, last touched by [fingerprintslast].")
			message_admins("LOG: Rigged light explosion, last touched by [fingerprintslast].")
			explode()
			return
		// Whichever number is smallest gets set as the prob
		// Each spook adds a 0.5% to 1% chance of burnout
		else if(prob(min(40, switchcount / 10)))
			burnout()
			return

	change_power_mode(ACTIVE_POWER_USE)
	update_icon()
	set_light(BR, PO, CO)
	if(play_sound)
		playsound(src, 'sound/machines/light_on.ogg', 60, TRUE)

/obj/machinery/light/proc/burnout()
	status = LIGHT_BURNED

	visible_message("<span class='boldwarning'>[src] burns out!</span>")
	do_sparks(2, 1, src)

	on = FALSE
	set_light(0)
	update_icon()

// attempt to set the light's on/off status
// will not switch on if broken/burned/empty
/obj/machinery/light/proc/seton(S)
	on = (S && status == LIGHT_OK)
	update()

// examine verb
/obj/machinery/light/examine(mob/user)
	. = ..()
	if(in_range(user, src))
		switch(status)
			if(LIGHT_OK)
				. += "<span class='notice'>It is turned [on ? "on" : "off"].</span>"
			if(LIGHT_EMPTY)
				. += "<span class='notice'>The [fitting] has been removed.</span>"
				. += "<span class='notice'>The casing can be <b>unscrewed</b>.</span>"
			if(LIGHT_BURNED)
				. += "<span class='notice'>The [fitting] is burnt out.</span>"
			if(LIGHT_BROKEN)
				. += "<span class='notice'>The [fitting] has been smashed.</span>"

// attack with item - insert light (if right type), otherwise try to break the light

/obj/machinery/light/attackby(obj/item/W, mob/living/user, params)
	user.changeNext_move(CLICK_CD_MELEE) // This is an ugly hack and I hate it forever
	//Light replacer code
	if(istype(W, /obj/item/lightreplacer))
		var/obj/item/lightreplacer/LR = W
		LR.ReplaceLight(src, user)
		return

	// Attack with Spray Can! Coloring time.
	if(istype(W, /obj/item/toy/crayon/spraycan))
		var/obj/item/toy/crayon/spraycan/spraycan = W

		// quick check to disable capped spraypainting, aesthetic reasons
		if(spraycan.capped)
			to_chat(user, "<span class='notice'>You can't spraypaint [src] with the cap still on!</span>")
			return
		var/list/hsl = rgb2hsl(hex2num(copytext(spraycan.colour, 2, 4)), hex2num(copytext(spraycan.colour, 4, 6)), hex2num(copytext(spraycan.colour, 6, 8)))
		hsl[3] = max(hsl[3], 0.4)
		var/list/rgb = hsl2rgb(arglist(hsl))
		var/new_color = "#[num2hex(rgb[1], 2)][num2hex(rgb[2], 2)][num2hex(rgb[3], 2)]"
		color = new_color
		to_chat(user, "<span class='notice'>You change [src]'s light bulb color.</span>")
		brightness_color = new_color
		update(TRUE, TRUE, FALSE)
		return

	// attempt to insert light
	if(istype(W, /obj/item/light))
		if(status != LIGHT_EMPTY)
			to_chat(user, "<span class='warning'>There is a [fitting] already inserted.</span>")
		else
			add_fingerprint(user)
			var/obj/item/light/L = W
			if(istype(L, light_type))
				status = L.status
				to_chat(user, "<span class='notice'>You insert [L].</span>")
				switchcount = L.switchcount
				rigged = L.rigged
				brightness_range = L.brightness_range
				brightness_power = L.brightness_power
				brightness_color = L.brightness_color
				lightmaterials = L.materials
				on = has_power()
				update(TRUE, TRUE, FALSE)

				user.drop_item()	//drop the item to update overlays and such
				qdel(L)

				if(on && rigged)

					log_admin("LOG: Rigged light explosion, last touched by [fingerprintslast]")
					message_admins("LOG: Rigged light explosion, last touched by [fingerprintslast]")

					explode()
			else
				to_chat(user, "<span class='warning'>This type of light requires a [fitting].</span>")
		return

		// attempt to break the light
		//If xenos decide they want to smash a light bulb with a toolbox, who am I to stop them? /N

	if(status != LIGHT_BROKEN && status != LIGHT_EMPTY)
		user.do_attack_animation(src)
		if(prob(1 + W.force * 5))

			user.visible_message("<span class='danger'>[user] smashed the light!</span>", "<span class='danger'>You hit the light, and it smashes!</span>", \
			"<span class='danger'>You hear the tinkle of breaking glass.</span>")
			if(on && (W.flags & CONDUCT))
				if(prob(12))
					electrocute_mob(user, get_area(src), src, 0.3, TRUE)
			break_light_tube()
		else
			user.visible_message("<span class='danger'>[user] hits the light.</span>", "<span class='danger'>You hit the light.</span>", \
			"<span class='danger'>You hear someone hitting a light.</span>")
			playsound(loc, 'sound/effects/glasshit.ogg', 75, 1)
		return

	// attempt to stick weapon into light socket
	if(status == LIGHT_EMPTY)
		if(has_power() && (W.flags & CONDUCT))
			do_sparks(3, 1, src)
			if(prob(75)) // If electrocuted
				electrocute_mob(user, get_area(src), src, rand(0.7, 1), TRUE)
				to_chat(user, "<span class='userdanger'>You are electrocuted by [src]!</span>")
			else // If not electrocuted
				to_chat(user, "<span class='danger'>You stick [W] into the light socket!</span>")
			return

	return ..()

/obj/machinery/light/screwdriver_act(mob/living/user, obj/item/I)
	if(status != LIGHT_EMPTY)
		return

	I.play_tool_sound(src)
	user.visible_message("<span class='notice'>[user] opens [src]'s casing.</span>", \
		"<span class='notice'>You open [src]'s casing.</span>", "<span class='notice'>You hear a screwdriver.</span>")
	deconstruct()
	return TRUE

/obj/machinery/light/deconstruct(disassembled = TRUE)
	if(!(flags & NODECONSTRUCT))
		var/obj/machinery/light_construct/newlight = null
		var/cur_stage = 2
		if(!disassembled)
			cur_stage = 1
		switch(fitting)
			if("tube")
				newlight = new /obj/machinery/light_construct(loc)
				newlight.icon_state = "tube-construct-stage2"

			if("bulb")
				newlight = new /obj/machinery/light_construct/small(loc)
				newlight.icon_state = "bulb-construct-stage2"
		newlight.setDir(dir)
		newlight.stage = cur_stage
		if(!disassembled)
			newlight.obj_integrity = newlight.max_integrity * 0.5
			if(status != LIGHT_BROKEN)
				break_light_tube()
			if(status != LIGHT_EMPTY)
				drop_light_tube()
			new /obj/item/stack/cable_coil(loc, 1, "red")
		transfer_fingerprints_to(newlight)
	qdel(src)

/obj/machinery/light/attacked_by(obj/item/I, mob/living/user)
	..()
	if(status == LIGHT_BROKEN || status == LIGHT_EMPTY)
		if(on && (I.flags & CONDUCT))
			if(prob(12))
				electrocute_mob(user, get_area(src), src, 0.3, TRUE)

/obj/machinery/light/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1)
	. = ..()
	if(. && !QDELETED(src))
		if(prob(damage_amount * 5))
			break_light_tube()

/obj/machinery/light/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			switch(status)
				if(LIGHT_EMPTY)
					playsound(loc, 'sound/weapons/smash.ogg', 50, TRUE)
				if(LIGHT_BROKEN)
					playsound(loc, 'sound/effects/hit_on_shattered_glass.ogg', 90, TRUE)
				else
					playsound(loc, 'sound/effects/glasshit.ogg', 90, TRUE)
		if(BURN)
			playsound(loc, 'sound/items/welder.ogg', 100, TRUE)

// returns if the light has power /but/ is manually turned off
// if a light is turned off, it won't activate emergency power
/obj/machinery/light/proc/turned_off()
	var/area/machine_area = get_area(src)
	return !machine_area.lightswitch && machine_area.powernet.has_power(PW_CHANNEL_LIGHTING)

// returns whether this light has power
// true if area has power and lightswitch is on
/obj/machinery/light/has_power()
	var/area/machine_area = get_area(src)
	return machine_area.lightswitch && machine_area.powernet.has_power(PW_CHANNEL_LIGHTING)

// attempts to set emergency lights
/obj/machinery/light/proc/set_emergency_lights()
	var/area/current_area = get_area(src)
	var/obj/machinery/power/apc/current_apc = current_area.get_apc()
	if(status != LIGHT_OK || !current_apc || flickering || no_emergency)
		emergency_lights_off(current_area, current_apc)
		return
	if(current_apc.emergency_lights || !current_apc.emergency_power)
		emergency_lights_off(current_area, current_apc)
		return
	if(fire_mode)
		set_light(nightshift_light_range, nightshift_light_power, bulb_emergency_colour)
		update_icon()
		return
	emergency_mode = TRUE
	set_light(3, 1.7, bulb_emergency_colour)
	update_icon()
	RegisterSignal(machine_powernet, COMSIG_POWERNET_POWER_CHANGE, PROC_REF(update), override = TRUE)

/obj/machinery/light/proc/emergency_lights_off(area/current_area, obj/machinery/power/apc/current_apc)
	set_light(0, 0, 0) //you, sir, are off!
	if(current_apc)
		RegisterSignal(machine_powernet, COMSIG_POWERNET_POWER_CHANGE, PROC_REF(update), override = TRUE)

/obj/machinery/light/get_spooked()
	return forced_flicker()

/obj/machinery/light/proc/forced_flicker(amount = rand(20, 30))
	if(flickering)
		return FALSE

	if(!on || status != LIGHT_OK || emergency_mode)
		return FALSE

	flickering = TRUE
	INVOKE_ASYNC(src, TYPE_PROC_REF(/obj/machinery/light, flicker_event), amount)

	return TRUE

/**
  * Flicker routine for the light.
  * Called by invoke_async so the parent proc can return immediately.
  */
/obj/machinery/light/proc/flicker_event(amount)
	if(on && status == LIGHT_OK)
		for(var/i = 0; i < amount; i++)
			if(status != LIGHT_OK || extinguished)
				break
			on = FALSE
			update(FALSE, TRUE, FALSE)
			sleep(rand(1, 3))
			on = (status == LIGHT_OK)
			update(FALSE, TRUE, FALSE)
			sleep(rand(1, 10))
		on = (status == LIGHT_OK && !extinguished)
		update(FALSE, TRUE, FALSE)
	flickering = FALSE


// ai attack - toggle emergency lighting
/obj/machinery/light/attack_ai(mob/user)
	no_emergency = !no_emergency
	to_chat(user, "<span class='notice'>Emergency lights for this fixture have been [no_emergency ? "disabled" : "enabled"].</span>")
	update(FALSE)

// attack with hand - remove tube/bulb
// if hands aren't protected and the light is on, burn the player

/obj/machinery/light/attack_hand(mob/user)
	user.changeNext_move(CLICK_CD_MELEE)
	add_fingerprint(user)

	if(status == LIGHT_EMPTY)
		return

	// make it burn hands if not wearing fire-insulated gloves
	if(on)
		var/prot = 0
		var/mob/living/carbon/human/H = user

		if(istype(H))
			if(H.gloves)
				var/obj/item/clothing/gloves/G = H.gloves
				if(G.max_heat_protection_temperature)
					prot = (G.max_heat_protection_temperature > 360)
		else
			prot = 1

		if(prot > 0 ||  HAS_TRAIT(user, TRAIT_RESISTHEAT) || HAS_TRAIT(user, TRAIT_RESISTHEATHANDS))
			to_chat(user, "<span class='notice'>You remove the light [fitting]</span>")
		else if(HAS_TRAIT(user, TRAIT_TELEKINESIS))
			to_chat(user, "<span class='notice'>You telekinetically remove the light [fitting].</span>")
		else
			if(user.a_intent == INTENT_DISARM || user.a_intent == INTENT_GRAB)
				to_chat(user, "<span class='warning'>You try to remove the light [fitting], but you burn your hand on it!</span>")

				var/obj/item/organ/external/affecting = H.get_organ("[user.hand ? "l" : "r" ]_hand")
				if(affecting.receive_damage(0, 5)) // 5 burn damage
					H.UpdateDamageIcon()
				H.updatehealth()
				return
			else
				to_chat(user, "<span class='notice'>You try to remove the light [fitting], but it's too hot to touch!</span>")
				return
	else
		to_chat(user, "<span class='notice'>You remove the light [fitting]</span>")
	// create a light tube/bulb item and put it in the user's hand
	drop_light_tube(user)

// break the light and make sparks if was on

/obj/machinery/light/proc/drop_light_tube(mob/user)
	if(status == LIGHT_EMPTY)
		return

	var/obj/item/light/L = new light_type()
	L.status = status
	L.rigged = rigged
	L.brightness_range = brightness_range
	L.brightness_power = brightness_power
	L.brightness_color = brightness_color
	L.materials = lightmaterials

	// light item inherits the switchcount, then zero it
	L.switchcount = switchcount
	switchcount = 0

	L.update()
	L.forceMove(loc)

	if(user) //puts it in our active hand
		L.add_fingerprint(user)
		user.put_in_active_hand(L)

	status = LIGHT_EMPTY
	update()
	return L

/obj/machinery/light/attack_tk(mob/user)
	if(status == LIGHT_EMPTY)
		to_chat(user, "There is no [fitting] in this light.")
		return

	to_chat(user, "You telekinetically remove the light [fitting].")
	// create a light tube/bulb item and put it in the user's hand
	var/obj/item/light/L = drop_light_tube()
	L.attack_tk(user)

/obj/machinery/light/proc/break_light_tube(skip_sound_and_sparks = FALSE, overloaded = FALSE)
	if(status == LIGHT_EMPTY || status == LIGHT_BROKEN)
		return

	if(!skip_sound_and_sparks)
		if(status == LIGHT_OK || status == LIGHT_BURNED)
			playsound(loc, 'sound/effects/glasshit.ogg', 75, 1)
		if(on || overloaded)
			do_sparks(3, 1, src)
	status = LIGHT_BROKEN
	update()

/obj/machinery/light/proc/fix()
	if(status == LIGHT_OK)
		return
	status = LIGHT_OK
	extinguished = FALSE
	on = TRUE
	update(FALSE, TRUE, FALSE)

/obj/machinery/light/zap_act(power, zap_flags)
	var/explosive = zap_flags & ZAP_MACHINE_EXPLOSIVE
	zap_flags &= ~(ZAP_MACHINE_EXPLOSIVE | ZAP_OBJ_DAMAGE)
	. = ..()
	if(explosive)
		explosion(src, 0, 0, 0, flame_range = 5, adminlog = FALSE)
		qdel(src)

// timed process
// use power

// called when area power state changes
/obj/machinery/light/power_change()
	var/area/A = get_area(src)
	if(A)
		seton(A.lightswitch && A.powernet.has_power(PW_CHANNEL_LIGHTING))

// called when on fire

/obj/machinery/light/temperature_expose(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	..()
	if(prob(max(0, exposed_temperature - 673)))   //0% at <400C, 100% at >500C
		break_light_tube()

// explode the light

/obj/machinery/light/proc/explode()
	var/turf/T = get_turf(loc)
	break_light_tube()	// break it first to give a warning
	sleep(2)
	explosion(T, 0, 0, 2, 2)
	qdel(src)

/**
  * MARK: Light item
  *
  * Parent type of light fittings (Light bulbs, light tubes)
  *
  * Will fit into empty [/obj/machinery/light] of the corresponding type
  */
/obj/item/light
	icon = 'icons/obj/lighting.dmi'
	force = 2
	throwforce = 5
	w_class = WEIGHT_CLASS_TINY
	blocks_emissive = FALSE
	/// Light status (LIGHT_OK | LIGHT_BURNED | LIGHT_BROKEN)
	var/status = LIGHT_OK
	var/base_state
	/// How many times has the light been switched on/off?
	var/switchcount = 0
	/// Materials the light is made of
	materials = list(MAT_GLASS = 200)
	/// Is the light rigged to explode?
	var/rigged = FALSE
	/// Light range
	var/brightness_range = 2
	/// Light intensity
	var/brightness_power = 1
	/// Light colour
	var/brightness_color = null

/obj/item/light/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/caltrop, force)

/obj/item/light/Crossed(mob/living/L)
	if(istype(L) && has_gravity(loc))
		if(L.incorporeal_move || L.flying || L.floating)
			return
		playsound(loc, 'sound/effects/glass_step.ogg', 50, TRUE)
		if(status == LIGHT_BURNED || status == LIGHT_OK)
			shatter()
	return ..()

/obj/item/light/decompile_act(obj/item/matter_decompiler/C, mob/user)
	C.stored_comms["glass"] += 1
	C.stored_comms["metal"] += 1
	qdel(src)
	return TRUE

/**
  * # Light Tube
  *
  * For use in an empty [/obj/machinery/light]
  */
/obj/item/light/tube
	name = "light tube"
	desc = "A replacement light tube."
	icon_state = "ltube"
	base_state = "ltube"
	item_state = "c_tube"
	brightness_range = 8
	brightness_color = "#ffffff"

/obj/item/light/tube/large
	w_class = WEIGHT_CLASS_SMALL
	name = "large light tube"
	brightness_range = 15
	brightness_power = 2

/**
  * # Light Bulb
  *
  * For use in an empty [/obj/machinery/light/small]
  */
/obj/item/light/bulb
	name = "light bulb"
	desc = "A replacement light bulb."
	icon_state = "lbulb"
	base_state = "lbulb"
	item_state = "contvapour"
	brightness_range = 5
	brightness_color = "#a0a080"

/obj/item/light/throw_impact(atom/hit_atom)
	..()
	shatter()

/obj/item/light/bulb/fire
	name = "fire bulb"
	desc = "A replacement fire bulb."
	icon_state = "fbulb"
	base_state = "fbulb"
	item_state = "egg4"
	brightness_range = 5

// update the icon state and description of the light

/obj/item/light/proc/update()
	switch(status)
		if(LIGHT_OK)
			icon_state = base_state
			desc = "A replacement [name]."
		if(LIGHT_BURNED)
			icon_state = "[base_state]-burned"
			desc = "A burnt-out [name]."
		if(LIGHT_BROKEN)
			icon_state = "[base_state]-broken"
			desc = "A broken [name]."


/obj/item/light/New()
	..()
	switch(name)
		if("light tube")
			brightness_range = rand(6,9)
		if("light bulb")
			brightness_range = rand(4,6)
	update()


// attack bulb/tube with object
// if a syringe, can inject plasma to make it explode. Light replacers eat them.
/obj/item/light/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/reagent_containers/syringe))
		var/obj/item/reagent_containers/syringe/S = I

		if(!length(S.reagents.reagent_list))
			return

		if(S.reagents.has_reagent("plasma", 5) || S.reagents.has_reagent("plasma_dust", 5))
			to_chat(user, "<span class='danger'>You inject the solution into [src], rigging it to explode!</span>")
			log_admin("LOG: [key_name(user)] injected a light with plasma, rigging it to explode.")
			message_admins("LOG: [key_name_admin(user)] injected a light with plasma, rigging it to explode.")

			rigged = TRUE
			S.reagents.clear_reagents()

		else // If it has a reagent, but it's not plasma
			to_chat(user, "<span class='warning'>You fail to rig [src] with the solution.</span>")

	else // If it's not a syringe
		return ..()

/obj/item/light/attack(mob/living/M, mob/living/user, def_zone)
	..()
	shatter()

/obj/item/light/attack_obj(obj/O, mob/living/user, params)
	..()
	shatter()

/obj/item/light/proc/shatter()
	if(status == LIGHT_OK || status == LIGHT_BURNED)
		visible_message("<span class='warning'>[src] shatters.</span>", "<span class='warning'>You hear a small glass object shatter.</span>")
		status = LIGHT_BROKEN
		force = 5
		sharp = TRUE
		playsound(loc, 'sound/effects/glasshit.ogg', 75, 1)
		update()

/obj/item/light/suicide_act(mob/living/carbon/human/user)
	user.visible_message("<span class='suicide'>[user] touches [src], burning [user.p_their()] hands off!</span>", "<span class='suicide'>You touch [src], burning your hands off!</span>")

	for(var/oname in list("l_hand", "r_hand"))
		var/obj/item/organ/external/limb = user.get_organ(oname)
		if(limb)
			limb.droplimb(0, DROPLIMB_BURN)
	return FIRELOSS

/obj/machinery/light/extinguish_light(force = FALSE)
	on = FALSE
	extinguished = TRUE
	emergency_mode = FALSE
	no_emergency = TRUE
	addtimer(CALLBACK(src, PROC_REF(enable_emergency_lighting)), 5 MINUTES, TIMER_UNIQUE|TIMER_OVERRIDE)
	visible_message("<span class='danger'>[src] flickers and falls dark.</span>")
	update(FALSE)

/obj/machinery/light/proc/enable_emergency_lighting()
	visible_message("<span class='notice'>[src]'s emergency lighting flickers back to life.</span>")
	extinguished = FALSE
	no_emergency = FALSE
	update(FALSE)

#undef MAXIMUM_SAFE_BACKUP_CHARGE
#undef EMERGENCY_LIGHT_POWER_USE
#undef LIGHT_OK
#undef LIGHT_EMPTY
#undef LIGHT_BROKEN
#undef LIGHT_BURNED
#undef LIGHT_ON_DELAY_LOWER
#undef LIGHT_ON_DELAY_UPPER
