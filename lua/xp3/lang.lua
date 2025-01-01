AddCSLuaFile()

local CVar = GetConVar("gmod_language")
local l = {
	["ru"] = {
		["Chat"] = "Чат",
		["Team"] = "Команда",
		["Local"] = "Локальный",
		["DMs"] = "Личные сообщения",
		["New DM"] = "Открыть новый диалог",
		["You"] = "Ты",
		["Copy"] = "Скопировать",
		["Clear Chatlog"] = "Очистить чат",
		["Cancel"] = "Отмена",
	},
}

chat.L = function(str)
	local lang = CVar:GetString()
	local getTranslation = l[lang ]

	return getTranslation and getTranslation[str]
		or str
end