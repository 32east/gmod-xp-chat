if SERVER then return end

local Mcche = {}
local function MaterialCache(a, b)
	a = a:lower()
	if Mcche[a] then return Mcche[a] end
	local m = Material(a, b)
	Mcche[a] = m
	return m
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
	["texture"] = {
		args = {
			[1] = {type = "string", default = "error"},
			[2] = {type = "number", min = 8, max = 32, default = 16},
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
	},
	["se"] = {
		args = {
			[1] = {type = "string", default = "error"},
			[2] = {type = "number", min = 8, max = 32, default = 22},
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
--	["font"] = {
--		args = {
--			[1] = {type = "string", default = "DermaDefault"}, -- fontname
--		},
--		TagStart = function(self, markup, buffer, args)
--			self._font = buffer.font
--		end,
--		ModifyBuffer = function(self, markup, buffer, args)
--			buffer.font = args[1]
--		end,
--		TagEnd = function(self, markup, buffer, args)
--			buffer.font = self._font or "chathud_18"
--		end,
--	},
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
