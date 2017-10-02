--[[-------------------------------------------------------------------------
	Basic shared functions

---------------------------------------------------------------------------]]
-- Beaufort scale
	local bfs = {}
		bfs[0] = "Calm"
		bfs[0.3] = "Light Air"
		bfs[1.6] = "Light Breeze"
		bfs[3.4] = "Gentle breeze"
		bfs[5.5] = "Moderate breeze"
		bfs[8] = "Fresh breeze"
		bfs[10.8] = "Strong breeze"
		bfs[13.9] = "Near gale"
		bfs[17.2] = "Gale"
		bfs[20.8] = "Strong gale"
		bfs[24.5] = "Storm"
		bfs[28.5] = "Violent Storm"
		bfs[32.7] = "Hurricane"
	local bfkey = table.GetKeys(bfs)
	table.sort(bfkey,function(a,b) return a < b end)

function StormFox.GetBeaufort(ms)
	local n = ms or StormFox.GetData( "Wind" , 0 )
	local Beaufort, Description = 0, "Calm"
	for k,kms in ipairs( bfkey ) do
		if kms < n then
			Beaufort, Description = k - 1, bfs[ kms ]
		else
			break
		end
	end
	return Beaufort, Description
end

-- WeatherData
function StormFox.CelsiusToFahrenheit(num)
	return num * (9 / 5) + 32
end