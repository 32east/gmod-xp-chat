local chatbox = {}

chatbox.settings = {
	test = {
		["TEST 1"] = {ty = "Bool", get = function() return false end, set = print},
		["TEST 2"] = {ty = "Color", get = function() return Color(255,255,255) end, set = print},
		["TEST 3"] = {ty = "Number", get = function() return 0 end, set = print, min = 0, max = 12}
	}
}

local box_font = CreateClientConVar("xp_chat_box_font","Roboto",true,false,"Changes the Fonts of the chatbox itself.")
local feed_font = CreateClientConVar("xp_chat_feed_font","Roboto",true,false,"Changes the Font of the text displayed inside the chatbox.")

local editedFonts = {}
local editedBoxFont = 0
local editedFeedFont = 0
local currentBoxFontName = "xp_chat_box_font"
local currentFeedFontName = "xp_chat_feed_font"
local currentTab = 1

local createFont = function(whatFont, fontName)
	if whatFont == "xp_chat_box_font" then
		editedBoxFont = editedBoxFont + 1
		currentBoxFontName = whatFont .. "_" .. editedBoxFont
	else
		editedFeedFont = editedFeedFont + 1
		currentFeedFontName = whatFont .. "_" .. editedBoxFont
	end

	surface.CreateFont(whatFont .. "_" .. editedBoxFont, {
		font = fontName,
		size = 16,
		extended = true,
		antialias = true,
	})
end

cvars.AddChangeCallback("xp_chat_box_font",function(cv,_,new)
	createFont("xp_chat_box_font", new)
end, "xp_chat_box_font")

cvars.AddChangeCallback("xp_chat_feed_font",function(cv,_,new)
	createFont("xp_chat_feed_font", new)
end, "xp_chat_feed_font")

createFont("xp_chat_box_font", box_font:GetString())
createFont("xp_chat_feed_font", feed_font:GetString())

chatbox.accent_color = Color(230, 230, 230, 255)
chatbox.back_color   = Color(000, 000, 000, 200)
chatbox.input_color  = Color(000, 000, 000, 150)

local CONFIG_FILE = "xp_chat_config.lua"
do
	local config = file.Read(CONFIG_FILE, "DATA")

	if config and luadata then
		local data = luadata.Decode(config)

		if data then
			for k, v in next, data do
				chatbox[k] = v
			end
		end
	end
end

function chatbox.WriteConfig()
	if luadata then
		local data = {
			accent_color = chatbox.accent_color,
			back_color = chatbox.back_color,
			input_color = chatbox.input_color,
		}

		data = luadata.Encode(data)
		file.Write(CONFIG_FILE, data)
	end

	local x, y, w, h = chatbox.frame:GetBounds()
	chatbox.frame:SetCookie("x", x)
	chatbox.frame:SetCookie("y", y)
	chatbox.frame:SetCookie("w", w)
	chatbox.frame:SetCookie("h", h)
end

function chatbox.IsOpen()
	return IsValid(chatbox.frame) and chatbox.frame:IsVisible()
end

