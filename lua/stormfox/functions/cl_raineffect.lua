
local clamp,min,max,ran,sin,cos,rad,ran,abs = math.Clamp,math.min,math.max,math.random,math.sin,math.cos,math.rad,math.random,math.abs
local rainmat = Material("stormfox/raindrop.png","noclamp smooth")
local rainmat_multi = Material("stormfox/raindrop-multi.png","noclamp smooth")
local snowmat_multi = Material("stormfox/snow-multi.png","noclamp smooth")
local snowmat = Material("particle/snow")
local rainmat_smoke = Material("particle/smokesprites_000"..ran(1,5))

local particles = {}
	particles.main = {}
	particles.bg = {}

local rain_range = 250
local random_side = 400
local downfallNorm,uptimer = Vector(0,0,1),0
local SysTime = SysTime
local EyePos,EyeAngles = EyePos,EyeAngles
local LocalPlayer = LocalPlayer

-- Do the math outside
	hook.Add("Think","StormFox - DownfallUpdater",function()
		if uptimer > SysTime() then return end
		uptimer = SysTime() + 1
		local Gauge = StormFox.GetData("Gauge",0)
		if Gauge <= 0 then return end

		local wind = StormFox.GetData("Wind",0)
		local windangle = StormFox.GetData("WindAngle",0)

		local downspeed = -max(1.56 * Gauge + 1.22,10) -- Base on realworld stuff .. and some tweaking (Was too slow)
		downfallNorm = Angle(0,windangle,0):Forward() * wind
			downfallNorm.z = downfallNorm.z + downspeed
	end)

-- Downfall functions
	local function ETPos(pos,pos2,mask)
		local t = util.TraceLine( {
		start = pos,
		endpos = pos2,
		mask = mask or LocalPlayer(),
		filter = LocalPlayer():GetViewEntity() or LocalPlayer()
		} )
		t.HitPos = t.HitPos or (pos + pos2)
		return t
	end

	function ET(pos,pos2,mask)
		local t = util.TraceLine( {
		start = pos,
		endpos = pos + pos2,
		mask = mask or LocalPlayer(),
		filter = LocalPlayer():GetViewEntity() or LocalPlayer()
		} )
		t.HitPos = t.HitPos or (pos + pos2)
		return t
	end

	local function ETHull(pos,pos2,size,mask)
		local t = util.TraceHull( {
			start = pos,
			endpos = pos + pos2,
			maxs = Vector(size,size,4),
			mins = Vector(-size,-size,0),
			mask = mask or LocalPlayer(),
			filter = LocalPlayer():GetViewEntity() or LocalPlayer()
			} )
		return t
	end

	local function ETCalcTrace(pos,size,fDN)
		if not size then size = 1 end
		local sky = ET(pos, fDN * -16384) --, MASK_SHOT)
		if not sky.HitSky and sky.HitTexture != "TOOLS/TOOLSINVISIBLE" then
			return nil
		end -- Not under sky
		--PrintTable(ET(sky.HitPos,pos))
		--PrintTable(ET(sky.HitPos - Vector(0,0,5),pos))
		local btr = ETPos(sky.HitPos + fDN,pos  + fDN)
		if btr.Hit then return nil end -- Trace was inside world .. but backtrace checked it

		-- We got a valid position now .. for now
		local t_ground = ETHull(pos ,fDN * 16384 ,size , MASK_SHOT )
		if not t_ground.Hit then return nil,"No ground found" end -- Outside the world

		-- Checl fpr water
		local wtr = ETPos(t_ground.StartPos,t_ground.HitPos,-1)
		if wtr.Hit and string.find(wtr.HitTexture:lower(),"water") then
			t_ground = wtr
			t_ground.HitWater = true
		else
			t_ground.HitWater = false
		end
		return t_ground
	end

