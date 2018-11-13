
--[[-------------------------------------------------------------------------
Cloud rendering (Its complicated)
---------------------------------------------------------------------------]]
-- Setup a seed for cloud-rendering. This will change everytime weather turns cloud'y.
if SERVER then
	--StormFox.SetNetworkData("CloudSeed",math.random(100))
	hook.Add("StormFox - NewWeather","StormFox - CloudSeed",function(weather,old_weather)
		if old_weather ~= "clear" then return end
		StormFox.SetNetworkData("CloudSeed",math.random(100))
	end)
	return
end

-- render.OverrideBlendFunc is to be replaced by render.OverrideBlend .. we need to be sure both versions work (Chrome, current and furture).
	local function render_OverrideBlend(enabled, srcBlend, destBlend, blendFunc, srcBlendAlpha, destBlendAlpha, blendFuncAlpha)
		if not render.OverrideBlendFunc then return end
		render.OverrideBlendFunc( enabled, srcBlend, destBlend, srcBlendAlpha, destBlendAlpha )
	end
	if render.OverrideBlend then
		render_OverrideBlend = render.OverrideBlend
	end

-- Localize for optimisasion
	local render_DrawQuadEasy = render.DrawQuadEasy
	local cam_PopModelMatrix = cam.PopModelMatrix
	local cam_PushModelMatrix = cam.PushModelMatrix
	local max,min,clamp,ceil,abs = math.max,math.min,math.Clamp,math.ceil,math.abs

