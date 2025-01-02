local type = class.type

local Base = {}

function Base:__ctor(markup, buffer, data)
	self.markup = markup
	self.data = data
end

function Base:__dtor() end

function Base:PerformLayout(markup, buffer, data) end
function Base:Think(markup, buffer, data) end
function Base:Draw(markup, buffer, data) end
function Base:ModifyBuffer(markup, buffer, data) end
function Base:TagStart(markup, buffer, data) end
function Base:TagEnd(markup, buffer, data) end
function Base:StartChar(markup, buffer, data, char, cx, cy, cw, ch, font) end
function Base:EndChar(markup, buffer, data, char, cx, cy, cw, ch, font) end
function Base:StartWord(markup, buffer, data) end
function Base:EndWord(markup, buffer, data) end

class:register("BaseChunk", Base, nil, true)

local Text = {}

local spaces =
"[" ..
"\x20\xC2\xA0\xE1\x9A\x80\xE1\xA0\x8E\xE2\x80\x80\xE2\x80\x81\xE2\x80\x82" ..
"\xE2\x80\x83\xE2\x80\x84\xE2\x80\x85\xE2\x80\x86\xE2\x80\x87\xE2\x80\x88" ..
"\xE2\x80\x89\xE2\x80\x8A\xE2\x80\x8B\xE2\x80\xAF\xE2\x81\x9F\xE3\x80\x80" ..
"\xEF\xBB\xBF]"

surface.__SetFont = surface.__SetFont or surface.SetFont
local setFont = surface.__SetFont

function surface.GetFont()
	return f
end

local cche = {}

surface.__CreateFont = surface.__CreateFont or surface.CreateFont
surface.CachedFonts = surface.CachedFonts or {}

function surface.GetLuaFonts()
	return surface.CachedFonts
end