-- Create Downfall drops
	local canSnow = 0
	local FrameTime = FrameTime
	hook.Add("Think","StormFox - RenderFalldownThink",function()
		local temp = StormFox.GetData("Temperature",20)
		local Gauge = StormFox.GetData("Gauge",0)
		local raindebug = StormFox.GetData("Raindebug",false)
		if Gauge <= 0 then return end

		local lp = LocalPlayer()
		if not lp then return end

		local pos,ang = EyePos(),EyeAngles()
		local angf = ang:Forward()
			angf.z = 0

		local mainpos = pos + angf * (rain_range * 0.8)
			mainpos.z = mainpos.z + ran(rain_range * 1, rain_range * 1.2)

		local skytrace = ET(lp:GetShootPos(),Vector(0,0,9000),lp)
		if skytrace.HitSky then
			mainpos.z = math.min(mainpos.z,skytrace.HitPos.z - 10)
		else
			-- Lets try and find this skybox .. or it will look strange
			local l = 4 -- 4 tries .. after all this is in think
			while l > 0 do
				l = l - 1
				skytrace = ET(skytrace.HitPos + Vector(0,0,1),Vector(0,0,9000),lp)
				if skytrace.HitSky then
					mainpos.z = math.min(mainpos.z,skytrace.HitPos.z - 10)
					break
				end
			end

		end

		-- Choose rain or snow
		local IsRain = true
		if temp < 5 then
			if temp < -2 then
				IsRain = false
			else
				-- Choose
				IsRain = temp > ran(-2,5)
			end
		end

		-- Calk max
		local exp = StormFox.GetExspensive()
		local maxparticles = max(exp,1) * 64

		local weight = IsRain and 1 or 0.2
		local fDN = Vector(downfallNorm.x,downfallNorm.y,downfallNorm.z * weight)
		local windoffset = fDN * (rain_range * 1)

		if #particles.main < maxparticles then
			local maxmake = maxparticles - #particles.main
			local m = maxmake * FrameTime() * Gauge * 2

			for i = 1,min(m,maxmake) do
				-- Make a rain/snowdrop

				local testpos = mainpos + Vector(ran(-random_side,random_side) + fDN.x * -(20 / weight) ,ran(-random_side,random_side) + fDN.y * -(20 / weight),1 / weight * 30)
					testpos.z = math.min(testpos.z,mainpos.z)
				local tr = ETCalcTrace(testpos,IsRain and 4 or clamp(20 - Gauge * 2,0,16),fDN)
				if tr then
					local drop = {}
					-- StartPos
						drop.pos = testpos
					-- Norm
						drop.norm = fDN
					-- Random
						drop.length_m = ran(1,2)
						drop.size = clamp(Gauge / ran(3,5),1,3)
					-- EndPos
						drop.endpos = tr.HitPos
					-- HitNormal
						drop.hitnorm = tr.HitNormal
					-- HitWater
						drop.hitwater = tr.HitWater
					-- NoDrop
						drop.nodrop = string.find(tr.HitTexture,"TOOLS/TOOLSSKYBOX") or string.find(tr.HitTexture,"TOOLS/TOOLSINVISIBLE") or false
						drop.alive = true
						drop.r = ran(360)
						drop.r2 = ran(10)
						drop.ang = fDN:Angle()
						drop.rain = IsRain
					table.insert(particles.main,drop)
					--if raindebug then
						--debugoverlay.Cross(testpos,10,0.1,Color(0,255,0))
						--debugoverlay.Cross(tr.HitPos,10,0.1,Color(255,255,255))
					--end
				end
			end
		end

		local maxbg = 32 + ((exp - 4) * 64)
		if not IsRain then maxbg = maxbg * 0.5 end
		if #particles.bg < maxbg then
			local maxmake = maxbg - #particles.bg
			local m = maxmake * FrameTime() * Gauge

			for i = 1,min(m,maxmake) do
				local s = ran(1,4)
				local xx = 0
				local yy = 0
				local mindistance = random_side
				if s == 1 then
					xx = ran(mindistance,random_side * 4)
					yy = ran(random_side * -2,random_side * 2)
				elseif s == 2 then
					xx = ran(mindistance,random_side * 4) * -1
					yy = ran(random_side * -2,random_side * 2)
				elseif s == 3 then
					yy = ran(mindistance,random_side * 4)
					xx = ran(random_side * -2,random_side * 2)
				elseif s == 4 then
					yy = ran(mindistance,random_side * 4) * -1
					xx = ran(random_side * -2,random_side * 2)
				end

				local testpos = mainpos + Vector(xx + fDN.x * -(20 / weight) ,yy + fDN.y * -(20 / weight),1 / weight * 30)
				local tr = ETCalcTrace(testpos,IsRain and 4 or clamp(96 - Gauge * 2,0,96),fDN)
				if tr then
					local drop = {}
					local smoke = ran(1,5) > 4
						drop.pos = testpos
						drop.norm = fDN
						drop.smoke = smoke
						drop.size = clamp(Gauge / ran(3,5),1,3) * (IsRain and 10 or 32)
						drop.length_m = ran(2,4)
						drop.endpos = tr.HitPos
						drop.hitnorm = tr.HitNormal
						drop.hitwater = string.find(tr.HitTexture,"water")
						drop.nodrop = string.find(tr.HitTexture,"TOOLS/TOOLSSKYBOX") or string.find(tr.HitTexture,"TOOLS/TOOLSINVISIBLE") or false
						drop.alive = true
						drop.r = ran(360)
						drop.r2 = ran(10)
						drop.ang = fDN:Angle()
						drop.rain = IsRain
					table.insert(particles.bg,drop)
					--if raindebug then
						--debugoverlay.Cross(testpos,10,0.1,Color(0,255,0))
						--debugoverlay.Cross(tr.HitPos,10,0.1,Color(255,255,255))
					--end
				end
			end
		end
	end)

