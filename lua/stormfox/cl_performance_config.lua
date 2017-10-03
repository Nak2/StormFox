StormFox.ClientSettingConfiguration = {}
StormFox.ClientSettingConfiguration.VeryLow = {
	breath = false, -- Draw players breath when it's cold
	clouds = false, -- Draw clouds?
	dynamic_shadows = false, -- Draw dynamic shadows?
	redownload_lightmap = false, -- redownload light maps when map light changes enough?
	drawfog = false, -- Draw skybox fog?
	rainParticles = 0, -- Max amount of rain particles, this is multiplied by 64 so 1 is 64 2 is 128
}

StormFox.ClientSettingConfiguration.Low = {
	breath = true, -- Draw players breath when it's cold
	clouds = true, -- Draw clouds?
	dynamic_shadows = false, -- Draw dynamic shadows?
	redownload_lightmap = true, -- redownload light maps when map light changes enough?
	drawfog = true, -- Draw skybox fog?
	rainParticles = 1, -- Max amount of rain particles, this is multiplied by 64 so 1 is 64 2 is 128
}

StormFox.ClientSettingConfiguration.Normal = {
	breath = true, -- Draw players breath when it's cold
	clouds = true, -- Draw clouds?
	dynamic_shadows = true, -- Draw dynamic shadows?
	redownload_lightmap = true, -- redownload light maps when map light changes enough?
	drawfog = true, -- Draw skybox fog?
	rainParticles = 4, -- Max amount of rain particles, this is multiplied by 64 so 1 is 64 2 is 128
}

StormFox.ClientSettingConfiguration.High = {
	breath = true, -- Draw players breath when it's cold
	clouds = true, -- Draw clouds?
	dynamic_shadows = true, -- Draw dynamic shadows?
	redownload_lightmap = true, -- redownload light maps when map light changes enough?
	drawfog = true, -- Draw skybox fog?
	rainParticles = 7, -- Max amount of rain particles, this is multiplied by 64 so 1 is 64 2 is 128
}

StormFox.ClientSettingConfiguration.Ultra = {
	breath = true, -- Draw players breath when it's cold
	clouds = true, -- Draw clouds?
	dynamic_shadows = true, -- Draw dynamic shadows?
	redownload_lightmap = true, -- redownload light maps when map light changes enough?
	drawfog = true, -- Draw skybox fog?
	rainParticles = 9, -- Max amount of rain particles, this is multiplied by 64 so 1 is 64 2 is 128
}

local tEnumMap = {
	[ 0 ] = "VeryLow",
	[ 1 ] = "Low",
	[ 2 ] = "Normal",
	[ 3 ] = "Hight",
	[ 4 ] = "Ultra"
}
local function settingTableFromGfxLevel( nGFXLevel )
	nGFXLevel = nGFXLevel and math.Clamp( nGFXLevel, 0, 4 ) or 2
	return StormFox.ClientSettingConfiguration[ tEnumMap[ nGFXLevel ] ]
end

local cvarSFoxWeatherQuality = GetConVar("sf_graphic_settings")
local nGraphicsLevel = cvarSFoxWeatherQuality and cvarSFoxWeatherQuality:GetInt() or 2

cvars.AddChangeCallback("sf_graphic_settings", function( sConvar, sOldValue, sNewValue )
	nGraphicsLevel = cvarSFoxWeatherQuality and math.Clamp( cvarSFoxWeatherQuality:GetInt(), 0, 4 ) or 2
	StormFox.ClientSettings = settingTableFromGfxLevel( nGraphicsLevel )
end, "StormFox.GraphicSettingsConvarUpdate")



StormFox.ClientSettings = settingTableFromGfxLevel( nGraphicsLevel )