local tempWidth = 0
function Text:MakeCharInfo(markup, buffer, data)
    local chars = utf_totable(data)
    local words = spaces:Explode(data, true)
    local x, y, w = buffer.x or 0, 0, markup.w or 99999999999

    surface.SetFont(buffer.font)

    local cword = 1
    local charinfo = {}
    local current_line = ""
    local current_line_width = 0

    local tabwidth = surface.GetTextSize("     ")
    local _,newline = surface.GetTextSize("\n")
    newline = newline / 2

    local h = 0
	buffer.tempWidth = buffer.tempWidth or 0

    local charC = #chars
    for i = 1, charC do
        local char = chars[i]
		
		if not char then
			continue
		end

        local cw, ch = surface.GetTextSize(char)

        if char:match(spaces) or char == "\t" then
            local word = words[cword + 1]
            if word then
                cword = cword + 1
                local ww = surface.GetTextSize(word)

                if buffer.tempWidth + cw > w then
					local line = string.Trim(current_line)
				
					if line ~= "" then
						charinfo[#charinfo + 1] = {line, x, y, current_line_width, newline}
					end
					
                    y = y + newline
                    x = 0
                    if newline + y > h then
                        h = newline + y
                    end
                    current_line = ""
                    current_line_width = 0
                end
            end
            current_line = current_line .. char
            current_line_width = current_line_width + (char == "\t" and tabwidth or cw)
			buffer.tempWidth = buffer.tempWidth + (char == "\t" and tabwidth or cw)
        elseif char == "\n" or char == "\r" then
			local line = string.Trim(current_line)
			
			if line ~= "" then
				charinfo[#charinfo + 1] = {line, x, y, current_line_width, newline}
			end

            y = y + newline
            x = 0
            if newline + y > h then
                    h = newline + y
            end
            current_line = ""
            current_line_width = 0
			buffer.tempWidth = 0
        else
            if buffer.tempWidth + cw > w then
				local line = string.Trim(current_line)

				if line ~= "" then
					charinfo[#charinfo + 1] = {line, x, y, current_line_width, newline}
				end

                y = y + newline
                x = 0
                if newline + y > h then
                    h = newline + y
                end
                current_line = ""
                current_line_width = 0
				buffer.tempWidth = 0
            end

            current_line = current_line .. char
            current_line_width = current_line_width + cw
			buffer.tempWidth = buffer.tempWidth + cw
        end
    end

	local line = string.Trim(current_line)
    if line ~= "" then
        charinfo[#charinfo + 1] = {line, x, y, current_line_width, newline}
        x = x + current_line_width

        if newline + y > h then
            h = newline + y
        end
    end

    self.charinfo = charinfo
    self.h, self.x, self.y = h, x, y
end

function Text:__ctor(markup, buffer, data)
	self:MakeCharInfo(markup, buffer, data)
end

function Text:PerformLayout(markup, buffer, data)
	self:MakeCharInfo(markup, buffer, data)
end

local pairs = pairs
local match = string.match
local surfaceSetFont = surface.SetFont
local surfaceSetFontFallback = surface.SetFontFallback
local surfaceSetTextColor = surface.SetTextColor
local surfaceSetTextPos = surface.SetTextPos
local surfaceDrawText = surface.DrawText
local surfaceSetDrawColor = surface.SetDrawColor
local surfaceDrawRect = surface.DrawRect
local number = number

local funcA = function(c) return markup, buffer, c.data end
local funcB = function(c) return markup, buffer, c.data, char, cx, cy, cw, ch, font end

function Text:Draw(markup, buffer, data)
    local chinfo = self.charinfo
    if not chinfo then return end
    local font, color = buffer.font, buffer.fgColor
    local bgcolor = buffer.bgColor
    local y = buffer.y or 0
	local oldShadow = chathud.oldShadow
	local cInfoC = #chinfo

	for i = 1, cInfoC do
		local ci = chinfo[i]
        local char, cx, cy, cw, ch = ci[1], ci[2], ci[3], ci[4], ci[5]
        cy = cy + y

        if buffer.shadow then
            local size = buffer.shadow
            surfaceSetFont(font .. "_blur")
            surfaceSetTextColor(0, 0, 0, 255)

            for i = 1, size do
                surfaceSetTextPos(cx, cy)
                surfaceDrawText(char)
            end
        end
        surfaceSetFont(font)

        if bgcolor.a > 0 then
            surfaceSetDrawColor(bgcolor)
            surfaceDrawRect(cx, cy, cw, ch)
        end

        surfaceSetTextColor(color)
        surfaceSetTextPos(cx, cy)
        surfaceDrawText(char)
    end
end

function Text:ModifyBuffer(markup, buffer, data)
	buffer.h, buffer.x, buffer.y = self.h, self.x, buffer.y + self.y
end

class:register("Text", Text, "BaseChunk")

local GenericDrawable = {}

function GenericDrawable:Draw(markup, buffer, data)
	if data.Draw then
		data.Draw(markup, buffer, data)
	end
end

function GenericDrawable:ModifyBuffer(markup, buffer, data)
	if data.ModifyBuffer then
		data.ModifyBuffer(markup, buffer, data)
	end
end

class:register("GenericDrawable", GenericDrawable, "BaseChunk")

local Image = {}

function Image:__ctor(markup, buffer, data)
	local size = data.size
	size = size > 128 and 128 or size < 8 and 8 or size
	self.size = size
end

function Image:Draw(markup, buffer, data)
	local image, size = _f(data.image), self.size
	if not image then return end
	if isstring(image) then image = MaterialCache(image, "noclamp smooth mips") end
	surface.SetDrawColor(buffer.fgColor)
	surface.SetMaterial(image)
	surface.DrawTexturedRect(buffer.x, buffer.y, size, size)
end

function Image:ModifyBuffer(markup, buffer, data)
	buffer.x, buffer.newlineSize = self.size, self.size
end

class:register("Image", Image, "BaseChunk")

local MarkupTag = {}

function MarkupTag:__ctor(markup, buffer, data)
	self.markupData = data.markupData
	self.type = data.markupType
end

local color_white, color_red = Color(255, 255, 255), Color(255, 0, 0)
function MarkupTag:TagPanic(err)
	if err ~= false then
		MsgC(color_white, "Preventing " .. (self.type or "unknown") .. " tag from misbehaving!\n")
		MsgC(color_red, "Reason:\n\t" .. tostring(err or "(no reason??)"):gsub("\n","\n\t") .. "\n")
		debug.Trace()
	end
	self.__panic = true
end

local function placeholder() end
local function wrap(method)
	return function(self, markup, buffer, data)
		local args = data.data
		local newargs = {}
		for i = 1, #args do
			newargs[#newargs + 1] = args[i]()
		end
		local ok, why = pcall(data[method] or placeholder, self, markup, buffer, newargs)
		if not ok then
			self:TagPanic("Lua ERROR: " .. why)
		end
	end
end

MarkupTag.TagStart = wrap("TagStart")
MarkupTag.TagEnd = wrap("TagEnd")
MarkupTag.StartChar = wrap("StartChar")
MarkupTag.EndChar = wrap("EndChar")
MarkupTag.StartWord = wrap("StartWord")
MarkupTag.EndWord = wrap("EndWord")
MarkupTag.Draw = wrap("Draw")
MarkupTag.ModifyBuffer = wrap("ModifyBuffer")

class:register("MarkupTag", MarkupTag, "BaseChunk")

local MarkupTagStopper = {}

class:register("MarkupTagStopper", MarkupTagStopper, "BaseChunk")

local MarkupBuffer = {}

function MarkupBuffer:__ctor(markup)
	getmetatable(self)["__markup"] = markup
	self:Clear()
end

local color_white, color_transparent = Color(255, 255, 255), Color(0, 0, 0, 0)
function MarkupBuffer:Fill()
	self.markup = getmetatable(self)["__markup"]
	self.x = 0
	self.y = 0
	self.w = 0

	self.fgColor = color_white
	self.bgColor = color_transparent
	self.font = "DermaDefault"
	self.shadow = false
end

function MarkupBuffer:Clear()
	getmetatable(self)["vars"] = {}
	self:Fill()
end

class:register("MarkupBuffer", MarkupBuffer)

local Markup = {}

function Markup:__ctor()
	self.alpha = 50
	self.chunks = {}
	self.buffer = class:new("MarkupBuffer", self)
end

function Markup:Call(method, ...)
	local arg1 = select(1, ...)
	local is_func = isfunction(arg1)
	local ch = self.chunks

	for i = 1, #ch do
		local chunk = ch[i]
		local m = chunk[method]

		if not m then
			goto skip
		end

		if is_func then
			m(chunk, arg1(chunk))
		else
			m(chunk, ...)
		end
		
		::skip::
	end
end

function Markup:Set(key, value)
	for _, chunk in ipairs(self.chunks) do
		chunk[key] = value
	end
end

function Markup:PerformLayout()
	self.buffer:Clear()
	for _, chunk in ipairs(self.chunks) do
		chunk:PerformLayout(self, self.buffer, chunk.data)
	end
	self:Draw(true)
end

function Markup:Draw(nodraw)
	self:Set("__skip", nil)
	local buffer = self.buffer
	buffer:Clear()
	local activeTags = {}
	local height = 0
	local ch = self.chunks
	
	for i = 1, #ch, 1 do
		local chunk = ch[i]
		if chunk.__skip or chunk.__panic then continue end
		local chunkType = type(chunk)

		if chunkType == "MarkupTag" then
			if not activeTags[chunk] then
				activeTags[chunk] = chunk
				chunk:TagStart(self, buffer, chunk.data)
			end
		elseif chunkType == "MarkupTagStopper" then
			if chunk.data then
				local chunker = activeTags[chunk.data]
				if chunker then
					activeTags[chunk.data] = nil
					chunker:TagEnd(self, buffer, chunker.data)
					chunker.__skip = true
				end
			else
				local cactiveTags = #activeTags
				for i = 1, cactiveTags do
					local chunker = activeTags[i]

					chunker:TagEnd(self, buffer, chunker.data)
					chunker.__skip = true
				end
				activeTags = {}
			end
		end

		if not nodraw then
			chunk:Draw(self, buffer	, chunk.data)
		end
		chunk:ModifyBuffer(self, buffer, chunk.data)

		local h = math.max(buffer.y + 22, buffer.h) or 0 -- HACK: https://b.catgirlsare.sexy/BhRE.txt
		if h > height then
			height = h
		end
	end
	self.h = height
end

function Markup:Think()
	self:Call("Think", function(c) return self, self.buffer, c.data end)
end

function Markup:AlphaTick()
	if not self.fadeOut then return end
	local s, e = self.startTime, self.endTime
	if s and e and CurTime() > s + e then
		self.alpha = self.alpha - self.fadeOut / 2
	else
		self.alpha = math.min(self.alpha + RealFrameTime() * 255 * 3, 255)
	end
end

function Markup:TagPanic(err)
	for _, chunk in pairs(self.chunks) do
		if type(chunk) == "MarkupTag" then
			chunk:TagPanic(err)
		end
	end
end

function Markup:InsertChunk(name, data)
	local obj = class:new(name, self, self.buffer, data)
	self.chunks[#self.chunks + 1] = obj
	obj:ModifyBuffer(self, self.buffer, data)
	return obj
end

function Markup:AddString(text)
	return self:InsertChunk("Text", text)
end

function Markup:AddImage(imageData)
	return self:InsertChunk("Image", imageData)
end

function Markup:AddFGColor(color)
	return self:InsertChunk("GenericDrawable", {ModifyBuffer = function(_, buffer)
		buffer.fgColor = _f(color)
	end})
end

function Markup:AddBGColor(color)
	return self:InsertChunk("GenericDrawable", {ModifyBuffer = function(_, buffer)
		buffer.bgColor = _f(color)
	end})
end

function Markup:AddFont(font)
	return self:InsertChunk("GenericDrawable", {ModifyBuffer = function(_, buffer)
		buffer.font = _f(font)
	end})
end

function Markup:AddShadow(size)
	return self:InsertChunk("GenericDrawable", {ModifyBuffer = function(_, buffer)
		buffer.shadow = _f(size)
	end})
end

function Markup:AddTag(data)
	return self:InsertChunk("MarkupTag", data)
end

function Markup:AddTagStopper(type)
	return self:InsertChunk("MarkupTagStopper", type)
end

function Markup:StartLife(length)
	self.startTime, self.endTime = CurTime(), tonumber(length) or 5
end

function Markup:EndLife()
	self.fadeOut = 7
	self:AddTagStopper()
end

local function env()
	local tick = 0
	return {
		sin = math.sin,
		cos = math.cos,
		tan = math.tan,
		sinh = math.sinh,
		cosh = math.cosh,
		tanh = math.tanh,
		rand = math.random,
		pi = math.pi,
		log = math.log,
		log10 = math.log10,
		time = CurTime,
		t = CurTime,
		realtime = RealTime,
		rt = RealTime,
		tick = function()
			local o = tick
			tick = tick + 1
			return o / 100
		end,
	}
end

local Expression = {}

function Expression:__ctor(expression, filter)
	self.expression = expression
	self.resfilter = filter
end

local bad_keywords = {
	"break",     "do",        "else",      "elseif",    "end",
	"false",     "for",       "function",  "if",        "in",
	"repeat",    "return",    "then",      "until",     "while",
	"local",
}

function Expression:Compile()
	local env, expression = env(), self.expression

	local ch = expression:match("[^=1234567890%-%+%*/%%%^%(%)%.A-z%s]")
	if ch then
		return "expression:1: invalid character " .. ch
	end

	for _, keyword in ipairs(bad_keywords) do
		local ch = expression:match("[^A-z]" .. keyword .. "[^A-z]") or expression:match("^" .. keyword .. "[^A-z]")
		if ch then
			return "expression:1: keywords are not allowed " .. ch
		end
	end

	local compiled = CompileString("return (" .. expression .. ")", "expression", false)
	if isstring(compiled) then
		compiled = CompileString(expression, "expression", false)
	end
	if isstring(compiled) then
		return compiled
	end
	if not isfunction(compiled) then
		return "expression:1: unknown error"
	end
	setfenv(compiled, env)
	self.compiled = compiled
end

function Expression:Run(resfilter)
	if not self.compiled then return end
	local ok, why = pcall(self.compiled)
	if not ok then
		return false, why
	end
	if self.resfilter then why = self.resfilter(why) end
	return why
end

class:register("Expression", Expression)

class:makeFunction("Expression")

local IGNORE = function() end
local function parse(self, str, ply, tags, shouldEscape, stopFunc, addFunc, addTagFunc)
	local stopFunc = stopFunc or IGNORE
	local addFunc = addFunc or IGNORE
	local addTagFunc = addTagFunc or IGNORE
	local makeTagObjFunc = makeTagObjFunc or IGNORE

	local cur = ""
	local inTag
	local activeTags = {}
	local escaped

	local toTable = utf_totable(str)
	for i = 1, #toTable do
		local s = toTable[i]

		if s == "<" and not inTag then
			inTag = true
			if cur ~= "" then
				addFunc(self, cur)
				cur = ""
			end
		continue end

		if s == ">" and inTag then
			inTag = nil

			if cur:sub(1, 1) == "/" then
				cur = cur:sub(2)

				if shouldEscape and escaped and cur == "noparse" then
					escaped = false
					cur = ""
					continue
				elseif not escaped and activeTags[cur] and #activeTags[cur] > 0 then
					stopFunc(self, activeTags[cur][#activeTags[cur]])
					table.remove(activeTags[cur], #activeTags[cur])
					cur = ""
					continue
				else
					addFunc(self, "</" .. cur .. ">")
					cur = ""
					continue
				end
			else
				local tag, args = cur:match("(.-)=(.+)")
				if not tag then
					tag, args = cur, ""
				end
				local tagobject = tags[tag]

				if shouldEscape and not escaped and tag == "noparse" then
					escaped = true
					cur = ""
					continue
				elseif escaped or not tagobject then
					addFunc(self, "<" .. cur .. ">")
					cur = ""
					continue
				end

				args = chathud:DoArgs(args, tagobject.args)
				if isentity(ply) and ply:IsPlayer() and hook.Run("CanPlayerUseTag", ply, tag, args) == false then
					addFunc(self, "<" .. cur .. ">")
					cur = ""
					continue
				end

				local t = addTagFunc(self, tagobject, args)
				activeTags[tag] = activeTags[tag] or {}
				activeTags[tag][#activeTags[tag] + 1] = t or {}
			end

			cur = ""
			continue 
		end

		cur = cur .. s
	end

	if cur ~= "" or inTag then
		local var = cur
		if inTag then
			var = "<" .. var
		end

		addFunc(self, var)
	end

end

local function evalPreTags(data)
	local str = ""
	local buffer = ""
	local shouldEdit = false

	parse(_, data, ply, chathud.PreTags, false,
	function(_, tag)
		local content = tag.func(buffer, tag.data)
		str = str .. content

		shouldEdit = false
		buffer = ""
	end,
	function(_, content)
		buffer = buffer .. content
	end,
	function(_, tagobject, args)
		if not shouldEdit and #buffer > 0 then
			str = str .. buffer
			buffer = ""
		end

		local newargs = {} -- Pretags don't get to evaluate their arguments more than once
		for _, arg in pairs(args) do
			newargs[#newargs + 1] = arg()
		end

		local t = {}
		t.data = newargs
		t.func = tagobject.func

		shouldEdit = true

		return t
	end)

	return str .. buffer
end

function Markup:Parse(data, ply, noPreTags, noShortcuts)
	local str = ""
	if noPreTags then
		str = data
	else
		str = evalPreTags(data)
	end

	if not noShortcuts then
		str = str:gsub("%:([0-9A-z%-_]-)%:", function(a)
			local sh = chathud.Shortcuts[a]

			if sh then
				return sh
			end
		end)
	end

	parse(self, str, ply, chathud.Tags, true,
	self.AddTagStopper,
	self.AddString,
	function(_, tagobject, args)
		local t = table.Copy(tagobject)
		t.data = args

		return self:AddTag(t)
	end)
end

local cache = {}
function markup_quickParse(data, ply)
	if cache[data] then
		return cache[data]
	end

	local str = ""
	if noPreTags then
		str = data
	else
		str = evalPreTags(data)
	end

	local ret = ""

	parse(nil, str, ply, chathud.Tags, true,
	nil,
	function(_, content)
		ret = ret .. content
	end,
	nil)

	cache[data] = ret

	return ret
end


class:register("Markup", Markup)
class:makeFunction("Markup")
