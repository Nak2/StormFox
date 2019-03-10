
local clamp,min,max,ran,sin,cos,rad,ran,abs = math.Clamp,math.min,math.max,math.random,math.sin,math.cos,math.rad,math.random,math.abs
local rainmat_smoke = {}
for i = 1,5 do
	table.insert(rainmat_smoke,(Material("particle/smokesprites_000" .. i)))
end
-- ParticleEmiters
	_STORMFOX_PEM = _STORMFOX_PEM or ParticleEmitter(Vector(0,0,0),true)
	_STORMFOX_PEM2d = _STORMFOX_PEM2d or ParticleEmitter(Vector(0,0,0))
	_STORMFOX_PEM:SetNoDraw(true)
	_STORMFOX_PEM2d:SetNoDraw(true)

local particles = {}
	particles.main = {}
	particles.bg = {}

local rain_range = 250
local random_side = 400
local downfallNorm = Vector(0,0,1)
local SysTime = SysTime
local EyeAngles = EyeAngles

local raindebug = StormFox.GetNetworkData("Raindebug",false)
local materials = {}
	materials.Rain 				= Material("stormfox/raindrop.png","noclamp smooth")
	materials.RainMultiTexture 	= Material("stormfox/raindrop-multi.png","noclamp smooth")
	materials.RainSmoke 	 	= Material("particle/smokesprites_0001")

	materials.Snow 				= Material("particle/snow")
	materials.SnowSmoke			= Material("particle/smokesprites_0001")
	materials.SnowMultiTexture	= Material("stormfox/snow-multi.png","noclamp smooth")
local snowEnabled,GaugeColor = true,Color(255,255,255)
local wind = StormFox.GetNetworkData("Wind",0) * 0.75
local temp = StormFox.GetNetworkData("Temperature",20)
local Gauge = StormFox.GetData("Gauge",0)
-- Downfall functions
	local util_TraceLine = util.TraceLine
	local util_TraceHull = util.TraceHull
	local function ETPos(pos,pos2,mask)
		local t = util_TraceLine( {
		start = pos,
		endpos = pos2,
		mask = mask,
		filter = LocalPlayer():GetViewEntity() or LocalPlayer()
		} )
		if not t then -- tracer failed, this should not happen. Create a fake result.
			local t = {}
				t.HitPos = pos + pos2
			return t 
		end
		t.HitPos = t.HitPos or (pos + pos2)
		return t
	end

	local function ET(pos,pos2,mask)
		local t = util_TraceLine( {
		start = pos,
		endpos = pos + pos2,
		mask = mask,
		filter = LocalPlayer():GetViewEntity() or LocalPlayer()
		} )
		if not t then -- tracer failed, this should not happen. Create a fake result.
			local t = {}
				t.HitPos = pos + pos2
			return t 
		end
		t.HitPos = t.HitPos or (pos + pos2)
		return t
	end

	local function ETHull(pos,pos2,size,mask)
		local t = util_TraceHull( {
			start = pos,
			endpos = pos + pos2,
			maxs = Vector(size,size,4),
			mins = Vector(-size,-size,0),
			mask = mask or LocalPlayer(),
			filter = LocalPlayer():GetViewEntity() or LocalPlayer()
			} )
		if not t then
			local t = {}
			t.HitPos = pos + pos2
			return t
		end
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
-- Do the math and update stuff outside
	local mainpos = Vector(0,0,0)
	timer.Create("StormFox - MainPos",0.5,0,function()
		if not StormFox.EFEnabled() then return end
		local lp = LocalPlayer()
		if not lp or not IsValid(lp) then return end

		local view = StormFox.GetCalcViewResult()
		local pos,ang = view.pos,view.ang
		local angf = ang:Forward()
			angf.z = 0
		local vel = lp:GetVelocity() * 0.6
			vel.z = 0
		local _tmainpos = pos + angf * (rain_range * 0.8)
			_tmainpos = ET(_tmainpos,Vector(0,0,rain_range - ran(50))).HitPos + (lp:GetShootPos() - lp:GetPos()) * 2 + vel
		if not _tmainpos then return end
		mainpos = _tmainpos
			--debugoverlay.Box(mainpos,Vector(0,0,0),Vector(5,5,5),1,Color( 255, 255, 255 ))
	end)
	timer.Create("StormFox - Downfallupdater",1,0,function()
		if not StormFox.EFEnabled() then return end
		raindebug = StormFox.GetNetworkData("Raindebug",false)
		-- update materials and vars
				materials.Rain 				= StormFox.GetData("RainTexture") or Material("stormfox/raindrop.png","noclamp smooth")
				materials.RainMultiTexture 	= StormFox.GetData("RainMultiTexture") or Material("stormfox/raindrop-multi.png","noclamp smooth")
				materials.RainSmoke 	 	= StormFox.GetData("RainSmoke") or Material("particle/smokesprites_0001")

				materials.Snow 				= StormFox.GetData("SnowTexture") or materials.RainSmoke or materials.Rain or Material("particle/snow")
				materials.SnowSmoke			= StormFox.GetData("SnowSmoke") or Material("particle/smokesprites_0001")
				materials.SnowMultiTexture	= StormFox.GetData("SnowMultiTexture") or materials.RainMultiTexture or Material("stormfox/snow-multi.png","noclamp smooth")
			snowEnabled,GaugeColor = StormFox.GetData("EnableSnow"),StormFox.GetData("GaugeColor") or Color(255,255,255)

		Gauge = StormFox.GetData("Gauge",0)
		temp = StormFox.GetNetworkData("Temperature",20)
		if Gauge <= 0 then return end

		wind = StormFox.GetNetworkData("Wind",0) * 0.75
		local windangle = StormFox.GetNetworkData("WindAngle",0)

		local downspeed = -max(1.56 * Gauge + 1.22,10) -- Base on realworld stuff .. and some tweaking (Was too slow)
		downfallNorm = Angle(0,windangle,0):Forward() * wind
			downfallNorm.z = downfallNorm.z + downspeed
	end)
