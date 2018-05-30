
-- Day controller
	-- Setup day-saver
		if SERVER then
			local currentDay = cookie.GetNumber("StormFox - Day",math.random(356))
			StormFox.SetNetworkData("Day",currentDay)
			hook.Add("ShutDown","StormFox - DayShutdown",function()
				cookie.Set("StormFox - Day",StormFox.GetNetworkData("Day",0))
			end)
		end
	
	function StormFox.GetDay()
		return StormFox.GetNetworkData("Day",0)
	end

	function StormFox.GetDate()
		local day = StormFox.GetNetworkData("Day",0) + 0
		local m = 1
		if day <= 31 then
			return 1,day 		-- 31
		elseif day <= 59 then
			return 2,(day - 31) -- 28
		elseif day <= 90 then
			return 3,(day - 59) -- 31
		elseif day <= 120 then
			return 4,(day - 90) -- 30
		elseif day <= 151 then
			return 5,(day - 120) -- 31
		elseif day <= 181 then
			return 6,(day - 151) -- 30
		elseif day <= 212 then
			return 7,(day - 181) -- 31
		elseif day <= 243 then
			return 8,(day - 212) -- 31
		elseif day <= 273 then
			return 9,(day - 243) -- 30
		elseif day <= 304 then
			return 10,(day - 273) -- 31
		elseif day <= 334 then
			return 11,(day - 304) -- 30
		else
			return 12,(day - 334) -- 31
		end
	end
	local m_name = {"January","February","March","April","May","June","July","August","September","October","November","December"}
	function StormFox.GetRealDate(short)
		local m,day = StormFox.GetDate()
		if short then
			return day, m_name[m]:sub(0,3)
		end
		return day, m_name[m]
	end

