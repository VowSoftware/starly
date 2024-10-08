# Starly

Starly is a orthographic camera library for Defold.

Please click the ☆ button on GitHub if this repository is useful. Thank you!

![Starly](https://github.com/user-attachments/assets/8b586e24-b806-439e-b6bc-3124cb6ed68b)

## Discussion

Starly's goal is to provide a feature-rich orthographic camera solution, confined to a single Lua module, where all properties can be edited or animated at runtime.

Exclusively supporting 2D games allows Starly to implement interesting, creative, and proven utility functions, without the complexity and redundancy that comes with simultaneously supporting 3D games.

Other camera libraries guard certain properties with getter and setter functions to abstract management of internal variables. This causes confusion and frustration when trying to edit those properties at runtime, especially when dealing with animation. Starly remedies this by exposing all properties such that they can be edited or animated at runtime.

Other camera libraries require you to include someone else's code in your render script. For example, the default render script contains projection functions, performs maintainence on camera properties, and captures messages that are required to properly update cameras. It's rare that a render script doesn't need to be heavily edited, which results in an irritating copy-paste-edit workflow, forcing the user to work around what was already written by somebody else. Starly remedies this by being entirely self-contained in a single Lua module.

## Installation

Add Starly as a dependency in your *game.project* file.

https://github.com/VowSoftware/starly/archive/main.zip

## Configuration

Each Starly game object is an independent camera. It contains a script component, which is used solely for configuration and cleanup.

![Screenshot 2024-10-03 134925](https://github.com/user-attachments/assets/37ad1938-9678-4050-9db4-c9ab0e84aa52)

* **Behavior:** How the viewport and projection should react to changes in the window size.
  * Behavior `center` shows a static area of the world, scales it without distortion, and centers it in the window. Borders are added to the window if necessary.
  * Behavior `expand` shows a dynamic area of the world, and doesn't scale or distort it.
  * Behavior `mixed` shows a dynamic area of the world, and scales it without distortion.
  * Behavior `stretch` shows a static area of the world, and scales it with distortion.
* **Viewport X / Viewport Y:** Bottom-left of the viewport in screen space. For example, values (0, 0) on a 1920 x 1080 window start the viewport at the bottom-left corner of the window, whereas values (960, 540) start the viewport at the center of the window.
* **Viewport Width / Viewport Height:** Size of the viewport in screen space. For example, values (1920, 1080) on a 1920 x 1080 window fill the entire window, whereas values (960, 540) fill one-fourth of the window.
* **Near / Far:** Clipping planes on the z axis. Orthographic projections usually use the standard values (-1, 1).
* **Zoom:** Orthographic scaling factor. For example, a value of 0.5 zooms out such that more of the world can be seen and objects appear 0.5x smaller, whereas a value of 2 zooms in such that less of the world can be seen and objects appear 2x larger.

## Behaviors

To demonstrate the affect of each behavior, the example window will start at 1920 x 1080, then non-uniformly scale down to 1920 x 390.

**Any Behavior (1920 x 1080)**

![normal](https://github.com/user-attachments/assets/5a1551b5-0f2a-4491-8db1-b2017f5bcd10)

**Center Behavior (1920 x 390)**

Shows a static area of the world, scales it without distortion, and centers it in the window. In this case, borders are added to the left and right sides of the window.

This behavior is ideal if you want don't want to show more or less of the world as the window size changes. Your scenes may be constructed to show an exact amount of objects. Showing anything outside those bounds might result in gaining an unfair advantage or accidentally showing out-of-bounds areas. Showing less than what's intended might result in being blind to something the player is supposed to see.

[VVVVVV](https://thelettervsixtim.es/) would have chosen this behavior.

![center](https://github.com/user-attachments/assets/06e6c906-2c0a-4648-9f69-68c39fdd9361)

**Expand Behavior (1920 x 390)**

Shows a dynamic area of the world, and doesn't scale or distort it.

This behavior is ideal if you don't care how much of the world the player can see. There might be somewhat of an advantage to seeing more, there might not be. Graphics are never scaled and always match their intended size.

[Don't Starve](https://www.klei.com/games/dont-starve) would have chosen this behavior.

![expand](https://github.com/user-attachments/assets/a024d941-2797-469b-bcda-4022aca1869b)

**Mixed Behavior**

Shows a dynamic area of the world, and scales it without distortion.

This behavior is ideal if it doesn't really matter how much of the world the player can see, but you also want graphics to scale if possible. This is somewhat of a mix between `center` and `expand`, but borders are never added to the window.

[Minecraft](https://www.minecraft.net/en-us) would have chosen this behavior.

**Stretch Behavior (1920 x 390)**

Shows a static area of the world, and scales it with distortion.

Many older games were designed to only run on specific machines where the screen resolution was known to the developers. For example, making a game for the Nintendo DS doesn't require adaptive projection or viewport logic because all Nintendo DS systems share a common screen resolution. Nowadays, this behavior is uncommon, but it is provided anyway for completeness.

![stretch](https://github.com/user-attachments/assets/27a6b9eb-4e36-4306-be92-79eca486a4b5)

## Runtime Edits and Animations

The game object's script simply forwards the above properties to the *starly.lua* module with `starly.create()`, then clears them with `starly.destroy()`. As a consequence, editing them with `go.set()` or `go.animate()` doesn't work. Instead, they can all be directly edited or animated with the `starly` table.

To interact with a camera, import the *starly.lua* module into any of your scripts.

```lua
local starly = require "starly.starly"
```

Camera data can be directly accessed by indexing the `starly` table by game object id.

```lua
-- Camera game object id.
local camera_id = hash("/starly")

-- Zoom out by a factor of 2.
starly[camera_id].zoom = starly[camera_id].zoom / 2
```

Since all camera properties are exposed, there isn't a single utility function in the Starly module that can't be implemented manually. Regardless, it's recommended to use these utility functions, as they perform many useful calculations for you.

```lua
-- Camera game object id.
local camera_id = hash("/starly")

-- Move 10 units up and 10 units right.
-- The `starly.get_offset()` function accounts for zoom and rotation.
local position = go.get_position(camera_id)
local distance = vmath.vector3(10, 10, 0)
local offset = starly.get_offset(camera_id, distance)
go.set_position(position + offset, camera_id)

-- Instead of moving by a distance, let's animate to an absolute position.
local position = vmath.vector3(50, 50, 0)
go.animate(camera_id, "position", go.PLAYBACK_ONCE_FORWARD, position, go.EASING_INOUTQUAD, 1)
```

## Render Script Integration
 
Starly provides a feature-rich render script. It includes organized configuration for predicates and targets, automatic creation of predicates and targets, automatic and custom resize logic for targets, and more. The script is well-documented, with hints and explanations throughout. The example project also serves as a very simple reference for how to integrate it into your own project.

Note however that this render script is only a template, not a complete solution.

Most games require a custom `update()` function in the render script. Therefore, you are required to write `update()` from scratch to meet your specific requirements. The decision to omit a pre-written `update()` was made to encourage Defold users to learn how their games are actually drawing graphics to the screen, rather than relying on a script that:

* was written by somebody else,
* for a greatly generalized and overly simplistic scenario,
* potentially performing many unnecessary operations,
* instilling a sense of learned helplessness,
* and promoting ignorance of how to create more graphically interesting and creative games.

You are always encouraged to write your own render script from scratch, especially since Starly offloads all camera logic and state management you see in the default script. This allows for a minimum viable render script in just a few lines of code.

In the `update()` function, a camera should be activated before making any draw calls. Activating a camera simply updates the engine's viewport, view, and projection, while also returning its frustum for culling purposes.

```lua
-- Camera game object id.
local camera_id = hash("/starly")

-- Activate the camera.
local frustum = starly.activate(camera_id)

-- Draw calls...
render.draw(predicate, { frustum = frustum })
```

## Variable API

**Module Variables**

* `starly.display_width`: `number` Default width of the window, specified in the *game.project* file.
* `starly.display_height`: `number` Default height of the window, specified in the *game.project* file.
* `starly.display_ratio`: `number` Default aspect ratio of the window.
* `starly.behavior_center`: `hash` Center behavior value.
* `starly.behavior_expand`: `hash` Expand behavior value.
* `starly.behavior_mixed`: `hash` Mixed behavior value.
* `starly.behavior_stretch`: `hash` Stretch behavior value.

**Camera Variables**

See [configuration](#configuration) for details.

* `starly[id].behavior`: `hash`
* `starly[id].viewport_x`: `number`
* `starly[id].viewport_y`: `number`
* `starly[id].viewport_width`: `number`
* `starly[id].viewport_height`: `number`
* `starly[id].near`: `number`
* `starly[id].far`: `number`
* `starly[id].zoom`: `number`

## Function API

### `m_starly.create(id)`

Creates a camera. This function is called automatically in the game object's script component.

**Parameters**

* `id`: `hash` Camera game object id.

---

### `m_starly.destroy(id)`

Destroys a camera. This function is called automatically in the game object's script component.

**Parameters**

* `id`: `hash` Camera game object id.

---

### `m_starly.activate(id)`

Activates a camera. This function should be called in the render script before any making any draw calls.

**Parameters**

* `id`: `hash` Camera game object id.

**Returns**

* `frustum`: `matrix4`

---

### `m_starly.get_viewport(id)`

Gets the viewport of a camera, in screen coordinates.

**Parameters**

* `id`: `hash` Camera game object id.

**Returns**

* `x`: `number` Left side of the rectangle.
* `y`: `number` Bottom of the rectangle.
* `width`: `number` Width of the rectangle.
* `height`: `number` Height of the rectangle.

---

### `m_starly.get_view(id)`

Gets the view of a camera.

**Parameters**

* `id`: `hash` Camera game object id.

**Returns**

* `view`: `matrix4`

---

### `m_starly.get_projection(id)`

Gets the projection of a camera.

**Parameters**

* `id`: `hash` Camera game object id.

**Returns**

* `projection`: `matrix4`

---

### `m_starly.shake(id, count, duration, radius, [duration_scalar = 1], [radius_scalar = 1])`

Shakes a camera.

**Parameters**

* `id`: `hash` Camera game object id.
* `count`: `number` Amount of pingpong movements.
* `duration`: `number` Duration of each pingpong.
* `radius`: `number` Distance of each pingpong.
* `[duration_scalar]`: `number` After each pingpong, the `duration` is scaled by this value.
* `[radius_scalar]`: `number` After each pingpong, the `radius` is scaled by this value.

---

### `m_starly.cancel_shake(id)`

Cancels an ongoing camera shake.

**Parameters**

* `id`: `hash` Camera game object id.

---

### `m_starly.is_shaking(id)`

Checks if a camera is shaking.

**Parameters**

* `id`: `hash` Camera game object id.

**Returns**

* `boolean`

---

### `m_starly.get_offset(id, distance, absolute)`

Gets the position offset of a camera after moving `distance` units, accounting for zoom and rotation.

**Parameters**

* `id`: `hash` Camera game object id.
* `distance`: `vector3` Position offset, before accounting for zoom and rotation.
* `absolute`: `boolean` Determines if `distance` is in absolute world coordinates, which ignore rotation.

**Returns**

* `vector3`

---

### `m_starly.get_world_area(id)`

Gets the world area of a camera, which is defined as the rectangular area of the world that the camera can see, in world coordinates.

**Parameters**

* `id`: `hash` Camera game object id.

**Returns**

* `x`: `number` Left side of the rectangle.
* `y`: `number` Bottom of the rectangle.
* `width`: `number` Width of the rectangle.
* `height`: `number` Height of the rectangle.

---

### `m_starly.get_tight_world_area(id, positions)`

Gets the center position, minimum zoom, and minimum world area of a camera that can see all `positions`.

This function was inspired by Super Smash Bros, where the camera moves and zooms to center and include all characters, with only a small amount of padding to the sides of the window.

**Parameters**

* `id`: `hash` Camera game object id.
* `positions`: `table` Array of `vector3` positions, in world coordinates.

**Returns**

* `position`: `vector3` Center position.
* `zoom`: `number` Minimum zoom.
* `x`: `number` Left side of the rectangle.
* `y`: `number` Bottom of the rectangle.
* `width`: `number` Width of the rectangle.
* `height`: `number` Height of the rectangle.

---

### `m_starly.screen_to_world(id, screen_x, screen_y, [visible = false])`

Converts screen coordinates to world coordinates.

**Parameters**

* `id`: `hash` Camera game object id.
* `visible`: `boolean` Determines if the cursor must be visible to the camera. If `true`, then this function returns `nil` when the cursor is outside the camera's viewport.

**Returns**

* `vector3` or `nil`

---

### `m_starly.world_to_screen(id, world_position, [visible = false])`

Converts world coordinates to screen coordinates.

**Parameters**

* `id`: `hash` Camera game object id.
* `visible`: `boolean` Determines if the cursor must be visible to the camera. If `true`, then this function returns `nil` when the cursor is outside the camera's viewport.

**Returns**

* `vector3` or `nil`
