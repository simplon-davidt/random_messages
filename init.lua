--[[
RandomMessages mod by arsdragonfly.
arsdragonfly@gmail.com
6/19/2013
xisd : 14/01/2017
--]]

local modname = minetest.get_current_modname()

math.randomseed(os.time())

random_messages = {}
random_messages.options = {} 	-- Options are stored in this table
random_messages.messages = {} 	-- This table contains all messages.

-- Read config file
dofile(core.get_modpath(modname).."/config.lua")

--Time between two subsequent messages.
-- 0 to use default (120)
local MESSAGE_INTERVAL = random_messages.options.messages_interval
-- Added default messages file
local default_messages_file_name = random_messages.options.default_messages_file_name or "messages"
local display_chat_messages	= random_messages.options.display_chat_messages
local place_messages_signs	= random_messages.options.place_messages_signs

-- Define langage (code from intllib mod)
local LANG = minetest.setting_get("language")
if not (LANG and (LANG ~= "")) then LANG = os.getenv("LANG") end
if not (LANG and (LANG ~= "")) then LANG = "en" end
LANG = LANG:sub(1, 2)

function table.count( t )
	local i = 0
	for k in pairs( t ) do i = i + 1 end
	return i
end

function table.random( t )
	local rk = math.random( 1, table.count( t ) )
	local i = 1
	for k, v in pairs( t ) do
		if ( i == rk ) then return v, k end
		i = i + 1
	end
end

function random_messages.initialize() --Set the interval in minetest.conf.
	minetest.setting_set("random_messages_interval",120)
	minetest.setting_save();
	return 120
end

