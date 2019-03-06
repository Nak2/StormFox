include("shared.lua")

function ENT:Initialize()
	self.PixVis = util.GetPixelVisibleHandle()
end

local ran,rand,max = math.random,math.Rand,math.max
local function createFlame(self)
	if not self.Emitter or not IsValid(self.Emitter) then -- Recreate missing emitter
		self.Emitter = ParticleEmitter(self:GetPos(),false)
	end

	local t = table.Random({"sprites/flamelet1","sprites/flamelet2","sprites/flamelet3"})
	local p = self.Emitter:Add(t,self:LocalToWorld(Vector(0,0, 7)))
		p:SetDieTime(rand(0.5,0.9))
		p:SetStartSize(ran(1,2) / 2)
		p:SetGravity(Vector(0,0,10))
		p:SetEndAlpha(0)
		p:SetStartAlpha(200)
		p:SetVelocity(Vector(0,0,1) + self:GetVelocity() / 3 )
		p:SetRoll(ran(360))
end

local mat = Material("models/effects/vol_light001")
local glass = Material("stormfox/models/oil_lamp_glass")
function ENT:Draw()
	render.MaterialOverrideByIndex(1,glass)
	render.SetColorModulation(1,1,1) -- Override entity color.
	if not self:GetNWBool("broken",false) then
		self:DrawModel()
	else
		render.MaterialOverrideByIndex(1,mat)
		self:DrawModel()
		render.MaterialOverrideByIndex()
	end
	render.MaterialOverrideByIndex()
end

local function GetDis(ent)
	if (ent.time_dis or 0) > CurTime() then return ent.time_dis_v or 0 end
		ent.time_dis = CurTime() + 1
	if not LocalPlayer() then return 0 end
	ent.time_dis_v = LocalPlayer():GetShootPos():DistToSqr(ent:GetPos())
	return ent.time_dis_v
end
function ENT:Think()
	if GetDis(self) > 4500000 then return end

	if (self.nextFlame or 0) > CurTime() then return end
	local ml = StormFox.GetData("MapLight",100)
	--if ml > 18 then return end
	if self:WaterLevel() > 0 then return end
	if self:GetNWBool("broken",false) then return end
	if not self:IsOn() then return end
	-- Wind
	self.nextFlame = CurTime() + (ran(5,10) / 200)
	createFlame(self)
	if (self.t2 or 0) <= CurTime() then
		self.t2 = CurTime() + ran(0.2,0.5)
		local dlight = DynamicLight( self:EntIndex() )
		if ( dlight ) then
			local c = self:GetColor()
			if c.g == 255 and c.b == 255 and c.r == 255 then 
				c.g = ran(185,155) 
				c.r = 255
				c.b = 0
			end
			dlight.pos = self:LocalToWorld(Vector(ran(-1,1), ran(-1,1), 7))
			dlight.r = c.r
			dlight.g = c.g
			dlight.b = c.b
			dlight.brightness = 3 - (ml / 40)
			dlight.Decay = 0
			dlight.Size = 192 * (2 - (ml / 200))
			dlight.DieTime = self.t2 + 0.5
		end
	end
end

function ENT:OnRemove( )
	if not IsValid(self.Emitter) then return end
	self.Emitter:Finish()
end

function ENT:DrawTranslucent()
	
end