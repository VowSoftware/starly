--------------------------------------------------------------------------------
-- Header
--------------------------------------------------------------------------------

-- GitHub: https://github.com/VowSoftware/starly

local m_starly = {}

--------------------------------------------------------------------------------
-- Local Constants
--------------------------------------------------------------------------------

local c_behavior_center = hash("center")
local c_behavior_expand = hash("expand")
local c_behavior_stretch = hash("stretch")

--------------------------------------------------------------------------------
-- Module Constants
--------------------------------------------------------------------------------

m_starly.c_display_width = sys.get_config_int("display.width")
m_starly.c_display_height = sys.get_config_int("display.height")

--------------------------------------------------------------------------------
-- Local Functions
--------------------------------------------------------------------------------

local function get_static_viewport(id)
	local window_width, window_height = window.get_size()
	local window_scale_x, window_scale_y = window_width / m_starly.c_display_width, window_height / m_starly.c_display_height
	return m_starly[id].viewport_x * window_scale_x, m_starly[id].viewport_y * window_scale_y, m_starly[id].viewport_width * window_scale_x, m_starly[id].viewport_height * window_scale_y
end

local function get_dynamic_viewport(id)
	local window_width, window_height = window.get_size()
	local window_scale_x, window_scale_y = window_width / m_starly.c_display_width, window_height / m_starly.c_display_height
	if window_scale_x < window_scale_y then
		local margin = (window_scale_y - window_scale_x) * window_height * 0.5
		return m_starly[id].viewport_x * window_scale_x, m_starly[id].viewport_y * window_scale_y + margin, m_starly[id].viewport_width * window_scale_x, m_starly[id].viewport_height * window_scale_y - margin * 2
	end
	if window_scale_y < window_scale_x then
		local margin = (window_scale_x - window_scale_y) * window_width * 0.5
		return m_starly[id].viewport_x * window_scale_x + margin, m_starly[id].viewport_y * window_scale_y, m_starly[id].viewport_width * window_scale_x - margin * 2, m_starly[id].viewport_height * window_scale_y
	end
	return m_starly[id].viewport_x * window_scale_x, m_starly[id].viewport_y * window_scale_y, m_starly[id].viewport_width * window_scale_x, m_starly[id].viewport_height * window_scale_y
end

local function get_viewport(id)
	if m_starly[id].behavior == c_behavior_center then
		return get_dynamic_viewport(id)
	elseif m_starly[id].behavior == c_behavior_expand then
		return get_static_viewport(id)
	elseif m_starly[id].behavior == c_behavior_stretch then
		return get_static_viewport(id)
	end
end

local function get_view(id)
	local camera_url = msg.url(m_starly[id].socket, id, "camera")
	return camera.get_view(camera_url)
end

local function get_center_projection(id)
	local left = -m_starly.c_display_width * 0.5 / m_starly[id].zoom
	local right = m_starly.c_display_width * 0.5 / m_starly[id].zoom
	local bottom = -m_starly.c_display_height * 0.5 / m_starly[id].zoom
	local top = m_starly.c_display_height * 0.5 / m_starly[id].zoom
	return vmath.matrix4_orthographic(left, right, bottom, top, m_starly[id].near, m_starly[id].far)
end

local function get_expand_projection(id)
	local window_width, window_height = window.get_size()
	local left = -window_width * 0.5 / m_starly[id].zoom
	local right = window_width * 0.5 / m_starly[id].zoom
	local bottom = -window_height * 0.5 / m_starly[id].zoom
	local top = window_height * 0.5 / m_starly[id].zoom
	return vmath.matrix4_orthographic(left, right, bottom, top, m_starly[id].near, m_starly[id].far)
end

local function get_stretch_projection(id)
	local left = -m_starly.c_display_width * 0.5 / m_starly[id].zoom
	local right = m_starly.c_display_width * 0.5 / m_starly[id].zoom
	local bottom = -m_starly.c_display_height * 0.5 / m_starly[id].zoom
	local top = m_starly.c_display_height * 0.5 / m_starly[id].zoom
	return vmath.matrix4_orthographic(left, right, bottom, top, m_starly[id].near, m_starly[id].far)
end

local function get_projection(id)
	if m_starly[id].behavior == c_behavior_center then
		return get_center_projection(id)
	elseif m_starly[id].behavior == c_behavior_expand then
		return get_expand_projection(id)
	elseif m_starly[id].behavior == c_behavior_stretch then
		return get_stretch_projection(id)
	end
