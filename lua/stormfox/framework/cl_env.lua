
local max,min,clamp,rad,cos,sin = math.max,math.min,math.Clamp,math.rad,math.cos,math.sin

--[[-------------------------------------------------------------------------
Outdoor varables
---------------------------------------------------------------------------]]
local FadeDistance = 160^2
-- Filters
local filter = {}
local function UpdateFilter()
	if not LocalPlayer() then return end
	filter = player.GetAll()
	table.insert(filter,LocalPlayer():GetViewEntity() or LocalPlayer())
end
-- Easy tracers
local function ETPos(pos,pos2,mask)
	local t = util.TraceLine( {
	start = pos,
	endpos = pos2,
	mask = mask or LocalPlayer(),
	filter = filter
	} )
	t.HitPos = t.HitPos or (pos + pos2)
	return t
end
local function IsHitGlass(traceData)
	-- Check if we hit anything 'useless'
	if not traceData.Hit then return false end
	-- Check entity
	if traceData.Entity then
		local m = string.lower(traceData.Entity:GetModel() or "*empty*")
		if string.match(m,"window") or string.match(m,"glass") then return true end
	end
	-- Check texture
	local hittext = string.lower(traceData.HitTexture or "*empty*")
	if string.match(hittext,"window") or string.match(hittext,"glass") then return true end
	return false
end
-- Get downfall norm
local function GetDFn() -- direction of rain
	local Gauge = StormFox.GetData("Gauge",0)
	local wind = StormFox.GetData("Wind",0)
	local windangle = StormFox.GetData("WindAngle",0)
	local downspeed = -max(1.56 * Gauge + 1.22,10) -- Base on realworld stuff .. and some tweaking (Was too slow)
		downfallNorm = Angle(0,windangle,0):Forward() * wind
		downfallNorm.z = downfallNorm.z + downspeed
	return downfallNorm
end
-- Calculate sky "pillars" to determine the environment by tracing up and down
--[[Returns:
		vector 	The positions if its not free
		Is it glass it hit?
]]
local function CreateSkyPillar(originalpos,norm)
	local p = originalpos
	if not norm then norm = Vector(0,0,1) end
	-- Find skybox
		local checkEasy = ETPos(originalpos,originalpos + norm * 16384)
		if checkEasy.HitSky then return nil end
		local t = 4
		local startpos = checkEasy.HitPos
		local skypos = nil
		while not checkEasy.HitSky and t > 0 do
			t = t - 1
			startpos = startpos + norm * 10
			local checkEasy2 = ETPos(startpos,startpos + norm * 16384)
			if checkEasy2.HitSky then
				-- There you are
				skypos = checkEasy2.HitPos
				break
			else
				if checkEasy2.Entity and checkEasy2.HitNonWorld then -- Hit entity
					startpos = checkEasy2.HitPos
				else
					startpos = checkEasy2.HitPos
				end
			end
		end
	if not skypos then return p + norm * 16384,false end -- Eh, too many layers or so far away. Can't be important.
	-- Alright .. lets trace down from the sky
	local eagleeye = ETPos(skypos,p,MASK_SHOT) -- Mask shoot to ignore fences
	if eagleeye.Hit then
		return eagleeye.HitPos,IsHitGlass(eagleeye) and true or false
	end
	return nil --eagleeye.HitPos
end

--[[
	Returns:
	arg 1
		Vector if hit
	arg 2
		Is something between me and the pos the way
	arg3
		Is it glass?
]]
local function HandleSkyPillar(ScanPos,norm,db)
	local HitPos,HitGlass = CreateSkyPillar(ScanPos or EyePos(),norm)

	-- From eyepos. No need to use more tracers
	if not ScanPos then
	--	debugoverlay.Box(HitPos or eyepos,Vector(-4,-4,-4),Vector(4,4,4),.5,HitPos and (HitGlass and Color(0,0,255) or Color(255,0,0)) or Color( 0,255,0 ),false)
		return HitPos,HitPos and true or false,HitGlass
	end

	-- Something is in the way
	local trace = ETPos(HitPos or ScanPos,EyePos())
	--debugoverlay.Line(HitPos or ScanPos,eyepos,4,Color( 255, 255, 255 ),false)
	if trace.Hit then
		HitPos = trace.HitPos
	end
	--debugoverlay.Box(HitPos or ScanPos,Vector(-4,-4,-4),Vector(4,4,4),.5,HitPos and Color(255,0,0) or Color( 0,255,0 ),false)
	return HitPos, trace.Hit, IsHitGlass(trace)
