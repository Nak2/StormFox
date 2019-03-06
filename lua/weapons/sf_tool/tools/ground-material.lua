
local NO_TYPE = -1
local DIRTGRASS_TYPE = 0
local ROOF_TYPE = 1
local ROAD_TYPE = 2
local PAVEMENT_TYPE = 3

local renderMat = Material( "stormfox/tool/sf_screen_mat" )
local tool = {}
	tool.name = "sf_tool.maptexture"
	tool.help = {"sf_tool.maptexture.helpm1","sf_tool.maptexture.helpm2"}
	local mat_r = Material("vgui/spawnmenu/hover")
	local mat_rs = Material("gui/workshop_rocket.png")
	local mat_num = { Material("sprites/key_0"),Material("sprites/key_1"),Material("sprites/key_2"),Material("sprites/key_3")}
	local r_num = {	"sf_type.dirtgrass","sf_type.roof","sf_type.road","sf_type.pavement"}
-- Generate UnlitGeneric
	local gen = "_"
	local function GetMaterial(str)
		str = str:lower()
		if str:sub(0,5) == "tools" then return end
		if gen == str then return renderMat,str end
		local mat = Material(str)
		local t = mat:GetString( "$basetexture" )
		if ( t ) then
			if StormFox.TexHandler.GetOriginial(str) then -- We havve replaced this material. Lets get the basetexture
				t = StormFox.TexHandler.GetOriginial(str)
			end
		end
		renderMat:SetTexture("$basetexture", t)
		renderMat:SetInt("$ignorez",1)
		gen = str
		return renderMat,str
	end
-- Get material
	local function FindMaterial(trace)
		if not trace then return end
		if not trace.Hit then return end
		if not trace.HitTexture then return end
		if not trace.HitWorld then return end
		if trace.HitSky then return end
		local m = Material(trace.HitTexture)
		if m:IsError() then return end
		return GetMaterial(trace.HitTexture)
	end
-- Get material list
	local function IsAdded(str)
		if not StormFox.TexHandler then return false end
		if not StormFox.TexHandler.Materials then return false end
		local tr = StormFox.TexHandler.Materials()
		if not tr or not tr.map then return false end
		return tr.map[str:lower()]
	end

tool.RenderScreen = function(w,h,trace)
	local mat,str = FindMaterial(trace)
	if not mat then
		surface.SetDrawColor(255,0,0)
		surface.DrawOutlinedRect(w * 0.1,w * 0.1,w * 0.8,w * 0.8)
		surface.DrawLine(w * 0.1,w * 0.1,w * 0.9,w * 0.9)
		surface.DrawLine(w * 0.1,w * 0.9,w * 0.9,w * 0.1)
	else
		surface.SetDrawColor(255,255,255)
		surface.SetMaterial(renderMat)
		surface.DrawTexturedRect(w * 0.1,w * 0.1,w * 0.8,w * 0.8)
		local s = w * 0.2
		surface.SetMaterial(mat_r)
		surface.DrawTexturedRect(w / 2 - s / 2,h - s,s,s)
		local add = IsAdded(str)
		if add then
			local s2 = w * 0.32
			local n = s - s2
			surface.SetDrawColor(122,252,122)
			surface.SetMaterial(mat_rs)
			surface.DrawTexturedRect(w / 2 - s2 / 2,h - s2 - n / 2,s2,s2)
			local n = ( add[1] or -1 ) + 1
			if mat_num[n] then
				local t = r_num[n]
				if t then
					draw.DrawText(StormFox.Language.Translate(t),"sf_tool_large",w / 2 - 1,5,Color(0,0,0),1)
					draw.DrawText(StormFox.Language.Translate(t),"sf_tool_large",w / 2,6,Color(255,255,255),1)
				else
					surface.SetDrawColor(0,0,0)
					surface.SetMaterial(mat_num[n])
					surface.DrawTexturedRect(w / 2 - s / 2,h - s,s,s)
				end
			end
		end
	end
end
tool.DrawHUD = function(trace)

end

local function ValidTexture(tex)
	if not tex then return false end
	if tex:GetName() == "" or tex:GetName() == "error" then return false end
	return true
