include("shared.lua")

function ENT:Initialize()
	self.PixVis = util.GetPixelVisibleHandle()
end

local ran,rand,max = math.random,math.Rand,math.max
local function createFlame(self,ember,windvec,wind)
	if not self.Emitter or not IsValid(self.Emitter) then -- Recreate missing emitter
		self.Emitter = ParticleEmitter(self:GetPos(),false)
	end

	local t = table.Random({"particles/fire1"})
	local p = self.Emitter:Add(t,-windvec * 0.1 + self:LocalToWorld(Vector(ran(-1,1), ran(-1,1), 40)))
		p:SetDieTime(rand(0.5,0.9) - wind / 40)
		p:SetStartSize(ran(1,5))
		p:SetGravity(Vector(0,0,30))
		p:SetEndAlpha(0)
		p:SetStartAlpha(200)
		p:SetVelocity(Vector(ran(-4,4),ran(-4,4),30) + windvec * 5)
		p:SetRoll(ran(360))
	if not ember then return end

	local t = table.Random({"effects/fire_embers1","effects/fire_embers2","effects/fire_embers3"})
	local p = self.Emitter:Add(t,self:LocalToWorld(Vector(ran(-6,6), ran(-6,6), 40)))
		p:SetDieTime(1)
		p:SetStartSize(ran(1,2))
		p:SetVelocity(Vector(ran(-1,1),ran(-1,1),ran(40,30)) + windvec * 5)
		p:SetAirResistance(20 - wind)
		p:SetEndAlpha(0)
		p:SetRoll(ran(360))
end

function ENT:Draw()
	self:DrawModel()
end

local function isWater(vec)
	return bit.band( util.PointContents( vec ), CONTENTS_WATER ) == CONTENTS_WATER
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
	local rm = StormFox.GetData("Gauge",0) * 10
	local ml = StormFox.GetData("MapLight",100) * max(rm,1)

	if ml > 20 then return end
	if isWater(self:LocalToWorld(Vector(0,0, 35))) then return end
	-- Wind
		local wind = StormFox.GetNetworkData("Wind",0)
		if wind > 20 then wind = 20 end
		local windangle = Angle(0,StormFox.GetNetworkData("WindAngle",270),0)
		local windvec = windangle:Forward() * wind

	self.nextFlame = CurTime() + (ran(5,10) / 200)
	createFlame(self,ran(10)>8,windvec,wind)
	if (self.t2 or 0) <= CurTime() then
		self.t2 = CurTime() + ran(0.2,0.5)
		local dlight = DynamicLight( self:EntIndex() )
		if ( dlight ) then
			dlight.pos = self:LocalToWorld(Vector(ran(-1,1), ran(-1,1), ran(40,50)))
			dlight.r = 255
			dlight.g = ran(155,255)
			dlight.b = 0
			dlight.brightness = 5 - (ml / 10)
			dlight.Decay = 0
			dlight.Size = 256 * 3
			dlight.DieTime = self.t2 + 0.5
		end
	end
end

function ENT:OnRemove( )
	if not self.Emitter then return end
	self.Emitter:Finish()
end

function ENT:DrawTranslucent()
	
end