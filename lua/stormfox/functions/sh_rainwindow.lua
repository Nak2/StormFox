
-- Cause mapcreators are lazy and don't follow the right varables ...
	local function SortVectors(...)
		local ar = {...}
		table.sort( ar, function(a,b) 
			if a.z > b.z then return true end
			return false
		end )
		local t = ar[2]
		ar[2] = ar[3]
		ar[3] = t
		return ar
	end
--[[ Test thingy. Left for me to easy debug.
	local function TestWindow( ent , time )
		local pos = ent:GetNWVector("SF_POS10")
		local pos2 = ent:GetNWVector("SF_POS11")
		local pos3 = ent:GetNWVector("SF_POS01")
		local pos4 = ent:GetNWVector("SF_POS00")
		local arr = SortVectors(pos,pos2,pos3,pos4)
		for k,v in pairs(arr) do
			local lifetime = time or 15
			debugoverlay.Sphere(v,5,lifetime,Color( 255, 255, 255 ),true)
			debugoverlay.Text(v,k,lifetime,false)
		end
		return --arr
	end]]

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

local function CheckSettings()
	local con =  GetConVar("sf_enable_windoweffect")
	if not con then return false end
	if not con:GetBool() then return false end
	if not StormFox.EFEnabled() then return false end
	return true
end
-- Only need to calculate some things once
	local s = 10 -- Texture size
	local function HandleVarablesWindow( ent )
		-- Get the window varables
			local pos = ent:GetNWVector("SF_POS10")
			local pos2 = ent:GetNWVector("SF_POS11")
			local pos3 = ent:GetNWVector("SF_POS01")
			local pos4 = ent:GetNWVector("SF_POS00")
		-- Is it valid?
			if type(pos)~= "Vector" or type(pos2)~= "Vector" or type(pos3)~= "Vector" or type(pos4)~= "Vector" then return end
		-- We can't trust mapcreators .. never do. Sort the varables by height.
			local arr = SortVectors(pos,pos2,pos3,pos4)
				pos = arr[1]
				pos2 = arr[4]
				pos3 = arr[2]
				pos4 = arr[3]
		-- Create some useful varables
			local size = pos3 - pos
			local center = pos + size / 2
			local ang = (pos2 - pos):Angle()
			local w = pos:Distance(pos4)
			local h = pos:Distance(pos2)
		-- Create the meshes ( we update the uvs later)
			local c = (CurTime() / 10) % 1
			local verts = {
				{ pos = pos4, u = w / s, v = -c }, -- Vertex 1 TOP
				{ pos = pos3, u = w / s, v = h / s-c }, -- Vertex 2 BOTTOM
				{ pos = pos2, u = 0, v = h / s -c}, -- Vertex 3 BOTTOM
				{ pos = pos, u = 0, v = -c }, -- Vertex 4 TOP
			}
			local verts2 = {
				{ pos = pos, u = 0, v = -c }, -- Vertex 1
				{ pos = pos2, u = 0, v = h / s -c }, -- Vertex 2
				{ pos = pos3, u = w / s, v = h / s-c}, -- Vertex 3
				{ pos = pos4, u = w / s, v = -c }, -- Vertex 4
			}
		-- Save the varables on the window
			ent.sf_vars = {}
			ent.sf_vars.center = center
			ent.sf_vars.normal = -ang:Right()
			ent.sf_vars.w = w 
			ent.sf_vars.h = h
			ent.sf_vars.verts = verts
			ent.sf_vars.verts2 = verts2
			ent.sf_vars.entity = ent
	end
-- Check if the window is in the wind
	local convar = GetConVar("sf_enable_windoweffect_enable_tr")
	local function IsWindowInRain( data, ent )
		if (ent.sf_inwindowcost or 0) > CurTime() then return ent.sf_inwindow or false end
			ent.sf_inwindowcost = CurTime() + 4
		if not convar:GetBool() then
			ent.sf_inwindow = true
			return true
		end
		--verts  then
		ent.sf_inwindow = StormFox.IsVectorInWind( data.center , ent )
		return ent.sf_inwindow
	end
-- Draw rain on windows
	local t = {} -- List of windows to render stuff on
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
		local p = LocalPlayer():GetShootPos()
		for _,ent in pairs(ents.FindByClass("func_breakable_surf")) do
			-- Check health
				if ent:Health() <= 0 then continue end
			-- Check if there are any useful varables
				if not ent.sf_vars then
					HandleVarablesWindow(ent)
				end
				if not ent.sf_vars then return end -- No valid windowdata
			-- Check the distance
				local dis = p:DistToSqr(ent.sf_vars.center)
				ent.sf_vars.dis = dis
				if dis > 90000 then continue end
			-- Check if its in the wind
				if not IsWindowInRain(ent.sf_vars,ent) then return end
			table.insert(t,ent) -- Add the window to the list
		end
	end)
-- Check if all varables is valid. This is to protect the mesh from causing errors.
	local function CheckValid(data) -- Mesh errors will ruin the whole game. Better get it right.
		if not data.dis then return false end
		if not data.entity then return false end
		if not data.center then return false end
		if not data.verts then return false end
		if not data.verts2 then return false end
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
				local c = (CurTime() / 20) % 1 -- Used to calculate UV for windows
				ent.sf_vars.verts[1].v = -c
				ent.sf_vars.verts[2].v = ent.sf_vars.h / s - c
				ent.sf_vars.verts[3].v = ent.sf_vars.h / s - c
				ent.sf_vars.verts[4].v = -c

				ent.sf_vars.verts2[1].v = -c
				ent.sf_vars.verts2[2].v = ent.sf_vars.h / s - c
				ent.sf_vars.verts2[3].v = ent.sf_vars.h / s - c
				ent.sf_vars.verts2[4].v = -c
			-- Here goes nothing
				mesh.Begin( MATERIAL_QUADS, 1 ) -- Begin writing to the dynamic mesh
				for i,verts in pairs(ent.sf_vars.verts) do
					mesh.Position( verts.pos ) -- Set the position
					mesh.Color(255,255,255,a)
					mesh.TexCoord( 0, verts.u, verts.v ) -- Set the texture UV coordinates
					mesh.AdvanceVertex() -- Write the vertex
				end
				mesh.End()
				mesh.Begin( MATERIAL_QUADS, 1 ) -- Begin writing to the dynamic mesh
				for i,verts in pairs(ent.sf_vars.verts2) do
					mesh.Position( verts.pos ) -- Set the position
					mesh.Color(255,255,255,a)
					mesh.TexCoord( 0, verts.u, verts.v ) -- Set the texture UV coordinates
					mesh.AdvanceVertex() -- Write the vertex
				end
				mesh.End()
				b = false
		end
	end)

	