-- Link code is from qchat/EPOE.
local function CheckFor(tbl, a, b)
	local a_len = #a
	local res, endpos = true, 1

	while res and endpos < a_len do
		res, endpos = a:find(b, endpos)

		if res then
			tbl[#tbl + 1] = {res, endpos}
		end
	end
end

local function AppendTextLink(a, callback)
	local result = {}

	CheckFor(result, a, "https?://[^%s%\"]+")
	CheckFor(result, a, "ftp://[^%s%\"]+")
	CheckFor(result, a, "steam://[^%s%\"]+")

	if #result == 0 then return false end

	table.sort(result, function(b, c) return b[1] < c[1] end)

	-- Fix overlaps
	local _l, _r
	for k, tbl in ipairs(result) do
		local l = tbl[1]

		if not _l then
			_l, _r = tbl[1], tbl[2]
			continue
		end

		if l < _r then table.remove(result, k) end

		_l, _r = tbl[1], tbl[2]
	end

	local function TEX(str) callback(false, str) end
	local function LNK(str) callback(true, str) end

	local offset = 1
	local right

	for _, tbl in ipairs(result) do
		local l, r = tbl[1], tbl[2]
		local link = a:sub(l, r)
		local left = a:sub(offset, l - 1)
		right = a:sub(r + 1, -1)
		offset = r + 1

		TEX(left)
		LNK(link)
	end

	TEX(right)

	return true
end

local function quick_parse(txt)
	return markup_quickParse(txt, chatexp.LastPlayer)
end

function chatbox.ParseInto(feed, ...)
	local tbl = {...}

	feed:InsertColorChange(120, 219, 87, 255)

	if #tbl == 1 and isstring(tbl[1]) then
		feed:AppendText(quick_parse(tbl[1]))
		feed:AppendText("\n")

		return
	end

	for i, v in next, tbl do
		if IsColor(v) or istable(v) then
			feed:InsertColorChange(v.r, v.g, v.b, 255)
		elseif isentity(v) then
			if v:IsPlayer() then
				local col = GAMEMODE:GetTeamColor(v)
				feed:InsertColorChange(col.r, col.g, col.b, 255)

				feed:AppendText(quick_parse(v:Nick()))
			else
				local name = (v.Name and isfunction(v.name) and v:Name()) or v.Name or v.PrintName or tostring(v)
				if v:EntIndex() == 0 then
					feed:InsertColorChange(106, 90, 205, 255)
					name = "Console"
				end

				feed:AppendText(quick_parse(name))
			end
		elseif v ~= nil then
			local function linkAppend(islink, text)
				if islink then
					feed:InsertClickableTextStart(text)
						feed:AppendText(text)
					feed:InsertClickableTextEnd()
				return end

				feed:AppendText(text)
			end

			local res = AppendTextLink(tostring(v), linkAppend)

			if not res then
				feed:AppendText(quick_parse(tostring(v)))
			end
		end
	end

	feed:AppendText("\n")
end

local tabHeight = 26
local function tab_paint(self, w, h)
	surface.SetFont(currentBoxFontName)
	local wText = surface.GetTextSize(self.Name)

	self:SetTall(tabHeight)
	self:SetWide(wText + tabHeight / 2 + 15)
	
	local w, h = self:GetSize()

	self.LerpAlpha = Lerp(RealFrameTime() * 10, self.LerpAlpha or 0, (self:IsHovered() or currentTab == self.Index) and 1 or 0)

	draw.RoundedBox(0, 0, 0, w, h, Color(10, 10, 10, 220))

	surface.SetAlphaMultiplier(self.LerpAlpha)
	draw.RoundedBox(0, 0, 0, w, h, Color(255, 255, 255, 5))
	surface.SetAlphaMultiplier(1)

	draw.RoundedBox(0, 0, h - 2, w, 2, Color(200, 200, 200, 230))

	surface.SetDrawColor(255,255,255)
	surface.SetMaterial(self.Icon)
	surface.DrawTexturedRect(5, h / 4, h / 2, h / 2)

	draw.SimpleText(self.Name, currentBoxFontName, h / 2 + 10, h / 2, Color(230, 230, 230), 0, 1)
end

local function input_type(enter, tab, all)
	return function(pan, key)
		local txt = pan:GetText():Trim()
		all(pan, txt)

		if key == KEY_ENTER then
			if txt ~= "" then
				pan:AddHistory(txt)
				pan:SetText("")

				pan.HistoryPos = 0
			end

			enter(pan, txt)
		end

		if key == KEY_TAB then
			tab(pan, txt)

			chatbox.mode = (chatbox.mode + 1) % #chatexp.Modes
			
			if chatbox.mode <= 0 then
				chatbox.mode = 1
			end
		end

		if key == KEY_UP then
			pan.HistoryPos = pan.HistoryPos - 1
			pan:UpdateFromHistory()
		end

		if key == KEY_DOWN then
			pan.HistoryPos = pan.HistoryPos + 1
			pan:UpdateFromHistory()
		end

		if key == KEY_ESCAPE then
			pan.HistoryPos = 0
			pan:UpdateFromHistory()
		end
	end
end

local function paint_back(pan, w, h, a)
	surface.SetDrawColor(a and chatbox.input_color or chatbox.back_color)
	surface.DrawRect(0, 0, w, h)
end

local function input_paint(pan, w, h)
	paint_back(pan, w, h, true)

	pan:DrawTextEntryText(chatbox.accent_color, pan:GetHighlightColor(), chatbox.accent_color)
end

local function feed_layout(pan)
	pan:SetFontInternal(currentFeedFontName)
	pan:SetUnderlineFont(currentFeedFontName)
	pan:SetFGColor(Color(0, 0, 0, 255))
end

function chatbox.GetModeString()
	return chat.ModeString[chatbox.mode] or chat.DefaultModeString
end

function chatbox.BuildTabChat(self, a)
	self.chat = vgui.Create("DPanel", self.tabs)
		function self.chat:Paint(w, h) end
		self.chat:Dock(FILL)
		self.chat.text_feed = vgui.Create("RichTextX", self.chat)
		self.chat.text_feed:Dock(FILL)
		self.chat.text_feed:DockMargin(0, 0, 0, 2)
		self.chat.text_feed.PerformLayout = feed_layout

		self.chat.input_base = vgui.Create("DPanel", self.chat)
			function self.chat.input_base:Paint(w, h) end
			self.chat.input_base:Dock(BOTTOM)

			self.chat.input = vgui.Create("DTextEntry", self.chat.input_base)
				self.chat.input:Dock(FILL)

				self.chat.input:SetHistoryEnabled(true)
				self.chat.input.HistoryPos = 0

				self.chat.input.OnKeyCodeTyped = input_type(
				function(pan, txt)
					if txt ~= "" then
						if chatexp and hook.Run("ChatShouldHandle", "chatexp", txt, chatbox.mode) ~= false then
							chatexp.Say(txt, chatbox.mode)
						elseif chitchat and chitchat.Say and hook.Run("ChatShouldHandle", "chitchat", txt, 1) ~= false then
							chitchat.Say(txt, 1)
						else
							LocalPlayer():ConCommand("say \"" .. txt .. "\"")
						end
					end

					chatbox.Close()
				end,
				function(pan, txt)
					local tab = hook.Run("OnChatTab", txt)

					if tab and isstring(tab) and tab ~= txt then
						pan:SetText(tab)
					end

					timer.Simple(0, function()
						pan:RequestFocus()
						pan:SetCaretPos(pan:GetText():len())
					end)
				end,
				function(pan, txt)
					hook.Run("ChatTextChanged", txt)
				end)

				self.chat.input.Paint = input_paint

				function self.chat.input:OnChange()
					hook.Run("ChatTextChanged", self:GetText() or "")
				end

				function self.chat.input.Think(pan) pan:SetFont(currentBoxFontName) end

			self.chat.mode = vgui.Create("DButton", self.chat.input_base)
				self.chat.mode:SetText("")
				self.chat.mode:Dock(LEFT)
				self.chat.mode:SetWide(48)

				function self.chat.mode.DoClick()
					self.chat.input.OnKeyCodeTyped(self.chat.input, KEY_TAB)
				end

				function self.chat.mode.Paint(pan)
					local text = chatbox.GetModeString()
					surface.SetFont(currentBoxFontName)
					local textW = surface.GetTextSize(text)
					pan:SetWide(textW + 16)

					local w, h = pan:GetSize()
					paint_back(pan, w, h, true)

					if pan:IsHovered() then
						draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 50))
					end

					draw.SimpleText(text, currentBoxFontName, w/2, h/2, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end

		a = self.tabs:AddSheet(chat.L"Chat", self.chat, "icon16/comments.png")

		function a.Tab.Think(pan) pan:SetFont(currentBoxFontName) end
	
	return self.chat
end

function chatbox.GetDMFeed(ply)
	if not chatexp or not IsValid(ply) then return end
	local sid = ply:AccountID()

	local self = chatbox.frame.direct_messages
	if not IsValid(self.tabs[sid]) then return end

	return self.tabs[sid].feed
end

local cache = {}
local function get_player(sid)
	if IsValid(cache[sid]) then return cache[sid] end

	for k, v in next, player.GetAll() do
		if v:AccountID() == sid then cache[sid] = v return v end
	end

	return NULL
end

local currentSelectedUser

function chatbox.AddDMTab(ply)
	if not IsValid(chatbox.frame) or not chatexp or not IsValid(ply) or ply == LocalPlayer() then return end
	local sid = ply:AccountID()

	local self = chatbox.frame.direct_messages
	if IsValid(self.tabs[sid]) then return end

	self.tabs[sid] = vgui.Create("DPanel", chatbox.frame.double)
	local tab = self.tabs[sid]

	function tab:Paint(w, h) end
	tab:Dock(FILL)

	tab.feed = vgui.Create("RichTextX", tab)
		tab.feed:Dock(FILL)
		tab.feed:DockMargin(0, 0, 0, 5)
		tab.feed.PerformLayout = feed_layout
		tab.feed:InsertColorChange(230, 230, 230, 255)
		tab.feed:AppendText("== Начало истории общения с ")
		local clr = team.GetColor(ply)
		tab.feed:InsertColorChange(clr.r or 230, clr.g or 230, clr.b or 230, 255)
		tab.feed:AppendText(ply:Name())
		tab.feed:InsertColorChange(230, 230, 230, 255)
		tab.feed:AppendText(" ==")

	tab.input_base = vgui.Create("DPanel", tab)
		function tab.input_base:Paint(w, h) end
		tab.input_base:Dock(BOTTOM)

		tab.input = vgui.Create("DTextEntry", tab.input_base)
			tab.input:Dock(FILL)

			tab.input:SetHistoryEnabled(true)
			tab.input.HistoryPos = 0

			tab.input.OnKeyCodeTyped = input_type(
			function(pan, txt)
				if txt ~= "" then
					if IsValid(get_player(sid)) then chatexp.DirectMessage(txt, get_player(sid)) else chatbox.ParseInto(tab.feed, "User is offline!") end
				else
					chatbox.Close()
				end
			end,
			function(pan, txt)
			end,
			function(pan, txt)
			end)

			tab.input.Paint = input_paint

			function tab.input.Think(pan) pan:SetFont(currentBoxFontName) end

	local a = self:AddLine("")
	a.AccountID = ply:AccountID()
	a.Player = ply
	a.HoverAlpha = 0
	a:SetCursor("hand")
	a.Paint = function(self, w, h)
		if self:IsHovered() then
			a.HoverAlpha = Lerp(RealFrameTime() * 16, a.HoverAlpha, 1)
		else
			a.HoverAlpha = Lerp(RealFrameTime() * 16, a.HoverAlpha, 0)
		end
	
		if currentSelectedUser == a.AccountID then
			draw.RoundedBox(0, 0, 0, w, h, Color(30, 150, 30))
		else
			surface.SetAlphaMultiplier(a.HoverAlpha)
			draw.RoundedBox(0, 0, 0, w, h, Color(30, 30, 30))
			surface.SetAlphaMultiplier(1)
		end
	
		if IsValid(ply) then
			draw.SimpleText(ply:Nick(), currentBoxFontName, 5, h / 2, color_white, 0, 1)
		end
	end

	function a.Think(pan)
		if IsValid(ply) then
			pan:SetText(ply:Nick())
		else
			a:Remove()
			self.tabs[a.AccountID] = nil
		end
	end
	
	tab:Hide()
end

function chatbox.BuildTabDMs(self, a)
	if not chatexp then return end
	self.double = vgui.Create("DPanel", self.tabs)
	self.double:Dock(FILL)
	self.double.Paint = function() end

	self.direct_messages = vgui.Create("DListView", self.double)
	self.direct_messages:SetMultiSelect(false)
	self.direct_messages:SetHideHeaders(true)
	self.direct_messages:AddColumn("")
	self.direct_messages:SetWidth(128)
	self.direct_messages:SetDataHeight(20)
	self.direct_messages:DockMargin(0, 0, 5, 0)
	self.direct_messages:Dock(LEFT)

	self.direct_messages.tabs = {}
	
	local nextCheck = -1
	local playersCount = table.Count(self.direct_messages.tabs)

	self.direct_messages.Paint = function(self, w, h)
		paint_back(pan, w, h, true)

		if nextCheck < CurTime() then
			nextCheck = CurTime() + 0.5
			playersCount = table.Count(self.tabs)
		end
		
		if playersCount <= 0 then
			draw.SimpleText("Нет игроков", currentBoxFontName, w / 2, h / 2, color_white, 1, 1)
		end
	end

	self.direct_messages.OnRowSelected = function(self, rowIndex, row)
		for key, value in pairs(self.tabs) do
			if row.AccountID == key then
				value:Show()
				
				currentSelectedUser = key
			elseif not IsValid(row.Player) then
				local tab = self.tabs[row.AccountID]
				if IsValid(tab) then
					tab:Remove()
					self.tabs[row.AccountID] = nil
				end

				value:Remove()
			else
				value:Hide()
			end
		end
	end

	for key, value in ipairs(player.GetAll()) do
		chatbox.AddDMTab(value)
	end

	a = self.tabs:AddSheet(chat.L"DMs", self.double, "icon16/group.png")

	function a.Tab.Think(pan)
		pan:SetFont(currentBoxFontName)
	end
	
	return self.double
end

hook.Add("NetworkEntityCreated", "xp_dm_create", function(ent)
	if not ent:IsPlayer()
		or ent == LocalPlayer() then
		return
	end

	chatbox.AddDMTab(ent)
end)

hook.Add("EntityRemoved", "xp_dm_remove", function(ent)
	if not ent:IsPlayer()
		or ent == LocalPlayer()
		or not IsValid(chatbox.frame) then
		return
	end

	local acID = ent:AccountID()
	local tab = chatbox.frame.tabs[acID]

	if not IsValid(tab) then
		return
	end
	
	tab:Remove()
	self.tabs[row.AccountID] = nil
end)

local function build_settings_from_table(self, tbl)
	for cat, i in next, tbl do
		local c_pan = vgui.Create("DLabel", self)
		c_pan:Dock(TOP)
		c_pan:DockMargin(0, 0, 3, 0)
		c_pan:SetText(cat)

		for item, data in next, i do
			local pan = vgui.Create("Panel", self)
			pan:Dock(TOP)
			pan:DockMargin(0, 8, 0, 8)
			pan:SizeToContents()

			if data.ty == "Number" then
				local tag = vgui.Create("DLabel", pan)
				tag:Dock(LEFT)
				tag:SetText(item)
				tag:SetContentAlignment(7)

				local slide = vgui.Create("DNumberScratch", pan)
				slide:Dock(FILL)
				slide:SetValue(data.get())
				slide:SetMin(data.min)
				slide:SetMax(data.max)

				slide.OnValueChanged = data.set
			elseif data.ty == "Color" then
				local tag = vgui.Create("DLabel", pan)
				tag:Dock(LEFT)
				tag:SetText(item)
				tag:SetContentAlignment(7)

				local color = vgui.Create("DColorMixer", pan)
				color:Dock(LEFT)
				color:SizeToContents()
				color:SetWidth(256)
				color:SetTall(128)
				pan:SetTall(128)

				color.ValueChanged = data.set
				
			elseif data.ty == "Bool" then
				local check = vgui.Create("DCheckBoxLabel", pan)
				check:Dock(FILL)
				check:SetChecked(data.get())
				check:SetText(item)
				-- check:SetConVar()
				-- check:SetValue()
				check:SizeToContents()

				check.OnChange = data.set
			end
		end
	end
end

function chatbox.BuildTabSettings(self, a)
	self.settings = vgui.Create("DScrollPanel", self.tabs)
		function self.settings:Paint(w, h) end
		self.settings:Dock(FILL)

		build_settings_from_table(self.settings, chatbox.settings)

		a = self.tabs:AddSheet("Settings", self.settings, "icon16/cog.png")

		function a.Tab.Think(pan) pan:SetFont(currentBoxFontName) end
	return self.settings
end

local matBlurScreen = Material("pp/blurscreen")

function chatbox.Build()
	if IsValid(chatbox.frame) then return end

	chatbox.frame = vgui.Create("DFrame")
	local self = chatbox.frame
		self:SetCookieName("qchat") -- Backwards/alt compatability

		local x = self:GetCookie("x", 20)
		local y = self:GetCookie("y", ScrH() - math.min(650, ScrH() - 350))
		local w = self:GetCookie("w", 600)
		local h = self:GetCookie("h", 350)

		self:SetPos(x, y)
		self:SetSize(w, h)

		self:SetTitle(GetHostName())
		self:SetIcon("icon16/application_xp_terminal.png")

		self:SetSizable(true)
		self:SetMinHeight(145)
		self:SetMinWidth(275)

		self:ShowCloseButton(false)

		function self.lblTitle.Think(pan) pan:SetFont(currentBoxFontName) end

		function self:PerformLayout()
			local titlePush = 0

			if IsValid(self.imgIcon) then
				self.imgIcon:SetPos(5, 5)
				self.imgIcon:SetSize(16, 16)
				titlePush = 18
			end

			self.btnClose:SetPos(0,0)
			self.btnClose:SetSize(0,0)

			self.btnMaxim:SetPos(0,0)
			self.btnMaxim:SetSize(0,0)

			self.btnMinim:SetPos(self:GetWide() - 31 - 4, 4)
			self.btnMinim:SetSize(32, 18)

			self.lblTitle:SetPos(10 + titlePush, 3)
			self.lblTitle:SetSize(self:GetWide() - 25 - titlePush, 20)
			self.lblTitle:SetColor(chatbox.accent_color)
		end

		function self:Paint(w, h)
			surface.SetMaterial( matBlurScreen )
			surface.SetDrawColor( 255, 255, 255, 255 )

			local x, y = self:LocalToScreen( 0, 0 )
			for i = 0.33, 1, 0.33 do
				matBlurScreen:SetFloat( "$blur", 2 * i )
				matBlurScreen:Recompute()
				render.UpdateScreenEffectTexture()
				surface.DrawTexturedRect( -x, -y, ScrW(), ScrH() )
			end

			surface.SetDrawColor(chatbox.back_color)
			surface.DrawRect(0, 0, w, 25)

			surface.SetDrawColor(chatbox.back_color)
			surface.DrawRect(0, 0, w, h)
		end


	local panels = {}
	local buttons = {}

	self.tabsButtons = vgui.Create("DPanel", self)
	function self.tabsButtons:Paint(w, h) end
	self.tabsButtons:Dock(TOP)
	self.tabsButtons:DockMargin(0, 0, 0, 2)
	self.tabsButtons:SetTall(tabHeight)

	self.tabs = vgui.Create("DPanel", self)
	self.tabs.SwitchToName = function(self, name)
		for key, p in pairs(buttons) do
			if name == p.Name then
				p.Frame:Show()
			else
				p.Frame:Hide()
			end
		end
	end

	self.tabs.AddSheet = function(_, buttonName, panel, icon)
		local buttonIndex = #buttons + 1
		local but = self.tabsButtons:Add("DButton")
		but:Dock(LEFT)
		but:DockMargin(0, 0, 5, 0)
		but:SetText("")
		but.Tab = but
		but.Frame = panel
		but.Name = buttonName
		but.Index = buttonIndex
		but.Paint = tab_paint
		but.Icon = Material(icon)
		but.DoClick = function()
			for key, p in pairs(panels) do
				if key == buttonIndex then
					p:Show()
					currentTab = buttonIndex
				else
					p:Hide()
				end
			end
		end
		
		table.insert(buttons, but)

		return but
	end

	function self.tabs:Paint(w, h) end
	self.tabs:Dock(FILL)

	table.insert(panels, chatbox.BuildTabChat(self, a))
	table.insert(panels, chatbox.BuildTabDMs(self, a))
	table.insert(panels, chatbox.BuildTabSettings(self, a))
	
	chatbox.Close(true)
end

function chatbox.GetChatFeed()
	return chatbox.frame.chat.text_feed
end

function chatbox.GetChatInput()
	return chatbox.frame.chat.input
end

function chatbox.GiveChatFocus()
	if not chatbox.IsOpen() then return end

	chatbox.frame.tabs:SwitchToName(chat.L"Chat")
	chatbox.frame.chat.input:RequestFocus()
end

function chatbox.Close(no_hook)
	chatbox.WriteConfig()
	chatbox.GetChatInput():SetText("")
	chatbox.frame:SetVisible(false)

	if IsValid(chatbox.frame.dmSelector) then
		chatbox.frame.dmSelector:Remove()
	end

	if not no_hook then hook.Run("FinishChat") end
end

function chatbox.Open(t)
	chatbox.Build()
	chatbox.mode = chatbox.mode or CHATMODE_DEFAULT
	-- Сделать настройку, чтобы можно было ебашить при открывании чат по-умолчанию.
	-- chatbox.mode = CHATMODE_DEFAULT

	chatbox.frame:SetTitle(GetHostName())
	chatbox.frame:SetVisible(true)
	chatbox.frame:MakePopup()

	chatbox.GiveChatFocus()

	hook.Run("StartChat", t)
	hook.Run("ChatTextChanged", "")
end

return chatbox
