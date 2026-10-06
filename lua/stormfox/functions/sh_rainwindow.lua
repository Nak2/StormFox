
-- Turns out these variables may not have these original positions

local function CheckSettings()
	local con =  GetConVar("sf_enable_windoweffect")
	if not con then return false end
	if not con:GetBool() then return false end
	if not StormFox.EFEnabled() then return false end
	return true
end
local s = 10 -- Texture size
local t = {} -- List of windows to render stuff on

-- Check if the window is in the wind
local convar = GetConVar("sf_enable_windoweffect_enable_tr")
local function IsWindowInRain( ent )
	if not convar or not convar:GetBool() or not ent.sf_vars then
		ent.sf_inwindow = true
		return true
	end
	ent.sf_inwindow = StormFox.IsVectorInWind( ent:LocalToWorld(ent.sf_vars.center), ent )
	return ent.sf_inwindow
end

local function SortCorners( ul, ur, ll, lr )
	local list = { ul, ur, ll, lr }
	table.sort( list, function( a, b ) return a.z > b.z end )
	local tl, tr, bl, br = list[1], list[2], list[3], list[4]
	if tl.z - br.z < 1 then
		return ul, ur, ll, lr
	end
	if tl:DistToSqr( br ) < tl:DistToSqr( bl ) then
		bl, br = br, bl
	end
	return tl, tr, bl, br
end

-- Creates the mesh-data. The positions are saved local to the window, since a brush entity can have any origin or angle.
-- It is a single quad that is rendered without culling, so both sides of the glass will have the effect.
local function BuildWindow( ent, ul, ur, ll, lr )
	local tl, tr, bl, br = SortCorners( ul, ur, ll, lr )
	local w = tl:Distance( tr )
	local h = tl:Distance( bl )
	if w <= 0 or h <= 0 then return false end
	-- V is 0 on the top and counts down. The render-hook scrolls it. U is 0 on the left.
	local verts = {
		{ pos = tr, u = w / s, v = 0 },     -- 1 Top right
		{ pos = br, u = w / s, v = h / s }, -- 2 Bottom right
		{ pos = bl, u = 0,     v = h / s }, -- 3 Bottom left
		{ pos = tl, u = 0,     v = 0 },     -- 4 Top left
	}
	ent.sf_vars = {
		center = ( tl + tr + bl + br ) / 4,
		w = w,
		h = h,
		verts = verts,
		entity = ent
	}
	return true
end

-- No need to network with NikNaks
if StormFox.NikNaks and NikNaks.Version >= 0.91 then
	if SERVER then return end

	local s_timer = CurTime() + 1
	local map = NikNaks.CurrentMap
	hook.Add("Think","StormFox - RainWindowEffectThink",function()
		if s_timer > CurTime() then return end -- Call this twice pr second
			s_timer = CurTime() + 0.5
		-- Remove all render windows
		table.Empty(t)
		-- Check settings
		if not CheckSettings() or StormFox.GetData("Gauge",10) <= 5 then return end
		for _,ent in pairs(ents.FindByClass("func_breakable_surf")) do
			if ent:Health() <= 0 or ent._sfd then continue end
			if not ent.sf_vars then
				local id = ent:MapCreationID()
				local windowData = id >= 0 and map:FindByMapCreationID(id)
				if not windowData then
					ent._sfd = true
					continue
				end
				local ur, ul = Vector( windowData.upperright ) - windowData.origin, Vector( windowData.upperleft ) - windowData.origin
				local lr, ll = Vector( windowData.lowerright ) - windowData.origin, Vector( windowData.lowerleft ) - windowData.origin
				if not ur or not ul or not lr or not ll or not BuildWindow( ent, ul, ur, ll, lr ) then
					ent._sfd = true
					continue
				end
			end

			-- Check the distance
			local dis = StormFox.DistToHeadSqr(ent:LocalToWorld(ent.sf_vars.center))
			if not dis then continue end
			ent.sf_vars.dis = dis
			if dis > 90000 then continue end
			-- Check if its in the wind
			if not IsWindowInRain(ent) then continue end
			table.insert(t,ent) -- Add the window to the list
		end
	end)
