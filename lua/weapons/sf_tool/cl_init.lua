
include( "shared.lua" )

SWEP.Slot			= 5
SWEP.SlotPos		= 6
SWEP.DrawAmmo		= false
SWEP.DrawCrosshair	= true

SWEP.WepSelectIcon = surface.GetTextureID( "vgui/sf_tool" )
SWEP.ToolNameHeight = 0
	local mat_n = Material("effects/tvscreen_noise002a")
function SWEP:Initialize()
	self:SetHoldType( "revolver" )
	self.launch = 0
	self.mode = nil
end

surface.CreateFont( "sf_tool_large", {
	font = "Verdana", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 30,
	weight = 700,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = true,
} )

surface.CreateFont( "sf_tool_small", {
	font = "Verdana",
	size = 17,
	weight = 1000
} )

local tools = {}
-- Add tools
	for _,fil in ipairs(file.Find("weapons/sf_tool/tools/*.lua","LUA")) do
		local n_t = include("weapons/sf_tool/tools/" .. fil)
		tools[n_t.name or #tools..""] = n_t
	end

local matScreen = Material( "stormfox/tool/sf_screen" )
local mBackground = Material("stormfox/tool/sf_screen_bg")
local ScreenSize = 256
local RTTexture = GetRenderTarget( "SFToolgunScreen", ScreenSize, ScreenSize )
function SWEP:RenderToolScreen()
	local TEX_SIZE = ScreenSize
	local oldW = ScrW()
	local oldH = ScrH()
	-- Set the material of the screen to our render target
		local OldRT = render.GetRenderTarget()
	-- Set up our view for drawing to the texture
		--cam.IgnoreZ(true)
		render.PushRenderTarget( RTTexture )
		render.ClearDepth()
		render.Clear( 0, 0, 0, 0 )
		cam.Start2D()
	-- Draw Screen
		if self.launch < 3 then
			-- Launch effect
				if self.launch == 0 then
					self:EmitSound("ambient/machines/combine_terminal_idle4.wav")
					self.launch = 0.1
				end
				self.launch = self.launch + FrameTime()
				if self.launch >= 3 then
					self:EmitSound("buttons/button14.wav")
				end
				surface.SetDrawColor( Color(255,255,255) )
				surface.SetMaterial( mBackground )
				surface.DrawTexturedRect( 0, 0, TEX_SIZE, TEX_SIZE )
				local t = "SF tool v" .. StormFox.Version
				local ft = ""
				local pl = 1.5 / #t
				for i = 1,#t do
					if self.launch > pl * i then
						ft = ft .. t[i]
					else
						ft = ft .. " "
					end
				end
				draw.DrawText(ft,"Trebuchet24",TEX_SIZE / 2,TEX_SIZE * 0.8,Color(255,255,255),1)
				local mw = TEX_SIZE
				local p = self.launch / 2
				if math.Round(self.launch * 3) % 2 < 1 then
					p = math.Round(self.launch / 2 ,1)
				end
				surface.DrawRect(0,TEX_SIZE * 0.95,mw * p,TEX_SIZE * 0.1)
		else
			local tool = tools[self.mode or ""]
			if not tool then
				draw.DrawText(StormFox.Language.Translate("sf_tool.menu_reload"),"Trebuchet24",TEX_SIZE / 2,TEX_SIZE * 0.8,Color(255,255,255),1)
				surface.SetMaterial(Material("gui/r.png"))
				surface.SetDrawColor(255,255,255)
				surface.DrawTexturedRect(TEX_SIZE / 2 - 30,TEX_SIZE / 2 - 30,60,60)
			else
				local tr = self.Owner:GetEyeTrace()
				if tool.RenderScreen then
					tool.RenderScreen(TEX_SIZE,TEX_SIZE,tr)
				end
			end
		end
	-- End
		local n = math.Rand(0.3,0.4)
		mat_n:SetVector("$color",Vector(n,n,n))
		surface.SetMaterial(mat_n)
		surface.SetDrawColor(255,255,255,1)
		surface.DrawTexturedRect(0,0,oldW,oldW)
		mat_n:SetVector("$color",Vector(1,1,1))
		cam.End2D()
		render.PopRenderTarget()

		matScreen:SetTexture( "$basetexture", RTTexture )
		--cam.IgnoreZ(false)
end
local mTool = Material("stormfox/tool/sf_tool")
function SWEP:PreDrawViewModel()
	self:RenderToolScreen()
	render.MaterialOverrideByIndex(1,matScreen)
	render.MaterialOverrideByIndex(2,mTool)
end
function SWEP:PostDrawViewModel()
	render.MaterialOverrideByIndex()
end
function SWEP:DrawWorldModel()
	if self.Owner and self.Owner == LocalPlayer() then
		render.MaterialOverrideByIndex(1,matScreen)
	else
		render.MaterialOverrideByIndex(1,mBackground)
	end
	render.MaterialOverrideByIndex(2,mTool)
	self:DrawModel()
	render.MaterialOverrideByIndex()
end
local tex_id = surface.GetTextureID( "gui/gradient" )
function SWEP:DrawHUD()
	if self.launch < 3 then return end
	local tool = tools[self.mode or ""]
	local title = StormFox.Language.Translate(tool and tool.name or "sf_tool.menu")
	local help_text = tool and tool.help or {"sf_tool.menu_reload"}

	surface.SetFont("sf_tool_large")
	local w,h = surface.GetTextSize(title)
	local title_h = h
	surface.SetFont("sf_tool_small")
	local help_array = {}
	local hth = 0
	for i = 1,#help_text do
		help_array[i] = StormFox.Language.Translate(help_text[i])
		local tw,th = surface.GetTextSize(help_array[i])
		w,hth = math.max(w,tw),math.max(hth,th)
	end
	h = h + hth * #help_text
	-- BG
		surface.SetTexture(tex_id)
		surface.SetDrawColor(0,0,0)
		surface.DrawTexturedRect(0,0,w + 40,h + 40)
	-- Title
		surface.SetFont("sf_tool_large")
		surface.SetTextColor(255,255,255)
		surface.SetTextPos(20,20)
		surface.DrawText(title)
	-- Help text
		surface.SetFont("sf_tool_small")
		for i = 1,#help_array do
			surface.SetTextPos(20,5 + title_h + hth * i)
			surface.DrawText(help_array[i])
		end
	if not tool then return end
	if tool.DrawHUD then
		local tr = self.Owner:GetEyeTrace()
		tool.DrawHUD(tr)
	end
end

function SWEP:OnReloaded()
	self.launch = 0
end
function SWEP:Reload()
	if self.launch < 3 then return end
	if ( not self.Owner:KeyPressed( IN_RELOAD ) ) then return end
	-- Open menu
		if STORMFOX_TOOL then
			STORMFOX_TOOL:Remove()
		end
		local w,h = 240,130
		-- Create DFrame
			STORMFOX_TOOL = mgui.Create("DFrame")
			STORMFOX_TOOL:SetTitle("sf_tool.menu")
			STORMFOX_TOOL:SetSize(w,h)
			STORMFOX_TOOL:Center()
			STORMFOX_TOOL:MakePopup()
			local dark = cookie.GetNumber("SF-DarkTheme",1) == 1
			local r = cookie.GetNumber("SF-ThemeR",30)
			local g = cookie.GetNumber("SF-ThemeG",136)
			local b = cookie.GetNumber("SF-ThemeB",229)
			STORMFOX_TOOL:SetPallete(Color(r, g, b),nil,dark)
		-- Create cbox
			local box = vgui.Create( "DScrollPanel", STORMFOX_TOOL )
			box:SetPos( 0, 24 )
			box:SetSize( w , h - 24 )
			local i = 0
			local wep = self
			for k,v in pairs(tools) do
				i = i + 1
				local b = mgui.Create("DButton",box)
				b:SetPos(10,i * 24 - 24)
				b:SetSize(w - 20,24)
				b:SetText(k)
				b.mode = k
				function b:DoClick()
					STORMFOX_TOOL:Remove()
					wep.mode = self.mode
				end
			end
end
-- M1 and M2
	function SWEP:CanPrimaryAttack()
		if self.launch < 3 then return false end
		if self.Owner ~= LocalPlayer() then return true end
		local tr = self.Owner:GetEyeTrace()
		local tool = tools[self.mode or ""]
		if not tool then return false end
		if not (tool.LeftClick and tool.LeftClick(tr)) then self:EmitSound("buttons/button10.wav") return false end
		return true
	end

	function SWEP:CanSecondaryAttack()
		if self.launch < 3 then return false end
		local tr = self.Owner:GetEyeTrace()
		local tool = tools[self.mode or ""]
		if not tool then return false end
		if not (tool.RightClick and tool.RightClick(tr)) then self:EmitSound("buttons/button10.wav")  return false end
		return true
	end