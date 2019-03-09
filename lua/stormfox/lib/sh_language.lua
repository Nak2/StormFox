--[[-------------------------------------------------------------------------
	Simple language functions
	Functions:
		StormFox.Language.Load( sLanguage )  -- Loads a language, defaults to english if missing.
		StormFox.Language.Translate( str )   -- Translates a string. Can be used as format if given a second or more agument.
		StormFox.Language.Format( str, ... ) -- Translates a string and inputs the varables.
		StormFox.Language.Debug()            -- Prints all missing translations.
---------------------------------------------------------------------------]]
local con = GetConVar( "gmod_language" )
local con_override = GetConVar("sf_language_override")
StormFox.Language = {}
-- Local functions
	local lang = {}
	local missing = {}
	local char = "[^%z]"
	local function ReadLine(str)
		-- Check for #
			if string.match(str,"^%s-#") then return end
		-- Match
			local a,b = string.match(str,"%s*(" .. char .. "+)%s*=%s*(" .. char .. "+)[%s]*")
			if not a or not b then return end -- Not a valid line
		-- Trim left
			--	a = a:gsub("^[%s	]+","")
				b = b:gsub("^[%s	]+","")
			-- Trim right
				a = a:gsub("[%s		]+$","")
				b = b:gsub("[%s	]+$","")
		lang[a] = b
		return a
	end
	local function LoadLangauge( str_langauge )
		table.Empty(missing)
		StormFox.Msg("Language: " .. str_langauge)
		-- Empty the table
			table.Empty(lang)
		-- Load the default english language
			if file.Exists("stormfox/language/en.lua","LUA") then
				for k,v in pairs( string.Explode("\n",file.Read( "stormfox/language/en.lua","LUA" ) or "") ) do
					if string.match(v,"::END::") then break end
					ReadLine(v)
				end
				if str_langauge == "en" then return end -- Already english
				if str_langauge == "debug" then
					for k,s in pairs(lang) do
						lang[k] = k
					end
					return
				elseif str_langauge == "empty" then
					for k,s in pairs(lang) do
						lang[k] = ""
					end
					return
				elseif str_langauge == "l33t" then
					for k,s in pairs(lang) do
						if math.random() > 0.2 then
							s = string.gsub(s,"ed%s","0r ")
							s = string.gsub(s,"er%s","0r ")
							s = string.gsub(s,"ed$","0r")
							s = string.gsub(s,"er$","0r")
						end
						s = string.gsub(s,"[aA]","4")
						s = string.gsub(s,"[eE]","3")
						s = string.gsub(s,"[iI]","1")
						if math.random() > 0.8 then
							s = string.gsub(s,"[oO]","()")
						else
							s = string.gsub(s,"[oO]","0")
						end
						if math.random() > 0.8 then
							s = string.gsub(s,"U","|_|")
						end
						if math.random() > 0.8 then
							s = string.gsub(s,"[tT]","7")
						end
						if math.random() > 0.8 then
							s = string.gsub(s,"D","|)")
						end
						if math.random() > 0.8 then
							s = string.gsub(s,"W",[[\/\/]])
						end
						if math.random() > 0.8 then
							s = string.gsub(s,"s","$")
						end
						lang[k] = s
					end
					return
				end
				for k,s in pairs(lang) do
					missing[k] = s
				end
			else
				ErrorNoHalt("StormFox couldn't find the default language file.")
			end
		-- Override the language table
			local c_lang = "stormfox/language/" .. str_langauge .. ".lua"
			if not file.Exists(c_lang,"LUA") then StormFox.Msg(StormFox.Language.Translate("sf_missinglanguage") .. ": " .. str_langauge .. ".") return end -- Not found
			local data = include(c_lang)
			for k,v in pairs( string.Explode("\n",data) ) do
				if string.match(v,"::END::") then break end
				local s = ReadLine(v or "")
				if s then missing[s] = nil end
			end
	end
-- Functions
	function StormFox.Language.Load()
		local languge = "en"
		if con and #con:GetString() > 0 then languge = con:GetString() or "en" end
		if con_override and #con_override:GetString() > 0 then languge = con_override:GetString() or "en" end
		LoadLangauge(languge)
	end
	function StormFox.Language.Format(str,...)
		if not lang[str] then print("MISSING: ",str) end
		return string.format(lang[str] or str, ... )
	end
	function StormFox.Language.Translate(str, a, ...)
		if not str then return "" end
		if not a then
			return lang[str] or str
		else
			return string.format(lang[str] or str, a, ... )
		end
	end
	function StormFox.Language.PrintMissingText()
		print("[SF] Missing translations:")
		for k,s in pairs(missing) do
			print(k .. " = " .. s)
		end
	end
	if CLIENT then
		concommand.Add( "sf_language_missing", StormFox.Language.PrintMissingText)
	end

-- Convar update.
	cvars.RemoveChangeCallback("gmod_language","StormFox_languagechange")
	cvars.RemoveChangeCallback("sf_language_override","StormFox_languagechange2")
	cvars.AddChangeCallback( "gmod_language", function( convar_name, value_old, value_new )
		StormFox.Language.Load()
	end,"StormFox_languagechange")
	cvars.AddChangeCallback( "sf_language_override", function( convar_name, value_old, value_new )
		StormFox.Language.Load()
	end,"StormFox_languagechange2")
-- Add the language files to download and list them
	local languages = {}
	for _,fil in ipairs(file.Find("stormfox/language/*.lua","LUA")) do
		if SERVER then
			AddCSLuaFile("stormfox/language/" .. fil)
		end
		local name = string.match(fil,"(.+).lua") or "error"
		if name == "chef" then continue end -- I'm hidden. Shhh
		table.insert(languages,name)
	end
	function StormFox.Language.GetAll()
		return languages
	end
-- Load language
	StormFox.Language.Load()