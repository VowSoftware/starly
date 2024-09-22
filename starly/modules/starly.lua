--------------------------------------------------------------------------------
-- Header
--------------------------------------------------------------------------------

-- GitHub: https://github.com/VowSoftware/starly

--------------------------------------------------------------------------------

local m_starly = {}

--------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------

function m_starly.shake(id, count, duration, radius, duration_scalar, radius_scalar)
	duration_scalar = duration_scalar and duration_scalar or 1
	radius_scalar = radius_scalar and radius_scalar or 1
	m_starly[id].shake_position = go.get_position(id)
	local total_count = 0
	local function shake()
		local random = math.random() * math.pi * 2
		local radius_position = m_starly[id].shake_position + vmath.vector3(math.cos(random), math.sin(random), 0) * radius
		go.animate(id, "position", go.PLAYBACK_ONCE_PINGPONG, radius_position, go.EASING_LINEAR, duration, 0, function()
			duration = duration * duration_scalar
			radius = radius * radius_scalar
			total_count = total_count + 1
			if total_count < count then
				shake()
			end
		end)
	end
	shake()
end

function m_starly.cancel_shake(id)
	go.cancel_animations(id, "position")
	go.set_position(m_starly[id].shake_position, id)
	m_starly[id].shake_position = nil
end

return m_starly