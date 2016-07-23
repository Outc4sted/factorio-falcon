global.flycar = {{}, {}}
global.birds = {
	falcon    = { vehicle = "falcon-1",    airborne = "falcon-2",    shadow = "falcon-shadow"    },
	sparrow   = { vehicle = "sparrow-1",   airborne = "sparrow-2",   shadow = "sparrow-shadow"   },
	albatross = { vehicle = "albatross-1", airborne = "albatross-2", shadow = "albatross-shadow" }
}

local function build(entity)
	if entity.name == global.birds.falcon.vehicle then
		table.insert(global.flycar[1], entity)
	end
end

local function playerSuicide(vehicle, playerIndex)
	local entity = playerIndex ~= nil and game.players[playerIndex] or vehicle[1]
	local tilename = entity.surface.get_tile(math.floor(entity.position.x), math.floor(entity.position.y)).name

	if tilename == "deepwater" or tilename == "water" then
		if vehicle then
			entity.passenger.die()
			entity.die()
			vehicle[2].destroy()
		else
			entity.character.die()
		end

		return true
	end

	return false
end

local function car_flying()
	local falcon = global.birds.falcon
	local cars   = global.flycar

	for index, vehicle in pairs(cars[1]) do
		if vehicle.valid and vehicle.speed >= 0.3 then
			local vehicleClone = {
				position 	= vehicle.position,
				speed 		= vehicle.speed,
				orientation = vehicle.orientation,
				health    	= vehicle.health,
				passenger 	= vehicle.passenger,
				surface 	= vehicle.surface,
				inventory = {
					vehicle.get_inventory(1).get_contents(),
					vehicle.get_inventory(2).get_contents(),
					vehicle.get_inventory(3).get_contents()
				}
			}
			local shadow = vehicleClone.surface.create_entity{
  		  		name     = falcon.shadow,
	  		  	force    = game.forces.neutral,
	  		  	position = vehicleClone.position
	  	  	}

			vehicle.destroy()
			vehicle = vehicleClone.surface.create_entity{
				name     = falcon.airborne,
				force    = game.forces.player,
				position = vehicleClone.position
			}

			for i, inventory in pairs(vehicleClone.inventory) do
				for name, count in pairs(inventory) do
					vehicle.insert({name = name, count = count})

					if i == 1 then
						shadow.insert({name = name, count = count})
					end
				end
			end

			vehicle.orientation = vehicleClone.orientation
			vehicle.speed 		= vehicleClone.speed
			vehicle.health 		= vehicleClone.health
			vehicle.passenger 	= vehicleClone.passenger
			shadow.orientation  = vehicleClone.orientation
			shadow.speed 	    = vehicleClone.speed

			table.insert(cars[2], {vehicle, shadow, 0.1})

		elseif not vehicle.valid then
			table.remove(cars[1], index)
		end
	end
	
	for index, vehicle in pairs(cars[2]) do
		if vehicle[1].valid and vehicle[1].speed <= 0.29 and not playerSuicide(vehicle) then
			local vehicleClone = {
				position 	= vehicle[1].position,
				speed 		= vehicle[1].speed,
				orientation = vehicle[1].orientation,
				health    	= vehicle[1].health,
				passenger 	= vehicle[1].passenger,
				surface 	= vehicle[1].surface,
				inventory = {
					vehicle[1].get_inventory(1).get_contents(),
					vehicle[1].get_inventory(2).get_contents(),
					vehicle[1].get_inventory(3).get_contents()
				}
			}

			vehicle[1].destroy()
			vehicle[2].destroy()
			vehicle = vehicleClone.surface.create_entity{
				name     = falcon.vehicle,
				force    = game.forces.player,
				position = vehicleClone.position
			}

			for i, inventory in pairs(vehicleClone.inventory) do
				for name, count in pairs(inventory) do
					vehicle.insert({name = name, count = count})
				end
			end

			vehicle.orientation = vehicleClone.orientation
			vehicle.speed 		= vehicleClone.speed
			vehicle.health 		= vehicleClone.health
			vehicle.passenger 	= vehicleClone.passenger
			table.insert(cars[1], vehicle)

		elseif vehicle[1].valid then
			local chight = (vehicle[1].speed - 0.29)*10 - vehicle[3]
			vehicle[3] = vehicle[3] + chight
			vehicle[1].teleport({vehicle[1].position.x, vehicle[1].position.y - chight})
			vehicle[2].teleport({vehicle[1].position.x + vehicle[3], vehicle[1].position.y + vehicle[3]})

			vehicle[2].orientation = vehicle[1].orientation
			vehicle[2].speed = vehicle[1].speed

		elseif vehicle[2].valid then
			vehicle[2].destroy()
			table.remove(cars[2], index)
		end
	end
end

script.on_event(defines.events.on_player_driving_changed_state, function(event)
	playerSuicide(nil, event.player_index)
end)

script.on_event(defines.events.on_built_entity, function(event)
	build(event.created_entity)
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
	build(event.created_entity)
end)

script.on_event(defines.events.on_tick, function()
	car_flying()
end)