end
local w,h = 240,130
local function openMatMenu(str)
	if not str then return end
	if STORMFOX_TOOL_MAT then
		STORMFOX_TOOL_MAT:Remove()
	end
	surface.SetFont("mgui_default")
	local t = str:lower()
	local tw = surface.GetTextSize(t)
	local ts = (#t / tw) * 200
	if tw > 220 then
		t = ".." .. t:sub(#t-ts)
	end
	local mat = Material(str)
	STORMFOX_TOOL_MAT = mgui.Create("DFrame")
	STORMFOX_TOOL_MAT:SetTitle(t)
	STORMFOX_TOOL_MAT:SetSize(w,h)
	STORMFOX_TOOL_MAT:Center()
	STORMFOX_TOOL_MAT:MakePopup()
	local dark = cookie.GetNumber("SF-DarkTheme",1) == 1
	local r = cookie.GetNumber("SF-ThemeR",30)
	local g = cookie.GetNumber("SF-ThemeG",136)
	local b = cookie.GetNumber("SF-ThemeB",229)

	STORMFOX_TOOL_MAT:SetPallete(Color(r, g, b),nil,dark)

	local base_texture = mgui.Create("Switch",STORMFOX_TOOL_MAT)
	local base_texture2 = mgui.Create("Switch",STORMFOX_TOOL_MAT)
	base_texture:SetPos(20 , 24)
	base_texture2:SetPos(20 , 48)
	local l = mgui.Create("Label",STORMFOX_TOOL_MAT)
	local l2 = mgui.Create("Label",STORMFOX_TOOL_MAT)
	l:SetPos(60 , 24)
	l2:SetPos(60 , 48)
	l:SetText("$basetexture")
	l2:SetText("$basetexture2")
	l:SizeToContentsX(5)
	l2:SizeToContentsX(5)

	local mat_type = vgui.Create( "DComboBox", STORMFOX_TOOL_MAT )
	mat_type:SetPos( 10, 72 )
	mat_type:SetSize( w - 20, 20 )
	mat_type:SetValue( StormFox.Language.Translate("sf_type.dirtgrass") )
	mat_type:AddChoice( StormFox.Language.Translate("sf_type.dirtgrass") )
	mat_type:AddChoice( StormFox.Language.Translate("sf_type.roof") )
	mat_type:AddChoice( StormFox.Language.Translate("sf_type.road") )
	mat_type:AddChoice( StormFox.Language.Translate("sf_type.pavement") )

	local t1,t2 = mat:GetTexture("$basetexture"),mat:GetTexture("$basetexture2")
	-- Basetexture
		if ValidTexture(t1) then
			base_texture.state = true
		else
			base_texture:SetDisabled( true )
		end
	-- Bastexture2
		if ValidTexture(t2) then
			-- Default on
				if not base_texture.state then
					base_texture2.state = true
				end
		else
			base_texture2:SetDisabled( true )
		end
	-- Add
		local b = mgui.Create("Button",STORMFOX_TOOL_MAT)
		b:SetText("sf_tool.addmaterial")
		b:SetSize(80,24)
		b:SetPos(w / 4 - 40,h - 30)
		function b:Think()
			if not base_texture.state and not base_texture2.state then
				self:SetDisabled(true)
			else
				self:SetDisabled(false)
			end
		end
		b.str = str
		function b:DoClick()
			net.Start("StormFox_Tool")
				net.WriteInt(0,3)
				net.WriteString(self.str)
				net.WriteBool(base_texture.state)
				net.WriteBool(base_texture2.state)
				net.WriteInt(math.max(mat_type:GetSelectedID() or 1,1) - 1,5)
			net.SendToServer()
			STORMFOX_TOOL_MAT:Remove()
		end
	-- Remove
		local b2 = mgui.Create("Button",STORMFOX_TOOL_MAT)
		b2:SetText("sf_tool.cancel")
		b2:SetSize(80,24)
		b2:SetPos((w / 4 * 3) - 40,h - 30)
		function b2.DoClick()
			STORMFOX_TOOL_MAT:Remove()
		end
	STORMFOX_TOOL_MAT:ShowCloseButton(false)
end
tool.LeftClick = function(trace)
	local mat,str = FindMaterial(trace)
	if not mat then return false end
	if IsAdded(str) then return false end -- Already made
	openMatMenu(str)
	return true
end
tool.RightClick = function(trace)
	local mat,str = FindMaterial(trace)
	if not mat then return false end
	if not IsAdded(str) then return false end -- Not a part of the map
	net.Start("StormFox_Tool")
		net.WriteInt(1,3)
		net.WriteString(str)
	net.SendToServer()
	return true
end
return tool