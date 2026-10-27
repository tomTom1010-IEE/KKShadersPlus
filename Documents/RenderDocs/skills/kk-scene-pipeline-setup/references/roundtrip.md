# Prove The Scene Authoring Round Trip

Use a small owned smoke asset before a city, full character or expensive shader bundle. The aim
is a native reloadable Studio scene plus an inspected game render, not merely a Blender screenshot
or an Editor preview. Record readiness by stage, leaving untested stages explicit.

## Blender To FBX

Create one asymmetric static mesh, a UV checker, a roughly 1 metre reference dimension and unique
material names. Keep the .blend source and export only intended objects. Review modifiers, custom
split normals, tangents, handedness, UV seams, material-slot order and triangle budget. Applying
transforms to skinned rigs is a different operation and is not part of this static smoke test.

The maintained Rainline static workflow used metric units, selected meshes, FBX forward -Z/up Y,
no animation, no extra leaf bones, and no baked-space-transform workaround. Treat that as a starting
recipe, not proof of every Blender/FBX importer version. Inspect the installed export operator before
calling it. Check the imported orientation, dimensions and normals in Unity. Avoid relying on Unity
to launch an arbitrary system Blender version to import .blend files automatically.

Export image files separately with source/license metadata. Principled BSDF graphs, Eevee effects
and Blender compositor nodes do not become equivalent Unity shaders through FBX. Rebuild material
inputs according to the chosen shader's RenderDocs rather than relabeling Blender sockets.

## FBX To Native Unity Prop

Use a dedicated Assets/Mods/<unique-mod-name> directory. Import the model and textures, inspect
scale/UVs and create materials and a prefab with Editor APIs through the installed bridge. Start
with a simple supported material; the first pass does not require compiling the full modern shader pack.

The generic bridge's createMaterial/createPrefab operations are useful smoke helpers but do not
create a complete Studio item. Use the template's Studio Item Example to author the proper hierarchy
and Studio.ItemComponent, with sensible renderer lists/color info and any required child transforms.
Read the current component schema rather than fabricating serialized YAML or guessing a GUID.
If the bridge lacks an import/component operation, implement a bounded project-specific Editor
adapter when the task authorizes it, returning a result through its own typed bridge queue.
Do not invent unsupported operation names or treat arbitrary code execution as an existing API.

Assign a stable, unique bundle path such as studio/<author>/<mod>.unity3d through AssetImporter.
Keep release prefab names stable. Create the matching List/Studio group/category/item CSVs and
a unique manifest GUID/version with the correct game. Use structured CSV/XML APIs or the template's
list editor, preserving its headers and conventions.

The essential identity chain is:

```text
Studio list (group, category, item ID)
  -> bundle path relative to abdata
  -> exact prefab asset name
  -> native prefab / referenced materials and model
  -> final zipmod manifest + lists + abdata payload
```

An item carrier is not a shader carrier a_xxxx. Do not register a prop as a shader just because its
material uses TomBSDF. ME shader registrations and Studio catalog items have different manifests/lists.

## Targeted Bundle And Zipmod

Confirm the build target and postprocess path from the chosen template. The generic
buildAssetBundles operation builds all assigned bundles; do not call it casually in a large shared
shader project. Prefer a task-owned targeted build adapter or the template's explicitly scoped
build workflow. Keep caches and stop after an uncertain/hung build rather than starting overlapping
attempts. Force Rebuild is not a connectivity fix.

Run the required Koikatsu modding postprocess against the correct user-owned game root. A raw bundle
is not automatically game-ready, and the bridge build operation does not itself assemble the final
zipmod. Verify the final archive contains manifest.xml, List/Studio CSVs and the correct file under
abdata/studio/...; compare that payload by hash with the accepted processed bundle.

For scene-material work, reuse the installed accepted TomX/BSDF shader package. Geometry-only
prefabs can carry simple authoring materials; select the desired registered shader through ME
after the prop loads. This avoids embedding/rebuilding another copy of the shader pack accidentally.

## Studio Catalog And ME

Install only the new owned zipmod into the correct game's mods folder, replacing the same GUID
deliberately rather than leaving conflicting combined packages. Restart/rescan via the supported
game workflow when needed. Through StudioMCP, catalog_search for the exact item, add it, and verify
its bounds, orientation, hierarchy, material identities and normal response in the rendered game.

Use material_set_shader / material_set / material_import_texture / material_texture_transform
through current schemas and saved ME APIs. Read back values and matching-material scope. NormalMap
and NormalMapDetail can be repacked by ME: choose the shader decoder by received data, not PNG color.
Independent coat/liquid slots and packed material-map layouts are family specific.

For a small environment test, add native lights plus a clearly distinct foreground/background.
Use a captured reflection probe and SH only when their providers are installed and ready; after
editing materials/sky/lights, explicitly refresh owned controllers and wait for new completion
counters. A high ReflectionIntensity without a real probe does not create environment reflection.
Use native Studio postprocessing first to isolate the pipeline; add other effects only if requested.

## Persistence And Output

1. Change one obvious material scalar/color and one texture/ST through ME, then read them back.
2. Save an owned native scene PNG/checkpoint. Preserve the user's current scene before replacing it.
3. Reload an independent PNG path, not only an optional bridge sidecar. scene_restore accepts the
   bridge's own output paths in the reviewed API; do not assume arbitrary scene import is supported.
4. Reacquire session/handles. Compare material values/maps/ST, transforms, visibility, camera,
   active sky/native effects and required bridge-controlled metadata. Wait for on-load Probe/SH.
5. Capture a small actual Studio image and inspect it. Increase output resolution only after this
   succeeds; supersampled captures can retain substantial memory across repeated reloads.
6. If required, export paired depth. Read its encoding/near/far/reversed-Z/row-order metadata and
   check finite foreground/midground/background values. Normal maps/POM do not create mesh depth,
   and glass/rain do not supply independent opaque depth interfaces. Test requested native DOF
   separately rather than forcing transparent ZWrite.

Keep required mesh zipmods and runtime DLLs alongside the delivery instructions. A scene card is
not a self-contained asset bundle. StudioMCP-authored sky/environment state needs the bridge DLL
at load time but not an active host connection. Report full-load and import/merge support separately.

## Handoff Record

Record game/Editor/Blender versions, source commits, bridge/provider hashes, installed mod identities,
the identity-chain values, successful connection gates, scene/card paths and color/depth results.
Retain failures/uncertainties without tokens, game binaries or unrelated scene data. Do not label
Editor-only compilation, file presence or this guide itself as a new end-to-end acceptance.