-- Init sky
	-- Generate dome
		local Render_Dome = Mesh()
		local cos,sin,rad = math.cos,math.sin,math.rad
		local sc = 20
		local stage = 0
		local e_r = math.rad(45)
		local t_s = 6
		mesh.Begin( Render_Dome, MATERIAL_TRIANGLES, 8 )
			for i=1,8 do
				local yaw = math.rad(45 * i)
				-- L
				local c,s = cos(yaw),sin(yaw)
				mesh.Position(Vector(c * sc,s * sc,0.1 * -sc))
				mesh.TexCoord( stage, (1 + c) / 2 * t_s,  (1 + s) / 2 * t_s )
				mesh.Color(255,255,255,0)
				mesh.AdvanceVertex()
				-- R
				local c,s = cos(yaw + e_r),sin(yaw + e_r)
				mesh.Position(Vector(c * sc,s * sc,0.1 * -sc))
				mesh.TexCoord( stage, (1 + c) / 2 * t_s,  (1 + s) / 2 * t_s )
				mesh.Color(255,255,255,0)
				mesh.AdvanceVertex()
				-- T
				mesh.Position(Vector(0,0,0.1 * sc))
				mesh.TexCoord( stage, 0.5 * t_s,0.5 * t_s )
				mesh.Color(255,255,255,255)
				mesh.AdvanceVertex()
			end
		mesh.End()
	-- Setup Materials
		local sky_mats = {}
		local offset = {}
		local params = {}
			params[ "$basetexture" ] = ""
			params[ "$translucent" ] = 0
			params[ "$vertexalpha" ] = 1
			params[ "$vertexcolor" ] = 1
			params[ "$nofog" ] = 1
			params[ "$nolod" ] = 1
			params[ "$nomip" ] = 1
			params["$additive"] = 0
		for i=1,4 do
			sky_mats[i] = CreateMaterial("SF_RENDER_Skytext4" .. i,"UnlitGeneric",params)
			offset[i] = {i * 128,i * 128}
		end	
	-- Setup RT-Render
		local sky_rts = {}
		local texscale = 512
		local half_texscale = texscale / 2 
		for i=1,4 do
			sky_rts[i] = GetRenderTargetEx( "StormFox - Sky" .. i, texscale, texscale, 1, MATERIAL_RT_DEPTH_NONE, 2, CREATERENDERTARGETFLAGS_UNFILTERABLE_OK, IMAGE_FORMAT_RGBA8888)
		end

	local cloudbig = Material("stormfox/clouds_big.png","nocull noclamp smooth")
		cloudbig:SetFloat("$nocull",1)
		cloudbig:SetFloat("$nocull",1)
		cloudbig:SetFloat("$additive",0)
	local zero_mat = Material("stormfox/mat_zero")
	local r = math.Round

	-- Render function that supports fractions (surface libary is whole numbers only)
		local function DrawTextureRectWindow(w,h,o_x,o_y)
			if o_x < 0 then o_x = o_x + w end
			if o_y < 0 then o_y = o_y + h end
			o_x = o_x % w
			o_y = o_y % h

			local m = Matrix()
			m:Identity() 
			
			m:Translate(Vector(o_x % w,o_y % h)) 
			cam.PushModelMatrix(m)
				surface.DrawTexturedRect(0,0,w,h)
				surface.DrawTexturedRect(-w,0,w,h)
				surface.DrawTexturedRect(0,-h,w,h)
				surface.DrawTexturedRect(-w,-h,w,h)
			cam.PopModelMatrix()		
		end
	-- Dome render
		local matrix = Matrix()
		local function RenderDome(pos,mat,alpha)
			matrix:Identity()
			matrix:Translate( vector_origin - pos )
			--mat:SetAlpha(alpha)
			cam_PushModelMatrix(matrix)
				render.SetBlend(alpha / 255)
				render.SetMaterial(mat)
				Render_Dome:Draw()
				render.SetBlend(1)
			cam_PopModelMatrix()
		end

	-- Cloud movement
		hook.Add("Think","StormFox - Cloud-Think",function()
			local w_ang = rad(StormFox.GetNetworkData("WindAngle",0))
			local w_force = max(StormFox.GetNetworkData("Wind",0) * (FrameTime() / 8),0.01)
			local x_w,y_w = cos(w_ang) * w_force,sin(w_ang) * w_force
			for i=1,4 do
				local ri = 5 - i
				local x,y = offset[i][1],offset[i][2]
				offset[i] = {x + x_w * ri ,y + y_w * ri}
			end
		end)
	-- Cloud-Rendering
	--[[-------------------------------------------------------------------------
		- Render the layer:
			- Color layer
				- BG color ('fill' color)
				- FG color (Cloud bonus by cloudseed)
			- Create 'holes' with blend function.
		- Render layer for top-color (Moon/sunlight and sunset/rise color). Offset by direction of light
		- Render "depth"-layer to block out toplayer .. making it depth-ish.

	---------------------------------------------------------------------------]]
	local mad = math.AngleDifference
	local function CalcAmbiantColor(t) -- Calc the "cloud" light
		t = t or StormFox.GetTime()
		local SunSetRise_Amount = StormFox.GetSun_SetRise(t)
		local amb_c = Color(0,0,0)
		local shine_c = Color(0,0,0)
		if t < 1080 and t > 360 then
			-- Day
			local sA = StormFox.GetData("SunColor",Color(255,255,255)).a / 255 * (1 - SunSetRise_Amount)
			amb_c = Color(255 * sA, 255 * sA, sA * 255)
			shine_c = Color(255 * sA + 255 * SunSetRise_Amount, 255 * sA + 127.5 * SunSetRise_Amount, sA * 255)
			return amb_c,shine_c,StormFox.GetSunAngle(t)
		else
			-- Night
			local mul = clamp(mad(StormFox.GetMoonAngle().p,360) / -90 * 5,0,1)
			local mA = StormFox.GetData("MoonVisibility",100) / 100 * (1 - SunSetRise_Amount) * mul
			amb_c = Color(25 * mA, 25 * mA, mA * 25)
			shine_c = Color(55 * mA + 255 * SunSetRise_Amount, 55 * mA + 127.5 * SunSetRise_Amount, mA * 55)
			return amb_c,shine_c,SunSetRise_Amount < 0.3 and StormFox.GetMoonAngle() or StormFox.GetSunAngle(t)
		end
		return amb_c,shine_c,0
	end
	local HQ_Rendering = true
	local function ColorMix(c,add,cmin,cmax)
		return Color(clamp(c.r + add,cmin or 0,cmax or 255),clamp(c.g + add,cmin or 0,cmax or 255),clamp(c.b + add,cmin or 0,cmax or 255))
	end

	local lastRT
	local function RTRender(RT,blend)
		lastRT = RT
		render.PushRenderTarget( RT )
			render.ClearDepth()
			render.Clear( 0, 0, 0, 0 )
			cam.Start2D()
		if not blend then return end
			render.OverrideAlphaWriteEnable( true, true )
	end
	local function RTMask(srcBlend,destBlend,srcBlendAlpha,destBlendAlpha)
		local srcBlend = 		srcBlend or BLEND_ZERO
		local destBlend = 		destBlend or BLEND_SRC_ALPHA	-- 
		local blendFunc = 		0	-- The blend mode used for drawing the color layer 
		local srcBlendAlpha = 	srcBlendAlpha or BLEND_DST_ALPHA	-- Determines how a rendered texture's final alpha should be calculated.
		local destBlendAlpha = 	destBlendAlpha or BLEND_ZERO	-- 
		local blendFuncAlpha = 	0	-- 
		render_OverrideBlend( true, srcBlend, destBlend, blendFunc, srcBlendAlpha, destBlendAlpha, blendFuncAlpha)
	end
	local function RTEnd(Mat_Output)
		render_OverrideBlend( false ) 
		render.OverrideAlphaWriteEnable( false )
		cam.End2D()
		render.PopRenderTarget()
		-- Apply changes
			Mat_Output:SetTexture("$basetexture",lastRT)
	end

	local function CloudRender(cloud_alpha,SE_quality) -- amount 0 - 1
		if cloud_alpha <= -1 or not StormFox.EFEnabled() then return end
		local cloud_alpha_n = 255 - cloud_alpha
		-- Check if we're even able to run ..
			if not StormFox.IsNight then return end -- Check if loaded
			if not StormFox.GetSunVisibility then return end -- Check if sun and moon been inited.
			if not StormFox.GetSun_SetRise then return end
			if not render_OverrideBlend then return end -- Just in case


		-- Load varables
			local SE_quality = SE_quality or StormFox.GetExspensive() -- quality_level
				HQ_Rendering = SE_quality >= 7 -- HQ render if quality_level is equal or above 7
				HQ_Rendering = false
			local c_seed = StormFox.GetNetworkData("CloudSeed",0)
			local d_seed = c_seed * 3.4 % 100
			local b_color_raw = StormFox.GetData("SkyBottomColor") or Color(255,255,255)
			local t_n = StormFox.GetData("ThunderLight",0) * 1.7

			-- Moon-color
			local mA = 0
			if StormFox.IsNight() then
				local mul = clamp(mad(StormFox.GetMoonAngle().p,360) / -90 * 5,0,1)
				mA = StormFox.GetData("MoonVisibility",100) / 100 * mul
			else
				mA = cloud_alpha_n / 200
			end
			local aa = (b_color_raw.r + b_color_raw.g + b_color_raw.b) / 3

			local b_color = ColorMix(Color(aa,aa,aa),t_n + mA * 30 ,15,255)

		
			ambiantLight = b_color
		-- Create top - cloud layer
			RTRender(sky_rts[1],true)
				surface.SetMaterial(cloudbig)
				surface.SetDrawColor(Color(255,255,255,min(cloud_alpha * 4,240)))
				DrawTextureRectWindow(texscale,texscale,offset[1][1] + c_seed,offset[1][2] + c_seed)
			RTMask()
				surface.SetMaterial(cloudbig)
				DrawTextureRectWindow(texscale,texscale,offset[1][1] + c_seed,offset[1][2] + c_seed)
			RTEnd(sky_mats[1])
			local r,g,b = 255,140,0
			sky_mats[1]:SetVector("$color", Vector(ambiantLight.r / 255,ambiantLight.g / 255,ambiantLight.b / 255))

		-- Create middle - cloud layer
			RTRender(sky_rts[2],true)
				surface.SetMaterial(cloudbig)
				surface.SetDrawColor(Color(255,255,255,max(0,cloud_alpha * 3 - 85)))
				DrawTextureRectWindow(texscale,texscale,offset[2][1] + d_seed,offset[2][2] + d_seed)
			RTMask()
				surface.SetMaterial(cloudbig)
				DrawTextureRectWindow(texscale,texscale,offset[2][1] + d_seed,offset[2][2] + d_seed)
			RTEnd(sky_mats[2])
			
			local r,g,b = 255,140,0
			--Vector(r / 255,g / 255,b / 255) or 
			sky_mats[2]:SetVector("$color",Vector(ambiantLight.r / 255,ambiantLight.g / 255,ambiantLight.b / 255))
		-- Create light 
			local ambiantLight,ambiantShine,amb_shine_ang = CalcAmbiantColor()
		--[[
			local off_a,off_mul = rad(amb_shine_ang.y),abs(mad(amb_shine_ang.p + 90 , 360)) / 5
			local offset_x,offset_y = cos(off_a) * off_mul,sin(off_a) * off_mul
			RTRender(sky_rts[2],true)
				surface.SetMaterial(sky_mats[1])
				surface.SetDrawColor(Color(255,255,255))
				DrawTextureRectWindow(texscale,texscale,offset_x,offset_y)
				surface.SetDrawColor(Color(0,0,0))
				surface.DrawTexturedRect(0,0,texscale,texscale)
			RTMask()
				surface.SetDrawColor(Color(255,255,255))
				surface.SetMaterial(sky_mats[1])
				surface.DrawTexturedRect(0,0,texscale,texscale,0,0)
			RTEnd(sky_mats[2])
			]]
	end

