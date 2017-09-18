--[[-------------------------------------------------------------------------
Functions
---------------------------------------------------------------------------]]
	local colors = {}
		colors[1] = Color(241,223,221,255)
		colors[2] = Color(78,85,93,255)
		colors[3] = Color(51,56,60)
		colors[4] = Color(47,50,55)
	local clamp,round,floor,cos,sin,rad = math.Clamp,math.Round,math.floor,math.cos,math.sin,math.rad

	local sf_icon = Material("stormfox/sf.png","noclamp")
	local grad = Material("gui/gradient_up")
	local m_arrow = Material("gui/arrow")
	local m_thunder = Material("stormfox/symbols/thunder.png")
	local m_cloudy = Material("stormfox/symbols/Cloudy.png")
	local m_cir = Material("vgui/circle")

	local function CreateButton(panel,text)
		local button = vgui.Create("DButton",panel)
		button:SetText("")
		button:SetSize(100,22)
		button.text = text or ""
		function button:Paint(w,h)
			if self:IsDown() then
				surface.SetDrawColor(colors[3])
			else
				surface.SetDrawColor(colors[2])
			end
			surface.DrawRect(0,0,w,h)
			surface.SetMaterial(grad)
			surface.SetDrawColor(colors[3])
			surface.DrawTexturedRect(0,0,w,h)
			surface.SetDrawColor(colors[4])
				surface.DrawLine(0,0,w,0)
				surface.DrawLine(0,0,0,h)
				surface.DrawLine(w - 1,0,w - 1,h)
				surface.DrawLine(w - 1,0,w - 1,h - 1)
			local col = Color(241,223,221)
			if self:IsDown() then
				col.a = 25
			end
			surface.SetTextColor(col)
			surface.SetFont("SkyFox-Console")
			local tw,th = surface.GetTextSize(self.text)
			surface.SetTextPos(w / 2 - tw / 2,h / 2 - th / 2)
			surface.DrawText(self.text)
		end
		return button
	end
--[[-------------------------------------------------------------------------
Problem finder
---------------------------------------------------------------------------]]
local options = {}
if file.Exists("stormfox/wizzard.txt","DATA") then
	options = util.JSONToTable(file.Read("stormfox/wizzard.txt","DATA")) or {}
