
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
			surface.SetFont("StormFox-Console")
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
		if options[title] and dontshow_option then return end
		if occurred[problem] then return end
		if snd then
			LocalPlayer():EmitSound(snd)
		end
			occurred[problem] = true -- Error protection
		print("[StormFox] " .. title)
		print(problem)
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
			textbox:SetFont("StormFox-Console")
			local ctext = ""
			local texta = {}
			for word in string.gmatch( problem or "An unknown error occurred.", "[^%s]+" ) do
				surface.SetFont("StormFox-Console")
				local new_text = ctext .. (#ctext > 0 and " " or "") .. word
				if surface.GetTextSize(new_text) < w - 10 then
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
				tick:SetText(StormFox.Language.Translate("sf_warning_missingmaterial.nevershow"))
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

	net.Receive("StormFox - SendMessageBox",function()
		ShowMessageBox(net.ReadString(),net.ReadString(),false,nil,net.ReadString())
	end)
--[[-------------------------------------------------------------------------
Material scanner
---------------------------------------------------------------------------]]
	local material_list = {
		"stormfox/effects/foot_hq.png",
		"stormfox/effects/foot_hql.png",
		"stormfox/effects/foot_m.png",
		"stormfox/effects/foot_s.png",
		"stormfox/effects/lightning.png",
		"stormfox/effects/lightning2.png",
		"stormfox/effects/lightning3.png",
		"stormfox/effects/lightning_end.png",
		"stormfox/effects/lightning_end2.png",
		"stormfox/effects/moon.png",
		"stormfox/effects/raindrop",
		"stormfox/effects/raindrop2",
		"stormfox/effects/raindrop3",
		"stormfox/effects/rainscreen",
		"stormfox/effects/rainscreen_dummy",
		"stormfox/models/char_coal",
		"stormfox/models/clock_material",
		"stormfox/models/clock_mini_material",
		"stormfox/models/combine_light_off",
		"stormfox/models/firewood_burn",
		"stormfox/models/moon_edit",
		"stormfox/models/oil_lamp",
		"stormfox/models/oil_lamp_glass",
		"stormfox/models/parklight_off",
		"stormfox/models/sf_effect_ent",
		"stormfox/models/sun_edit",
		"stormfox/models/torch_bark",
		"stormfox/models/torch_base",
		"stormfox/models/torch_cap",
		"stormfox/moon_phases/0.png",
		"stormfox/moon_phases/25.png",
		"stormfox/moon_phases/50.png",
		"stormfox/moon_phases/75.png",
		"stormfox/symbols/Celsius.png",
		"stormfox/symbols/Cloudy.png",
		"stormfox/symbols/Cloudy_Windy.png",
		"stormfox/symbols/Fahrenheit.png",
		"stormfox/symbols/Fog.png",
		"stormfox/symbols/Icy.png",
		"stormfox/symbols/Night - Cloudy.png",
		"stormfox/symbols/Night.png",
		"stormfox/symbols/Radioactive.png",
		"stormfox/symbols/Raining - Thunder.png",
		"stormfox/symbols/Raining - Windy.png",
		"stormfox/symbols/Raining.png",
		"stormfox/symbols/RainingSnowing.png",
		"stormfox/symbols/Sandstorm.png",
		"stormfox/symbols/Snowing.png",
		"stormfox/symbols/Sunny.png",
		"stormfox/symbols/Thunder.png",
		"stormfox/symbols/Windy.png",
		"stormfox/symbols/time_default.png",
		"stormfox/symbols/time_pause.png",
		"stormfox/symbols/time_slow.png",
		"stormfox/symbols/time_speedup.png",
		"stormfox/symbols/time_speedup2.png",
		"stormfox/symbols/time_speedup3.png",
		"stormfox/tool/sf_screen",
		"stormfox/tool/sf_screen_bg",
		"stormfox/SF.png",
		"stormfox/SF_cl_settings.png",
		"stormfox/StormFox.png",
		"stormfox/clouds_big.png",
		"stormfox/imdoinguselessthings.png",
		"stormfox/moon_glow",
		"stormfox/raindrop-multi.png",
		"stormfox/raindrop.png",
		"stormfox/shadow_sprite",
		"stormfox/small_shadow_sprite",
		"stormfox/snow-multi.png",
	}


	--[[ -- Function to update the materiallist.
	function PrintDebugList()
		print("Printing current material list:")
		print("	local material_list = {")
		local function AddDir(dir,dirlen)
			if not dirlen then dirlen = dir:len() end
			local files, folders = file.Find(dir .. "/*", "GAME")
			for _, fdir in ipairs(folders) do
				if fdir ~= ".svn" then
					AddDir(dir .. "/" .. fdir)
				end
			end
			for k, v in ipairs(files) do
				local fil = dir .. "/" .. v --:sub(dirlen + 2)
				if string.find(fil,".vmt") or string.find(fil,".png") then
					local m = string.Replace(fil,".vmt","")
						m = string.Replace(m,"materials/","")
					print('		"' .. m .. '"' .. ",") -- Create a list of materials for material-checker
				end
			end
		end
		AddDir("materials/stormfox")
		print("	}")
	end
	--]]
	timer.Simple(10,function()
		local a = {}
		for _,matstr in ipairs(material_list) do
			if Material(matstr):IsError() then
				table.insert(a,matstr)
			end
		end
		if #a > 0 then
			ShowMessageBox(StormFox.Language.Translate("sf_warning_missingmaterial.title"),StormFox.Language.Format("sf_warning_missingmaterial",#a),true)
			print("[StormFox]: " .. StormFox.Language.Translate("sf_warning_missingmaterial.title"))
			PrintTable(a)
		end
	end)
--[[-------------------------------------------------------------------------
Check for low FPS and high settings
---------------------------------------------------------------------------]]
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
--[[-------------------------------------------------------------------------
Check for hooks overriding (+ sh_debugcompatibility.lua)
---------------------------------------------------------------------------]]
	if StormFox.DebugHooks and hook.GetCallResult then
		-- Adv debugging enabled

		timer.Create("StormFox - Debugger",20,0,function()
			for hook_name,_ in pairs(StormFox.DebugHooks()) do
				local result = hook.GetCallResult(hook_name) or {}
				if result.short_src and result.short_src ~= "[C]" and not string.find(result.short_src,"/stormfox/") then
					-- This addon returns stuff ..
					ShowMessageBox("A mod is breaking hooks!",result.short_src .. " is breaking StormFox and other mods by blocking " .. hook_name .. "-hooks.",false,nil,"vo/eli_lab/eli_lookgordon.wav")
				end
			end
		end)
	end
--[[-------------------------------------------------------------------------
Check for commen problems
---------------------------------------------------------------------------
	local problemTree = {}
	-- Black triangles on 2D maps
		function _light_on_2dsky()
			-- if dynamic light is allowed and its a 2D sky
		--	if not StormFox.GetMapSetting("dynamiclight") or StormFox.Is3DSkybox() then return false end
			local function DIS()
				net.Start("sf_mapsettings")
					net.WriteString("set")
					net.WriteString("dynamiclight")
					net.WriteType(false)
				net.SendToServer()
			end
			return "Dynamic light on 2D maps can cause black triangles. Want to disable dynamiclight for all clients?",DIS
		end
		problemTree["_sky_problem"] = _light_on_2dsky
	-- Angry clients who hate SF
		local function _angry_clients()
			local con = GetConVar("sf_allowcl_disableeffects")
			if con:GetBool() then return false end
			local function DIS()
				net.Start("StormFox_Settings")
					net.WriteString("sf_allowcl_disableeffects")
					net.WriteString("1")
				net.SendToServer()
			end
			return "Allow clients to disable SF? (Clients might get an unfair advantage in heavy rain with this.)",DIS
		end
		problemTree["_sky_problem"] = _light_on_2dsky


local function commenwizard()

end]]
