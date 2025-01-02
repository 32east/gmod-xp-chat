file.CreateDir("emoticon_cache")

local col = Color(255, 200, 0, 255)
local Msg = function(...) MsgC(col, ...)  end

chathud = chathud or {}
chathud.oldShadow = chathud.oldShadow or false
chathud.Shortcuts = chathud.Shortcuts or {}

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

local b = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

chathud.dec = function(data)
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

if string.anime then
	chathud.PreTags["anime"] = {
		args = {
			-- no args
		},
		func = string.anime
	}
end

if CLIENT then
	include("xp3/modules/chat_tags.lua")
	include("xp3/modules/steam_emojis.lua")
end

chathud.x = 32
chathud.y = ScrH() - 200
chathud.w = 550

chathud.markups = {}

for _, icon in ipairs(file.Find("materials/icon16/*.png", "GAME")) do
	chathud.Shortcuts[string.StripExtension(icon)] = "<texture=icon16/" .. icon .. ">"
end

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
	markup:AddShadow(chathud.oldShadow and 2 or 4)
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
	local FT = RealFrameTime() * 24

    for i = 1, #markups do
        local markup = markups[i]
        local alpha = markup.alpha

        if alpha > 0 then
            surface_SetAlphaMultiplier(math.ease.InOutQuart(alpha / 255))

            local x = chathud_x
            if pace_editor_wide then
                x = x + pace_editor_wide
            end

			if not markup.cX then
				markup.cX = -100
			end

			markup.cX = Lerp(FT, markup.cX, x)
			markup.cY = Lerp(FT, markup.cY or markup.y or 0, markup.y or 0)

			localizedVec.x = markup.cX
			localizedVec.y = markup.cY

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

function chathud:DoArgs(str, argfilter)
	local argtb = str:Split(",")
	if argtb[1] == "" then argtb = {} end
	local t = {}
	for i = 1, #argfilter do
		local f = argfilter[i]
		local value
		local m = argtb[i]

		if m and m:match("%[.+%]") then
			local exp = class:new("Expression", m:sub(2,-2), function(res)
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
				value = number(m, f.min, f.max, f.default)
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
