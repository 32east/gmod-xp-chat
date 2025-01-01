file.CreateDir("emoticon_cache")

local col = Color(255, 200, 0, 255)
local Msg = function(...) MsgC(col, ...)  end

chathud = chathud or {}
chathud.oldShadow = chathud.oldShadow or false

-- What's the difference between a PreTag and a Tag, I hear you ask.

-- A pretag is evaluated BEFORE all normal tags.
-- Pretags also only get evaluated ONCE due to their nature, making expression
-- arguments with variable data basicly useless.

-- Rather than providing functionality to the buffer, they change the data IN the buffer.

chathud.PreTags = {
	["rep"] = {
		args = {
			[1] = {type = "number", min = 0, max = 10, default = 1},
		},
		func = function(text, args)
			return text:rep(args[1])
		end
	},
}

if string.anime then
	chathud.PreTags["anime"] = {
		args = {
			-- no args
		},
		func = string.anime
	}
end

chathud.Tags = {
	["color"] = {
		args = {
			[1] = {type = "number", min = 0, max = 255, default = 255}, -- r
			[2] = {type = "number", min = 0, max = 255, default = 255}, -- g
			[3] = {type = "number", min = 0, max = 255, default = 255}, -- b
			[4] = {type = "number", min = 0, max = 255, default = 255}, -- a
		},
		TagStart = function(self, markup, buffer, args)
			self._fgColor = buffer.fgColor
		end,
		ModifyBuffer = function(self, markup, buffer, args)
			buffer.fgColor = Color(args[1] or 255, args[2] or 255, args[3] or 255, args[4] or 255)
		end,
		TagEnd = function(self, markup, buffer, args)
			buffer.fgColor = self._fgColor or Color(255, 255, 255, 255)
			self._fgColor = nil
		end,
	},
	["bgcolor"] = {
		args = {
			[1] = {type = "number", min = 0, max = 255, default = 255}, -- r
			[2] = {type = "number", min = 0, max = 255, default = 255}, -- g
			[3] = {type = "number", min = 0, max = 255, default = 255}, -- b
			[4] = {type = "number", min = 0, max = 255, default = 0}, -- a
		},
		TagStart = function(self, markup, buffer, args)
			self._bgColor = buffer.bgColor
		end,
		ModifyBuffer = function(self, markup, buffer, args)
			buffer.bgColor = Color(args[1] or 255, args[2] or 255, args[3] or 255, args[4] or 255)
		end,
		TagEnd = function(self, markup, buffer, args)
			buffer.bgColor = self._bgColor or Color(255, 255, 255, 0)
		end,
	},
	["font"] = {
		args = {
			[1] = {type = "string", default = "DermaDefault"}, -- fontname
		},
		TagStart = function(self, markup, buffer, args)
			self._font = buffer.font
		end,
		ModifyBuffer = function(self, markup, buffer, args)
			buffer.font = args[1]
		end,
		TagEnd = function(self, markup, buffer, args)
			buffer.font = self._font or "chathud_18"
		end,
	},
	["hsv"] = {
		args = {
			[1] = {type = "number", default = 0},					--h
			[2] = {type = "number", min = 0, max = 1, default = 1},	--s
			[3] = {type = "number", min = 0, max = 1, default = 1},	--v
		},
		TagStart = function(self, markup, buffer, args)
			self._fgColor = buffer.fgColor
		end,
		ModifyBuffer = function(self, markup, buffer, args)
			if not self._fgColor then self._fgColor = buffer.fgColor end
			buffer.fgColor = HSVToColor(args[1] % 360, args[2], args[3])
		end,
		TagEnd = function(self, markup, buffer, args)
			buffer.fgColor = self._fgColor or Color(255, 255, 255, 255)
		end,
	},
	["dev_hsvbg"] = {
		args = {
			[1] = {type = "number", default = 0},					--h
			[2] = {type = "number", min = 0, max = 1, default = 1},	--s
			[3] = {type = "number", min = 0, max = 1, default = 1},	--v
		},
		TagStart = function(self, markup, buffer, args)
			self._bgColor = buffer.bgColor
		end,
		ModifyBuffer = function(self, markup, buffer, args)
			buffer.bgColor = HSVToColor(args[1] % 360, args[2], args[3])
		end,
		TagEnd = function(self, markup, buffer, args)
			buffer.bgColor = self._bgColor or Color(255, 255, 255, 0)
		end,
	},
	
--	["translate"] = {
--		args = {
--			[1] = {type = "number", default = 0},	-- x
--			[2] = {type = "number", default = 0},	-- y
--		},
--		TagStart = function(self, markup, buffer, args)
--			self.mtrx = Matrix()
--		end,
--		Draw = function(self, markup, buffer, args)
--			self.mtrx:SetTranslation(Vector(chathud.x + args[1], markup.y + args[2]))
--			cam.PushModelMatrix(self.mtrx)
--		end,
--		TagEnd = function(self)
--			cam.PopModelMatrix()
--		end,
--	},
--
--	["rotate"] = {
--		args = {
--			[1] = {type = "number", default = 0},	-- y
--		},
--		TagStart = function(self, markup, buffer, args)
--			self.mtrx = Matrix()
--		end,
--		Draw = function(self, markup, buffer, args)
--			self.mtrx:SetTranslation(Vector(chathud.x, markup.y))
--
--			self.mtrx:Translate(Vector(buffer.x, buffer.y + (buffer.h * 0.5)))
--				self.mtrx:Rotate(Angle(0, args[1], 0))
--			self.mtrx:Translate(-Vector(buffer.x, buffer.y + (buffer.h * 0.5)))
--
--			cam.PushModelMatrix(self.mtrx)
--		end,
--		TagEnd = function(self)
--			cam.PopModelMatrix()
--		end,
--	},
--
--	["scale"] = {
--		args = {
--			[1] = {type = "number", default = 1},	-- x
--			[2] = {type = "number", default = 1},	-- y
--		},
--		TagStart = function(self, markup, buffer, args)
--			self.mtrx = Matrix()
--		end,
--		Draw = function(self, markup, buffer, args)
--			self.mtrx:SetTranslation(Vector(chathud.x, markup.y))
--
--			self.mtrx:Translate(Vector(buffer.x, buffer.y + (buffer.h * 0.5)))
--				self.mtrx:Scale(Vector(args[1], args[2]))
--			self.mtrx:Translate(-Vector(buffer.x, buffer.y + (buffer.h * 0.5)))
--
--			cam.PushModelMatrix(self.mtrx)
--		end,
--		TagEnd = function(self)
--			cam.PopModelMatrix()
--		end,
--	},

}
chathud.Shortcuts = {}

