# Starly

Starly is a orthographic camera library for Defold.

Please click the ☆ button on GitHub if this repository is useful. Thank you!

![Starly](https://github.com/user-attachments/assets/8b586e24-b806-439e-b6bc-3124cb6ed68b)

## Discussion

Starly's goal is to provide a feature-rich orthographic camera solution, confined to a single Lua module, where all properties can be edited or animated at runtime.

Supporting 2D games allows Starly to implement interesting, creative, and proven utility functions, without the complexity and redundancy that comes with simultaneously supporting 3D games.

Other camera libraries guard certain properties with getter and setter functions to abstract management of internal variables. This causes confusion and frustration when trying to edit those properties at runtime, especially when dealing with animation. **Starly remedies this by allowing all properties to be edited or animated at runtime without getters and setters.**

The default render pipeline and all other camera libraries require you to include someone else's code inside your render script. For example, the default render script contains a subset of projection calculation functions, performs maintainence on camera properties each frame, and captures messages in its `on_message()` function that are required to properly update cameras. Other camera libraries suffer from similar requirements. It's rare that a render script doesn't need to be heavily edited, which results in an irritating copy-paste-edit workflow for render scripts, forcing the user to work around what was already written by somebody else. **Starly remedies this by being entirely self-contained in a single Lua module.** It doesn't make any assumptions about the user's render script. An example render script is available for reference, however you are encouraged to write your own based on your specific requirements.

## Installation

Add Starly as a dependency in your *game.project* file.

https://github.com/VowSoftware/starly/archive/main.zip

## Configuration

Each Starly game object is an independent camera. It contains a script component, which is used solely for configuration and cleanup.

![Screenshot 2024-10-03 134925](https://github.com/user-attachments/assets/37ad1938-9678-4050-9db4-c9ab0e84aa52)

* **Behavior:** How the viewport and projection should react to changes in the window size.
  * Behavior `center` shows a static area of the world, scales it without distortion, and centers it in the window. Borders are added to the window if necessary.
  * Behavior `expand` shows a dynamic area of the world, and doesn't scale or distort it.
  * Behavior `stretch` shows a static area of the world, and scales it with distortion.
* **Viewport X / Viewport Y:** Bottom-left of the viewport in screen space. For example, values (0, 0) on a 1920 x 1080 window start the viewport in the bottom-left corner of the window, whereas values of (960, 540) start the viewport in the center of the window.
* **Viewport Width / Viewport Height:** Size of the viewport in screen space. For example, values (1920, 1080) on a 1920 x 1080 window fill the entire window, whereas values of (960, 540) fill one-fourth of the window.
* **Near / Far:** Clipping planes on the z axis. Orthographic projections usually use the standard values (-1, 1).
* **Zoom:** Orthographic scaling factor. For example, a value of 0.5 zooms out such that more of the world can be seen and objects appear smaller, whereas a value of 2.0 zooms in such that less of the world can be seen and objects appear larger.

## Behaviors

To demonstrate the affect of each behavior, the example window will start at 1920 x 1080, then non-uniformly scale down to 1920 x 390.

**Any Behavior (1920 x 1080)**

![normal](https://github.com/user-attachments/assets/5a1551b5-0f2a-4491-8db1-b2017f5bcd10)

**Center Behavior (1920 x 390)**

Shows a static area of the world, scales it without distortion, and centers it in the window. In this case, borders are added to the left and right sides of the window, however they blend in with the clear color.

This behavior is ideal if you want don't want to show more or less of the world as the window size changes. Your scenes may be constructed to show an exact amount of objects. Showing anything outside those bounds might result in gaining an unfair advantage or accidentally showing out-of-bounds areas. Showing less than what's intended might result in being blind to something the player is supposed to see.

This is arguably the most common use case, so it's set as the default behavior value.

![center](https://github.com/user-attachments/assets/bdb21f34-45f5-4bec-b206-c7afef36c5a8)

**Expand Behavior (1920 x 390)**

Shows a dynamic area of the world, and doesn't scale or distort it.

Your scenes may be constructed without an exact amount of objects in mind to show simultaneously. This might be ideal for games where the player explores a large map.

![expand](https://github.com/user-attachments/assets/a024d941-2797-469b-bcda-4022aca1869b)

**Stretch Behavior (1920 x 390)**

Shows a static area of the world, and scales it with distortion.

Many older games were designed to only run on specific machines where the screen resolution was known to the developers. For example, making a game for the Nintendo DS doesn't require adaptive projection or viewport logic because all Nintendo DS systems share a common screen resolution.

Nowadays, this behavior is uncommon, but it is provided anyway for completeness.

![stretch](https://github.com/user-attachments/assets/27a6b9eb-4e36-4306-be92-79eca486a4b5)

## Runtime Edits and Animations

The game object's script simply forwards the above properties to the *starly.lua* module with `starly.create()`, then clears them with `starly.destroy()`. As a consequence, editing them with `go.set()` or `go.animate()` doesn't work. Instead, they can all be directly edited or animated with the `starly` table.

To interact with a camera, import the *starly.lua* module into any of your scripts.

```
local starly = require "starly.starly"
```

Camera data can be directly accessed by indexing the `starly` table by game object id.

```
-- Camera game object id.
local camera_id = hash("/starly")

-- Zoom out by a factor of 2.
starly[camera_id].zoom = starly[camera_id].zoom / 2
```

Since all camera properties are exposed, there isn't a single utility function in the Starly module that can't be implemented manually. Regardless, it's recommended to use these utility functions, as they perform many useful calculations for you.

```
-- Camera game object id.
local camera_id = hash("/starly")

-- Move 10 units up and 10 units right.
-- The `starly.move()` function accounts for the `zoom` value, which is required for an intuitive user experience.
local distance = vmath.vector3(10, 10, 0)
starly.move(camera_id, distance)

-- Instead of moving by a distance, let's animate to an absolute position.
local position = vmath.vector3(50, 50, 0)
go.animate(camera_id, "position", go.PLAYBACK_ONCE_FORWARD, position, go.EASING_INOUTQUAD, 1)
```

## Render Script Integration

Cameras must be activated in the render script before any making any draw calls. Activating a camera simply sets the engine's viewport, view, and projection.

```
-- Camera game object id.
local camera_id = hash("/starly")

-- Activate the camera.
starly.activate(camera_id)

-- Draw calls...
```

An example render script is available for reference, however you are encouraged to write your own based on your specific requirements. This may seem intimidating to users who don't have much experience with Defold's render pipeline, however because Starly offloads all camera functionality to the *starly.lua* file, your render script should transform into a much shorter and simpler version of what you're used to.

For example, the default render script is 236 lines long. After stripping all of the camera logic and replacing it with `starly.activate()`, the script is roughly half as long. Your render script will become solely focused on graphics, rather than also including complicated camera logic and state management.

## Variable API

Module and camera variables can be accessed directly. Note that the prefix `c_` refers to a constant.

* `starly.c_display_width`: Default width of the window, specified in the *game.project* file.
* `starly.c_display_height`: Default height of the window, specified in the *game.project* file.
* `starly[id].behavior`: See [configuration](#configuration) for details.
* `starly[id].viewport_x`: See [configuration](#configuration) for details.
* `starly[id].viewport_y`: See [configuration](#configuration) for details.
* `starly[id].viewport_width`: See [configuration](#configuration) for details.
* `starly[id].viewport_height`: See [configuration](#configuration) for details.
* `starly[id].near`: See [configuration](#configuration) for details.
* `starly[id].far`: See [configuration](#configuration) for details.
* `starly[id].zoom`: See [configuration](#configuration) for details.

## Function API

### `m_starly.create(id)`

Creates a camera. This function is called automatically in the game object's script component.

### `m_starly.destroy(id)`

Destroys a camera. This function is called automatically in the game object's script component.

### `m_starly.activate(id)`

Activates a camera. This function should be called in the user's render script before any making any draw calls.

### `m_starly.move(id, offset)`

Moves a camera by some distance. Accounts for the camera's `zoom` value.

### `m_starly.shake(id, count, duration, radius, [duration_scalar = 1], [radius_scalar = 1])`

Shakes a camera.

* `count`: `number` Amount of pingpong movements.
* `duration`: `number` Duration of each pingpong.
* `radius`: `number` Distance of each pingpong.
* `[duration_scalar]`: `number` After each pingpong, the `duration` is scaled by this value.
* `[radius_scalar]`: `number` After each pingpong, the `radius` is scaled by this value.

### `m_starly.cancel_shake(id)`

Cancels an ongoing camera shake.

### `m_starly.is_shaking(id)`

Checks if a camera is shaking.

Returns a `boolean`.

### `m_starly.get_world_area(id)`

Gets the world area of a camera, which is defined as the rectangular area of the world that the camera can see, in world coordinates.

Returns `x`, `y`, `width`, and `height`, where `x` and `y` are the bottom-left of the rectangle.

### `m_starly.screen_to_world(id, screen_x, screen_y, [visible = false])`

Converts screen coordinates to world coordinates.

* `visible`: `boolean` Determines if the cursor must be visible to the camera. If `true`, then this function returns `nil` when the cursor is outside the camera's viewport.

### `m_starly.world_to_screen(id, world_position, [visible = false])`

Converts world coordinates to screen coordinates.

* `visible`: `boolean` Determines if the cursor must be visible to the camera. If `true`, then this function returns `nil` when the cursor is outside the camera's viewport.
