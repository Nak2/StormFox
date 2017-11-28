
local max,min,clamp,rad,cos,sin,abs = math.max,math.min,math.Clamp,math.rad,math.cos,math.sin,math.abs
--[[-------------------------------------------------------------------------
ConVar
---------------------------------------------------------------------------]]
-- ConVar value
	local con = GetConVar("sf_sunmoon_yaw")
	function StormFox.GetSunMoonAngle()
		return con and con:GetFloat() or 270
	end

--[[-------------------------------------------------------------------------
Potato protection
---------------------------------------------------------------------------]]
	local avagefps = 1 / RealFrameTime()
	local bi,buffer = 0,0
	local conDetect = 1
	timer.Create("StormFox - PotatoSupport",0.5,0,function()
		if not system.HasFocus() then return end
		if bi < 10 then
			buffer = buffer + 1 / RealFrameTime()
			bi = bi + 1
		else
			avagefps = buffer / bi
			buffer = 0
			local max = math.Clamp(math.Round(avagefps / 8),1,(cookie.GetNumber("StormFox_ultraqt",0) == 0 and 7 or 20))
			conDetect = (conDetect + max) / 2
			bi = 0
		end
	end)
	local con = GetConVar("sf_exspensive")
	function StormFox.GetExspensive()
		local n = con:GetFloat() or 3
		local b = system.HasFocus()
		if n <= 0 then
			-- Detect
			return b and conDetect or 1
		else
			return b and n or max(n / 4,1)
		end
	end
	function StormFox.GetAvageFPS()
		return avagefps or 1 / RealFrameTime()
	end
--[[-------------------------------------------------------------------------
Reliable EyePos
---------------------------------------------------------------------------]]
local eyepos = Vector(0,0,0)
hook.Add("PreDrawTranslucentRenderables","StormFox - EyeFix",function() eyepos = EyePos() end)
function StormFox.GetEyePos()
	return eyepos
