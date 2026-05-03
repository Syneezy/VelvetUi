--[[
    ██╗   ██╗███████╗██╗     ██╗   ██╗███████╗████████╗    ██╗   ██╗██╗
    ██║   ██║██╔════╝██║     ██║   ██║██╔════╝╚══██╔══╝    ██║   ██║██║
    ██║   ██║█████╗  ██║     ██║   ██║█████╗     ██║       ██║   ██║██║
    ╚██╗ ██╔╝██╔══╝  ██║     ╚██╗ ██╔╝██╔══╝     ██║       ██║   ██║██║
     ╚████╔╝ ███████╗███████╗ ╚████╔╝ ███████╗   ██║       ╚██████╔╝██║
      ╚═══╝  ╚══════╝╚══════╝  ╚═══╝  ╚══════╝   ╚═╝        ╚═════╝ ╚═╝

    Velvet UI — v1.0.0
    Studio entry point. Used as: require(path.to.VelvetUi)

    For executor usage, see loader.lua at the repo root instead.
    MIT License — github.com/VelvetUi
--]]

-- ── Bootstrap ─────────────────────────────────────────────────────────────────
-- Env and Loader are loaded directly via require() because we are in a normal
-- Roblox ModuleScript context where script is a valid Instance reference.
-- Everything else goes through Loader so MANIFEST stays the single source of truth.

local Env    = require(script.src.Env)
local Loader = require(script.src.Loader)

Loader.configure(Env, {
    strategy  = "require",
    scriptRef = script,   -- VelvetUi root ModuleScript; Loader resolves children from here
})

-- ── Load & wire ───────────────────────────────────────────────────────────────

local state = {
    windows    = {},
    globalFont = Enum.Font.Gotham,
    scaleMode  = "Auto",
    debugMode  = false,
    version    = "1.0.0",
}

local modules = Loader.loadAll()
Loader.wire(modules, state)

-- ── Return the public API ─────────────────────────────────────────────────────

return Loader.buildAPI(modules, state)
