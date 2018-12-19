include("shared.lua")

-- nature/dirtfloor005
-- wood/woodburnt001

function ENT:Initialize()
	self.Rocks = {}
	local R = 10
	for i = 1 , R do
		local E = ClientsideModel("models/props_debris/concrete_chunk05g.mdl", 
				RENDERGROUP_OPAQUE)
		if E:IsValid() then
			self.Rocks[i] = E
			E:SetAngles(AngleRand())
			local A = 6.28 / R* i
			local V = Vector(math.cos(A)*30,math.sin(A)*30,-2)
			E:SetPos(self:LocalToWorld(V))
			E:SetParent(self)
			E:SetModelScale(3,0)
			E:SetNoDraw(true)
		end
	end
	self.Sticks = {}
	local r = 360 / 5
	for i =1, 5 do
		self.Sticks[i] = ClientsideModel("models/props_phx/construct/wood/wood_boardx1.mdl", 
					RENDERGROUP_OPAQUE)
		self.Sticks[i]:SetPos(self:LocalToWorld(Vector(math.cos(math.rad(r * i)) * 12,math.sin(math.rad(r * i)) * 12,5)))
		self.Sticks[i]:SetModelScale(0.7,0)
		self.Sticks[i]:SetAngles(self:LocalToWorldAngles(Angle(50,r * i,i * 2)))
		self.Sticks[i]:SetParent(self)
		self.Sticks[i]:SetNoDraw(true)
		self.Sticks[i]:SetMaterial("stormfox/models/firewood_burn")
	end
	self.Bottom = ClientsideModel("models/props_debris/concrete_floorpile01a.mdl",RENDERGROUP_OPAQUE)
	self.Bottom:SetPos(self:LocalToWorld(Vector(0,0,-5)))
	self.Bottom:SetModelScale(0.4,0)
	self.Bottom:SetAngles(self:GetAngles())
	self.Bottom:SetParent(self)
	self.Bottom:SetNoDraw(true)
	self.Bottom:SetMaterial("stormfox/models/char_coal")
	self.Emitter = ParticleEmitter(self:GetPos(),false)
	self.t = 0
	self.t2 = 0
	self.ES = 1
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
end

local ran,rand = math.random,math.Rand
function ENT:Think()
	if not StormFox then return end
	if not self.rendered then return end
	self.rendered = false
	if self:GetColor().r ~= 255 then self.ES = 1 return end
	self.ES = ran(0.2,0.3)
	if self.t2 <= CurTime() then
		self.t2 = CurTime() + ran(0.2,0.5)
		local dlight = DynamicLight( self:EntIndex() )
		if ( dlight ) then
			dlight.pos = self:LocalToWorld(Vector(ran(-5,5), ran(-5,5), 10))
			dlight.r = 255
			dlight.g = ran(155,255)
			dlight.b = 0
			dlight.brightness = 2 - (StormFox.GetData("MapLight",0) / 100) * 4
			dlight.Decay = 0
			dlight.Size = 256 * 3
			dlight.DieTime = self.t2
		end
	end

	if self.t > CurTime() then return end
	if not self.Emitter or not IsValid(self.Emitter) then -- Recreate missing emitter
		self.Emitter = ParticleEmitter(self:GetPos(),false)
	end
	local r = math.Rand(0.2,0.4)
		self.t = CurTime() + r
	local wind = StormFox.GetNetworkData("Wind",0) * 0.75
	if wind > 20 then wind = 20 end
	local windangle = Angle(0,StormFox.GetNetworkData("WindAngle",270),0)

	local windvec = windangle:Forward() * wind
	for i = 1,10 do
		local t = table.Random({"particles/fire1"})
		local p = self.Emitter:Add(t,i * -windvec * 0.1 + self:LocalToWorld(Vector(ran(-5,5), ran(-5,5), i * -2)))
			p:SetDieTime(rand(0.5,0.9) - wind / 40)
			p:SetStartSize(ran(10,15) + self.ES)
			p:SetGravity(Vector(0,0,30))
			p:SetEndAlpha(0)
			p:SetVelocity(Vector(ran(-4,4),ran(-4,4),60) + windvec * 5)
			p:SetRoll(ran(360))
	end
	for i = 1,4 do
		local n = ran(1,9)
		local t = "particle/smokesprites_000" .. n
		if n == 7 then
			t = "particle/smokesprites_0015"
		end

		local p = self.Emitter:Add(t,self:LocalToWorld(Vector(ran(-5,5), ran(-5,5), i * 2 + 20)) + windvec * 2)
			p:SetDieTime(rand(0.5,0.9) + self.ES * 2)
			p:SetStartSize(self.ES * 50)
			p:SetEndSize(ran(20,15))
			p:SetGravity(Vector(0,0,30))
			p:SetStartAlpha(30)
			p:SetEndAlpha(0)
			p:SetColor(155,155,155)
			p:SetVelocity(Vector(ran(-4,4),ran(-4,4),60) + windvec * 5)
			p:SetRoll(ran(360))
	end
	local t = table.Random({"effects/fire_embers1","effects/fire_embers2","effects/fire_embers3"})
	local p = self.Emitter:Add(t,self:LocalToWorld(Vector(ran(-15,15), ran(-15,15), 0)))
		p:SetDieTime(1)
		p:SetStartSize(ran(1,2))
		p:SetVelocity(Vector(ran(-20,20),ran(-20,20),ran(50,100)) + windvec * 5)
		p:SetAirResistance(20 - wind)
		p:SetEndAlpha(0)
		p:SetRoll(ran(360))