end
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
			local HitPos,HitGlass = CreateSkyPillar(ScanPos or eyepos,norm)

			-- From eyepos. No need to use more tracers
			if not ScanPos then
			--	debugoverlay.Box(HitPos or eyepos,Vector(-4,-4,-4),Vector(4,4,4),.5,HitPos and (HitGlass and Color(0,0,255) or Color(255,0,0)) or Color( 0,255,0 ),false)
				return HitPos,HitPos and true or false,HitGlass
			end

			-- Something is in the way
			local trace = ETPos(HitPos or ScanPos,eyepos)
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
				pos = (FadeDistance - pos:DistToSqr(eyepos)) / FadeDistance
			end

			if pos <= 0 then return end -- Throw it out if its 0 or less
			if enviroment[name] and enviroment[name] > pos then -- Check with current varable
				return
			end
			enviroment[name] = pos -- Set it as current
			return
		end
		--[[
		local function debugBox(vec,hit,glass)
			local col = Color(255,255,255,55)
			if glass then
				col = Color(0,0,255,55)
			elseif hit then
				col = Color(255,0,0,55)
			else
				col = Color(0,255,0,55)
			end

			debugoverlay.Box(vec,Vector(-5,-5,-5),Vector(5,5,5),1,col)
		end]]

		local lFilter,lEnv = 0,0
		hook.Add("Think","StormFox - Outdoor Env",function()
			-- Update the soundfilter. This can be a bit slow, so only every 5th second.
				if lFilter <= SysTime() then
					lFilter = SysTime() + 5
					UpdateFilter()
				end
			-- Scan the enviroment
				if lEnv > SysTime() then return end
				local eyepos,eyeang = eyepos,EyeAngles()
				local exp = StormFox.GetExspensive()
				lEnv = SysTime() + clamp( 1 - exp * 0.1,0.2,2)
				table.Empty(enviroment)
				--debugoverlay.Line(eyepos,eyepos + -GetDFn() * 100,lEnv - SysTime(),Color( 255, 255, 255 ),false)
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
--local con1 = GetConVar("sf_enable_ekstra_lightsupport")
local con2 = GetConVar("sf_redownloadlightmaps")
local lastL,nowL = "-","-"
local canRedownload = false
hook.Add("StormFox - NetDataChange","StormFox - lightfix",function(str,var)
	if str ~= "MapLightChar" then return end
	--if not con2 or not con2:GetBool() then return end
	nowL = var
end)
timer.Create("StormFox - Changemaplights",2,0,function()
	if nowL == lastL then return end
	if not canRedownload then return end
	lastL = nowL
	timer.Simple(2,function()
		render.RedownloadAllLightmaps()
	end)
end)
hook.Add("StormFox - PostEntity","StormFox - FixMapBlackness",function()
	timer.Simple(10,function()
		render.RedownloadAllLightmaps()
		canRedownload = true
		print("[StormFox]: Fix lightmap.")
	end)
end)

--[[
hook.Add("HUDPaint","RainDebug2",function()
	surface.SetFont("default")
	surface.SetTextPos(24,120)
	surface.SetTextColor(255,255,255)
	surface.DrawText("HQ: "..StormFox.GetExspensive())
end)]]

--[[-------------------------------------------------------------------------
Tip box
---------------------------------------------------------------------------]]
	local tip,tippos,tip_time,tip_w_h
		local colors = {}
			colors[1] = Color(241,223,221,255)
			colors[2] = Color(78,85,93,255)
			colors[3] = Color(51,56,60)
			colors[4] = Color(47,50,55)
	function StormFox.DisplayTip(x,y,text,time)
		surface.SetFont("GModWorldtip")
		local tw,tl = surface.GetTextSize(text)
		if tw < 260 then
			tip = {text}
			tip_w_h = {tw,tl}
		else
			local words = string.Explode("%s",text,true)
			local current = words[1]
			tip = {}
			local minsize = 0
			for i = 2,#words do
				local csize = surface.GetTextSize((current and current .. " " or "") .. words[i])
				if words[i] == "|" then
					table.insert(tip,current)
					current = nil
				elseif csize >= 260 then
					table.insert(tip,current)
					current = words[i]
				else
					if minsize < csize then
						minsize = csize
					end
					current = (current and current .. " " or "") .. words[i]
				end
			end
			table.insert(tip,current)
			tip_w_h = {minsize,tl * #tip}
		end
		tippos = {x = x,y = y}
		tip_time = time + CurTime()
	end

	local ceil = math.ceil
	hook.Add("DrawOverlay","StormFox - HUDTips",function()
		if not tip then return end
		if tip_time < CurTime() then return end
		surface.SetFont("GModWorldtip")
		local _,tl = surface.GetTextSize("ABCabc")
		surface.SetDrawColor(Color(0,0,0,205))
		local w,h = tip_w_h[1],tip_w_h[2]
		local x,y = tippos.x - w - 8,tippos.y - h / 5
		local offset = 5
		surface.DrawOutlinedRect(x - offset,y - offset,w + offset * 2,h + offset * 2)
		surface.DrawRect(x - offset,y - offset,w + offset * 2,h + offset * 2)
		surface.SetTextColor(colors[1])
		for i,str in ipairs(tip) do
			surface.SetTextPos(x,y + i * tl - tl)
			surface.DrawText(str)
		end
	end)

--[[-------------------------------------------------------------------------
	Effects enabled
---------------------------------------------------------------------------]]
	local EFEnabled = true
	timer.Create("SF_CheckEFEnable",1,0,function()
		local sv_con = GetConVar("sf_allowcl_disableeffects")
		local cl_con = GetConVar("sf_disableeffects")
		if not sv_con or not cl_con then -- Missing convars
			EFEnabled = true
			return
		end
		if not sv_con:GetBool() or not cl_con:GetBool() then
			EFEnabled = true
			return
		end
		EFEnabled = false
	end)

	function StormFox.EFEnabled()
		return EFEnabled
	end