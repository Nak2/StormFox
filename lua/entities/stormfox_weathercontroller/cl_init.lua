include("shared.lua")

function ENT:Initialize()
	self.sw = StormFox.GetWeathersDefaultNumber()
	self.swp = 0.5
end

local cos,sin,rad,min,max = math.cos,math.sin,math.rad,math.min,math.max
local mat = Material("models/props_combine/combine_intmonitor001_disp_off")

	surface.CreateFont( "StormFox-Console_B", {
			font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
			extended = false,
			size = 30,
			weight = 500,
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
			outline = false,
	} )
	surface.CreateFont( "StormFox-Console", {
			font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
			extended = false,
			size = 15,
			weight = 500,
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
			outline = false,
	} )

-- Thanks wiki
local function WorldToScreen(vWorldPos,vPos,vScale,aRot)
	local vWorldPos=vWorldPos-vPos;
	vWorldPos:Rotate(Angle(0,-aRot.y,0));
	vWorldPos:Rotate(Angle(-aRot.p,0,0));
	vWorldPos:Rotate(Angle(0,0,-aRot.r));
	return vWorldPos.x / vScale,(-vWorldPos.y) / vScale;
end

local col = Color(155 ,155 ,255)
local m_arrow = Material("gui/arrow")
local c_arrow = Material("sprites/arrow")

local function WithinABox(ax,ay,x,y,w,h)
	if ax < x then return false end
	if ax > x + w then return false end
	if ay < y then return false end
	if ay > y + h then return false end
	return true
end

local function RenderButton(x,y,w,h,ax,ay,mat,r,a)
	local b = false
	if WithinABox(ax,ay,x,y,w,h) then
		surface.SetDrawColor(255,255,255,a or 255)
		b = true
	else
		surface.SetDrawColor(col.r,col.g,col.b,a or 255)
	end
	if mat then
		surface.SetMaterial(mat)
		surface.DrawTexturedRectRotated(x + w / 2,y + h / 2,w,h,r or 0)
	else
		surface.DrawRect(x,y,w,h)
	end
	return b
end

local env_tonemap_controller = false
local light_environment = false
local env_fog_controller = false
local env_sun = false
local env_skypaint = false
local shadow_control = false

local l = 0
function ENT:Think()
	if l > SysTime() then return end
		l = SysTime() + 1
	env_tonemap_controller = StormFox.GetNetworkData("has_env_tonemap_controller",false)
	light_environment = StormFox.GetNetworkData("has_light_environment",false)
	env_fog_controller = StormFox.GetNetworkData("has_env_fog_controller",false)
	env_skypaint = StormFox.GetNetworkData("has_env_skypaint",false)
	shadow_control = StormFox.GetNetworkData("has_shadow_control",false)
end

local function drawdebug(x,y,str,var,disabled)
	local c = var and Color(0,255,0) or Color(255,0,0)
	if var and disabled then
		var = "disabled"
		c = Color(0,0,255)
	end
	local wl = surface.GetTextSize(tostring(var))
	draw.DrawText( tostring(var), "default", x, y, c, 2 )
	draw.DrawText( str .. ": ", "default", x - wl, y, Color(255,255,255), 2 )
end

