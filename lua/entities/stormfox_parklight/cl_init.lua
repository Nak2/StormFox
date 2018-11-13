include("shared.lua")

function ENT:Initialize()
	self.PixVis = util.GetPixelVisibleHandle()
	self.on = false
end

local matLight = Material( "sprites/light_ignorez" )
local matBeam = Material( "effects/lamp_beam" )
function ENT:Draw()
	self:DrawModel()
end

local function GetDis(ent)
	if (ent.time_dis or 0) > CurTime() then return ent.time_dis_v or 0 end
		ent.time_dis = CurTime() + 1
	if not LocalPlayer() then return 0 end
	ent.time_dis_v = LocalPlayer():GetShootPos():DistToSqr(ent:GetPos())
	return ent.time_dis_v
end

function ENT:Think()
	if not self.on then return end
	if GetDis(self) > 1309552 then return end
	
	local con = GetConVar("sf_allow_dynamiclights")
	if not con:GetBool() then return end
	local dlight = DynamicLight( self:EntIndex() )
	if ( dlight ) then
		dlight.pos = self:LocalToWorld(Vector(0, 0, 65))
		dlight.r = 255
		dlight.g = 255
		dlight.b = 255
		dlight.brightness = 5
		dlight.Decay = 1000
		dlight.Size = 256 * 2
		dlight.DieTime = CurTime() + 0.1
	end
end

function ENT:DrawTranslucent()
	self.on = false
	if ( halo.RenderedEntity() == self ) then return end
	local dis = EyePos():DistToSqr(self:GetPos())
	if self:GetMaterial() == "stormfox/models/parklight_off" then return end

	if dis < 1000000 then self.rendered = true end
	if dis > 30000000 then return end
	local lpos = self:LocalToWorld(Vector(0, 0, 65))
	self.on = true

	render.SetMaterial(matBeam)

	-- Thx gmod_light
	local LightNrm = -self:GetAngles():Up()
	local ViewNormal = lpos - EyePos()
	local Distance = ViewNormal:Length()
	ViewNormal:Normalize()
	local ViewDot = ViewNormal:Dot( LightNrm * -1 )

	if ( ViewDot >= 0 ) then
			render.SetMaterial( matLight )
			local Visibile = util.PixelVisible( lpos, 16, self.PixVis )

			if ( !Visibile ) then return end
			local Size = math.Clamp( Distance * Visibile * ViewDot * 2, 64, 512 / 2 )
			Distance = math.Clamp( Distance, 32, 8000 )
			local Alpha = math.Clamp( ( 8000 - Distance ) * Visibile * ViewDot, 0, 200 ) * 0.15
			local Col = self:GetColor()
			Col.a = Alpha
			render.DrawSprite( lpos + ViewNormal, Size, Size, Col, Visibile * ViewDot )
			render.DrawSprite( lpos + ViewNormal, Size * 0.4, Size * 0.4, Color( 255, 255, 255, Alpha ), Visibile * ViewDot )
		end
end