function random_messages.set_interval() --Read the interval from minetest.conf(set it if it doesn'st exist)
	MESSAGE_INTERVAL = tonumber(minetest.setting_get("random_messages_interval")) or random_messages.initialize()
end

function random_messages.check_params(name,func,params)
	local stat,msg = func(params)
	if not stat then
		minetest.chat_send_player(name,msg)
		return false
	end
	return true
end

function random_messages.read_messages()
	local line_number = 1
	-- Defizne input 
	local input = io.open(minetest.get_worldpath()..'/'..modname,"r")
	-- no input file found (in the world folder)
	if not input then
		-- look a localized default file in (in the mod folder)
		local default_input = io.open(core.get_modpath(modname)..'/'..default_messages_file_name..'.'..LANG..'.txt',"r")
		local output = io.open(minetest.get_worldpath()..'/'..modname,"w")
		if not default_input then
			-- localised file not found, look for a generic default file (in the mod folder)
			default_input = io.open(minetest.get_modpath(modname)..'/'..default_messages_file_name..'.txt',"r")
		end
		if not default_input then
			-- Now we're out of options, blame the admin
			output:write("Blame the server admin! He/She has probably not edited the random messages yet.\n")
			output:write("Tell your dumb admin that this line is in (worldpath)/random_messages \n")
		else
			-- or write default_input content in worldpath message file
			local content = default_input:read("*all")
			output:write(content)
		end
		io.close(output)
		if default_input then io.close(default_input) end
		input = io.open(minetest.get_worldpath()..'/'..modname,"r")
	end
	-- we should have input by now, so lets read it
	for line in input:lines() do
		random_messages.messages[line_number] = line
		line_number = line_number + 1
	end
	-- close it
	io.close(input)
end

function random_messages.display_message(message_number)
	local msg = random_messages.messages[message_number] or message_number
	if msg then
		minetest.chat_send_all(msg)
	end
end

function random_messages.show_message()
	random_messages.display_message(table.random(random_messages.messages))
end

function random_messages.list_messages()
	local str = ""
	for k,v in pairs(random_messages.messages) do
		str = str .. k .. " | " .. v .. "\n"
	end
	return str
end

function random_messages.remove_message(k)
	table.remove(random_messages.messages,k)
	random_messages.save_messages()
end

function random_messages.add_message(t)
	table.insert(random_messages.messages,table.concat(t," ",2))
	random_messages.save_messages()
end

function random_messages.save_messages()
		local output = io.open(minetest.get_worldpath()..'/'..modname,"w")
		for k,v in pairs(random_messages.messages) do
			output:write(v .. "\n")
		end
		io.close(output)
end

--When server starts:
random_messages.set_interval()
random_messages.read_messages()

if display_chat_messages then
	local TIMER = 0
	minetest.register_globalstep(function(dtime)
		TIMER = TIMER + dtime;
		if TIMER > MESSAGE_INTERVAL then
			random_messages.show_message()
			TIMER = 0
		end
	end)
end

local register_chatcommand_table = {
	params = "viewmessages | removemessage <number> | addmessage <number>",
	privs = {server = true},
	description = "View and/or alter the server's random messages",
	func = function(name,param)
		local t = string.split(param, " ")
		if t[1] == "viewmessages" or nil then
			minetest.chat_send_player(name,random_messages.list_messages())
		elseif t[1] == "removemessage" then
			if not random_messages.check_params(
			name,
			function (params)
				if not tonumber(params[2]) or
				random_messages.messages[tonumber(params[2])] == nil then
					return false,"ERROR: No such message."
				end
				return true
			end,
			t) then return end
			random_messages.remove_message(t[2])
		elseif t[1] == "addmessage" then
			if not t[2] then
				minetest.chat_send_player(name,"ERROR: No message.")
			else
				random_messages.add_message(t)
			end
		else
				minetest.chat_send_player(name,"ERROR: Invalid command.")
		end
	end
}

minetest.register_chatcommand("random_messages", register_chatcommand_table)
minetest.register_chatcommand("rmessages", register_chatcommand_table)


-- Place signs in the world with random messages on it
-- Most of the code was adapted from tsm_chests_exemple 

if place_messages_signs then
	-- Height limits to place the signs
	local h_min = random_messages.options.signs.h_min or -200
	local h_max = random_messages.options.signs.h_max or 200
	local signs_per_chunk = random_messages.options.signs.signs_per_chunk or 1


	-- Register cubic sign node if no yard sign
	if minetest.get_modpath("default") 
	and ( not minetest.get_modpath("signs_lib"))
	and ( not minetest.get_modpath("signs")) 	
	then
		minetest.register_node(modname..":sign", {
			description = "Informative Sign",
			tiles = {"default_wood.png^default_sign_wood.png"},
			is_ground_content = true,
			groups = {choppy = 2, flammable = 2, oddly_breakable_by_hand = 3},
			drop = 'default:sign_wall_wood',
			sounds = default.node_sound_wood_defaults(),
			})
	end


	minetest.register_on_generated(function(minp, maxp, seed)
		-- get the water level and convert it to a number
		local water_level = minetest.setting_get("water_level")
		if water_level == nil or type(water_level) ~= "number" then
			water_level = 1
		else
			water_level = tonumber(water_level)
		end

		-- signs minimum and maximum spawn height
		local height_min = water_level + h_min 
		local height_max = water_level + h_max

		if(maxp.y < height_min or minp.y > height_max) then
			return
		end	
		local y_min = math.max(minp.y, height_min)
		local y_max = math.min(maxp.y, height_max)
		for i=1, signs_per_chunk do
			local pos = {x=math.random(minp.x,maxp.x),z=math.random(minp.z,maxp.z), y=minp.y}
			local env = minetest.env

			 -- Find ground level
			local ground = nil
			local top = y_max	
			if env:get_node({x=pos.x,y=y_max,z=pos.z}).name ~= "air" and env:get_node({x=pos.x,y=y_max,z=pos.z}).name ~= "default:water_source" and env:get_node({x=pos.x,y=y_max,z=pos.z}).name ~= "default:lava_source" then
				for y=y_max,y_min,-1 do
					local p = {x=pos.x,y=y,z=pos.z}
					if env:get_node(p).name == "air" or env:get_node(p).name == "default:water_source" or env:get_node(p) == "default:lava_source" then
						top = y
						break
					end
				end
			end
			for y=top,y_min,-1 do
				local p = {x=pos.x,y=y,z=pos.z}
				if env:get_node(p).name ~= "air" and env:get_node(p).name ~= "default:water_source" and env:get_node(p).name ~= "default:lava_source" then
					ground = y
					break
				end
			end
			if(ground~=nil) then
				local sign_pos = {x=pos.x,y=ground+1, z=pos.z}
				local nn = minetest.get_node(sign_pos).name	-- sign node name (before it becomes a sign)
				if nn == "air" then
					-- Replace plants and other buildable to nodes instead of placing on it
					local under = minetest.get_node({x=pos.x, y=ground, z=pos.z}).name
					local under_def = minetest.registered_nodes[under] 
					if under_def and under_def.buildable_to then
						ground = ground - 1
						sign_pos = {x=pos.x,y=ground+1, z=pos.z}
						nn = minetest.get_node(sign_pos).name
					end
					-- Define message to display
					local message_number = table.random(random_messages.messages)
					local msg = random_messages.messages[message_number] or message_number
					if msg then
						-- Define the rest of the sign
						local sign = {}
						if minetest.get_modpath("signs_lib") or	minetest.get_modpath("signs") then
							sign.name = "signs:sign_yard"		
						else
							sign.name = modname..":sign"
						end
						-- secondly: rotate the chest
						-- find possible faces
						local xp, xm, zp, zm
						xp = minetest.get_node({x=pos.x+1,y=ground+1, z=pos.z})
						xm = minetest.get_node({x=pos.x-1,y=ground+1, z=pos.z})
						zp = minetest.get_node({x=pos.x,y=ground+1, z=pos.z+1})
						zm = minetest.get_node({x=pos.x,y=ground+1, z=pos.z-1})

						local facedirs = {}
						if(xp.name=="air" or xp.name=="default:water_source") then
							table.insert(facedirs, minetest.dir_to_facedir({x=-1,y=0,z=0}))
						end
						if(xm.name=="air" or xm.name=="default:water_source") then
							table.insert(facedirs, minetest.dir_to_facedir({x=1,y=0,z=0}))
						end
						if(zp.name=="air" or zp.name=="default:water_source") then
							table.insert(facedirs, minetest.dir_to_facedir({x=0,y=0,z=-1}))
						end
						if(zm.name=="air" or zm.name=="default:water_source") then
							table.insert(facedirs, minetest.dir_to_facedir({x=0,y=0,z=1}))
						end
						
						-- choose a random face (if possible)
						if(#facedirs == 0) then
							minetest.set_node({x=pos.x,y=ground+1, z=pos.z+1},{name=nn})
							sign.param2 = minetest.dir_to_facedir({x=0,y=0,z=1})
						else
							sign.param2 = facedirs[math.floor(math.random(#facedirs))]
						end
								
						-- Lastly: place the sign
						minetest.set_node(sign_pos,sign)
						local meta = minetest.get_meta(sign_pos)
						meta:set_string("text",msg)
						meta:set_string("infotext",msg) 
					end
				end	
			end		
		end		
	end)
end
