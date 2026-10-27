# Connect The Three Applications

Read the current tool schemas. Transport topology:

```text
Agent --stdio MCP host--> Blender addon/socket --> Blender document
Agent --local JSON files--> Unity Codex Bridge --> Editor APIs / authoring assets
Agent --stdio StudioMcp.Host--> authenticated loopback WebSocket --> CharaStudio / ME
```

## Blender

The reviewed upstream is ahujasid/mcp-for-blender, a third-party community integration, not a
Blender Foundation release. The former blender-mcp name is retained upstream as a compatibility
entry; use the reviewed current name for new installs. Inspect the chosen release before upgrading.

With uv installed and reachable in the agent host's PATH:

```powershell
uvx mcp-for-blender install-addon
codex mcp add blender -- uvx mcp-for-blender
```

Enable the installed add-on in Blender. Verify/start its server using the add-on's controls; older
and newer releases differ in automatic startup. Reconnect the client, inspect its discovered tools,
and request read-only scene information from the intended Blender document. Do not run multiple
hosts against one addon/socket accidentally. Optional asset/generation services need their own
permissions; they are not necessary for the first box test. Do not expose an arbitrary-code addon
socket to the LAN/Internet.

## Unity File Queue

After Editor compilation, the bridge creates CodexBridge/Inbox, Outbox and Logs at the project root.
Use a unique request filename and make the completed JSON visible atomically (write outside Inbox,
then rename it into place). A connectivity request needs no game data:

```json
{ "operation": "ping" }
```

For request setup-ping-<unique-id>.json, read Outbox/setup-ping-<unique-id>.result.json and require
success=true with pong. The processed file ends in .json.done. Logs/unity-log.jsonl provides
forwarded errors. A pending request is not failure: check import/compile state and the project path.
Do not enqueue duplicate mutations or delete caches when a result is delayed.

The public 2019 bridge waits during compilation/import but cannot cancel an executing build.
Local BSDF jobs may use a separate .running lifecycle; that is not a portable command to invent.
Only installed operations may be sent. A ping proves the active bridge, not every helper module.

## StudioMCP

Start Studio with the matching plugin, then configure the external host. Example Codex CLI command,
with variables set to real source/game locations:

```powershell
$GameRoot = 'C:/Games/KKS'
$StudioRepo = 'C:/Modding/StudioMCP'
codex mcp add studio --env "STUDIOMCP_CONNECTION=$GameRoot/UserData/StudioMCP/connection.json" -- dotnet "$StudioRepo/src/StudioMcp.Host/bin/Release/net8.0/StudioMcp.Host.dll"
codex mcp list
```

Read studio_status and scene_snapshot first. Check the returned game, write mode and sceneSession.
Use the current session on writes and reacquire renderer/material handles after scene/character
rebuilds. Inspect matchingMaterials: ME can affect multiple same-named materials in an object scope,
even when the request specifies one renderer handle.

assets/mcp.codex.example.toml is an alternative configuration example, not another file to append
blindly. Merge selected server tables into the target Codex config; preserve unrelated entries and
back up the original. Its sample paths need replacement. Generic clients using mcpServers JSON
require their own configuration format; do not paste that JSON into Codex TOML.

A connection file can outlive its game process. Read-only host status, not file presence, establishes
reachability. The bridge defaults to loopback and read-only; do not copy credentials between users.
The reviewed defaults are KKS port 8846 and KK 8847, but use the generated connection descriptor,
not a guessed socket URL. An OAuth login is not the authentication mechanism for this local bridge.

## Timeout And Capability Boundaries

Client tool wait, StudioMCP host response wait and the game's queue-admission deadline are different.
Use only timeout settings documented by the installed host version; do not assume an environment
variable supported by another release is recognized. The reviewed game queue admission is
30 seconds. A longer client timeout does not interrupt or safely retry a
Unity operation already executing. Inspect state before retrying any timed-out write.

Capture uses the installed Screencap API and may be asynchronous. withDepth requires its supported
paired-depth export API, not simply a camera depthTextureMode flag. Unsupported tools/vector kinds,
missing authoring operations and absent depth capability must be reported, not bypassed through
computer-use automation. No unrestricted C# game-execution endpoint is required for this workflow.
