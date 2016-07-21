global.flycar = {{}, {}}
global.birds = {
	falcon    = { vehicle = "falcon-1",    airborne = "falcon-2",    shadow = "falcon-shadow"    },
	sparrow   = { vehicle = "sparrow-1",   airborne = "sparrow-2",   shadow = "sparrow-shadow"   },
	albatross = { vehicle = "albatross-1", airborne = "albatross-2", shadow = "albatross-shadow" }
}

local function build(ent)
	if ent.name == global.birds.falcon.vehicle then
		table.insert(global.flycar[1], ent)
	end
end

local function car_flying()
	local falcon = global.birds.falcon,
		  cars   = global.flycar

	for index,vehicle in pairs(cars[1]) do
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
			},
			shadow = vehicleClone.surface.create_entity{
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

			for i,inventory in pairs(vehicleClone.inventory) do
				for name,count in pairs(inventory) do
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
	
	for i,j in pairs(cars[2]) do
		if j[1].valid then
			if j[1].speed <= 0.29 then
				local idx = j[1].passenger
				local surface = j[1].surface
				local tilename = surface.get_tile(math.floor(j[1].position.x), math.floor(j[1].position.y)).name
				if tilename == "deepwater" or tilename == "water" then
					j[1].die()
					j[2].destroy()
					if idx ~= nil then
						if idx.valid then
							local position = idx.position
							tilename = surface.get_tile(math.floor(position.x), math.floor(position.y)).name
							if tilename == "deepwater" or tilename == "water" then idx.die() return
							else idx.health = idx.health - math.random(1,52)
								if idx.health == 0 then idx.die() return end
							end
						end
					end
				else
					local fly = {position = j[1].position, speed = j[1].speed, orientation = j[1].orientation, health = j[1].health}
					local inv = j[1].get_inventory(1).get_contents()
					local inv2 = j[1].get_inventory(2).get_contents()
					local inv3 = j[1].get_inventory(3).get_contents()
					j[1].destroy()
					j[2].destroy()
					j = surface.create_entity{name = falcon.vehicle, position = fly.position, force = game.forces.player}
					for y,u in pairs(inv) do
						j.insert({name = y, count = u})
					end
					for y,u in pairs(inv2) do
						j.insert({name = y, count = u})
					end
					for y,u in pairs(inv3) do
						j.insert({name = y, count = u})
					end
					j.orientation = fly.orientation
					j.speed = fly.speed
					j.health = fly.health
					j.passenger = idx
					table.insert(cars[1], j)
				end
			else
				local chight = (j[1].speed - 0.29)*10 - j[3]
				j[3] = j[3] + chight
				j[1].teleport({j[1].position.x, j[1].position.y - chight})
				j[2].teleport({j[1].position.x + j[3], j[1].position.y + j[3]})
				j[2].orientation = j[1].orientation
				j[2].speed = j[1].speed
			end
		else
			if j[2].valid then j[2].destroy() end
			table.remove(cars[2], i)
		end
	end
end

local function drive_control(idx)
	local player = game.players[idx]

	if not player.driving then
		local tilename = player.surface.get_tile(math.floor(player.position.x), math.floor(player.position.y)).name

		if tilename == "deepwater" or tilename == "water" then 
			player.character.die()
			return 
		end
	end
end

script.on_event(defines.events.on_player_driving_changed_state, function(event)
	drive_control(event.player_index)
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