-- Special days
	local function dateToDay(d,m)
		if m == 1 then return d end
		if m == 2 then return d + 31 end
		if m == 3 then return d + 59 end
		if m == 4 then return d + 90 end
		if m == 5 then return d + 120 end
		if m == 6 then return d + 151 end
		if m == 7 then return d + 181 end
		if m == 8 then return d + 212 end
		if m == 9 then return d + 243 end
		if m == 10 then return d + 273 end
		if m == 11 then return d + 304 end
		return d + 334
	end
	local s_d = {}
	function StormFox.AddSpecialDay(name,day,month,to_day,to_month)
		if not to_day then to_day = day end
		if not to_month then to_month = month end
		s_d[name] = {dateToDay(day,month),dateToDay(to_day,to_month)}
	end
	-- January
		StormFox.AddSpecialDay("New Years Eve",1,1)
		StormFox.AddSpecialDay("Public Domain Day",1,1)
		StormFox.AddSpecialDay("National Science Fiction Day",2,1)
		StormFox.AddSpecialDay("National Youth Day",12,1)
		StormFox.AddSpecialDay("Australia Day",26,1)
		StormFox.AddSpecialDay("Data Privacy Day",28,1)
		StormFox.AddSpecialDay("Jugend Eine Welt",31,1)
	-- February
		StormFox.AddSpecialDay("Groundhog Day",2,2)
		StormFox.AddSpecialDay("World Cancer Day",4,2)
		StormFox.AddSpecialDay("Darwin Day",12,2)
		StormFox.AddSpecialDay("World Radio Day",13,2)
		StormFox.AddSpecialDay("Valentine's Day",14,2)
		StormFox.AddSpecialDay("White Day",14,2) -- (South Korea)
	-- March
		StormFox.AddSpecialDay("Self-injury Awareness Day",15,3)
		StormFox.AddSpecialDay("International Women's Day",8,3)
		StormFox.AddSpecialDay("Pi-Day",14,3)
		StormFox.AddSpecialDay("World Consumer Rights Day",15,3)
		StormFox.AddSpecialDay("Saint Patrick's Day",17,3)
		StormFox.AddSpecialDay("International Day of Happiness",20,3)
	-- April
		StormFox.AddSpecialDay(--[["April Fools Day"]] "Butt Day",1,4)
		StormFox.AddSpecialDay("World Health Day",7,4)
		StormFox.AddSpecialDay("Black Day",14,4) -- (South Korea)
		StormFox.AddSpecialDay("Earth Day",22,4)
		StormFox.AddSpecialDay("International Day of Happiness",20,4)
		StormFox.AddSpecialDay("Anzac Day",25,4)
	-- May
		StormFox.AddSpecialDay("International Workers' Day",1,5)
		StormFox.AddSpecialDay("World Pizza Day",9,5) -- Why didn't I know this earlier!?!??
		StormFox.AddSpecialDay("Remembrance of the Dead",4,5)
		StormFox.AddSpecialDay("Star Wars Day",4,5)
		StormFox.AddSpecialDay("International No Diet Day",6,5)
		StormFox.AddSpecialDay("Victory in Europe Day",7,5,8,5)
		StormFox.AddSpecialDay("International No Diet Day",6,5)
		StormFox.AddSpecialDay("World Turtle Day",23,5)
	-- June
		StormFox.AddSpecialDay("D-DAy",6,6)
		StormFox.AddSpecialDay("Music Day",21,6)
		StormFox.AddSpecialDay("World Environment Day",5,6)
	-- July
		StormFox.AddSpecialDay("Canada Day",1,7)
		StormFox.AddSpecialDay("International Tiger Day",29,7)
		StormFox.AddSpecialDay("World Emoji Day",17,7)
		StormFox.AddSpecialDay("World Day for International Justice",17,7)
		StormFox.AddSpecialDay("World Chocolate Day",7,7)
		StormFox.AddSpecialDay("World UFO Day",24,7)
	-- August
		StormFox.AddSpecialDay("National Burger Day",24,8)
		--StormFox.AddSpecialDay("Women's Equality Day",26,8) Don't display both dog and equality day
		StormFox.AddSpecialDay("National Dog Day",26,8)
		StormFox.AddSpecialDay("National Burger Day",24,8)
		StormFox.AddSpecialDay("National Sports Day",29,8)
	-- Spetemper
		StormFox.AddSpecialDay("International Talk Like a Pirate Day",29,9)
		StormFox.AddSpecialDay("International Day of Peace",21,9)
		StormFox.AddSpecialDay("Celebrate Bisexuality Day",23,9)
		StormFox.AddSpecialDay("International Talk Like a Pirate Day",29,9)
		StormFox.AddSpecialDay("European Day of Languages",26,9)
	-- October
		StormFox.AddSpecialDay("International Coffee Day",1,10)	-- Best day
		StormFox.AddSpecialDay("International Day of Non-Violence",2,10)
		StormFox.AddSpecialDay("World Animal Day",4,10)
		StormFox.AddSpecialDay("Coming Out Day",11,10)
		StormFox.AddSpecialDay("Halloween",31,10)		-- Gonna add a fog-modifier for this day
		StormFox.AddSpecialDay("World Students' Day",15,10)
	-- November
		StormFox.AddSpecialDay("International Men's Day",19,11)
		StormFox.AddSpecialDay("Guy Fawkes Night",5,11)
		StormFox.AddSpecialDay("Australia Day",26,11)
	-- December
		StormFox.AddSpecialDay("Human Rights Day",10,12)
		StormFox.AddSpecialDay("International Tea Day",15,12)
		StormFox.AddSpecialDay("Christmas Eve",24,12)
		StormFox.AddSpecialDay("Christmas",25,12)
		StormFox.AddSpecialDay("New Years Eve",31,12)
	
	local function FindDE(day)
		local current_events = {}
		for event,tab in pairs(s_d) do
			if tab[1]>=day and tab[2] <= day then
				table.insert(current_events,event)
			end
		end
		return current_events
	end
	local d_event = FindDE(StormFox.GetNetworkData("Day",0))
	hook.Add("StormFox - NetDataChange","StormFox - DayEventLogic",function(var,day)
		if var ~= "Day" then return end
		d_event = FindDE(day)
	end)
	function StormFox.SpecialDay(day,month)
		if month then
			day = dateToDay(day,month)
		end
		if day then return FindDE(day) end
		return d_event
	end

-- Moon logic
	--  The lunar phases gradually and cyclically change over the period of a synodic month (about 29.53 days), so thats 12.2 pitch pr night with the sun direction
	StormFox.SetNetworkData("Moon-offset_p",math.random(359))
	local moon_roll = math.random(359)
	StormFox.SetNetworkData("Moon-offset_r",math.cos(moon_roll) * 28.5) -- 5deg from horizon + 23.5 degress offset

-- DayLogic
	if SERVER then
		hook.Add("StormFox-NewDay", "StormFox-SetNextDay", function()
			local nd = StormFox.GetNetworkData("Day",0) + 1
			if nd > 356 then nd = 1 end
			StormFox.SetNetworkData("Day",nd)
			-- Moon pitch
				local p = StormFox.GetNetworkData("Moon-offset_p",0)
				StormFox.SetNetworkData("Moon-offset_p",(p + 12.2) % 360)
			-- Moon roll
				moon_roll = (moon_roll + 0.98) % 360
				StormFox.SetNetworkData("Moon-offset_r",moon_roll)
		end )
	end