chathud.x = 32
chathud.y = ScrH() - 200
chathud.w = 550

chathud.markups = {}

for _, icon in ipairs(file.Find("materials/icon16/*.png", "GAME")) do
	chathud.Shortcuts[string.StripExtension(icon)] = "<texture=icon16/" .. icon .. ">"
end

local blacklist = {
	["0"] = true,
	["1"] = true,
}
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

function chathud:AddMarkup()
	local markup = class:new("Markup")
	self.markups[#self.markups + 1] = markup
	self:CleanupOldMarkups()
	markup.w = self.w
	self:Invalidate(true)
	return markup
end

function chathud:CleanupOldMarkups()
	for _, m in pairs(self.markups) do
		if m.alpha <= 0 then
			table.RemoveByValue(self.markups, m)
		end
	end
end

local consoleColor = Color(106, 90, 205, 255)
function chathud:AddText(...)
	local markup = self:AddMarkup()
	markup:StartLife(10)
	markup:AddFont("chathud_18")
	markup:AddShadow(chathud.oldShadow and 2 or 3)
	for i = 1, select("#", ...) do
		local var = select(i, ...)
		if isstring(var) then
			markup:Parse(var, chatexp.LastPlayer)
		elseif istable(var) and var.r and var.g and var.b and var.a then
			markup:AddFGColor(var)
		elseif isentity(var) then
			if var:IsPlayer() then
				markup:AddFGColor(team.GetColor(var:Team()))
				markup:Parse(var:Nick())
			else
				local name = (var.Name and isfunction(var.name) and var:Name()) or var.Name or var.PrintName or tostring(var)
				if var:EntIndex() == 0 then
					markup:AddFGColor(consoleColor)
					name = "Console"
				end

				markup:AddString(name)
			end
		else
			markup:AddString(tostring(var))
		end
	end
	markup:EndLife()
end

function chathud:Think()
	local markups = self.markups
    for i = 1, #markups do
		markups[i]:AlphaTick()
	end
end

function chathud:Invalidate(now)
	self.needs_layout = true
	if now then self:PerformLayout() end
end

function chathud:PerformLayout()
	local y = self.y
	for i = #self.markups, 1, -1 do
		local markup = self.markups[i]
		if markup.h then
			y = y - markup.h
		end
		markup.y = y
	end
end

function chathud:TagPanic()
	local markups = self.markups
    for i = 1, #markups do
		markups[i]:TagPanic(false)
	end
end

local matrix = Matrix()
local surface_SetAlphaMultiplier = surface.SetAlphaMultiplier
local cam_PushModelMatrix = cam.PushModelMatrix
local cam_PopModelMatrix = cam.PopModelMatrix
local pcall = pcall
local Msg = Msg
local print = print
local debug_traceback = debug.traceback
local Vector = Vector
local localizedVec = Vector()
local VMatrix = FindMetaTable("VMatrix")
local SetTranslation = VMatrix.SetTranslation

function chathud:Draw()
    if self.needs_layout then
        self:PerformLayout()
    end

    local markups = self.markups
    local chathud_x = chathud.x
    local pace_active = pace and pace.IsActive()
    local pace_editor_alpha = pace_active and pace.Editor:GetAlpha()
    local pace_editor_wide = pace_active and pace_editor_alpha ~= 0 and pace.Editor:GetWide()

    for i = 1, #markups do
        local markup = markups[i]
        local alpha = markup.alpha

        if alpha > 0 then
            surface_SetAlphaMultiplier(math.ease.InOutQuart(alpha / 255))

            local x = chathud_x
            if pace_editor_wide then
                x = x + pace_editor_wide
            end
			localizedVec.x = x
			localizedVec.y = markup.y or 0
            SetTranslation(matrix, localizedVec)

            cam_PushModelMatrix(matrix)
            local ok, why = pcall(markup.Draw, markup)
            if not ok then
                Msg"ChatHUD " print("Drawing Error!")
                print(why, "\n", debug_traceback())
            end
            cam_PopModelMatrix()
        end
    end

    surface_SetAlphaMultiplier(1)

    if self.needs_layout then
         self:PerformLayout()
         self.needs_layout = nil
    end
end

-------------------------

local emoticon_cache = {}
local busy = {}

local function MakeCache(filename, emoticon)
	local mat = Material("data/" .. filename, "noclamp smooth")
	emoticon_cache[emoticon or string.StripExtension(string.GetFileFromFilename(filename))] = mat
end

local dec
do
	local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	function dec(data)
		data = string.gsub(data, "[^" .. b .. "=]", "")
		return data:gsub(".", function(x)
			if x == "=" then return "" end
			local r, f = "", b:find(x) - 1
			for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
			return r
		end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
			if #x ~= 8 then return "" end
			local c = 0
			for i = 1,8 do c = c + (x:sub(i,i) == "1" and 2 ^ (8 - i) or 0) end
			return string.char(c)
		end)
	end
end

file.CreateDir("emoticon_cache")

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
			body = dec(body)
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

-------------------------

local Mcche = {}

local function MaterialCache(a, b)
	a = a:lower()
	if Mcche[a] then return Mcche[a] end
	local m = Material(a, b)
	Mcche[a] = m
	return m
end

chathud.Tags["se"] = {
	args = {
		[1] = {type = "string", default = "error"},
		[2] = {type = "number", min = 8, max = 128, default = 18},
	},
	Draw = function(self, markup, buffer, args)
		local image, size = args[1], args[2]
		image = chathud:GetSteamEmoticon(image)
		if image == false then image = MaterialCache("error") end
		surface.SetDrawColor(buffer.fgColor)
		surface.SetMaterial(image)
		surface.DrawTexturedRect(buffer.x, buffer.y, size, size)
	end,
	ModifyBuffer = function(self, markup, buffer, args)
		local size = args[2]
		buffer.h, buffer.x = size, buffer.x + size
		if buffer.x > markup.w then
			buffer.x = 0
			buffer.y = buffer.y + size
			buffer.h = buffer.y + size
		end
	end,
}

chathud.Tags["texture"] = {
	args = {
		[1] = {type = "string", default = "error"},
		[2] = {type = "number", min = 8, max = 128, default = 16},
	},
	Draw = function(self, markup, buffer, args)
		local image, size = args[1], args[2]
		image = MaterialCache(image)
		if image == false then image = MaterialCache("error") end
		local yoff = 0
		if size < 18 then yoff = 18 - size end
		surface.SetDrawColor(buffer.fgColor)
		surface.SetMaterial(image)
		surface.DrawTexturedRect(buffer.x, buffer.y + yoff, size, size)
	end,
	ModifyBuffer = function(self, markup, buffer, args)
		local size = args[2]
		buffer.h, buffer.x = size, buffer.x + size
		if buffer.x > markup.w then
			buffer.x = 0
			buffer.y = buffer.y + size
			buffer.h = buffer.h + size
		end
	end,
}

function chathud:DoArgs(str, argfilter)
	local argtb = str:Split(",")
	if argtb[1] == "" then argtb = {} end
	local t = {}
	for i = 1, #argfilter do
		local f = argfilter[i]
		local value
		local m = argtb[i]
		if m and m:match("%[.+%]") then
			local exp = class:new("Expression", m:sub(2, -2), function(res)
				if f.type == "number" then
					return number(res, f.min, f.max, f.default)
				else
					return res or f.default or ""
				end
			end)
			local res = exp:Compile()
			if res then
				Msg"ChatHUD " print("Expression error: " .. res)
				value = f.type == "number" and number(nil, f.min, f.max, f.default) or (f.default or "")
			else
				exp.altfilter = f
				value = function()
					return exp:Run()
				end
			end
		else
			if f.type == "number" then
				value = tonumber(m) or f.default
			else
				value = m or f.default or ""
			end
		end
		t[i] = function()
			local a, b = _f(value)
			if a == false and isstring(b) then
				Msg"ChatHUD " print("Expression error: " .. b)
				return f.type == "number" and number(nil, f.min, f.max, f.default) or (f.default or "")
			end
			return a
		end
	end
	return t
end

return chathud
