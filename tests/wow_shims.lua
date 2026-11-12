--[[
	Minimal WoW API shims so that addon files can be loaded and exercised by a
	plain Lua 5.1 interpreter (lua5.1.exe) for automated testing.

	Usage (from any test script):
		local shims = dofile(root .. "/tests/wow_shims.lua")(root)
		shims.LoadAddonFile("TSP.lua")
		local TSP = shims.Routes.TSP

	Only what the tested files need is stubbed; add to it as tests grow.
]]

return function(root)
	local shims = { root = root }

	---------------------------------------------------------------------
	-- Library extensions WoW adds to the standard Lua libraries.
	-- These must exist before they are aliased to globals below.
	function table.wipe(t)
		for k in pairs(t) do
			t[k] = nil
		end
		return t
	end

	function string.trim(s, chars)
		if chars then
			local set = "[" .. chars:gsub("[%]%^%-%%]", "%%%0") .. "]*"
			return (s:gsub("^" .. set, ""):gsub(set .. "$", ""))
		end
		return (s:gsub("^%s+", ""):gsub("%s+$", ""))
	end

	function string.split(delims, s, pieces)
		local out, n, start = {}, 0, 1
		local set = "[" .. delims:gsub("[%]%^%-%%]", "%%%0") .. "]"
		while true do
			if pieces and n + 1 >= pieces then break end
			local pos = s:find(set, start)
			if not pos then break end
			n = n + 1
			out[n] = s:sub(start, pos - 1)
			start = pos + 1
		end
		out[n + 1] = s:sub(start)
		return unpack(out, 1, n + 1)
	end

	function string.join(delim, ...)
		return table.concat({ ... }, delim)
	end

	-- The global aliases WoW provides for the functions of the standard
	-- libraries. Its trigonometric functions work with degrees.
	tinsert, tremove, wipe, sort = table.insert, table.remove, table.wipe, table.sort
	foreach, foreachi, getn = table.foreach, table.foreachi, table.getn
	abs, ceil, floor, max, min = math.abs, math.ceil, math.floor, math.max, math.min
	sqrt, exp, log, log10, frexp, ldexp = math.sqrt, math.exp, math.log, math.log10, math.frexp, math.ldexp
	mod, deg, rad, PI = math.fmod, math.deg, math.rad, math.pi
	sin = function(x) return math.sin(math.rad(x)) end
	cos = function(x) return math.cos(math.rad(x)) end
	tan = function(x) return math.tan(math.rad(x)) end
	asin = function(x) return math.deg(math.asin(x)) end
	acos = function(x) return math.deg(math.acos(x)) end
	atan = function(x) return math.deg(math.atan(x)) end
	atan2 = function(y, x) return math.deg(math.atan2(y, x)) end
	format, gsub, gmatch = string.format, string.gsub, string.gmatch
	strbyte, strchar, strfind, strlen, strlower = string.byte, string.char, string.find, string.len, string.lower
	strmatch, strrep, strrev, strsub, strupper = string.match, string.rep, string.reverse, string.sub, string.upper
	strtrim = string.trim

	-- Deterministic replacement for WoW's random() so that tests are
	-- reproducible on every machine: random() -> [0, 1), random(n) -> 1..n,
	-- random(a, b) -> a..b. Park-Miller minimal standard generator.
	local randomState = 1
	function shims.SeedRandom(seed)
		randomState = seed % 2147483646 + 1
	end
	function random(a, b)
		randomState = (randomState * 16807) % 2147483647
		local r = (randomState - 1) / 2147483646
		if not a then return r end
		if not b then return floor(r * a) + 1 end
		return a + floor(r * (b - a + 1))
	end

	strsplit = string.split
	strjoin = string.join
	tostringall = function(...)
		local t = { ... }
		for i = 1, select("#", ...) do t[i] = tostring(t[i]) end
		return unpack(t, 1, select("#", ...))
	end

	---------------------------------------------------------------------
	-- Timing
	local clock = os.clock
	local profileStart = clock()
	function debugprofilestop() -- milliseconds, high resolution
		return (clock() - profileStart) * 1000
	end
	function debugprofilestart()
		profileStart = clock()
	end
	function GetTime() -- seconds
		return clock()
	end

	---------------------------------------------------------------------
	-- Error handler
	local errorhandler = function(msg) error(msg, 2) end
	function geterrorhandler() return errorhandler end
	function seterrorhandler(f) errorhandler = f end

	---------------------------------------------------------------------
	-- Frames: just enough for OnUpdate driven background work.
	-- No catch-all __index on purpose, so that unset fields read as nil.
	local frames = {}
	shims.frames = frames

	local FrameMethods = {}
	function FrameMethods:SetScript(name, func) self.__scripts[name] = func end
	function FrameMethods:GetScript(name) return self.__scripts[name] end
	function FrameMethods:HookScript(name, func)
		local old = self.__scripts[name]
		self.__scripts[name] = old and function(...) old(...) return func(...) end or func
	end
	function FrameMethods:Show() self.__shown = true end
	function FrameMethods:Hide() self.__shown = false end
	function FrameMethods:IsShown() return self.__shown end
	function FrameMethods:RegisterEvent() end
	function FrameMethods:UnregisterEvent() end
	function FrameMethods:UnregisterAllEvents() end

	function CreateFrame(frameType, name, parent, template)
		local frame = { __scripts = {}, __shown = true, __type = frameType, __name = name }
		for k, v in pairs(FrameMethods) do frame[k] = v end
		frames[#frames + 1] = frame
		if name then _G[name] = frame end
		return frame
	end

	-- Simulates one rendered frame: runs every OnUpdate script once.
	-- Returns the number of OnUpdate scripts that ran.
	function shims.PumpFrame(elapsed)
		elapsed = elapsed or 1 / 60
		local ran = 0
		for i = 1, #frames do
			local frame = frames[i]
			local func = frame.__shown and frame.__scripts.OnUpdate
			if func then
				func(frame, elapsed)
				ran = ran + 1
			end
		end
		return ran
	end

	-- Pumps frames until isDone() returns true. Returns the number of frames
	-- it took, or nil if maxFrames was exceeded or nothing is running anymore.
	function shims.PumpUntil(isDone, maxFrames)
		for n = 1, maxFrames or 1e7 do
			if isDone() then return n - 1 end
			if shims.PumpFrame() == 0 then
				return isDone() and n or nil
			end
		end
		return isDone() and (maxFrames or 1e7) or nil
	end

	---------------------------------------------------------------------
	-- LibStub and the Routes addon object
	local libs = {}
	shims.libs = libs
	LibStub = setmetatable({
		GetLibrary = function(self, name, silent)
			local lib = libs[name]
			if not lib and not silent then
				error(("Cannot find a library instance of %q."):format(tostring(name)), 2)
			end
			return lib
		end,
		NewLibrary = function(self, name)
			libs[name] = libs[name] or {}
			return libs[name]
		end,
	}, { __call = function(self, name, silent) return self:GetLibrary(name, silent) end })

	-- Zone sizes in yards, registered by the tests per (fake) zone ID
	local zoneSizes = {}
	function shims.SetZoneSize(zoneID, width, height)
		zoneSizes[zoneID] = { width, height }
	end

	local printed = {}
	shims.printed = printed -- everything sent to Routes:Print()

	local Routes = {
		L = setmetatable({}, { __index = function(t, k) return k end }),
		Dragons = {
			GetZoneSize = function(self, zoneID)
				local size = zoneSizes[zoneID]
				if not size then
					error("test zone " .. tostring(zoneID) .. " has no size, call shims.SetZoneSize()", 2)
				end
				return size[1], size[2]
			end,
		},
		Print = function(self, ...)
			printed[#printed + 1] = table.concat({ tostringall(...) }, " ")
		end,
	}
	shims.Routes = Routes

	local addons = { Routes = Routes }
	libs["AceAddon-3.0"] = {
		GetAddon = function(self, name, silent)
			if not addons[name] and not silent then
				error(("Cannot find an AceAddon %q."):format(tostring(name)), 2)
			end
			return addons[name]
		end,
	}

	---------------------------------------------------------------------
	-- Loads a file of the addon the way the WoW client does: (addonName, ns)
	local namespace = {}
	function shims.LoadAddonFile(file)
		local f = assert(io.open(root .. "/" .. file, "rb"))
		local source = f:read("*a")
		f:close()
		source = source:gsub("^\239\187\191", "") -- WoW accepts an UTF-8 BOM, Lua does not
		local chunk = assert(loadstring(source, "@" .. file))
		return chunk("Routes", namespace)
	end

	return shims
end