else
	if StormFox.NikNaks then
		StormFox.Msg("NikNaks is installed, but it is outdated. Some features are disabled.")
	end
	local function HandleVarablesWindow( ent )
		-- Get the window varables ( world positions )
			local ll = ent:GetNWVector("SF_POS10")
			local lr = ent:GetNWVector("SF_POS11")
			local ur = ent:GetNWVector("SF_POS01")
			local ul = ent:GetNWVector("SF_POS00")
		-- Is it valid?
			if type(ll) ~= "Vector" or type(lr) ~= "Vector" or type(ur) ~= "Vector" or type(ul) ~= "Vector" then return end
			if ll == vector_origin and lr == vector_origin and ur == vector_origin and ul == vector_origin then return end
		BuildWindow( ent, ul, ur, ll, lr )
	end

	if SERVER then
		-- Give each window the required varables
		hook.Add("EntityKeyValue","StormFox - SetData",function(ent,key,val) -- GetKeyValues() on client plz
			if ent:GetClass() ~= "func_breakable_surf" then return end
			if key == "upperleft" then 								-- ↖ 00 
				local t = string.Explode(" ",val)
				ent:SetNWVector("SF_POS00",Vector(t[1],t[2],t[3]))
			elseif key == "upperright" then 						-- ↗ 01
				local t = string.Explode(" ",val)
				ent:SetNWVector("SF_POS01",Vector(t[1],t[2],t[3]))
			elseif key == "lowerleft" then 							-- ↙ 10
				local t = string.Explode(" ",val)
				ent:SetNWVector("SF_POS10",Vector(t[1],t[2],t[3]))
			elseif key == "lowerright" then 						-- ↘ 11
				local t = string.Explode(" ",val)
				ent:SetNWVector("SF_POS11",Vector(t[1],t[2],t[3]))
			end
		end)
		return
	end

	local s_timer = 0
	hook.Add("Think","StormFox - RainWindowEffectThink",function()
		if s_timer > CurTime() then return end -- Call this twice pr second
			s_timer = CurTime() + 0.5
		-- Remove all render windows
		table.Empty(t)
		-- Check settings
		if not CheckSettings() then return end
		-- Only trigger this in semi-heavy rain
		if StormFox.GetData("Gauge",10) <= 5 then return end 
		for _,ent in pairs(ents.FindByClass("func_breakable_surf")) do
			-- Check health
			if ent:Health() <= 0 then continue end
			-- Check if there are any useful varables
			if not ent.sf_vars then
				HandleVarablesWindow(ent)
			end
			if not ent.sf_vars then continue end -- No valid windowdata
			-- Check the distance
			local dis = StormFox.DistToHeadSqr(ent:LocalToWorld(ent.sf_vars.center))
			if not dis then continue end
			ent.sf_vars.dis = dis
			if dis > 90000 then continue end
			-- Check if its in the wind
			if not IsWindowInRain(ent) then continue end
			table.insert(t,ent) -- Add the window to the list
		end
	end)
end

-- Check if all varables is valid. This is to protect the mesh from causing errors.
local function CheckValid(data) -- Mesh errors will ruin the whole game. Better get it right.
	if not data.dis then return false end
	if not data.entity then return false end
	if not data.center then return false end
	if not data.verts then return false end
	if not data.h then return false end
	if not data.w then return false end
	return true
end
-- Render the effect
local clamp = math.Clamp
local b = false
local mat = Material("stormfox/effects/rainscreen")
hook.Add("PreDrawTranslucentRenderables","StormFox - RainWindowEffect",function()
	if #t <= 0 then return end
	render.SetColorMaterial()
	render.SetMaterial(mat)
	render.CullMode( MATERIAL_CULLMODE_NONE )
	for _,ent in pairs(t) do
		if not IsValid(ent) then continue end
		if ent:Health() <= 0 then continue end
		if not CheckValid(ent.sf_vars) then continue end
		local a = clamp(455 - ent.sf_vars.dis / 152,0,255) -- Alpha. doesn't really work well with this type of material.
		if a <= 0 then continue end
		-- Mesh protector 2#. Stops the game from going crazy
		if b then return end
		b = true
		-- Update texture UV
		local c = (CurTime() / 8) % 1 -- Used to calculate UV for windows
		ent.sf_vars.verts[1].v = -c
		ent.sf_vars.verts[2].v = ent.sf_vars.h / s - c
		ent.sf_vars.verts[3].v = ent.sf_vars.h / s - c
		ent.sf_vars.verts[4].v = -c

		-- Here goes nothing
		mesh.Begin( MATERIAL_QUADS, 1 ) -- Begin writing to the dynamic mesh
		for i,verts in pairs(ent.sf_vars.verts) do
			mesh.Position( ent:LocalToWorld( verts.pos)  ) -- Set the position
			mesh.Color(255,255,255,a)
			mesh.TexCoord( 0, verts.u, verts.v ) -- Set the texture UV coordinates
			mesh.AdvanceVertex() -- Write the vertex
		end
		mesh.End()
		b = false
	end
	render.CullMode( MATERIAL_CULLMODE_CCW )
end)
