
-- Start WeatherType metatable

StormFox.WeatherType = {}
StormFox.WeatherType.__index = StormFox.WeatherType

StormFox.WeatherType.StormMagnitudeMin = 0.1
StormFox.WeatherType.StormMagnitudeMax = 1

-- Time enumerations
StormFox.WeatherType.TIME_SUNRISE = 360
StormFox.WeatherType.TIME_NOON = 750
StormFox.WeatherType.TIME_SUNSET = 1260
StormFox.WeatherType.TIME_NIGHT = 1440

-- Data having to do with skybox color, lighting etc that is more dependent on the time of day then the storm conditions
StormFox.WeatherType.TimeDependentData = {
	SkyTopColor = { -- The top color painted in the skybox
		TIME_SUNRISE = Color(43, 142, 196),
		TIME_NOON = Color(6, 146, 221),
		TIME_SUNSET = Color(6, 105, 130),
		TIME_NIGHT = Color( 1, 19, 31 )
	},
	SkyBottomColor = { -- The bottom color painted in the skybox
		TIME_SUNRISE = Color(244, 122, 60),
		TIME_NOON = Color(56, 174, 255),
		TIME_SUNSET = Color(255, 171, 150),
		TIME_NIGHT = Color( 0, 0, 0 )
	},
	FadeBias = { -- TODO: Nak, what is this? Please add a comment
		TIME_SUNRISE = 0.3,
		TIME_SUNSET = 0.16,
		TIME_NIGHT = 0.06
	},
	DuskColor = { -- The color of the skybox at dusk
		 TIME_SUNRISE = Color(140, 80, 120),
		 TIME_SUNSET = Color(170, 70, 90),
		 TIME_NIGHT = Color(0, 0, 0)
	},
	DuskIntensity = { -- How intense the sunset/sunrise is
		 TIME_SUNRISE = 0.3,
		 TIME_SUNSET = 0.2,
		 TIME_NIGHT = 0
	},
	HDRScale = { -- TODO: Nak, what is this? Please add a comment
		 TIME_SUNRISE = 0.66,
		 TIME_NOON = 0.5,
		 TIME_SUNSET = 0.1
	},
	MapLight = { -- The amount of daylight ( suns brightness )
		 TIME_SUNRISE = 20,
		 TIME_NOON = 80,
		 TIME_SUNSET = 20,
		 TIME_NIGHT = 6
	},
	Fogdensity = { -- TODO: Nak, what is this? Please add a comment
		 TIME_SUNRISE = 0.8,
		 TIME_SUNSET = 0.9
	},
	Fogend = { -- TODO: Nak, what is this? Please add a comment
		 TIME_SUNRISE = 108000,
		 TIME_SUNSET = 60000
	},
	Fogstart = 0, -- TODO: Nak, what is this? Please add a comment
	Fogcolor = nil -- TODO: Nak, what is this? Please add a comment
}

-- Data that is either static or computed. If you set the value to be a function then when the storms power changes these values will update
StormFox.WeatherType.CalculatedData = {
	StarFade = 1,
	StarSpeed = 0.001,
	SunSize = 35,
	SunColor = Color( 255, 255, 255 ),
	MoonLight = 100,
	MoonColor = Color( 205, 205, 205 ),
	Gauge = 0,
}
-- Here you can add functions that update any of the values in CalculatedData when the storm magnitude changes.
StormFox.WeatherType.DataCalculationFunctions = {
	-- Example:
	-- MoonLight = function( stormMag ) return 100 * ( 1-stormMag ) end,
}

-- Data that is set once and remains the same value. No lerping or time interpolation or anything. The values don't change
StormFox.WeatherType.StaticData = {
	StarsEnabled = true,
	DrawStars = true,
	StarTexture = "skybox/starfield",
	MoonTexture = "stormfox/moon_fix",

	GaugeColor = Color(255,255,255),
}


