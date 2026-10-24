
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

-- render.OverrideBlend
	local render_OverrideBlend = render.OverrideBlend

-- Localize for optimisasion
	local cam_PopModelMatrix = cam.PopModelMatrix
	local cam_PushModelMatrix = cam.PushModelMatrix
	local max,min,clamp,ceil,abs = math.max,math.min,math.Clamp,math.ceil,math.abs

-- Init sky
	-- Generate dome
		local Render_Dome
		local cos,sin,rad = math.cos,math.sin,math.rad
		local layers = 4
		local top_height = 20
		local z_level = -.8
		local sc = 20
		local e_r = rad(45)
		local t_s = 1
		local function UVMulti(uv,mul)
			return (uv - 0.5) * mul + 0.5
		end
		local function BuildDome(mat)
			local tris, n = {}, 0
			local function V(pos, u, v, a)
				n = n + 1
				tris[n] = { pos = pos, u = u, v = v, color = Color(255, 255, 255, a) }
			end
			for i = 1,8 do
				local yaw = rad(45 * i)
				-- Top
				local c,s = cos(yaw),sin(yaw)
				local L = {Vector(c * sc,s * sc,0.1 * -sc),(1 + c) / 2 * t_s,(1 + s) / 2 * t_s}
				local c,s = cos(yaw + e_r),sin(yaw + e_r)
				local R = {Vector(c * sc,s * sc,0.1 * -sc),(1 + c) / 2 * t_s,(1 + s) / 2 * t_s}
				V(L[1], L[2], L[3], 255)
				V(R[1], R[2], R[3], 255)
				V(Vector(0,0,0.1 * top_height), 0.5 * t_s, 0.5 * t_s, 255)
				-- Side 1 (fades out towards the horizon)
				local R2 = {R[1] * 1.4 - Vector(0,0,4),UVMulti(R[2],1.4),UVMulti(R[3],1.4)}
				V(L[1], L[2], L[3], 255)
				V(R2[1], R2[2], R2[3], 0)
				V(R[1], R[2], R[3], 255)
				-- Side 2
				V(L[1], L[2], L[3], 255)
				V(L[1] * 1.4 - Vector(0,0,4), UVMulti(L[2], 1.4), UVMulti(L[3],1.4), 0)
				V(R2[1], R2[2], R2[3], 0)
			end
			local m = Mesh(mat)
			m:BuildFromTriangles(tris)
			return m
		end
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
		for i=1,layers do
			sky_mats[i] = CreateMaterial("SF_RENDER_Skytext4" .. i,"UnlitGeneric",params)
			offset[i] = {i * 99,i * 33}
		end
		Render_Dome = BuildDome(sky_mats[1])
	-- Setup RT-Render
		local sky_rts = {}
		local texscale = 512
		for i=1,layers do
			sky_rts[i] = GetRenderTargetEx( "StormFox - Sky" .. i, texscale, texscale, 1, MATERIAL_RT_DEPTH_NONE, 2, CREATERENDERTARGETFLAGS_UNFILTERABLE_OK, IMAGE_FORMAT_RGBA8888)
		end

	local cloudbig = Material("stormfox/clouds_big.png","nocull noclamp smooth")
		cloudbig:SetFloat("$nocull",1)
		cloudbig:SetFloat("$nocull",1)
		cloudbig:SetFloat("$additive",0)

		-- Render function that supports fractions (surface libary is whole numbers only)
		local win_m,win_v = Matrix(),Vector()
		local function DrawTextureRectWindow(w,h,o_x,o_y)
			if o_x < 0 then o_x = o_x + w end
			if o_y < 0 then o_y = o_y + h end
			o_x = o_x % w
			o_y = o_y % h

			local m = win_m
			m:Identity()
			win_v.x,win_v.y = o_x % w,o_y % h
			m:Translate(win_v)
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
			matrix:Translate( vector_origin + pos )
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
			for i=1,layers do
				local ri = layers - i + 1
				local o = offset[i]
				o[1],o[2] = o[1] + x_w * ri,o[2] + y_w * ri
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

		
			local ambiantLight = b_color
		-- Create cloud layers (each layer has its own RT, offset and speed)
			local n = clamp(ceil(cloud_alpha / 60),0,layers)
			local light = Vector(ambiantLight.r,ambiantLight.g,ambiantLight.b) / 255
			for i = 1,n do
				local seed = (i == 1) and c_seed or d_seed
				local a = (i == 1) and min(cloud_alpha * 4,240) or max(0,cloud_alpha * 3 - 85)
				local ox,oy = offset[i][1] + seed + i * 33,offset[i][2] + seed + i * 33
				RTRender(sky_rts[i],true)
					surface.SetMaterial(cloudbig)
					surface.SetDrawColor(255,255,255,a)
					DrawTextureRectWindow(texscale,texscale,ox,oy)
				RTMask()
					surface.SetMaterial(cloudbig)
					DrawTextureRectWindow(texscale,texscale,ox,oy)
				RTEnd(sky_mats[i])
				-- Upper layers are a bit brighter
				local amp = 1 + .4 * (1 - (i / n))
				sky_mats[i]:SetVector("$color",Vector(min(light.x * amp,1),min(light.y * amp,1),min(light.z * amp,1)))
			end
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
hook.Add("StormFox - RenderClouds","StormFox - CloudsRender",function(c_pos,map_center)
	if not StormFox.EFEnabled() then return end
	if not StormFox.MapOBBCenter or not StormFox.GetEyePos then return end
	local c_a = StormFox.GetData("CloudsAlpha",0)
	local n = clamp(ceil(c_a / 60),0,layers)
	if n <= 0 then return end
	CloudRender(c_a,StormFox.GetExspensive())
	-- A sane near-plane keeps the depth buffer precise, otherwise the layers z-fight (flicker).
	cam.Start3D( Vector( 0, 0, 0 ), EyeAngles() ,nil,nil,nil,nil,nil,1,1000)
		-- Layers are spaced apart so they never share depth.
		for i = 1,n do
			local ri = n - i + layers
			RenderDome(Vector(0,0,z_level + 0.4 * ri),sky_mats[i],255)
		end
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