end
-- Allow varables to be set
local enviroment = {}
local function AddEnvData(name,pos)
	if type(pos) == "boolean" and pos then
		enviroment[name] = true
		return
	end
	if not pos then return end
	if type(pos) == "Vector" then
		pos = (FadeDistance - pos:DistToSqr(EyePos())) / FadeDistance
	end

	if pos <= 0 then return end -- Throw it out if its 0 or less
	if enviroment[name] and enviroment[name] > pos then -- Check with current varable
		return
	end
	enviroment[name] = pos -- Set it as current
	return
end

local lFilter,lEnv = 0,0
hook.Add("Think","StormFox - Outdoor Env",function()
	-- Update the soundfilter. This can be a bit slow, so only every 5th second.
	if lFilter <= CurTime() then
		lFilter = CurTime() + 5
		UpdateFilter()
	end
	-- Scan the enviroment
	if lEnv > CurTime() then return end
	local eyepos,eyeang = EyePos(),EyeAngles()

	-- local exp = StormFox.GetExpensive() -- NOTE: If bad computers are still having problems on low settings we can add something to change this time interval
	lEnv = CurTime() + 1.3 -- clamp( 1 - exp * 0.1,0.2,2)
	table.Empty(enviroment)
	--debugoverlay.Line(eyepos,eyepos + -GetDFn() * 100,lEnv - CurTime(),Color( 255, 255, 255 ),false)
	-- Check the players head
	local overhead,_,underglass = HandleSkyPillar(nil)
	if not overhead then
		AddEnvData("Outside",true)
	else
		--debugoverlay.Box(overhead,Vector(-5,-5,-5),Vector(5,5,5),1,Color( 255, 255, 255 ))
	end
	-- Check the direct rain
	local dir_overhead,_,glass = HandleSkyPillar(nil,-GetDFn())
	if not dir_overhead then
		AddEnvData("InRain",true)
	else
		--debugoverlay.Box(dir_overhead,Vector(-5,-5,-5),Vector(5,5,5),1,Color( 255, 255, 255 ))
	end

	if overhead or dir_overhead then
		if underglass or glass then
			AddEnvData("Window",dir_overhead)
			AddEnvData("Window",overhead)
		else
			--AddEnvData("Roof",dir_overhead)
			AddEnvData("Roof",overhead)
		end
	end
	if not dir_overhead then hook.Call("StormFox - EnvUpdate") return end -- No need to check indoor things

	-- Scan infront (Just in case)
	local r = rad(eyeang.y)
	local pos = eyepos + Vector(cos(r) * 250,sin(r) * 250,0)
	local result,in_the_way,is_glass = HandleSkyPillar(pos,-GetDFn())
	--debugBox(result or pos,in_the_way,is_glass)
	if not result and not in_the_way then
		AddEnvData("NextToOutside",true)
	elseif is_glass then
		AddEnvData("Window",vec)
	end
	-- Scan around
		local n = clamp(exp * 4 - 1,4,16)
		for i = 0,n do
			local r = rad(i * (360 / (n + 1)))
			local pos = eyepos + Vector(cos(r) * 250,sin(r) * 250,0)
			local result,in_the_way,is_glass = HandleSkyPillar(pos,-GetDFn())

			--debugBox(result or pos,in_the_way,is_glass)
			if is_glass then
				AddEnvData("Window",result)
			elseif not wall_hit and not in_the_way then
				AddEnvData("NextToOutside",true)
			end
		end
	hook.Call("StormFox - EnvUpdate")
end)

-- Easy functions
StormFox.Env = {}
function StormFox.Env.IsOutside()
	return enviroment.Outside or false
end
function StormFox.Env.IsInRain()
	return enviroment.InRain or false
end
function StormFox.Env.NearOutside()
	return enviroment.NextToOutside or false
end
-- Returns a varable from 1 ro 0
function StormFox.Env.FadeDistanceToWindow()
	return enviroment.Window or 0
end
function StormFox.Env.FadeDistanceToRoof()
	return enviroment.Roof or 0
end

--[[-------------------------------------------------------------------------
Non light_env support
---------------------------------------------------------------------------]]
local t,oml = 0,-1
local abs = math.abs
hook.Add("Think","StormFox - light_env support",function()
	if not StormFox.ClientSettings.redownload_lightmap then return end
	if t > CurTime() then return end
		t = CurTime() + 15
	local ml = StormFox.GetData("MapLight",0)
	if abs(ml - oml) < 32 then return end
	oml = ml
	MsgN("Redownloading light maps")
	render.RedownloadAllLightmaps()
end)