function StormFox.WeatherType.new( sId )
	if not type( sId ) == "string" then
		error("ERROR: Attempted to create new WeatherType with invalid ID. String expected, Got: " .. type(sId) )
	end

	local metaWeatherType = {}
	metaWeatherType.id = sId
	return setmetatable( metaWeatherType, table.Copy(StormFox.WeatherType) )
end

-- Allows you to initialize a weather type using StormFox.WeatherType("<id>")
function StormFox.WeatherType.__call( _, ... )
    return StormFox.WeatherType.new( ... )
end
setmetatable( StormFox.WeatherType, { __call = StormFox.WeatherType.__call } )

-- Gets a stormMagnitude dependent variable. If a calculation function exists it uses that otherwise it returns the value in CalculatedData
function StormFox.WeatherType:GetCalculatedData( sIndex, flStormMagnitude )
	flStormMagnitude = flStormMagnitude or StormFox.StormMagnitude
	flStormMagnitude = math.Clamp( flStormMagnitude, 0, 1 )

	local fCalculationFunc = self.DataCalculationFunctions[ sIndex ]
	if fCalculationFunc then return fCalculationFunc( flStormMagnitude ) end
	return self.CalculatedData[ sIndex ]
end

-- if we are trying to get the value for a time that isn't set it will use this table to decide what value to use instead
-- format [ missingIndex = nextIndexToTry ]
local timeValueNotFoundFallbacks = {
	TIME_SUNRISE = "TIME_NOON",
	TIME_NOON = "TIME_SURISE",
	TIME_SUNSET = "TIME_NIGHT",
	TIME_NIGHT = "TIME_SUNSET"
}

local function timeToEnumeratedValue( flTime )
	if flTime <= StormFox.WeatherType.TIME_SUNRISE then
		return "TIME_SUNRISE"
	elseif flTime <= StormFox.WeatherType.TIME_NOON then
		return "TIME_NOON"
	elseif flTime <= StormFox.WeatherType.TIME_SUNSET then
		return "TIME_SUNSET"
	elseif flTime <= (StormFox.WeatherType.TIME_NIGHT + 5) then
		return "TIME_NIGHT"
	else
		ErrorNoHalt("Warning enumerated value requested for weather type but time was out of bounds. Falling back to TIME_NIGHT. Time: " .. flTime )
		debug.Trace()
		return "TIME_NIGHT"
	end
end

local tPreviousTimeIntervals = { TIME_SUNRISE = "TIME_NIGHT", TIME_NOON = "TIME_SUNRISE", TIME_SUNSET="TIME_NOON", TIME_NIGHT = "TIME_SUNSET" }

-- Gets the current time enum, this may cause confusion because this is often the next time. Example at 2am the interval is SUNRISE
-- But the current values are actually from NIGHT. If you want to get the last interval which values were lerped to use previousInterval
function StormFox.WeatherType:GetCurrentTimeInterval( flTime )
	return timeToEnumeratedValue( flTime )
end

-- Gets the last time interval passed that resulted in the current time values.
-- Example: Before TIME_NIGHT but after TIME_SUNSET the previous interval would return TIME_SUNSET.
function StormFox.WeatherType:GetPreviousTimeInterval( flTime )
	return tPreviousTimeIntervals[ self:GetCurrentTimeInterval( flTime ) ]
end

-- The times of the previous intervals start times.
local timeIntervalStarts = {
	TIME_SUNRISE = StormFox.WeatherType.TIME_SUNRISE - 60,
	TIME_NOON = StormFox.WeatherType.TIME_SUNRISE + 50,
	TIME_SUNSET = StormFox.WeatherType.TIME_SUNSET - 60,
	TIME_NIGHT = StormFox.WeatherType.TIME_SUNSET + 30
}
-- local function getPercentOfTimeInterval( flTime )
--
-- end

