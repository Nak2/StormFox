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

function ENT:Think()
	if not self.on then return end
	local con = GetConVar("sf_allow_dynamiclights")
	if not con:GetBool() then return end
	local dlight = DynamicLight( self:EntIndex() )
	if ( dlight ) then
		dlight.pos = self:LocalToWorld(Vector(0, 0, 65))
		dlight.r = 255
		dlight.g = 255
		dlight.b = 255
		dlight.brightness = 3
		dlight.Decay = 1000
		dlight.Size = 256 * 2
		dlight.DieTime = CurTime() + 1
	end
end

function ENT:DrawTranslucent()
	self.on = false
	if ( halo.RenderedEntity() == self ) then return end
	local dis = EyePos():DistToSqr(self:GetPos())
	if dis < 200000 and not self:GetPersistent() then
		local pos = EyeAngles():Forward() * -10
		cam.Start3D2D(self:LocalToWorld(Vector(0,0,-20)) + pos,Angle(0,EyeAngles().y + 270,90),0.2)
			draw.DrawText("Press E to make persistent","BudgetLabel",0,0,Color(255,255,255),1)
		cam.End3D2D()
	end
	if self:GetColor().r ~= 254 then return end

	if dis > 3000000 then return end
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
			Distance = math.Clamp( Distance, 32, 800 )
			local Alpha = math.Clamp( ( 800 - Distance ) * Visibile * ViewDot, 0, 100 ) * 0.5
			local Col = self:GetColor()
			Col.a = Alpha
			render.DrawSprite( lpos + ViewNormal, Size, Size, Col, Visibile * ViewDot )
			render.DrawSprite( lpos + ViewNormal, Size * 0.4, Size * 0.4, Color( 255, 255, 255, Alpha ), Visibile * ViewDot )
		end
end