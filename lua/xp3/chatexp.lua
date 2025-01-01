AddCSLuaFile()

local col = Color(200, 0, 255, 255)
local Msg = function(...) MsgC(col, ...)  end

chatexp = chatexp or {}
chatexp.NetTag = "chatexp" -- Do not change this unless you experience some very strange issues
chatexp.AbuseMode = "Kick" -- Kick or EarRape, this is what happens to people who try and epxloit the system

-- This is basicly chitchat3
-- Max message length is now 0x80000000 (10^31)
-- Filters are fixed, better mode handling.

local color_red = Color(225, 0, 0, 255)
local color_greentext = Color(0, 240, 0, 255)
local color_green = Color(0, 200, 0, 255)
local color_hint = Color(240, 220, 180, 255)

function net.HasOverflowed()
	return (net.BytesWritten() or 0) >= 65536
end

function net.WriteCompressedString(str)
	local c_str = util.Compress(str)
	
	if c_str and #c_str < #str then
		net.WriteBool(true)
		net.WriteUInt(#c_str, 16)
		net.WriteData(c_str, #c_str)
	else
		net.WriteBool(false)
		net.WriteString(str)
	end
end

function net.ReadCompressedString()
	local isCompressed = net.ReadBool()

	return isCompressed
		and util.Decompress(net.ReadData(net.ReadUInt(16)), 1024)
		or net.ReadString()
		or ""
end

chatexp.Modes = {
	{
			Name = "Default",
			Filter = function(send, ply)
				return true
			end,
			Handle = function(tbl, ply, msg, dead, mode_data)
				if dead then
					tbl[#tbl + 1] = color_red
					tbl[#tbl + 1] = "*DEAD* "
				end

				tbl[#tbl + 1] = ply -- ChatHUD parses this automaticly
				tbl[#tbl + 1] = color_white
				tbl[#tbl + 1] = ": "
				tbl[#tbl + 1] = color_white

				if msg:StartWith(">") and #msg > 1 then
					tbl[#tbl + 1] = color_greentext
				end

				tbl[#tbl + 1] = msg
			end,
	},

	{
			Name = "Local",
			Filter = function(send, ply)
				return send:GetPos():DistToSqr(ply:GetPos()) < 256*256
			end,
			Handle = function(tbl, ply, msg, dead, mode_data)
				if dead then
					tbl[#tbl + 1] = color_red
					tbl[#tbl + 1] = "*DEAD* "
				end

				tbl[#tbl + 1] = Color(125, 110, 255)
				tbl[#tbl + 1] = "(" .. chat.L"Local" .. ") "

				tbl[#tbl + 1] = ply -- ChatHUD parses this automaticly
				tbl[#tbl + 1] = color_white
				tbl[#tbl + 1] = ": "
				tbl[#tbl + 1] = color_white

				if msg:StartWith(">") and #msg > 1 then
					tbl[#tbl + 1] = color_greentext
				end

				tbl[#tbl + 1] = msg
			end,
	},

	{
			Name = "DM",
			-- No Filter.
			Handle = function(tbl, ply, msg, dead, mode_data)
				if ply == LocalPlayer() then
					tbl[#tbl + 1] = color_hint
					tbl[#tbl + 1] = chat.L"You"
					tbl[#tbl + 1] = color_white
					tbl[#tbl + 1] = " -> "
					tbl[#tbl + 1] = Player(mode_data)

					hook.Run("SendDM", Player(mode_data), msg)
				else
					tbl[#tbl + 1] = ply
					tbl[#tbl + 1] = color_white
					tbl[#tbl + 1] = " -> "
					tbl[#tbl + 1] = color_hint
					tbl[#tbl + 1] = chat.L"You"

					hook.Run("ReceiveDM", ply, msg)
				end

				tbl[#tbl + 1] = color_white
				tbl[#tbl + 1] = ": "

				tbl[#tbl + 1] = color_white
				tbl[#tbl + 1] = msg
			end,
	},
}

for k, v in next, chatexp.Modes do
	_G["CHATMODE_"..v.Name:upper()] = k
end

if CLIENT then
	function chatexp.Say(msg, mode, mode_data)
		net.Start(chatexp.NetTag)
			net.WriteCompressedString(msg)

			net.WriteUInt(mode, 8)
			net.WriteUInt(mode_data or 0, 16)
		net.SendToServer()
	end

	function chatexp.SayChannel(msg, channel)
		chatexp.Say(msg, CHATMODE_CHANNEL, channel)
	end

	function chatexp.DirectMessage(msg, ply)
		chatexp.Say(msg, CHATMODE_DM, ply:UserID())
	end

	net.Receive(chatexp.NetTag, function()
		local ply 	= net.ReadEntity()
		local data = net.ReadCompressedString()
		local mode 	= net.ReadUInt(8)
		local mode_data = net.ReadUInt(16)

		local dead = ply:IsValid() and ply:IsPlayer() and not ply:Alive()
		hook.Run("OnPlayerChat", ply, data, mode, dead, mode_data)
	end)

else -- SERVER

	util.AddNetworkString(chatexp.NetTag)

	local print = _print or print

	function chatexp.SayAs(ply, data, mode, mode_data)
		if #data > 1024 then
			Msg"CEXP " print"Too much data!"
			return
		end

		local ret = hook.Run("PlayerSay", ply, data, mode)

		if ret == "" or ret == false then return end
		if isstring(ret) then data = ret end

		local msgmode = chatexp.Modes[mode]

		local filter = {}
		if mode == CHATMODE_DM then
			local plSend = Player(mode_data)
			
			if plSend == ply then
				return
			end

			filter = {plSend}
		elseif msgmode.Filter then
			for k, v in next,player.GetHumans() do
				if msgmode.Filter(ply, v) ~= false then filter[#filter+1] = v end
			end
		else
			filter = player.GetHumans()
		end

		if #filter == 0 then return end
		if not table.HasValue(filter, ply) then filter[#filter+1] = ply end

		net.Start(chatexp.NetTag)
			net.WriteEntity(ply)

			net.WriteCompressedString(data)

			net.WriteUInt(mode, 8)
			net.WriteUInt(mode_data, 16)

			if net.HasOverflowed() then
				Msg"CEXP " print("Net overflow -> '" .. data .. "'")
				return
			end
		net.Send(filter)
	end

	net.Receive(chatexp.NetTag, function(_, ply)
		local data = net.ReadCompressedString()

		local mode	= net.ReadUInt(8)
		local mode_data = net.ReadUInt(16)

		chatexp.SayAs(ply, data, mode, mode_data)
	end)

end -- SERVER