local function lerpAnyValue( amount, currentValue, targetValue )
	if not currentValue then return targetValue end -- NOTE: If you find that the values are going instantly to the target check here first
	if not targetValue then return currentValue end

	amount = math.Clamp( amount, 0, 1 )
	if type( currentValue ) != type( targetValue ) then
		ErrorNoHalt("ERROR: lerpAnyValue called with values of two different types. Returning original value")
		debug.Trace()
		return currentValue
	end

	if type( currentValue ) == "number" then -- Standard number Lerp
		return Lerp( amount, currentValue, targetValue )
	elseif type( currentValue ) == "table" and currentValue.a and currentValue.r and currentValue.g and currentValue.b then -- Color lerp
		local r = Lerp( amount, currentValue.r, targetValue.r )
		local g = Lerp( amount, currentValue.g, targetValue.g )
		local b = Lerp( amount, currentValue.b, targetValue.b )
		local a = Lerp( amount, currentValue.a, targetValue.a )
		return Color( r, g, b, a )
	end
	ErrorNoHalt("ERROR: Unsupported lerp value type. Returning original value")
	return currentValue
end

-- Gets a time value in relation to the time passed, applies any applicable lerps
function StormFox.WeatherType:GetLerpedTimeValue( sIndex, previousWeatherVal, flTime )
	flTime = flTime or StormFox.GetTime()
	local targetValue = self:GetTimeBasedData( sIndex, flTime )
	-- The value is static for this weather type and doesn't change based on time so we just return it
	if type( self.TimeDependentData[ sIndex ] ) != "table" then return self.TimeDependentData[ sIndex ] end

	local timeEnumeration = timeToEnumeratedValue( flTime )
	local flTargetTime = self[ timeEnumeration ]
	local lerpAmount = 0
	if previousWeatherVal then
		local flStartTime = timeIntervalStarts[ timeEnumeration ]
		local sPreviousTimeEnum = tPreviousTimeIntervals[ timeEnumeration ] -- Get the most recent passed interval to check what our values should be
		if flStartTime > flTime then -- We are not within a lerp transition (see commend bellow).
			local expectedValue = self.TimeDependentData[ sIndex ][ sPreviousTimeEnum ]
			local currentValue = StormFox.GetData( index )
			if currentValue and currentValue != expectedValue then
				-- The weather may have been manually edited or we are transitioning from a storm. We need to lerp the current data to match the expectedValue
				return lerpAnyValue( 0.07, currentValue, expectedValue )
			end
		else -- Lerp based on time, this slowly adjust values at given time intervals. For example 60 mins before sunset it starts to get lighter outside
			lerpAmount = math.Clamp( ( flTime - flStartTime ) / ( flTargetTime - flStartTime ), 0, 1 )
		end
	end
	return lerpAnyValue( lerpAmount, previousWeatherVal, targetValue )
end

-- Returns a table containing all time based data lerped in relation to the time passed
function StormFox.WeatherType:GetTimeBasedData( sIndex, flTime )
	local varTable = self.TimeDependentData[ sIndex ]
	if not varTable then
		ErrorNoHalt("Unable to find timebaseddata val for index: " .. sIndex)
		return 1
	end
	if type( varTable ) != "table" then
		return varTable
	end

	local timeIndex =  timeToEnumeratedValue( flTime )
	return varTable[ timeIndex ] or varTable[ timeValueNotFoundFallbacks[ timeIndex ] ]
end

-- When a user first joins or the time is set manually the lerping won't take effect until we get close to the next interval
-- So this can be called to update all time based data instantly
function StormFox.WeatherType:UpdateTimeBasedDataImmediate( flTime )
	local sPreviousTimeEnum = self:GetPreviousTimeInterval( flTime )

	for index, value in pairs( self.TimeDependentData ) do
		StormFox.SetData( index, self:GetTimeBasedData( index, self[ sPreviousTimeEnum ] ) )
	end
end