-- Create Downfall drops
	hook.Add("Think","StormFox - RenderFalldownThink",function()
		if not StormFox.EFEnabled() then return end
		if Gauge <= 0 then return end
		local ft = RealFrameTime()
		-- Choose rain or snow
			local IsRain = true
			if temp < 5 and snowEnabled then
				if temp < -2 then
					IsRain = false
				else
					-- Choose
					IsRain = temp > ran(-2,5)
				end
			end
		-- Calc max particles
			local exp = StormFox.GetExspensive()
			local maxparticles = max(exp,1) * 32

			local maxbg = 32 + max(exp,1) * 16 * (Gauge / 10)
			if not IsRain then maxbg = maxbg * 0.5 end
		-- Calk weight and dir
			local weight = IsRain and 1 or 0.2
			local fDN = Vector(downfallNorm.x,downfallNorm.y,downfallNorm.z) * weight
		-- Create particle
			if #particles.main < maxparticles then
				local maxmake = maxparticles - #particles.main
				local m = maxmake * ft * Gauge * 2
				for i = 1,min(m,maxmake) do
					-- Make a rain/snowdrop

					local testpos = mainpos + Vector(ran(-random_side,random_side) + fDN.x * -(20 / weight) ,ran(-random_side,random_side) + fDN.y * -(20 / weight),1 / weight * 30)
						testpos.z = math.min(testpos.z,mainpos.z) - ran(40)
					local smoke = ran(100) < clamp(wind * 2,0,70) - 14
					local size = IsRain and (smoke and 20 * Gauge or clamp(Gauge / ran(3,5),1,3)) or (smoke and ran(10,30) * Gauge or clamp(Gauge / ran(3,5),1,3))
					local tr = ETCalcTrace(testpos,size,fDN)
					local break_ = IsRain and 1 or max(wind / 25,0.4)
					if tr then
						local drop = {}
							drop.smoke = smoke
						-- StartPos
							drop.pos = testpos
						-- Norm
							drop.norm = fDN * break_
						-- Random
							drop.length_m = ran(1,2)
							drop.size = size
						-- EndPos
							drop.endpos = tr.HitPos
						-- HitNormal
							drop.hitnorm = tr.HitNormal
						-- HitWater
							drop.hitwater = tr.HitWater
						-- NoDrop
							drop.nodrop = string.find(tr.HitTexture,"TOOLS/TOOLSSKYBOX") or string.find(tr.HitTexture,"TOOLS/TOOLSINVISIBLE") or smoke or false
							drop.alive = true
							drop.r = ran(360)
							drop.r2 = ran(10)
							drop.rain = IsRain
							drop.material = smoke and (IsRain and materials.RainSmoke or materials.SnowSmoke) or (IsRain and materials.Rain or materials.Snow)
						table.insert(particles.main,drop)
					end
				end
			end
		-- Create Multi (background) Particle
			if #particles.bg < maxbg then
				local maxmake = maxbg - #particles.bg
				local m = maxmake * ft * Gauge

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
					local smoke = ran(100) < clamp(wind * 2,0,70) - 14
					local size = smoke and (IsRain and 30 or 20 * Gauge) or (clamp(Gauge / ran(3,5),1,3) * (IsRain and 32 or 32))
					local tr = ETCalcTrace(testpos,size,fDN)
					if tr then
						local drop = {}
						local break_ = smoke and (IsRain and 0.5 or 0.7) or 1
							drop.pos = testpos
							drop.norm = fDN * break_
							drop.smoke = smoke
							drop.a = 0
							drop.size = size
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
							drop.material = IsRain and (smoke and materials.RainSmoke or materials.RainMultiTexture) or (smoke and materials.SnowSmoke or materials.SnowMultiTexture)
						table.insert(particles.bg,drop)
						--if raindebug then
							--debugoverlay.Cross(testpos,10,0.1,Color(0,255,0))
							--debugoverlay.Cross(tr.HitPos,10,0.1,Color(255,255,255))
						--end
					end
				end
			end
	end)
