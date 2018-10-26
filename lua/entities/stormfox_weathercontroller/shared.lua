ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Weather Controller"
ENT.Author = "Nak"
ENT.Purpose		= "Controls the weather"
ENT.Instructions = "Place it somewhere"
ENT.Category		= "StormFox"

ENT.Editable		= false
ENT.Spawnable		= true
ENT.AdminOnly		= true
ENT.DisableDuplicator = true

if SERVER then

else
	function ENT:SetWeather(str,pro)
		net.Start("StormFox - WeatherC")
			net.WriteBool(false)
			net.WriteString(str)
			net.WriteType(pro)
		net.SendToServer()
	end
	function ENT:SetDataWeather(str,var)
		net.Start("StormFox - WeatherC")
			net.WriteBool(true)
			net.WriteString(str)
			net.WriteType(var)
		net.SendToServer()
	end
end