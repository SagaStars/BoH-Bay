/datum/riding
	var/generic_pixel_x = 0 //All dirs show this pixel_x for the driver
	var/generic_pixel_y = 0 //All dirs show this pixel_y for the driver, use these vars if the pixel shift is stable across all dir, override handle_vehicle_offsets otherwise.
	var/next_vehicle_move = 0 //used for move delays
	var/vehicle_move_delay = 2 //tick delay between movements, lower = faster, higher = slower
	var/keytype = null
	var/atom/movable/ridden = null

	var/slowed = FALSE
	var/slowvalue = 1

/datum/riding/proc/on_vehicle_move()
	for(var/mob/living/M in ridden.buckled_mobs)
		ride_check(M)
	handle_vehicle_offsets()
	handle_vehicle_layer()

/datum/riding/proc/ride_check(mob/living/M)
	return TRUE

/datum/riding/proc/force_dismount(mob/living/M)
	ridden.unbuckle_mob(M)

///////Humans. Yes, I said humans. No, this won't end well...//////////
/datum/riding/human
	keytype = null

/datum/riding/human/ride_check(mob/living/M)
	var/mob/living/carbon/human/H = ridden	//IF this runtimes I'm blaming the admins.
	if(M.incapacitated(FALSE, TRUE) || H.incapacitated(FALSE, TRUE))
		M.visible_message("<span class='boldwarning'>[M] falls off of [ridden]!</span>")
		ridden.unbuckle_mob(M)
		return FALSE
	if(M.restrained(TRUE))
		M.visible_message("<span class='boldwarning'>[M] can't hang onto [ridden] with their hands cuffed!</span>")	//Honestly this should put the ridden mob in a chokehold.
		ridden.unbuckle_mob(M)
		return FALSE
	if(H.pulling == M)
		H.stop_pulling()

/datum/riding/human/handle_vehicle_offsets()
	for(var/mob/living/M in ridden.buckled_mobs)
		M.setDir(ridden.dir)
		switch(ridden.dir)
			if(NORTH)
				M.pixel_x = 0
				M.pixel_y = 6
			if(SOUTH)
				M.pixel_x = 0
				M.pixel_y = 6
			if(EAST)
				M.pixel_x = -6
				M.pixel_y = 4
			if(WEST)
				M.pixel_x = 6
				M.pixel_y = 4

/datum/riding/human/handle_vehicle_layer()
	if(ridden.buckled_mobs && ridden.buckled_mobs.len)
		if(ridden.dir == SOUTH)
			ridden.layer = ABOVE_MOB_LAYER
		else
			ridden.layer = OBJ_LAYER
	else
		ridden.layer = MOB_LAYER

/datum/riding/human/force_dismount(mob/living/user)
	ridden.unbuckle_mob(user)
	user.Weaken(3)
	user.Stun(3)
	user.visible_message("<span class='boldwarning'>[ridden] pushes [user] off of them!</span>")

/datum/riding/cyborg/ride_check(mob/user)
	if(user.incapacitated())
		var/kick = TRUE
		if(istype(ridden, /mob/living/silicon/robot))
			var/mob/living/silicon/robot/R = ridden
			if(R.module && R.module.ride_allow_incapacitated)
				kick = FALSE
		if(kick)
			user << "<span class='userdanger'>You fall off of [ridden]!</span>"
			ridden.unbuckle_mob(user)
			return
	if(istype(user, /mob/living/carbon))
		var/mob/living/carbon/carbonuser = user
		if(!carbonuser.get_num_arms())
			ridden.unbuckle_mob(user)
			user << "<span class='userdanger'>You can't grab onto [ridden] with no hands!</span>"
			return

/datum/riding/cyborg/handle_vehicle_layer()
	if(ridden.buckled_mobs && ridden.buckled_mobs.len)
		if(ridden.dir == SOUTH)
			ridden.layer = ABOVE_MOB_LAYER
		else
			ridden.layer = OBJ_LAYER
	else
		ridden.layer = MOB_LAYER

/datum/riding/cyborg/force_dismount(mob/living/M)
	ridden.unbuckle_mob(M)
	var/turf/target = get_edge_target_turf(ridden, ridden.dir)
	var/turf/targetm = get_step(get_turf(ridden), ridden.dir)
	M.Move(targetm)
	M.visible_message("<span class='boldwarning'>[M] is thrown clear of [ridden]!</span>")
	M.throw_at(target, 14, 5, ridden)
	M.Weaken(3)

/datum/riding/proc/equip_buckle_inhands(mob/living/carbon/human/user, amount_required = 1)
	var/amount_equipped = 0
	for(var/amount_needed = amount_required, amount_needed > 0, amount_needed--)
		var/obj/item/riding_offhand/inhand = new /obj/item/riding_offhand(user)
		inhand.rider = user
		inhand.ridden = ridden
		if(user.put_in_hands(inhand, TRUE))
			amount_equipped++
		else
			break
	if(amount_equipped >= amount_required)
		return TRUE
	else
		unequip_buckle_inhands(user)
		return FALSE

/datum/riding/proc/unequip_buckle_inhands(mob/living/carbon/user)
	for(var/obj/item/riding_offhand/O in user.contents)
		if(O.ridden != ridden)
			CRASH("RIDING OFFHAND ON WRONG MOB")
			continue
		if(O.selfdeleting)
			continue
		else
			qdel(O)
	return TRUE

/obj/item/riding_offhand
	name = "offhand"
	icon = 'icons/obj/weapons.dmi'
	icon_state = "offhand"
	w_class = WEIGHT_CLASS_HUGE
	flags = ABSTRACT | DROPDEL | NOBLUDGEON
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/mob/living/carbon/rider
	var/mob/living/ridden
	var/selfdeleting = FALSE

/obj/item/riding_offhand/dropped()
	selfdeleting = TRUE
	. = ..()

/obj/item/riding_offhand/equipped()
	if(loc != rider)
		selfdeleting = TRUE
		qdel(src)
	. = ..()

/obj/item/riding_offhand/Destroy()
	if(selfdeleting)
		if(rider in ridden.buckled_mobs)
			ridden.unbuckle_mob(rider)
	. = ..()