-- Handle and kill raindrops
	local rainsplash_w = Material("effects/splashwake3")
	local rainsplash = Material("effects/splash4")
	local last = SysTime()
	local pf = function( part, hitpos, hitnormal )
		part:SetDieTime(0)
	end
	hook.Add("Think","StormFox - RenderFalldownHandle",function()
		if not StormFox.EFEnabled() then return end
		local FT = (SysTime() - last) * 100
			last = SysTime()
		local exp = StormFox.GetExspensive()
		local Gauge = StormFox.GetData("Gauge",0)
		local eyepos = StormFox.GetEyePos()
		if LocalPlayer():WaterLevel() >= 3 then return end
		--local sky_col = StormFox.GetData("Bottomcolor",Color(204,255,255))
		--	sky_col = Color(max(sky_col.r,24),max(sky_col.g,155),max(sky_col.b,155),155)
		local sky_col = Color(255,255,255)
		local snowmat = StormFox.GetData("SnowTexture") or Material("particle/snow")
		for id,data in ipairs(particles.main) do
			if data.alive then
				local speed = data.norm * -FT
				if not data.markfordeath and (data.pos.z <= data.endpos.z + speed.z + data.size / 2 or data.pos.z < eyepos.z - 200) then
					-- mark for death
					data.markfordeath = true
					-- Skip to the bottom
					if data.pos.z >= eyepos.z - 200 then
						data.pos = data.endpos
						data.size = data.size / 2
					else
						data.alive = false
					end
				elseif data.markfordeath then
					data.alive = false
					data.markfordeath = true
					if exp >= 4 and ran(4) < 2 and not data.nodrop and not data.smoke then
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
		for id,data in ipairs(particles.bg) do
			if data.alive then
				local speed = data.norm * -FT
				if not data.markfordeath and (data.pos.z <= data.endpos.z + speed.z + data.size / 2 or data.pos.z < eyepos.z - 200) then
					-- Skip to the bottom
					if data.pos.z >= eyepos.z - 200 then
						data.pos = data.endpos
						data.markfordeath = true
					else
						data.alive = false
					end
				elseif data.markfordeath then
					data.alive = false
					if exp >= 4 and ran(4) < 2 and not data.nodrop then
						-- Splash
						local size = max(wind * 2.2,30)
						if data.rain then
							local p = _STORMFOX_PEM2d:Add(table.Random(rainmat_smoke),data.endpos + (data.hitnorm * size) ) -- + Vector(0,0,ran(size / 2,size * 0.4)
									p:SetAngles(data.hitnorm:Angle())
									p:SetStartSize(size)
									p:SetEndSize(size * 1.2)
									p:SetDieTime(ran(2,5))
									p:SetEndAlpha(0)
									p:SetStartAlpha( min(max(1000 / _STORMFOX_PEM2d:GetNumActiveParticles(),2),10) )
									p:SetColor(255,255,255)
									p:SetGravity(Vector(0,0,ran(4)))
									p:SetCollide(true)
									p:SetBounce(0)
									p:SetAirResistance(20)
									p:SetVelocity(Vector(downfallNorm.x * wind,downfallNorm.y * wind,0) + data.hitnorm * -10)
									p:SetCollideCallback( pf )
									--	p:SetStartLength(1)
						elseif false then
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
	local render_DrawBeam = render.DrawBeam
	local render_DrawSprite = render.DrawSprite
	local render_SetMaterial = render.SetMaterial
	local RenderRain = function(depth, sky)
		--if depth or sky then return end
		--if true then return end
		if LocalPlayer():WaterLevel() >= 3 then return end
		if not StormFox.GetData then return end
		if depth or sky then return end
		_STORMFOX_PEM:Draw()
		_STORMFOX_PEM2d:Draw()
		local Gauge = StormFox.GetData("Gauge",0)
		local alpha = 75 + min(Gauge * 10,150)

		local sky_col = StormFox.GetData("Bottomcolor",Color(204,255,255))
			sky_col = Color(max(sky_col.r,4),max(sky_col.g,55),max(sky_col.b,55),max(alpha,155))
		for id,data in ipairs(particles.main) do
			render_SetMaterial(data.material or materials.Rain)
			if data.rain then
				if data.smoke then
					render_DrawSprite(data.pos, data.size, data.size,Color(GaugeColor.r * 0.5,GaugeColor.g * 0.5,GaugeColor.b * 0.5,15))
				else
					render_DrawBeam(  data.pos,  data.pos - data.norm * data.size * data.length_m, 10 * data.size, 1, 0, Color(GaugeColor.r,GaugeColor.g,GaugeColor.b,5))
				end
			else
				if data.smoke then
					render_DrawSprite(data.pos, data.size * 1.4, data.size * 1.4,Color(GaugeColor.r * 0.5,GaugeColor.g * 0.5,GaugeColor.b * 0.5,max(5,Gauge * 2)))
				else
					local d = data.pos.z - data.endpos.z + data.r
					local n = sin(d / 100)
					local s = data.size
					local nn = max(0,16 - wind)
					render_DrawSprite(data.pos + Vector(n * nn,n * nn,0), s, s,Color(GaugeColor.r * 0.5,GaugeColor.g * 0.5,GaugeColor.b * 0.5))
				end
			end
			if raindebug then
				render_SetMaterial(Material("sprites/sent_ball"))
				if data.smoke then
					render_DrawSprite(data.endpos, 10,10,Color(0,0,255))
				else
					render_DrawSprite(data.endpos, 10,10,Color(0,255,0))
				end
			end
		end
		for id,data in ipairs(particles.bg) do
			render_SetMaterial(data.material)
			if data.rain then
				if data.smoke then
					--render.DrawBeam(startPos,  endPos                    ,number width,number textureStart,number textureEnd,table color)
					render_DrawBeam(  data.pos,  data.pos - data.norm * data.size * data.length_m, 6 * data.size, 1, 0, Color(GaugeColor.r,GaugeColor.g,GaugeColor.b,6))
				else
					render_DrawBeam(  data.pos,  data.pos - data.norm * data.size * data.length_m, data.size, 2, 0, Color(GaugeColor.r,GaugeColor.g,GaugeColor.b,25))
				end
			else
				if data.smoke then
					data.a = max(data.a + RealFrameTime() * 0.1,5)
					render_DrawBeam(  data.pos,  data.pos - data.norm * data.size * data.length_m,  data.size * 10, 1, 0, Color(GaugeColor.r,GaugeColor.g,GaugeColor.b,data.a))
				else
					local d = data.pos.z - data.endpos.z + data.r
					local n = sin(d / 100)
					local s = data.size * 10
					local nn = clamp(20 - Gauge * 2,0,16)
					render_DrawSprite(data.pos + Vector(n * nn,n * nn,0) + data.ang:Forward() * 10, s, s,Color(GaugeColor.r,GaugeColor.g,GaugeColor.b,55))
				end
			end
			if raindebug then
				render_SetMaterial(Material("sprites/sent_ball"))
				render_DrawSprite(data.endpos, 10,10,Color(255,0,0))
			end
		end
	end

	hook.Add("PostDrawTranslucentRenderables", "StormFox - RenderFalldown", function(depth,sky)
		if sky or depth then return end
		if not StormFox.EFEnabled() then return end
		RenderRain(depth,sky)
	end)

-- 2D Rain
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
			if not StormFox.EFEnabled() then table.Empty(screenParticles) return end
			local Gauge = StormFox.GetData("Gauge",0)
			if LocalPlayer():WaterLevel() >= 3 or Gauge <= 0 then
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
			-- Is it even raining?
				
				if Gauge <= 0 then table.Empty(screenParticles) return end
			-- Safty first
				if #screenParticles > 200 then return end
			-- Are you standing in the rain?
				if not StormFox.Env.IsInRain() then return end
			-- Get the temp and type
				local temp = StormFox.GetNetworkData("Temperature",20)
				local rain = temp > 0
			-- Get the dot
				local fDN = Vector(downfallNorm.x,downfallNorm.y,downfallNorm.z * 1)
					fDN:Normalize()
				local a = EyeAngles():Forward():Dot(fDN)
			viewAmount = -a
			if viewAmount <= 0 then viewAmount = 0 return end
			rainAmount = max((10 - Gauge) / 10,0.1) -- 0 in heavy rain, 1 in light
			-- Next rainrop
				l = SysTime() + (rand(rainAmount,rainAmount * 2) / viewAmount * 0.01 * (rain and 1 or 100))
			local drop = {}
				drop.life = SysTime() + ran(0.4,1)
				drop.x = ran(ScrW())
				drop.y = ran(ScrH())
				drop.size = 25 + rand(2,3) * Gauge * (rain and 1 or 2)
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

-- Draw drain on screen
	local RainScreen_RT = GetRenderTarget("StormFox RainScreenRT",ScrW(),ScrH())
	local ScreenDummy = Material("stormfox/effects/rainscreen_dummy")
	local mat_Copy		= Material( "pp/fb" )
	local rainscreen_mat = Material("stormfox/effects/rainscreen")
	local old_raindrop = Material("sprites/heatwave")
	local rainscreen_alpha = 0
	hook.Add("HUDPaint","StormFox - RenderRainScreen",function()
		if not LocalPlayer() then return end
		local con = GetConVar("sf_allow_raindrops")
		if con and not con:GetBool() then return end
		if not StormFox.EFEnabled() then return end

		local Gauge = StormFox.GetData("Gauge",20)
		if LocalPlayer():WaterLevel() >= 3 then rainscreen_alpha = 0.8 return end
		local ft = RealFrameTime()
		local temp = StormFox.GetNetworkData("Temperature",20)

		local acc = (viewAmount * clamp(temp - 4,0,(Gauge / 200))) * ft * 10
		if acc <= 0 or not StormFox.Env.IsInRain() or Gauge <= 0 then
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
		if not StormFox.EFEnabled() then return end
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