end

function ENT:Draw()
	-- Render stuff
	render.SetColorModulation(0.4,0.4,0.4)
	-- Repair missing bottom
	if not self.Bottom or not IsValid(self.Bottom) then
		self.Bottom = ClientsideModel("models/props_debris/concrete_floorpile01a.mdl",RENDERGROUP_OPAQUE)
	end
	self.Bottom:DrawModel()
	self.rendered = true
	render.SetColorModulation(1,1,1)
	-- Repair rocks
	for i,ent in ipairs(self.Rocks) do
		if not ent or not IsValid(ent) then
			ent = ClientsideModel("models/props_debris/concrete_chunk05g.mdl",
				RENDERGROUP_OPAQUE)
			self.Rocks[i] = ent
			ent:SetAngles(AngleRand())
			local A = 6.28 / 10 * i
			local V = Vector(math.cos(A) * 30,math.sin(A) * 30,-2)
			ent:SetPos(self:LocalToWorld(V))
			ent:SetParent(self)
			ent:SetModelScale(3,0)
			ent:SetNoDraw(true)
		end
		ent:DrawModel()
	end
	-- Repair sticks
	for i,ent in ipairs(self.Sticks) do
		if not ent or not IsValid(ent) then
			local r = 360 / 5
			ent = ClientsideModel("models/props_phx/construct/wood/wood_boardx1.mdl",
					RENDERGROUP_OPAQUE)
			self.Sticks[i] = ent
			ent:SetPos(self:LocalToWorld(Vector(math.cos(math.rad(r * i)) * 12,math.sin(math.rad(r * i)) * 12,5)))
			ent:SetModelScale(0.7,0)
			ent:SetAngles(self:LocalToWorldAngles(Angle(50,r * i,i * 2)))
			ent:SetParent(self)
			ent:SetNoDraw(true)
			ent:SetMaterial("stormfox/models/firewood_burn")
		end
		ent:DrawModel()
	end
end

function ENT:OnRemove( )
	for I=1,#self.Rocks do
		self.Rocks[I]:Remove()
	end
	for I=1,#self.Sticks do
		self.Sticks[I]:Remove()
	end
	SafeRemoveEntity(self.Bottom)
	if IsValid(self.Emitter) then
		self.Emitter:Finish()
	end
end