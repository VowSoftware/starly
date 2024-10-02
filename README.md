# Starly

Starly is a orthographic camera library for Defold.

Please click the ☆ button on GitHub if this repository is useful. Thank you!

## Discussion

The purpose of creating Starly is to provide a feature-rich orthographic camera solution that is confined to a single Lua module.

Focusing on 2D games allows Starly to provide more interesting, creative, and maintainable features. Supporting 3D games would introduce more complexity, redundancy, and would restrict the freedom to add functionality that differs between what you might see in a 2D game versus a 3D game.

At the time of writing, all other Defold camera solutions require you to include library code in your render script. For example, the default render script contains a subset of projection calculation functions, performs maintainence on camera properties each frame, captures built-in engine messages in its `on_message()` function that are required to properly update the camera, etc. The accepted workflow for other camera libraries is to either use their pre-packaged render script, or copy and paste it into your project then edit what needs to be edited. It's rare that a render script doesn't need to be heavily edited, due to most games requiring custom graphics pipelines. In my opinion, this copy-paste-edit paradigm is irritating. I would rather separate my own code from the library's code.

To remedy this, Starly is entirely self-contained in a single Lua module. It doesn't make any assumptions about the user's render script. A pre-packaged render script is available for referencing or quickstarting development, however you are encouraged to write your own render script based on your specific requirements.

## Configuration

Add Starly as a dependency in your *game.project* file. (Main -> Bootstrap -> Dependencies)

If you're using the pre-packaged render script, replace the default render component in your *game.project* file. (Main -> Bootstrap -> Render)