local E = false
local round,floor = math.Round,math.floor
function ENT:Draw()
	render.MaterialOverrideByIndex( 1, mat )
		self:DrawModel()
	render.MaterialOverrideByIndex()
	if ( halo.RenderedEntity() == self ) then return end
	if not StormFox then return end
	if not StormFox.GetTime then return end

	local campos = self:LocalToWorld(Vector(30,-12,45))
	cam.Start3D2D(campos,self:LocalToWorldAngles(Angle(0,90,90)),0.1)
		-- Debug values
		local weathers = StormFox.GetWeathers()
		local x = -80
		draw.RoundedBox(3,x - 110,40,114,138,col)
		draw.RoundedBox(3,x - 150,40,152,138,Color(0,0,0,255))

			local t = StormFox.Language.Translate("sf_description.map_entities") .. ":"
			draw.DrawText( t, "default", x,40,col, 2 )
			drawdebug(x,54,"tonemap_controller",env_tonemap_controller,not light_environment)
			drawdebug(x,54 + 18,"light_environment",light_environment)
			drawdebug(x,54 + 36,"env_fog_controller",env_fog_controller)
			drawdebug(x,54 + 54,"env_skypaint",env_skypaint)
			drawdebug(x,54 + 72,"shadow_control",shadow_control)
			drawdebug(x,54 + 90,"3D skybox",StormFox.Is3DSkybox())

		local ax,ay = 0,0
		if LocalPlayer():GetEyeTrace().Entity == self then
			ax,ay = WorldToScreen(LocalPlayer():GetEyeTrace().HitPos,campos,0.1,self:LocalToWorldAngles(Angle(0,90,90)))
			ax = min(max(ax,20),220)
			ay = min(max(ay,0),340)
		end

		local s = 24
		local selected = -1

		if WithinABox(ax,ay,50,5,152,25) then
			selected = 0
		end

		local c = col
		if selected == 0 then
			c = Color(255,255,255)
		end
		surface.SetFont("StormFox-Console_B")
		local setw_text = StormFox.Language.Translate("sf_setweather")
		local tw,th = surface.GetTextSize(setw_text)
		surface.SetTextColor(c)
		surface.SetTextPos(120 - tw / 2,0)
		surface.DrawText(setw_text)
		surface.SetDrawColor(c)
		surface.DrawOutlinedRect(120 - tw / 2,0,tw,th)

		local t = weathers[self.sw or 1]
		local title = t
		if StormFox.WeatherTypes[t] then
			title = StormFox.WeatherTypes[t].Name or weather
		end

		surface.SetMaterial(StormFox.GetWeatherType(t):GetStaticIcon( ))
		surface.SetDrawColor(col)
		surface.DrawTexturedRect(100,40,40,40)
		surface.SetMaterial(StormFox.Weather:GetIcon())
		surface.DrawTexturedRect(-10,40,50,50)

		draw.DrawText( StormFox.Language.Translate(title), "StormFox-Console", 120, 80, col, 1 )

		if RenderButton(68,68,24,24,ax,ay,m_arrow,90) then
			selected = 1
		end
		if RenderButton(148,68,24,24,ax,ay,m_arrow,-90) then
			selected = 2
		end

		if RenderButton(50,110,140,12,ax,ay,nil,0.2,10) then
			selected = 3
			surface.SetDrawColor(255,255,255)
		else
			surface.SetDrawColor(col)
		end
		surface.DrawRect(60,115,120,2)
		surface.DrawRect(60 + 120 * (self.swp or 0.5),111,2,10)

		local thunder = StormFox.GetNetworkData("Thunder",false)
		local tl = StormFox.GetData("ThunderLight",0)
		local m = Material("stormfox/symbols/cloudy.png")
		if thunder then
			m = Material("stormfox/symbols/thunder.png")
		end
		if RenderButton(105,130,30,30,ax,ay,m) then
			selected = 4
		end
		if tl > 0 then
			surface.SetDrawColor(Color(min(col.r + tl,255),min(col.g + tl,255),min(col.b + tl,255)))
			surface.DrawTexturedRectRotated(122,147,30,30,0)
		end

		-- Temp
		if RenderButton(50,200,140,12,ax,ay,nil,0.2,10) then
			selected = 5
			surface.SetDrawColor(255,255,255)
		else
			surface.SetDrawColor(col)
		end
		surface.DrawRect(60,205,120,2)
		local temp = StormFox.GetNetworkData("Temperature",20)
		surface.DrawRect(100 + temp * 2,201,2,10)
		draw.DrawText( round(temp,1) .. "°C - " .. round(StormFox.CelsiusToFahrenheit(temp),1) .. "°F", "StormFox-Console", 120, 180, col, 1 )

		-- Wind
		if RenderButton(50,250,140,12,ax,ay,nil,0.2,10) then
			selected = 6
			surface.SetDrawColor(255,255,255)
		else
			surface.SetDrawColor(col)
		end
		surface.DrawRect(60,255,120,2)
		local wind = StormFox.GetNetworkData("Wind",0)
		surface.DrawRect(60 + wind * 2.4,251,2,10)
		local _,str = StormFox.GetBeaufort(wind)
		draw.DrawText( StormFox.Language.Translate("Wind") .. ": " .. str, "StormFox-Console", 120, 230, col, 1 )

		-- Windangle
		if RenderButton(50,295,140,12,ax,ay,nil,0.2,10) then
			selected = 7
			surface.SetDrawColor(255,255,255)
		else
			surface.SetDrawColor(col)
		end
		surface.DrawRect(60,300,120,2)
		local windang = StormFox.GetNetworkData("WindAngle",0)
		surface.DrawRect(60 + windang * 0.33,296,2,10)
		draw.DrawText( StormFox.Language.Translate("sf_setwindangle") .. ":" .. round(windang,1) .. "°", "StormFox-Console", 120, 275, col, 1 )

		if input.IsKeyDown(KEY_E) and not E then
			E = true
			if selected == 0 then
				self:SetWeather(weathers[self.sw],self.swp)
			elseif selected == 1 then
				self.sw = self.sw - 1
				if self.sw <= 0 then
					self.sw = #weathers
				end
				self:EmitSound("common/wpn_moveselect.wav")
			elseif selected == 2 then
				self.sw = self.sw + 1
				if self.sw > #weathers then
					self.sw = 1
				end
				self:EmitSound("common/wpn_moveselect.wav")
			elseif selected == 3 then
				local p = math.Clamp((ax - 60) / 120,0,1)
				self.swp = p
				self:EmitSound("common/wpn_select.wav")
			elseif selected == 4 then
				self:SetDataWeather("Thunder",not thunder)
			elseif selected == 5 then
				local p = math.floor(math.Clamp((ax - 100) / 2,-10,40))
				self:SetDataWeather("Temperature",p)
			elseif selected == 6 then
				local p = math.floor(math.Clamp((ax - 60) / 2.4,0,50))
				self:SetDataWeather("Wind",p)
			elseif selected == 7 then
				local p = math.floor(math.Clamp((ax - 60) * 3,0,360))
				self:SetDataWeather("WindAngle",p)
			end
		elseif not input.IsKeyDown(KEY_E) then
			E = false
		end
		if input.IsKeyDown(KEY_E) then
			surface.SetDrawColor(255,255,255)
		end
		surface.SetMaterial(c_arrow)
		surface.DrawTexturedRect(ax - 10,ay - 10,20,20)
	cam.End3D2D()
end