local blacklist = {
	["0"] = true,
	["1"] = true,
}

local emoticon_cache = {}
local busy = {}

local function MakeCache(filename, emoticon)
	local mat = Material("data/" .. filename, "noclamp smooth")
	emoticon_cache[emoticon or string.StripExtension(string.GetFileFromFilename(filename))] = mat
end

function chathud.CreateSteamShortcuts(update)
	local tag = os.date("%Y%m%d")
	local latest = "steam_emotes_" .. tag .. ".dat"

	local found = file.Find("emoticon_cache/steam_emotes_*.dat", "DATA")
	for k, v in next,found do
		if v ~= latest then file.Delete("emoticon_cache/" .. v) end
	end

	latest = "emoticon_cache/" .. latest

	if file.Exists(latest, "DATA") and not update then
		local data = file.Read(latest, "DATA")

		local explode = string.Split(data, ",")
		for key, name in ipairs(explode) do
			if not chathud.Shortcuts[name] and not blacklist[name] then
				chathud.Shortcuts[name] = "<se=" .. name .. ">"
			end
		end
	else
		http.Fetch("https://raw.githubusercontent.com/Earu/EasyChat/master/external_data/steam_emoticons.txt", function(b, _, _, code)
			if code ~= 200 then
				return
			end

			local explode = string.Split(b, ",")
			for key, name in ipairs(explode) do
				if not chathud.Shortcuts[name] and not blacklist[name] then
					chathud.Shortcuts[name] = "<se=" .. name .. ">"
				end
			end

			file.Write(latest, b)
		end)
	end
end

chathud.CreateSteamShortcuts()

function chathud:GetSteamEmoticon(emoticon)
	emoticon = emoticon:gsub(":",""):Trim()
	if emoticon_cache[emoticon] then
		return emoticon_cache[emoticon]
	end

	if busy[emoticon] then
		return false
	end
	if file.Exists("emoticon_cache/" .. emoticon .. ".png", "DATA") then
		MakeCache("emoticon_cache/" .. emoticon .. ".png", emoticon)
	return emoticon_cache[emoticon] or false end
	Msg"ChatHUD " print("Downloading emoticon " .. emoticon)
	http.Fetch("https://steamcommunity-a.akamaihd.net/economy/emoticonhover/:" .. emoticon .. ":", function(body, len, headers, code)
		if code == 200 then
			if body == "" then
				Msg"ChatHUD " print("Server returned OK but empty response")
			return end
			Msg"ChatHUD " print("Download OK")
			local whole = body
			body = body:match("src=\"data:image/png;base64,(.-)\"")
			if not body then Msg"ChatHUD " print("ERROR! (no body)", whole) return end
			local b64 = body
			body = chathud.dec(body)
			if not body then Msg"ChatHUD " print("ERROR! (not b64)", b64) return end
			file.Write("emoticon_cache/" .. emoticon .. ".png", body)
			MakeCache("emoticon_cache/" .. emoticon .. ".png", emoticon)
		else
			Msg"ChatHUD " print("Download failure. Code: " .. code)
		end
	end)
	busy[emoticon] = true
	return false
end
