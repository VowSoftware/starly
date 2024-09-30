--------------------------------------------------------------------------------
-- Header
--------------------------------------------------------------------------------

-- GitHub: https://github.com/VowSoftware/starly

local m_starly = {}

--------------------------------------------------------------------------------
-- Local Constants
--------------------------------------------------------------------------------

-- Viewport and projection behaviors.
local c_behavior_center = hash("center")
local c_behavior_expand = hash("expand")
local c_behavior_stretch = hash("stretch")

--------------------------------------------------------------------------------
-- Module Constants
--------------------------------------------------------------------------------

-- Default window size, specified in *game.project*.
m_starly.c_display_width = sys.get_config_int("display.width")
m_starly.c_display_height = sys.get_config_int("display.height")

--------------------------------------------------------------------------------
-- Local Functions
--------------------------------------------------------------------------------

local function shake(id, count, duration, radius, duration_scalar, radius_scalar, shake_count)
	local camera = m_starly[id]
	local random = os.clock() * 1000
	local radius_position = camera.shake_position + vmath.vector3(math.cos(random), math.sin(random), 0) * radius
	go.animate(id, "position", go.PLAYBACK_ONCE_PINGPONG, radius_position, go.EASING_LINEAR, duration, 0, function()
		duration = duration * duration_scalar
		radius = radius * radius_scalar
		shake_count = shake_count + 1
		if shake_count < count then
			shake(id, count, duration, radius, duration_scalar, radius_scalar, shake_count)
		else
			camera.shake_position = nil
		end
	end)
end

local function get_static_viewport(id)
	local camera = m_starly[id]
	local window_width, window_height = window.get_size()
	local window_scale_x, window_scale_y = window_width / m_starly.c_display_width, window_height / m_starly.c_display_height
	return camera.viewport_x * window_scale_x, camera.viewport_y * window_scale_y, camera.viewport_width * window_scale_x, camera.viewport_height * window_scale_y
end

local function get_dynamic_viewport(id)
	local camera = m_starly[id]
	local window_width, window_height = window.get_size()
	local window_scale_x, window_scale_y = window_width / m_starly.c_display_width, window_height / m_starly.c_display_height
	if window_scale_x < window_scale_y then
		local margin = (window_scale_y - window_scale_x) * window_height * 0.5
		return camera.viewport_x * window_scale_x, camera.viewport_y * window_scale_y + margin, camera.viewport_width * window_scale_x, camera.viewport_height * window_scale_y - margin * 2
	end
	if window_scale_y < window_scale_x then
		local margin = (window_scale_x - window_scale_y) * window_width * 0.5
		return camera.viewport_x * window_scale_x + margin, camera.viewport_y * window_scale_y, camera.viewport_width * window_scale_x - margin * 2, camera.viewport_height * window_scale_y
	end
	return camera.viewport_x * window_scale_x, camera.viewport_y * window_scale_y, camera.viewport_width * window_scale_x, camera.viewport_height * window_scale_y
end

local function get_viewport(id)
	local camera = m_starly[id]
	if camera.behavior == c_behavior_center then
		return get_dynamic_viewport(id)
	elseif camera.behavior == c_behavior_expand then
		return get_static_viewport(id)
	elseif camera.behavior == c_behavior_stretch then
		return get_static_viewport(id)
	end
end

local function get_view(id)
	return vmath.inv(go.get_world_transform(id))
end

local function get_center_projection(id)
	local camera = m_starly[id]
	local left = -m_starly.c_display_width * 0.5 / camera.zoom
	local right = m_starly.c_display_width * 0.5 / camera.zoom
	local bottom = -m_starly.c_display_height * 0.5 / camera.zoom
	local top = m_starly.c_display_height * 0.5 / camera.zoom
	return vmath.matrix4_orthographic(left, right, bottom, top, camera.near, camera.far)
end

local function get_expand_projection(id)
	local camera = m_starly[id]
	local window_width, window_height = window.get_size()
	local left = -window_width * 0.5 / camera.zoom
	local right = window_width * 0.5 / camera.zoom
	local bottom = -window_height * 0.5 / camera.zoom
	local top = window_height * 0.5 / camera.zoom
	return vmath.matrix4_orthographic(left, right, bottom, top, camera.near, camera.far)
end

local function get_stretch_projection(id)
	local camera = m_starly[id]
	local left = -m_starly.c_display_width * 0.5 / camera.zoom
	local right = m_starly.c_display_width * 0.5 / camera.zoom
	local bottom = -m_starly.c_display_height * 0.5 / camera.zoom
	local top = m_starly.c_display_height * 0.5 / camera.zoom
	return vmath.matrix4_orthographic(left, right, bottom, top, camera.near, camera.far)
end

local function get_projection(id)
	local camera = m_starly[id]
	if camera.behavior == c_behavior_center then
		return get_center_projection(id)
	elseif camera.behavior == c_behavior_expand then
		return get_expand_projection(id)
	elseif camera.behavior == c_behavior_stretch then
		return get_stretch_projection(id)
	end