-- Gets a data member from TimeDependentData, CalculatedData, or StaticData. For TimeDependentData it takes the current time into consideration
function StormFox.WeatherType:GetData( sVariableName, flTime )
	if self.TimeDependentData[ sVariableName ] then
		return self:GetTimeBasedData( sVariableName, flTime )
	elseif self.CalculatedData[ sVariableName ] then
		return self.CalculatedData[ sVariableName ]
	elseif self.StaticData[ sVariableName ] then
		return self.StaticData[ sVariableName ]
	else
		return nil
	end
end

-- Dumps all the variables of the weather system and lerps them if given a current value table
function StormFox.WeatherType:GetAllVariables( flTime, flStormMagnitude, tCurrentValues )
	local tValues = {}
	-- Get all time variables
	for index, value in pairs( self.TimeDependentData ) do
		tValues[ index ] = self:GetLerpedTimeValue( index, tCurrentValues and tCurrentValues[ index ] or nil, flTime )
	end
	-- Get all storm magnitude variables
	for index, value in pairs( self.CalculatedData ) do
		tValues[ index ] = self:GetCalculatedData( index, flStormMagnitude )
	end
	-- Get all Static variables
	for index, value in pairs( self.StaticData ) do
		tValues[ index ] = value
	end
	return tValues
end

-- Updates all variables in StormFox.Data with lerped data accurate to the current storm conditions, time and previous values
function StormFox.WeatherType:UpdateAllVariables( flTime, flStormMagnitude, tPreviousWeatherValues )
	tPreviousWeatherValues = tPreviousWeatherValues or StormFox.GetDataTable()
	-- Get all time variables
	for index, value in pairs( self.TimeDependentData ) do
		StormFox.SetData( index, self:GetLerpedTimeValue( index, tPreviousWeatherValues and tPreviousWeatherValues[ index ] or nil, flTime ) )
	end
	-- Get all storm magnitude variables

	for index, value in pairs( self.CalculatedData ) do
		StormFox.SetData( index, self:GetCalculatedData( index, flStormMagnitude ) )
	end
	-- Get all Static variables
	for index, value in pairs( self.StaticData ) do
		StormFox.SetData( index, value )
	end
end


-- The weather names change depending on the current conditions. We only use one weather type to describe multiple different subtypes of weather so we need this
function StormFox.WeatherType:GetName( nTemperature, nWindSpeed, bThunder  )
	return bThunder and "Thunder" or ( nWindSpeed > 14 and "Windy" or "Clear")
end

local m = Material("stormfox/symbols/Clear.png")
local m4 = Material("stormfox/symbols/Windy.png")
local m5 = Material("stormfox/symbols/Icy.png")
local m6 = Material("stormfox/symbols/Night.png")
local m8 = Material("stormfox/symbols/Thunder.png")
function StormFox.WeatherType:GetIcon( nTemperature, nWindSpeed, bThunder )
	if bThunder then
		return m8
	elseif nWindSpeed then
		return m4
	elseif nTemperature <= 0 then
		return m5
	end

	local flTime = StormFox.GetTime() <= 0.4
	local bIsNight = flTime < 340 or flTime > 1075
	return bIsNight and m6 or m
end


-- For managing the table of weather types. Not worth putting it in a new file cause its only 2 small funcs

StormFox.WeatherTypes = StormFox.WeatherTypes or {
	clear = StormFox.WeatherType.new("clear")
}

StormFox.Weather = StormFox.Weather or StormFox.WeatherTypes[ "clear" ] -- Current weather

function StormFox.AddWeatherType( metaWeatherType )
	if not metaWeatherType.id then
		error("Attempted to add invalid weather type. You must use an instance of the StormFox.WeatherType class")
	end

	StormFox.WeatherTypes[ metaWeatherType.id ] = metaWeatherType
	MsgN( "[StormFox] Weather Type: " .. metaWeatherType.id .. " initialized." )
end

function StormFox.GetWeatherType( sWeatherId )
	return StormFox.WeatherTypes[ sWeatherId ]
end
