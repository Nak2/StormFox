light_spots = { {}, {}, {}, {}, {}, {} }

-- Packs the lights into 5 different waves so they don't all turn off at once. Instead they'll turn off in 6 groups
local function shuffleIntoLightArray( tLights )
	local random = math.random
	for i = 1, #tLights do
		local wave = random( 6 )
		table.insert( light_spots[ wave ], tLights[i] )
	end
end

local scanned = false
local relay_dawn,relay_dusk
local function ScanForLights()
	if scanned then return end
	-- Day relay
	relay_dawn = ents.FindByName( "dawn" );
	table.Add(relay_dawn,ents.FindByName( "day_events" ))
	-- Nmight relay
	relay_dusk = ents.FindByName( "dusk" );
	table.Add(relay_dusk,ents.FindByName( "night_events" ))
	if #relay_dusk > 0 or #relay_dawn > 0 then
		StormFox.SetNetworkData("has_trigger",true)
	end
	-- Locate light
	local tLights = {}
	light_spots = { {}, {}, {}, {}, {}, {} }
	for _,ent in ipairs(ents.FindByClass("light_spot")) do
		local name = ent:GetName() or "night"
		if not string.find(name,"indoor") and (string.find(name,"night") or string.find(name,"1") or string.find(name,"day")) then
			table.insert(tLights,ent)
		end
	end
	shuffleIntoLightArray( tLights )
	scanned = true
end
timer.Simple( 4, ScanForLights )


-- Turn the map lights on/off in waves
local lightState,currentindex = false,0
local clamp = math.Clamp
local nT = 0
timer.Create("StormFox - LightTimer",0.5,0,function()
	if lightState and currentindex > 6 then return end
	if not lightState and currentindex <= 0 then return end
	if nT > CurTime() then return end
	nT = math.random(0.2,2) + CurTime()
	currentindex = clamp(currentindex,1,6)

	local sOnOff = lightState and "TurnOn" or "TurnOff"
	local wave = light_spots[ currentindex ]
	if wave then
		for index = 1, #wave do
			if wave[ index ] and IsValid(wave[ index ]) then
				wave[ index ]:Fire( sOnOff )
			end
		end
	end
	if lightState then
		currentindex = currentindex + 1
	else
		currentindex = currentindex - 1
	end
end)
local function SwitchLights( bTurnOn )
	lightState = bTurnOn
	if bTurnOn then
		currentindex = 1
	else
		currentindex = 6
	end
end

timer.Create("StormFox - Light/Lamp support",2,0,function()
	if not scanned then ScanForLights() end
	local map_light = StormFox.GetData("MapLight",80)
	local on = map_light < 20
	if on and (not _STORMFOX_LIGHTSTATUS or _STORMFOX_LIGHTSTATUS == nil) then
		for _,ent in ipairs(relay_dusk) do
			if IsValid(ent) then
				ent:Fire( "Trigger", "" );
			end
		end
		SwitchLights( true )
		_STORMFOX_LIGHTSTATUS = true
	elseif not on and (_STORMFOX_LIGHTSTATUS or _STORMFOX_LIGHTSTATUS == nil) then
		for _,ent in ipairs(relay_dawn) do
			if IsValid(ent) then
				ent:Fire( "Trigger", "" );
			end
		end
		SwitchLights( false )
		_STORMFOX_LIGHTSTATUS = false
	end
end)