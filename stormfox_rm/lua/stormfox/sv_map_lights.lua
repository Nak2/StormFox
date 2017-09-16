local light_spot = {}

-- Functions
	local function shuffle(array)
	    local n, random, j = #array, math.random
	    for i = 1, n do
	        j,k = random(n), random(n)
	        array[j],array[k] = array[k],array[j]
	    end
		return array
	end
	local scanned = false
	local function ScanForLights()
		light_spot = ents.FindByClass("light_spot")
		light_spot = shuffle(light_spot)
		light_spot = shuffle(light_spot)
		scanned = true
	end
timer.Simple(4,ScanForLights)

local SwitchID,TurnOn = -1,nil
local randomWait = 1
local a = math.random(10,20)

hook.Add("Think","StormFox - LightEntities",function()
	if not scanned then return end
	local l = StormFox.GetDaylightAmount()
	if l > 0.5 then
		-- Sun
		if TurnOn or TurnOn == nil then
			TurnOn = false
			SwitchID = 1
		end
	else
		-- Night
		if not TurnOn then
			TurnOn = true
			SwitchID = 1
		end
	end

	if SwitchID < 1 then return end
	if randomWait > SysTime() then return end
	if a < 1 then
		randomWait = SysTime() + (math.random(1,2) / 5)
		a = math.random(10,20)
	else
		a = a - 1
	end
	if not light_spot[SwitchID] then -- No lightspots .. end function
		SwitchID = -1 return
	end
	--print("Light ",SwitchID,TurnOn,light_spot[SwitchID]:EntIndex())
	if IsValid(light_spot[SwitchID]) then
		light_spot[SwitchID]:Fire(TurnOn and "TurnOn" or "TurnOff")
	end
	SwitchID = SwitchID + 1
end)