end

local function check_clip_space(clip_x, clip_y)
	return -1 <= clip_x and clip_x <= 1 and -1 <= clip_y and clip_y <= 1
end

local function shake(id, count, duration, radius, duration_scalar, radius_scalar, shake_count)
	local random = os.clock() * 1000
	local radius_position = m_starly[id].shake_position + vmath.vector3(math.cos(random), math.sin(random), 0) * radius
	go.animate(id, "position", go.PLAYBACK_ONCE_PINGPONG, radius_position, go.EASING_LINEAR, duration, 0, function()
		duration = duration * duration_scalar
		radius = radius * radius_scalar
		shake_count = shake_count + 1
		if shake_count < count then
			shake(id, count, duration, radius, duration_scalar, radius_scalar, shake_count)
		else
			m_starly[id].shake_position = nil
		end
	end)
end

--------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------

function m_starly.create(id)
	local script_url = msg.url(nil, id, "script")
	m_starly[id] =
	{
		socket = script_url.socket,
		behavior = go.get(script_url, "behavior"),
		viewport_x = go.get(script_url, "viewport_x"),
		viewport_y = go.get(script_url, "viewport_y"),
		viewport_width = go.get(script_url, "viewport_width"),
		viewport_height = go.get(script_url, "viewport_height"),
		near = go.get(script_url, "near"),
		far = go.get(script_url, "far"),
		zoom = go.get(script_url, "zoom"),
		shake_position = nil
	}
end

function m_starly.destroy(id)
	m_starly[id] = nil
end

function m_starly.activate(id)
	local viewport_x, viewport_y, viewport_width, viewport_height = get_viewport(id)
	local view = get_view(id)
	local projection = get_projection(id)
	render.set_viewport(viewport_x, viewport_y, viewport_width, viewport_height)
	render.set_view(view)
	render.set_projection(projection)
end

function m_starly.move(id, offset)
	local position = go.get_position(id) + offset / m_starly[id].zoom
	go.set_position(position, id)
end

function m_starly.shake(id, count, duration, radius, duration_scalar, radius_scalar)
	if m_starly[id].shake_position then
		m_starly.cancel_shake(id)
	end
	m_starly[id].shake_position = go.get_position(id)
	duration_scalar = duration_scalar and duration_scalar or 1
	radius_scalar = radius_scalar and radius_scalar or 1
	shake(id, count, duration, radius, duration_scalar, radius_scalar, 0)
end

function m_starly.cancel_shake(id)
	if not m_starly[id].shake_position then return end
	go.cancel_animations(id, "position")
	go.set_position(m_starly[id].shake_position, id)
	m_starly[id].shake_position = nil
end

function m_starly.is_shaking(id)
	return m_starly[id].shake_position and true or false
end

function m_starly.get_world_area(id)
	local _, _, viewport_width, viewport_height = get_viewport(id)
	local world_position = go.get_position(id)
	local area_x = world_position.x - viewport_width * 0.5 / m_starly[id].zoom
	local area_y = world_position.y - viewport_height * 0.5 / m_starly[id].zoom
	local area_width = viewport_width / m_starly[id].zoom
	local area_height = viewport_height / m_starly[id].zoom
	return area_x, area_y, area_width, area_height
end

function m_starly.screen_to_world(id, screen_x, screen_y, visible)
	local viewport_x, viewport_y, viewport_width, viewport_height = get_viewport(id)
	local inverse_frustum = vmath.inv(get_projection(id) * get_view(id))
	local clip_x = (screen_x - viewport_x) / viewport_width * 2 - 1
	local clip_y = (screen_y - viewport_y) / viewport_height * 2 - 1
	if visible and not check_clip_space(clip_x, clip_y) then return end
	local world_position = inverse_frustum * vmath.vector4(clip_x, clip_y, 0, 1)
	return vmath.vector3(world_position.x, world_position.y, 0)
end

function m_starly.world_to_screen(id, world_position, visible)
	local _, _, viewport_width, viewport_height = get_viewport(id)
	local frustum = get_projection(id) * get_view(id)
	local clip_position = frustum * vmath.vector4(world_position.x, world_position.y, 0, 1)
	if visible and not check_clip_space(clip_position.x, clip_position.y) then return end
	local screen_x = (clip_position.x + 1) * 0.5 * viewport_width
	local screen_y = (clip_position.y + 1) * 0.5 * viewport_height
	return screen_x, screen_y
end

return m_starly