end
local occurred = {}
local function ShowMessageBox(title,problem,dontshow_option,yesnooption,snd)
	if options[title] then return end
	if occurred[problem] then return end
	if snd then
		print(snd)
		LocalPlayer():EmitSound(snd)
	end
		occurred[problem] = true -- Error protection
	local w,h = 320,160
	local panel = vgui.Create("DFrame")
		panel:SetSize(w,h)
		panel:Center()
		function panel.Paint(self,w,h)
			surface.SetDrawColor(colors[2])
			surface.DrawRect(0,0,w,h)
			surface.SetDrawColor(colors[4])
			surface.DrawRect(0,0,w,24)
			surface.SetMaterial(sf_icon)
			surface.SetDrawColor(255,0,0,25)
			surface.DrawTexturedRectUV(w - 96, 24, 120, 96,0,0.2,1,1)
		end
		panel:SetTitle("StormFox: " .. (title or "A problem occurred"))
		local textbox = vgui.Create("DLabel",panel)
		textbox:SetSize(w,h)
		textbox:SetFont("SkyFox-Console")
		local ctext = ""
		local texta = {}
		for word in string.gmatch( problem or "An unknown error occurred.", "[^%s]+" ) do
			surface.SetFont("SkyFox-Console")
			local new_text = ctext .. (#ctext > 0 and " " or "") .. word
			if surface.GetTextSize(new_text) < w then
				ctext = new_text
			else
				table.insert(texta,ctext)
				ctext = word
			end
		end
		table.insert(texta,ctext)
		handetext = table.concat(texta,"\n")
		textbox:SetText(handetext)
		textbox:SetAutoStretchVertical(true)
		textbox:SetPos(10,30)
		local tick
		if dontshow_option then
			tick = vgui.Create("DCheckBoxLabel",panel)
			tick:SetText("Never show this again.")
			tick:SetValue(0)
			tick:SizeToContents()
			tick:SetPos(w - tick:GetSize() - 2,h - 16)
		end
		local closebutton = CreateButton(panel,"Ok")
		local ww,hh = closebutton:GetSize()
		if not yesnooption then
			closebutton:SetPos(w / 2 - ww / 2, h - 40)
		else
			closebutton:SetPos(w / 3 * 2 - ww / 2, h - 40)
			local yesbutton = CreateButton(panel,"Yes")
			closebutton.text = "No"
			local ww,hh = yesbutton:GetSize()
			yesbutton:SetPos(w / 3 - ww / 2, h - 40)
			function yesbutton.DoClick ()
				if tick and tick:GetChecked() then
					options[title] = true
					file.Write("stormfox/wizzard.txt",util.TableToJSON(options))
				end
				yesnooption()
				panel:Remove()
			end
		end
		function closebutton.DoClick ()
			if tick and tick:GetChecked() then
				options[title] = true
				file.Write("stormfox/wizzard.txt",util.TableToJSON(options))
			end
			panel:Remove()
		end
	panel:MakePopup()
	panel:ShowCloseButton(false)
end

--[[-------------------------------------------------------------------------
Conflict scanner
---------------------------------------------------------------------------]]
local material_list = {"stormfox/effects/raindrop.vmt",
	"stormfox/effects/raindrop2.vmt",
	"stormfox/effects/raindrop3.vmt",
	"stormfox/effects/rainscreen.vmt",
	"stormfox/effects/rainscreen_dummy.vmt",
	"stormfox/symbols/Celsius.png",
	"stormfox/symbols/Cloudy.png",
	"stormfox/symbols/Cloudy_Windy.png",
	"stormfox/symbols/Fahrenheit.png",
	"stormfox/symbols/Fog.png",
	"stormfox/symbols/Icy.png",
	"stormfox/symbols/Night - Cloudy.png",
	"stormfox/symbols/Night.png",
	"stormfox/symbols/Raining - Thunder.png",
	"stormfox/symbols/Raining - Windy.png",
	"stormfox/symbols/Raining.png",
	"stormfox/symbols/RainingSnowing.png",
	"stormfox/symbols/Snowing.png",
	"stormfox/symbols/Sunny.png",
	"stormfox/symbols/Thunder.png",
	"stormfox/symbols/Windy.png",
	"stormfox/MaterialReplacement.png",
	"stormfox/clock_material.vmt",
	"stormfox/combine_light_off.vmt",
	"stormfox/imdoinguselessthings.png",
	"stormfox/moon_dark.png",
	"stormfox/moon_fix.vmt",
	"stormfox/moon_full.png",
	"stormfox/moon_glow.vmt",
	"stormfox/normalmap.png",
	"stormfox/raindrop-multi.png",
	"stormfox/raindrop.png",
	"stormfox/sf.png",
	"stormfox/shadow_sprite.vmt",
	"stormfox/small_shadow_sprite.vmt",
	"stormfox/snow-multi.png",
	"stormfox/stormfox.png"
}
timer.Simple(30,function()
	if g_SkyPaint then
		_STORMFOX_TOPCOLOROR = _STORMFOX_TOPCOLOROR or g_SkyPaint.SetTopColor
		function g_SkyPaint.SetTopColor(...)
			local calldata = string.Explode("\n",debug.traceback())[3]
			local caller = string.match(calldata,"%s-([%a%d/_-]+).lua")
			local addon = string.match(caller,"addons/(.-)/")
			caller = addon or "Unknown"
			if caller ~= "stormfox_rm" then
				ShowMessageBox("A mod is causing conflict","A mod is causing conflict with StormFox.\nThe mod is called '" .. caller .. "'.",true)
			end
			_STORMFOX_TOPCOLOROR(...)
			--ShowMessageBox(title,problem,dontshow_option,yesnooption)
		end
	end
	local a = {}
	for _,matstr in ipairs(material_list) do
		if Material(matstr):IsError() then
			table.insert(a,matstr)
		end
	end
	if #a > 0 then
		ShowMessageBox("You're missing materials","You're missing " .. #a .. " material" .. (#a ~= 1 and "s" or "") .. ". ",true)
	end
end)

local ts = SysTime() + 30
timer.Create("StormFox - Wizzardcheck",4,0,function()
	-- Only do this after 10 seconds. Just in case.
	if ts >= SysTime() or not system.HasFocus() then return end
	-- Check FPS vs quality settings
	if StormFox.GetAvageFPS() < 20 then
		-- Damn that is a slow framerate
		local t = {}
			t["sf_exspensive"] = 0
			t["sf_allow_dynamiclights"] = 0
			t["sf_allow_sunbeams"] = 0
			t["sf_allow_dynamicshadow"] = 0
			t["sf_allow_raindrops"] = 0
		-- Check if we can change anything
		local samevars = true
		for con,var in pairs(t) do
			local c = GetConVar(con)
			if c:GetFloat() ~= var then
				samevars = false
				break
			end
		end
		if samevars then return end
		ShowMessageBox("Low FPS!","Detected low framerate. Want to set everything on low quality?",true,function()
			for con,var in pairs(t) do
				RunConsoleCommand(con,var)
			end
			LocalPlayer():EmitSound("buttons/lever2.wav")
			ShowMessageBox("Done","All settings are now set to low.")
		end,"vo/k_lab/ba_pushinit.wav")
	end
end)