end

local function check_clip_space(clip_x, clip_y)
	return -1 <= clip_x and clip_x <= 1 and -1 <= clip_y and clip_y <= 1
end

local function validate_boundary(id)
	local camera = m_starly[id]
	local offset = vmath.vector3()
	local area_x, area_y, area_width, area_height = m_starly.get_world_area(id)
	if area_x < camera.boundary_x then
		offset.x = camera.boundary_x - area_x
	end
	if camera.boundary_x + camera.boundary_width < area_x + area_width then
		offset.x = (camera.boundary_x + camera.boundary_width) - (area_x + area_width)
	end
	if area_y < camera.boundary_y then
		offset.y = camera.boundary_y - area_y
	end
	if camera.boundary_y + camera.boundary_height < area_y + area_height then
		offset.y = (camera.boundary_y + camera.boundary_height) - (area_y + area_height)
	end
	m_starly.move(id, offset)
end

local function cache_properties(id)
	local camera = m_starly[id]
	camera.cache_viewport_x, camera.cache_viewport_y, camera.cache_viewport_width, camera.cache_viewport_height = get_viewport(id)
	camera.cache_view = get_view(id)
	camera.cache_projection = get_projection(id)
end

--------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------

function m_starly.create(id)
	local script_url = msg.url(nil, id, "script")
	m_starly[id] =
	{
		id = id,
		behavior = go.get(script_url, "behavior"),
		viewport_x = go.get(script_url, "viewport_x"),
		viewport_y = go.get(script_url, "viewport_y"),
		viewport_width = go.get(script_url, "viewport_width"),
		viewport_height = go.get(script_url, "viewport_height"),
		near = go.get(script_url, "near"),
		far = go.get(script_url, "far"),
		zoom = go.get(script_url, "zoom"),
		zoom_max = go.get(script_url, "zoom_max"),
		zoom_min = go.get(script_url, "zoom_min"),
		boundary = go.get(script_url, "boundary"),
		boundary_x = go.get(script_url, "boundary_x"),
		boundary_y = go.get(script_url, "boundary_y"),
		boundary_width = go.get(script_url, "boundary_width"),
		boundary_height = go.get(script_url, "boundary_height"),
		cache_viewport_x = nil,
		cache_viewport_y = nil,
		cache_viewport_width = nil,
		cache_viewport_height = nil,
		cache_view = nil,
		cache_projection = nil,
		shake_position = nil
	}
end

function m_starly.destroy(id)
	m_starly[id] = nil
end

function m_starly.late_update(id)
	local camera = m_starly[id]
	if camera.boundary then
		validate_boundary(id)
	end
	cache_properties(id)
end

function m_starly.activate(id)
	local camera = m_starly[id]
	render.set_viewport(camera.cache_viewport_x, camera.cache_viewport_y, camera.cache_viewport_width, camera.cache_viewport_height)
	render.set_view(camera.cache_view)
	render.set_projection(camera.cache_projection)
end

function m_starly.set_position(id, position)
	go.set_position(position, id)
end

function m_starly.move(id, offset)
	local camera = m_starly[id]
	local position = go.get_position(id) + offset / camera.zoom
	m_starly.set_position(id, position)
end

function m_starly.set_zoom(id, zoom)
	local camera = m_starly[id]
	if zoom < camera.zoom_min then
		camera.zoom = camera.zoom_min
	elseif zoom > camera.zoom_max then
		camera.zoom = camera.zoom_max
	else
		camera.zoom = zoom
	end
end

function m_starly.zoom(id, offset)
	local camera = m_starly[id]
	local zoom = camera.zoom + offset
	m_starly.set_zoom(id, zoom)
end

function m_starly.shake(id, count, duration, radius, duration_scalar, radius_scalar)
	local camera = m_starly[id]
	if camera.shake_position then
		m_starly.cancel_shake(id)
	end
	camera.shake_position = go.get_position(id)
	duration_scalar = duration_scalar and duration_scalar or 1
	radius_scalar = radius_scalar and radius_scalar or 1
	shake(id, count, duration, radius, duration_scalar, radius_scalar, 0)
end

function m_starly.cancel_shake(id)
	local camera = m_starly[id]
	if not camera.shake_position then return end
	go.cancel_animations(id, "position")
	go.set_position(camera.shake_position, id)
	camera.shake_position = nil
end

function m_starly.get_world_area(id)
	local camera = m_starly[id]
	local _, _, viewport_width, viewport_height = get_viewport(id)
	local world_position = go.get_position(id)
	local area_x = world_position.x - viewport_width * 0.5 / camera.zoom
	local area_y = world_position.y - viewport_height * 0.5 / camera.zoom
	local area_width = viewport_width / camera.zoom
	local area_height = viewport_height / camera.zoom
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