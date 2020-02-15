if not rawget(_G, "BetterDelayedCalls") then
	rawset(_G, "BetterDelayedCalls", {})
	BetterDelayedCalls._calls = {}

	function BetterDelayedCalls:Update(time, deltaTime)
		local t = {}
		for key, v in pairs( self._calls ) do
			if v ~= nil then
				v.currentTime = v.currentTime + deltaTime
				if v.currentTime >= v.timeToWait then

					if v.functionCall then
						v.functionCall()
					end

					if v.loop then
						if self._calls[key] then
							v.currentTime = 0
							table.insert(t, v)
						end
					else
						v = nil
					end
				else
					table.insert(t, v)
				end
			end
		end
		self._calls = t
	end

	function BetterDelayedCalls:Add(id, time, func, sloop)
		local queuedFunc = {
			functionCall = func,
			timeToWait = time,
			currentTime = 0,
			loop = (sloop or false)
		}
		self._calls[id] = queuedFunc
	end

	function BetterDelayedCalls:Remove( id )
		self._calls[id] = nil
	end

	if RequiredScript == "lib/managers/menumanager" then
		local __orig = MenuManager.update
		function MenuManager:update(t, dt)
			__orig(self, t, dt)
			BetterDelayedCalls:Update(t, dt)
		end
	end
end