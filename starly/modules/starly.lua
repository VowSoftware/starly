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

local function check_clip_space(clip_x, clip_y)
	return -1 <= clip_x and clip_x <= 1 and -1 <= clip_y and clip_y <= 1
end

local function get_boundary_offset(id)
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
	return offset
end

-- Scales the viewport relative to the window size, but doesn't change the viewport's x and y coordinates.
local function get_static_viewport(id)
	local camera = m_starly[id]
	local window_width, window_height = window.get_size()
	local window_scale_x, window_scale_y = window_width / m_starly.c_display_width, window_height / m_starly.c_display_height
	return camera.viewport_x * window_scale_x, camera.viewport_y * window_scale_y, camera.viewport_width * window_scale_x, camera.viewport_height * window_scale_y
end

-- Scales the viewport relative to the window size, and changes the viewport's x and y coordinates to avoid distortion.
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

--------------------------------------------------------------------------------
-- Module Functions
--------------------------------------------------------------------------------

function m_starly.create(id)
	local script_url = msg.url(nil, id, "script")
	m_starly[id] =
	{
		script_url = msg.url(nil, id, "script"),
		behavior = go.get(script_url, "behavior"),
		viewport_x = go.get(script_url, "viewport_x"),
		viewport_y = go.get(script_url, "viewport_y"),
		viewport_width = go.get(script_url, "viewport_width"),
		viewport_height = go.get(script_url, "viewport_height"),
		adjusted_viewport_x = go.get(script_url, "viewport_x"),
		adjusted_viewport_y = go.get(script_url, "viewport_y"),
		adjusted_viewport_width = go.get(script_url, "viewport_width"),
		adjusted_viewport_height = go.get(script_url, "viewport_height"),
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
		view = vmath.matrix4(),
		projection = vmath.matrix4(),
		frustum = vmath.matrix4(),
		inverse_frustum = vmath.matrix4(),
		shake_position = nil
	}
end

function m_starly.destroy(id)
	m_starly[id] = nil
end

function m_starly.update(id)
	local camera = m_starly[id]
	camera.view = get_view(id)
	if camera.behavior == c_behavior_center then
		camera.adjusted_viewport_x, camera.adjusted_viewport_y, camera.adjusted_viewport_width, camera.adjusted_viewport_height = get_dynamic_viewport(id)
		camera.projection = get_center_projection(id)
	elseif camera.behavior == c_behavior_expand then
		camera.adjusted_viewport_x, camera.adjusted_viewport_y, camera.adjusted_viewport_width, camera.adjusted_viewport_height = get_static_viewport(id)
		camera.projection = get_expand_projection(id)
	elseif camera.behavior == c_behavior_stretch then
		camera.adjusted_viewport_x, camera.adjusted_viewport_y, camera.adjusted_viewport_width, camera.adjusted_viewport_height = get_static_viewport(id)
		camera.projection = get_stretch_projection(id)
	end
	camera.frustum = camera.projection * camera.view
	camera.inverse_frustum = vmath.inv(camera.frustum)
end

function m_starly.activate(id)
	local camera = m_starly[id]
	render.set_viewport(camera.adjusted_viewport_x, camera.adjusted_viewport_y, camera.adjusted_viewport_width, camera.adjusted_viewport_height)
	render.set_view(camera.view)
	render.set_projection(camera.projection)
end

function m_starly.set_position(id, position)
	local camera = m_starly[id]
	go.set_position(position, id)
	if camera.boundary then
		local offset = get_boundary_offset(id)
		go.set_position(position + offset, id)
	end
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
	local screen_x = camera.adjusted_viewport_x
	local screen_y = camera.adjusted_viewport_y
	local screen_width = camera.adjusted_viewport_x + camera.adjusted_viewport_width
	local screen_height = camera.adjusted_viewport_x + camera.adjusted_viewport_height
	local world_position_bottom_left = m_starly.get_world_position(id, screen_x, screen_y)
	local world_position_top_right = m_starly.get_world_position(id, screen_width, screen_height)
	local world_size = world_position_top_right - world_position_bottom_left
	return world_position_bottom_left.x, world_position_bottom_left.y, world_size.x, world_size.y
end

function m_starly.get_world_position(id, screen_x, screen_y, visible)
	local camera = m_starly[id]
	local clip_x = (screen_x - camera.adjusted_viewport_x) / camera.adjusted_viewport_width * 2 - 1
	local clip_y = (screen_y - camera.adjusted_viewport_y) / camera.adjusted_viewport_height * 2 - 1
	if visible and not check_clip_space(clip_x, clip_y) then return end
	local world_position = camera.inverse_frustum * vmath.vector4(clip_x, clip_y, 0, 1)
	return vmath.vector3(world_position.x, world_position.y, 0)
end

function m_starly.get_screen_position(id, world_position, visible)
	local camera = m_starly[id]
	local clip_position = camera.frustum * vmath.vector4(world_position.x, world_position.y, 0, 1)
	if visible and not check_clip_space(clip_position.x, clip_position.y) then return end
	local screen_x = (clip_position.x + 1) * 0.5 * camera.adjusted_viewport_width
	local screen_y = (clip_position.y + 1) * 0.5 * camera.adjusted_viewport_height
	return screen_x, screen_y
end

return m_starly