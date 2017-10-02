local light_spots = { {}, {}, {}, {}, {}, {} }

-- Packs the lights into 5 different waves so they don't all turn off at once. Instead they'll turn off in 6 groups
local function shuffleIntoLightArray( tLights )
	local random = math.random
    for i = 1, #tLights do
		local wave = random( 6 )
		table.insert( light_spots[ wave ], tLights[i] )
    end
end

local scanned = false
local function ScanForLights()
	tLights = ents.FindByClass("light_spot")
	shuffleIntoLightArray( tLights )
	scanned = true
end
timer.Simple( 4, ScanForLights )


-- Turn the map lights on/off in waves
local function SwitchLights( bTurnOn, nWave )
	nWave = nWave or 1
	local sOnOff = bTurnOn and "TurnOn" or "TurnOff"

	for index = 1, #light_spots[ nWave ] do
		light_spots[ nWave ][ index ]:Fire( sOnOff )
	end

	if nWave == #light_spots then return end
	timer.Simple( 5, function() -- call the next wave after a delay
		SwitchLights( bTurnOn, nWave + 1 )
	end )
end

hook.Add( "StormFox-Sunrise", "Stormfox-Lights-Off", function()
	SwitchLights( false )
end )

hook.Add( "StormFox-Sunset", "Stormfox-Lights-On", function()
	if not scanned then ScanForLights() end
	SwitchLights( true )
end )