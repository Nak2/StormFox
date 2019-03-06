include("shared.lua")

function ENT:Initialize()

--	self.Glass = ClientsideModel("models/props_c17/tv_monitor01_screen.mdl",RENDERGROUP_TRANSLUCENT)
--	self.Glass:SetPos(self:LocalToWorld(Vector(0,0,0)))
--	self.Glass:SetAngles(self:GetAngles())
--	self.Glass:SetParent(self)
--	self.Glass:SetNoDraw(true)
end

surface.CreateFont( "SkyFox-DigitalClock", {
	font = "Arial", -- Use the font-name which is shown to you by your operating system Font Viewer, not the file name
	extended = false,
	size = 50,
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

local cos,sin,rad,round = math.cos,math.sin,math.rad,math.Round
--local sf = Material("stormfox/SF.png")
 -- StormFox.SetData("WeekWeather",week)
local cel,fer = Material("stormfox/symbols/Celsius.png"),Material("stormfox/symbols/Fahrenheit.png")
function ENT:Draw()
	self:DrawModel()
end

local mat = Material("gui/arrow")
function ENT:DrawTranslucent()
	self:DrawModel()
	local Freedom = self:GetNWBool("Freedom",false)
	cam.Start3D2D(self:LocalToWorld(Vector(6.4,-28,35)),self:LocalToWorldAngles(Angle(0,90,90)),0.1)
		surface.SetDrawColor(Color(155,155,255))
		local w,h = 564,325
		surface.DrawRect(0,0,w,h)
		local w_data = StormFox.GetNetworkData("WeekWeather",{})
		if #w_data < 1 then return end
		local wd = (w - 100) / 7
		surface.SetDrawColor(255,255,255,55)

		for i = 1,7 do
			surface.DrawLine(50,160 + i * 10,w - 50,160 + i * 10)
		end
		local xx = wd / 1440 * StormFox.GetTime()
		surface.DrawLine(50 + xx,170,50 + xx,230)
		surface.SetDrawColor(255,255,255,255)
		surface.DrawLine(50,160 + 5 * 10,w - 50,160 + 5 * 10)

		local lasty,lastx,lasta
		for i = 1,#w_data do
			local data = w_data[i]
			local x = (i - 1) * wd + 50
			
			local weather = (data.percent or 0) > 0.2 and data.name or "clear"
			local p = data.percent or 0
			if weather == "rain" and p > 0 then
				surface.SetDrawColor(0,0,255,155)
				local xx = 50 + wd * (i - 1) + (wd / 1440 * data.trigger)
				local h = math.floor(p * 45)
				local l = wd / 1440 * (data.stoptime - data.trigger)
				surface.DrawRect(xx,210 - h,l,h)
			end

			surface.SetDrawColor(255,255,255)
			local temp = data.temp
			local name = StormFox.GetWeatherType(data.name):GetName( temp, data.wind, data.thunder  )
			local wmat = StormFox.GetWeatherType(data.name):GetIcon(  temp, data.wind, data.thunder )
			surface.SetMaterial(wmat)

			surface.SetTextColor(255,255,255)
			draw.SimpleText(name,"SkyFox-Console",x + wd / 2,80,Color(255,255,255),1,0)
			
			surface.DrawTexturedRect(x,100,wd,50)
			surface.SetDrawColor(0,0,0)

			local temp_x = x + (wd / 1440 * data.trigger)
			local temp_y = 170 - data.temp * 2 + 40
			surface.DrawCircle(temp_x,temp_y,1,Color(255,255,255))
			surface.SetTextPos(temp_x,temp_y)
			surface.SetFont("default")
			surface.SetTextColor(0,0,0)
			surface.DrawText(Freedom and (StormFox.CelsiusToFahrenheit(round(data.temp,1)) .. "°F") or (round(data.temp,1) .. "°C"))

			surface.SetMaterial(mat)
			local wind = data.wind
			surface.DrawTexturedRectRotated(x + wd / 2,260,10 + wind,10 + wind,data.windangle)
			if Freedom then
				wind = wind * 2.236936
			end
			draw.DrawText(math.Round(wind,1) .. (Freedom and "mph" or "m/s"),"default",x + wd / 2,270,Color(0,0,0),1)
			lasta = data.tempacc or 0
			if lasty then
				surface.DrawLine(temp_x,temp_y,lastx,lasty)
			else
				local oldtemp = w_data["ot"] or StormFox.GetData("Temperature",20)
				lastx = 50
				lasty = 170 - oldtemp * 2 + 40
				surface.DrawLine(temp_x,temp_y,lastx,lasty)
			end
			lasty = temp_y
			lastx = temp_x
		end
		surface.DrawLine(lastx,lasty,w - 50,lasty - lasta )

	cam.End3D2D()
end