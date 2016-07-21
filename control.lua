global.flycar = {{},{}}

local function build (ent)
	if ent.name == "falcon-1" then
		table.insert(global.flycar[1], ent)
	end
end

local function car_flying ()
	local cars = global.flycar

	for i,vehicle in pairs(cars[1]) do
		if vehicle.valid then
			if vehicle.speed >= 0.3 then
				local idx = vehicle.passenger
				local surface = vehicle.surface
				local fly = {
						  position = vehicle.position,
						  speed = vehicle.speed,
						  orientation = vehicle.orientation,
						  health = vehicle.health
					  }

				vehicle.destroy()
				vehicle = surface.create_entity{
					name = "falcon-2", 
					position = fly.position, 
					force = game.forces.player
				}
				vehicle.orientation = fly.orientation
				vehicle.speed = fly.speed
				vehicle.health = fly.health
				vehicle.passenger = idx

				local shadow = surface.create_entity{
	  		  		name = "falcon-shadow", 
		  		  	position = fly.position, 
		  		  	force = game.forces.neutral
		  	  	}
				shadow.insert({name = "solid-fuel", count = 500})
				shadow.orientation = fly.orientation
				shadow.speed = fly.speed

				for inventorySlot = 1, 3 do
					inventory = vehicle.get_inventory(inventorySlot).get_contents()
					
					for name,count in pairs(inventory) do
						vehicle.insert({name = name, count = count})
					end
				end

				table.insert(cars[2], {vehicle, shadow, 0.1})
			end
		else table.remove(cars[1], i)
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
					j = surface.create_entity{name = "falcon-1", position = fly.position, force = game.forces.player}
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