-- render.CullMode(1) render render.CullMode(0) will change the render
-- Cloud layer
hook.Add("StormFox - MiddleSkyRender","StormFox - CloudsRender",function()
	if not StormFox.EFEnabled() then return end
	if not StormFox.MapOBBCenter or not StormFox.GetEyePos then return end
	local mC = StormFox.MapOBBCenter() or Vector(0,0,0)
	local c_pos = StormFox.GetEyePos() or EyePos()
	local height = mC.z
	-- Start render
	local c_a = StormFox.GetData("CloudsAlpha",0)
	local SE_quality = StormFox.GetExspensive()
	CloudRender(c_a,SE_quality)
	cam.Start3D( Vector( 0, 0, 0 ), EyeAngles() ,nil,nil,nil,nil,nil,0,32000)
		local n = clamp(ceil(c_a / 60),0,4)
		-- Render top clouds
		for i = 1,1 do
			RenderDome(c_pos * 0 + Vector(0,0,0.9 * (0.4 + i * 0.04)),sky_mats[2],255)
		end
		-- Render clouds
		for i = 1,2 do
			RenderDome(c_pos * 0 + Vector(0,0,1 * (0.4 + i * 0.01)),sky_mats[1],255)
		end
		-- Render light
		

	cam.End3D()
end)

-- Debug materials
local size = 105
hook.Add("HUDPaint","StormFox - DebugClouds",function()
	if true then return end
	for i=1,4 do
		local x = (size + 5) * i - size
		surface.SetMaterial(sky_mats[i])
		surface.SetDrawColor(255,255,255)
		surface.DrawTexturedRect(x, 0, size, size)

		surface.SetDrawColor(255,255,255)
		surface.DrawRect(x, size + 5, size, size)
		surface.DrawTexturedRect(x, size + 5, size, size)

		surface.SetDrawColor(0,0,0)
		surface.DrawRect(x, (size + 5) * 2, size, size)
		surface.SetDrawColor(255,255,255)
		surface.DrawTexturedRect(x, (size + 5) * 2, size, size)
	end

	surface.SetMaterial(cloudbig)
end)