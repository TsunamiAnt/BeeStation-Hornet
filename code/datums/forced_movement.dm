//Just new and forget
//Depricated, use movement loops instead. Exists to support things that want to move more then 10 times a second
/datum/forced_movement
	var/atom/movable/victim
	var/atom/target
	var/last_processed
	var/steps_per_tick
	var/allow_climbing
	var/datum/callback/on_step
	var/moved_at_all = FALSE
															//as fast as ssfastprocess
/datum/forced_movement/New(atom/movable/_victim, atom/_target, _steps_per_tick = 0.5, _allow_climbing = FALSE, datum/callback/_on_step = null)
	victim = _victim
	target = _target
	steps_per_tick = _steps_per_tick
	allow_climbing = _allow_climbing
	on_step = _on_step

	. = ..()

	if(_victim && _target && _steps_per_tick && !_victim.force_moving)
		last_processed = world.time
		_victim.force_moving = src
		START_PROCESSING(SSfastprocess, src)
	else
		qdel(src)	//if you want to overwrite the current forced movement, call qdel(victim.force_moving) before creating this

/datum/forced_movement/Destroy()
	if(victim?.force_moving == src)
		victim.force_moving = null
		if(moved_at_all)
			victim.forceMove(victim.loc)	//get the side effects of moving here that require us to currently not be force_moving aka reslipping on ice
		STOP_PROCESSING(SSfastprocess, src)
	victim = null
	target = null
	return ..()

/datum/forced_movement/process()
	if(QDELETED(victim) || !victim.loc || QDELETED(target) || !target.loc)
		qdel(src)
		return
	var/steps_to_take = round(steps_per_tick * (world.time - last_processed))
	if(steps_to_take)
		for(var/i in 1 to steps_to_take)
			if(TryMove())
				moved_at_all = TRUE
				if(on_step)
					on_step.InvokeAsync()
			else
				qdel(src)
				return
		last_processed = world.time

/datum/forced_movement/proc/TryMove(recursive = FALSE)
	if(QDELETED(src)) //Our previous step caused deletion of this datum
		return

	var/atom/movable/vic = victim	//sanic
	var/atom/tar = target

	if(!recursive)
		. = step_towards(vic, tar)

	//shit way for getting around corners
	if(!.) //If stepping towards the target failed
		if(tar.x > vic.x) //If we're going x, step x
			if(step(vic, EAST))
				. = TRUE
		else if(tar.x < vic.x)
			if(step(vic, WEST))
				. = TRUE

		if(!.) //If the x step failed, go y
			if(tar.y > vic.y)
				if(step(vic, NORTH))
					. = TRUE
			else if(tar.y < vic.y)
				if(step(vic, SOUTH))
					. = TRUE

			if(!.) //If both failed, try again for some reason
				if(recursive)
					return FALSE
				else
					. = TryMove(TRUE)

	. = . && (vic.loc != tar.loc)