local screenParticles = {}
local l = 0
local w = 0
local rand = math.Rand
local viewAmount = 0
local rainAmount = 0
local snow_particles = {(Material("particle/smokesprites_0001")),(Material("particle/smokesprites_0002")),(Material("particle/smokesprites_0003"))}
local rain_particles = { (Material("stormfox/effects/raindrop")), (Material("stormfox/effects/raindrop2"))}--, (Material("stormfox/effects/raindrop2")) }
-- Create 2D raindrops
	hook.Add("Think","StormFox - RenderFalldownScreenThink",function()
		if not LocalPlayer() then return end
		if LocalPlayer():WaterLevel() >= 3 then
			if #screenParticles > 0 then
				table.Empty(screenParticles)
			end
			return
		end
		if l > SysTime() then return end
		-- Bin old particles
			for i = #screenParticles,1,-1 do
				if screenParticles[i].life < SysTime() then
					table.remove(screenParticles,i)
				end
			end
		-- Safty first
			if #screenParticles > 200 then return end
		-- Is it even raining?
			local Gauge = StormFox.GetData("Gauge",0)
			if Gauge <= 0 then return end
		-- Are you standing in the rain?
			if not StormFox.Env.IsInRain() then return end
		-- Get the temp and type
			local temp = StormFox.GetData("Temperature",20)
			local rain = true
			if temp < 5 then
				if temp < -2 then
					rain = false
				else
					-- Choose
					if not (temp > ran(-2,5) )then
						rain = false
					end
				end
			end
		-- Get the dot
			local fDN = Vector(downfallNorm.x,downfallNorm.y,downfallNorm.z * 1)
				fDN:Normalize()
			local a = EyeAngles():Forward():Dot(fDN)
		viewAmount = -a
		if viewAmount <= 0 then viewAmount = 0 return end
		rainAmount = max((10 - Gauge) / 10,0.1) -- 0 in heavy rain, 1 in light
		-- Next rainrop
			l = SysTime() + rand(rainAmount,rainAmount * 2) / viewAmount * 0.01
		local drop = {}
			drop.life = SysTime() + ran(0.4,1)
			drop.x = ran(ScrW())
			drop.y = ran(ScrH())
			drop.size = 25 + rand(2,3) * Gauge
			drop.weight = ran(0,1)
			drop.rain = rain
			drop.r = ran(360)
			drop.p = rain and ran(1,#rain_particles) or ran(1,#snow_particles)
		table.insert(screenParticles,drop)
	end)

-- 2D rainscreenfunctions
	local ceil = math.ceil
	local function drawSemiRandomUV(x,y,w,h,length,height)
		local nw = ceil(w / length)
		local nh = ceil(h / height)
		local flipi = 0
		local flip = 1
		local flipy = 1
		for ih = 1,nh do
			for i = 1,nw do
				flipi = flipi + 1
				if flipi == 2 then
					flip = 1 - flip
				end
				if flipi > 3 then
					flipy = 1 - flipy
				end
				surface.DrawTexturedRectUV(x + (i - 1) * length,y + (ih - 1) * height,length,height,1 - flip,1 - flipy,flip,flipy)
			end
		end
	end

local RainScreen_RT = GetRenderTarget("StormFox RainScreenRT",ScrW(),ScrH())
local ScreenDummy = Material("stormfox/effects/rainscreen_dummy")
local mat_Copy		= Material( "pp/fb" )
local rainscreen_mat = Material("stormfox/effects/rainscreen")
local old_raindrop = Material("sprites/heatwave")
-- Draw drain on screen
	local rainscreen_alpha = 0
	local icescreen_alpha = 0
	hook.Add("HUDPaint","StormFox - RenderRainScreen",function()
		if not LocalPlayer() then return end
		local con = GetConVar("sf_allow_raindrops")
		if con and not con:GetBool() then return end

		local Gauge = StormFox.GetData("Gauge",20)
		if LocalPlayer():WaterLevel() >= 3 then rainscreen_alpha = 0.8 return end
		local ft = RealFrameTime()
		local temp = StormFox.GetData("Temperature",20)
		
		local acc = (viewAmount * clamp(temp - 4,0.1,(Gauge / 200))) * ft * 10
		if acc <= 0 or not StormFox.Env.IsInRain() then
			acc = -0.4 * ft
		end
		rainscreen_alpha = clamp(rainscreen_alpha + acc,0,0.8)
		if rainscreen_alpha <= 0 then return end
		--if true then return end
		cam.Start2D()
		local w,h = ScrW(),ScrH()
		local scale = 256 * 1
		-- Copy the backbuffer to the screen effect texture
		render.UpdateScreenEffectTexture()
		-- Render the screen
		local OldRT = render.GetRenderTarget()
			ScreenDummy:SetFloat( "$translucent", 1 )
			ScreenDummy:SetFloat( "$alpha", 1 - rainscreen_alpha )
			ScreenDummy:SetFloat( "$vertexalpha", 1 )
			render.SetRenderTarget( RainScreen_RT )
				render.SetMaterial( mat_Copy )
				render.DrawScreenQuad()
		-- Reset
		render.SetRenderTarget( OldRT )
		-- Draw raindrops
			surface.SetDrawColor(255,255,255)
			surface.SetMaterial(rainscreen_mat)
			drawSemiRandomUV(0,0,w,h,scale,scale)
		-- Override screen with old and draw
			ScreenDummy:SetTexture("$basetexture",RainScreen_RT)
		cam.End2D()
		render.SetMaterial(ScreenDummy)
		render.DrawScreenQuad()
	end)

	hook.Add("HUDPaint","StormFox - RainScreenEffect",function()
		surface.SetDrawColor(255,255,255)
		local grav = max(50 -  abs(EyeAngles().p),0) / 60 --Gravity the raindrops
		local con = GetConVar("sf_allow_raindrops")
		local oldrain = con and not con:GetBool() or false
		local ms = 1
		if oldrain then
			ms = 2
		end
		for i,d in ipairs(screenParticles) do
			if d.rain then
				surface.SetDrawColor(255,255,255)
				surface.SetMaterial(oldrain and old_raindrop or rain_particles[d.p or 1])
				surface.DrawTexturedRect(d.x,d.y,d.size * ms,d.size * 1.2 * ms)
				screenParticles[i].y = d.y + grav * d.weight * 100 * FrameTime()
			else
				local ll = d.life - SysTime()
				surface.SetDrawColor(255,255,255,55 * ll)
				surface.SetMaterial(snow_particles[d.p])
				surface.DrawTexturedRectRotated(d.x,d.y,d.size + d.weight * 5,d.size + d.weight * 5,d.r)
				screenParticles[i].y = d.y + grav * d.weight * 100 * FrameTime()
			end
			screenParticles[i].weight = max(screenParticles[i].weight - rand(1,0.2) * FrameTime(),0.01)
		end
	end)
--[[]]

-- ParticleEmiters
	_STORMFOX_PEM = _STORMFOX_PEM or ParticleEmitter(Vector(0,0,0),true)
	_STORMFOX_PEM2d = _STORMFOX_PEM2d or ParticleEmitter(Vector(0,0,0))
	_STORMFOX_PEM:SetNoDraw(true)
	_STORMFOX_PEM2d:SetNoDraw(true)

-- Handle raindrops
local rainsplash_w = Material("effects/splashwake3")
local rainsplash = Material("effects/splash4")
local last = SysTime()
hook.Add("Think","StormFox - RenderFalldownHanlde",function()
	local FT = (SysTime() - last) * 100
		last = SysTime()
	local exp = StormFox.GetExspensive()
	local wind = StormFox.GetData("Wind",0)
	local Gauge = StormFox.GetData("Gauge",0)
	local eyepos = EyePos()
	if LocalPlayer():WaterLevel() >= 3 then return end
	--local sky_col = StormFox.GetData("Bottomcolor",Color(204,255,255))
	--	sky_col = Color(max(sky_col.r,24),max(sky_col.g,155),max(sky_col.b,155),155)
	local sky_col = Color(255,255,255)
	for id,data in ipairs(particles.main) do
		if data.alive then
			local speed = data.norm * -FT
			if data.pos.z <= data.endpos.z + speed.z + data.size / 2 or data.pos.z < eyepos.z - 100 then
				data.alive = false
				if exp >= 4 and ran(4) < 2 and not data.nodrop then
					-- Splash
					if data.rain then
						if data.hitwater then
							local p = _STORMFOX_PEM:Add(rainsplash_w,data.endpos + Vector(0,0,1))
								p:SetAngles(data.hitnorm:Angle())
								p:SetStartSize(8)
								p:SetEndSize(40)
								p:SetDieTime(1)
								p:SetEndAlpha(0)
								p:SetStartAlpha(4)
						else
							local p = _STORMFOX_PEM:Add(rainsplash,data.endpos + Vector(0,0,1))
								p:SetAngles(data.hitnorm:Angle())
								p:SetStartSize(4)
								p:SetEndSize(10)
								p:SetDieTime(0.2)
								p:SetEndAlpha(0)
								p:SetStartAlpha(40)
							--	p:SetColor(sky_col)

							local p2 = _STORMFOX_PEM:Add(rainsplash,data.endpos + Vector(0,0,1))
								p2:SetAngles((-data.hitnorm):Angle())
								p2:SetStartSize(4)
								p2:SetEndSize(10)
								p2:SetDieTime(0.2)
								p2:SetEndAlpha(0)
								p2:SetStartAlpha(40)
						--		p2:SetColor(sky_col)
						end
					else
						-- Snow
						if data.hitwater then
							local p = _STORMFOX_PEM:Add(rainsplash_w,data.endpos + Vector(0,0,1))
							p:SetAngles(data.hitnorm:Angle())
							p:SetStartSize(8)
							p:SetEndSize(40)
							p:SetDieTime(1)
							p:SetEndAlpha(0)
							p:SetStartAlpha(4)
						else
							local p = _STORMFOX_PEM2d:Add(snowmat,data.endpos + Vector(0,0,1))
							p:SetStartSize(min(1.5,data.size))
							p:SetEndSize(min(1.5,data.size))
							p:SetDieTime(4)
							p:SetEndAlpha(0)
							p:SetStartAlpha(200)
						end
					end
				end
			else
				data.pos = data.pos - speed
			end
		end
	end
	for i = #particles.main,1,-1 do
		if not particles.main[i].alive then
			table.remove(particles.main,i)
		end
	end

	local pf = function( part, hitpos, hitnormal ) --This is an in-line function
		part:SetDieTime(0)
	end

	for id,data in ipairs(particles.bg) do
		if data.alive then
			local speed = data.norm * -FT


			if data.pos.z <= data.endpos.z + speed.z + data.size / 2 or data.pos.z < eyepos.z - 100 then
				data.alive = false
				if exp >= 4 and ran(4) < 2 and not data.nodrop then
					-- Splash
					if data.rain then
						if true then
							local p = _STORMFOX_PEM2d:Add(rainmat_smoke,data.endpos + Vector(0,0,ran(30,40)))
									p:SetAngles(data.hitnorm:Angle())
									p:SetStartSize(50)
									p:SetEndSize(60)
									p:SetDieTime(ran(2,5))
									p:SetEndAlpha(0)
									p:SetStartAlpha( max(1000 / _STORMFOX_PEM2d:GetNumActiveParticles(),6) )
									p:SetColor(255,255,255)
									p:SetGravity(Vector(0,0,ran(4)))
									p:SetCollide(true)
									p:SetBounce(0)
									p:SetAirResistance(20)
									p:SetVelocity(Vector(downfallNorm.x * wind * 1,downfallNorm.y * 1 * wind,0))
									p:SetCollideCallback( pf )
								--	p:SetStartLength(1)
						else
							if data.hitwater then
								local p = _STORMFOX_PEM:Add(rainsplash_w,data.endpos + Vector(0,0,1))
									p:SetAngles(data.hitnorm:Angle())
									p:SetStartSize(8)
									p:SetEndSize(30)
									p:SetDieTime(1)
									p:SetEndAlpha(0)
									p:SetStartAlpha(50)
									p:SetColor(sky_col)
							else
								local p = _STORMFOX_PEM:Add(rainsplash,data.endpos + Vector(0,0,1))
									p:SetAngles(data.hitnorm:Angle())
									p:SetStartSize(4)
									p:SetEndSize(10)
									p:SetDieTime(0.2)
									p:SetEndAlpha(0)
									p:SetStartAlpha(200)
									p:SetColor(sky_col)

								local p2 = _STORMFOX_PEM:Add(rainsplash,data.endpos + Vector(0,0,1))
									p2:SetAngles((-data.hitnorm):Angle())
									p2:SetStartSize(4)
									p2:SetEndSize(10)
									p2:SetDieTime(0.2)
									p2:SetEndAlpha(0)
									p2:SetStartAlpha(200)
									p2:SetColor(sky_col)
							end
						end
					else
						-- Snow
						if data.hitwater then
							local p = _STORMFOX_PEM:Add(rainsplash_w,data.endpos + Vector(0,0,1))
							p:SetAngles(data.hitnorm:Angle())
							p:SetStartSize(8)
							p:SetEndSize(30)
							p:SetDieTime(1)
							p:SetEndAlpha(0)
							p:SetStartAlpha(50)
						else
							local p = _STORMFOX_PEM2d:Add(snowmat,data.endpos + Vector(0,0,1))
							p:SetStartSize(min(1.5,data.size))
							p:SetEndSize(min(1.5,data.size))
							p:SetDieTime(4)
							p:SetEndAlpha(0)
							p:SetStartAlpha(255)
						end
					end
				end
			else
				data.pos = data.pos - speed
			end
		end
	end
	for i = #particles.bg,1,-1 do
		if not particles.bg[i].alive then
			table.remove(particles.bg,i)
		end
	end
end)

-- Render the raindrops
local RenderRain = function(depth, sky)
	--if depth or sky then return end
	--if true then return end
	if LocalPlayer():WaterLevel() >= 3 then return end
	if not StormFox.GetData then return end
	if depth or sky then return end
	_STORMFOX_PEM:Draw()
	_STORMFOX_PEM2d:Draw()
	local raindebug = StormFox.GetData("Raindebug",false)
	local Gauge = StormFox.GetData("Gauge",0)
	local alpha = 75 + min(Gauge * 10,150)

	local sky_col = StormFox.GetData("Bottomcolor",Color(204,255,255))
		sky_col = Color(max(sky_col.r,4),max(sky_col.g,55),max(sky_col.b,55),max(alpha,155))
	for id,data in ipairs(particles.main) do
		if data.rain then
			render.SetMaterial(rainmat)
			local l = data.size * data.length_m
			render.DrawBeam(  data.pos,  data.pos - data.norm * data.size* data.length_m, 10 * data.size, 1, 0, Color(255,255,255,5))
		else
			local d = data.pos.z - data.endpos.z + data.r
			local n = sin(d / 100)
			render.SetMaterial(snowmat)
			local s = data.size
			local nn = clamp(20 - Gauge * 2,0,16)
			render.DrawSprite(data.pos + Vector(n * nn,n * nn,0), s, s,Color(155,155,155))
		end
		if raindebug then
			render.SetMaterial(Material("sprites/sent_ball"))
			render.DrawSprite(data.endpos, 10,10,Color(0,255,0))
		end
	end
	for id,data in ipairs(particles.bg) do
		if data.rain then
			render.SetMaterial(rainmat_multi)
			render.DrawBeam(  data.pos,  data.pos - data.norm * data.size * data.length_m, 10 * data.size, 1, 0, Color(255,255,255,5))
		else
			local d = data.pos.z - data.endpos.z + data.r
			local n = sin(d / 100)
			render.SetMaterial(snowmat_multi)
			local s = data.size * 10
			local nn = clamp(20 - Gauge * 2,0,16)
			render.DrawSprite(data.pos + Vector(n * nn,n * nn,0) + data.ang:Forward() * 10, s, s,Color(255,255,255,55))
		end
		if raindebug then
			render.SetMaterial(Material("sprites/sent_ball"))
			render.DrawSprite(data.endpos, 10,10,Color(255,0,0))
		end
	end
end

hook.Add("PostDrawTranslucentRenderables", "StormFox - RenderFalldown", function(depth,sky)
--	if StormFox.GetOutdoorEnv()["Outdoor"][1] > -1 then
		RenderRain(depth,sky)
--	end
end)
-- Damn you old render engien. Can't use this
--[[
hook.Add("PostDrawOpaqueRenderables", "StormFox - RenderFalldown_inside", function(depth,sky)

end)]]
--

-- Debug rain
--[[
hook.Add("HUDPaint","StormFox - Debug Rain",function()
	surface.SetTextPos(10,40)
	surface.SetFont("Default")
	local temp = StormFox.GetData("Temperature",20)
	local Gauge = StormFox.GetData("Gauge",0)
	local exp = StormFox.GetExspensive()
	local maxparticles = max(exp,1) * 64
	surface.SetTextColor(255,255,255)
	surface.DrawText("Max particles: " .. maxparticles)
	surface.SetDrawColor(255,255,255)
	surface.DrawRect(9,59,102,12)
	surface.SetDrawColor(0,0,0)
	surface.DrawRect(10,60,100,10)
	local p = 100 / maxparticles * #particles.main
	surface.SetDrawColor(2.55 * p,2.55 * (100-p),0)
	surface.DrawRect(10,60,p,10)

	surface.SetTextPos(10,80)
	local maxparticles = max(0,32 + (exp - 4) * 64)
	surface.SetTextColor(255,255,255)
	surface.DrawText("Max particles: " .. maxparticles)
	surface.SetDrawColor(255,255,255)
	surface.DrawRect(9,99,102,12)
	surface.SetDrawColor(0,0,0)
	surface.DrawRect(10,100,100,10)
	local p = 100 / maxparticles * #particles.bg
	surface.SetDrawColor(2.55 * p,2.55 * (100-p),0)
	surface.DrawRect(10,100,p,10)

	surface.SetTextPos(24,200)
	surface.DrawText("Weather quality: " .. exp)
end)]]