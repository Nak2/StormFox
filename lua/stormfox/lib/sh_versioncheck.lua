--[[-------------------------------------------------------------------------
	Reports the SF version. 
---------------------------------------------------------------------------]]
-- Local functions
	local function ReportVersion(version)
		assert(StormFox.Language,"No language functions!")
		if StormFox.Version < version then
			if CLIENT then
				chat.AddText(Color(155,155,255),"[StormFox] ",Color(255,255,255),StormFox.Language.Translate("sf_description.oldversion") .. ".")
			end
			StormFox.Msg(Color(255,0,0),StormFox.Language.Translate("sf_description.oldversion") .. ".")
			StormFox.Msg(StormFox.Version .. " < " .. version .. ".")
		elseif StormFox.Version > version then
			if CLIENT then
				chat.AddText(Color(155,155,255),"[StormFox] ",Color(255,255,255),StormFox.Language.Translate("sf_description.newversion") .. ".")
			end
			StormFox.Msg(Color(255,0,0),StormFox.Language.Translate("sf_description.newversion") .. ".")
			StormFox.Msg(StormFox.Version .. " > " .. version .. ".")
		end
	end
-- Check the version
	local nextCheck = cookie.GetNumber("StormFox.VersionCheck",0) + 86400
	local lastVersionCheck = cookie.GetNumber("StormFox.LastVersionCheck",0)
	local toDay = os.time()
	-- In case we got a new StormFox version
		if lastVersionCheck < StormFox.Version then
			cookie.Set("StormFox.LastVersionCheck",StormFox.Version)
			nextCheck = 0 -- We check today
		end
	hook.Add("StormFox.PostEntity","StormFox.ReportVersion",function()
		if nextCheck > toDay then -- No need to check the webpage. Use the last number.
			ReportVersion(cookie.GetNumber("StormFox.VersionLast", StormFox.Version))
		else -- Check the workshop. Its been over a day.
			cookie.Set("StormFox.VersionCheck",os.time())
			local function onSuccess(body)
				local workshopVersion = tonumber(body:match("Version ([%d%.]+)%s") or "") or StormFox.Version
				cookie.Set("StormFox.VersionLast",workshopVersion)
				ReportVersion(workshopVersion)
			end
			local function onFail()
				ReportVersion(cookie.GetNumber("StormFox.VersionLast", StormFox.Version))
			end
			http.Fetch("http://steamcommunity.com/sharedfiles/filedetails/?id=1132466603",onSuccess,onFail)
		end
	end)