# Starly

Starly is a orthographic camera library for Defold.

Please click the ☆ button on GitHub if this repository is useful. Thank you!

![thumbnail](https://github.com/user-attachments/assets/d7f1c49f-aef0-437b-917a-f49345524988)

## Discussion

The purpose of creating Starly is to provide a feature-rich orthographic camera solution that is confined to a single Lua module.

Focusing on 2D games allows Starly to provide more interesting, creative, and maintainable features. Supporting 3D games would introduce more complexity, redundancy, and would restrict the freedom to add functionality that differs between what you might see in a 2D game versus a 3D game.

At the time of writing, all other Defold camera solutions require you to include library code in your render script. For example, the default render script contains a subset of projection calculation functions, performs maintainence on camera properties each frame, captures built-in engine messages in its `on_message()` function that are required to properly update the camera, etc. The accepted workflow for other camera libraries is to either use their pre-packaged render script, or copy and paste it into your project then edit what needs to be edited. It's rare that a render script doesn't need to be heavily edited, due to most games requiring custom graphics pipelines. In my opinion, this copy-paste-edit paradigm is irritating. I would rather separate my own code from the library's code.

To remedy this, Starly is entirely self-contained in a single Lua module. It doesn't make any assumptions about the user's render script. An example render script is available for reference, however you are encouraged to write your own render script based on your specific requirements.

## Installation

Add Starly as a dependency in your *game.project* file.

https://github.com/VowSoftware/starly/archive/main.zip

## Configuration

Each Starly game object is an independent camera. It contains a script component, which is used solely for configuration and cleanup. Click on the script component to see its configurable properties.

![Screenshot 2024-10-02 130935](https://github.com/user-attachments/assets/8b3ac0f7-caa8-42eb-8f11-d08ab66073f7)

* **Behavior:** How the viewport and projection should react to changes in the window size.
  * Behavior `center` shows a static area of the world, scales it without distortion, and centers it in the window. Borders are added to the window if necessary.
  * Behavior `expand` shows a dynamic area of the world, and doesn't scale or distort it.
  * Behavior `stretch` shows a static area of the world, and scales it with distortion.
* **Viewport X / Viewport Y:** Bottom-left of the viewport in screen space. For example, values (0, 0) on a 1920 x 1080 window start the viewport in the bottom-left corner of the window, whereas values of (960, 540) start the viewport in the center of the window.
* **Viewport Width / Viewport Height:** Size of the viewport in screen space. For example, values (1920, 1080) on a 1920 x 1080 window fill the entire window, whereas values of (960, 540) fill one-fourth of the window.
* **Near / Far:** Clipping planes on the z axis. Orthographic projections usually use the standard values (-1, 1).
* **Zoom:** Orthographic scaling factor. For example, a value of 0.5 zooms out such that more of the world can be seen and objects appear smaller, whereas a value of 2.0 zooms in such that less of the world can be seen and objects appear larger.
* **Zoom Max / Zoom Min:** Maximum and minimum zoom values. These are useful if your game allows the player to zoom in and out. If you as the developer have full control over the zoom level however, then these should match the `zoom` value.
* **Boundary:** Determines if a rectangular boundary should be enforced. This is useful if you want to restrict the camera to showing only a certain area of the world on the x and y axes.
* **Boundary X / Boundary Y:** Bottom-left of the boundary in world space. Only required if `boundary` is enabled.
* **Boundary Width / Boundary Height:** Size of the boundary in world space. Only required if `boundary` is enabled.

## Runtime Edits and Animations

The game object's script simply forwards its properties to the *starly.lua* module with `starly.create()`, then clears them with `starly.destroy()`. As a consequence, calling `go.set()` or `go.animate()` doesn't work. Instead, they can all be edited or animated at runtime through Starly's API.

To interact with a camera, import the *starly.lua* module into any of your scripts.

```
local starly = require "starly.starly"
```
