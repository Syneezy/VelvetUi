--[[
    Velvet UI — loader.lua
    Executor entry point. Call this when NOT running inside Roblox Studio.
    Returns the exact same Velvet API as the Studio init.lua.

    ── Usage ─────────────────────────────────────────────────────────────────────

    Option A — Local files (executor with FileIO, e.g. Synapse X, KRNL):
        local VelvetUi = loadstring(readfile("VelvetUi/loader.lua"))()

    Option B — GitHub HTTP (any executor with internet access):
        local VelvetUi = loadstring(game:HttpGet(
            "https://raw.githubusercontent.com/VelvetUi/VelvetUi/main/loader.lua"
        ))()

    Option C — Custom base path / URL (self-hosted or renamed folder):
        local VelvetUi = loadstring(readfile("MyFolder/loader.lua"))({
            basePath = "MyFolder/",
        })
        -- OR with HTTP:
        local VelvetUi = loadstring(game:HttpGet("https://myhost.com/velvet/loader.lua"))({
            baseUrl = "https://myhost.com/velvet/",
        })

    Option D — Force a specific strategy (advanced):
        local VelvetUi = loadstring(readfile("VelvetUi/loader.lua"))({
            strategy = "http",   -- "filesystem" | "http"
            baseUrl  = "https://raw.githubusercontent.com/VelvetUi/VelvetUi/main/",
        })

    ── Config fields ─────────────────────────────────────────────────────────────
        basePath   string  Local folder that contains src/, e.g. "VelvetUi/"
        baseUrl    string  Raw URL base, e.g. "https://raw.githubusercontent.com/..."
        strategy   string  "filesystem" | "http" (nil = auto-detect)
        scaleMode  string  "Auto" | "Desktop" | "Mobile" (default "Auto")
        debugMode  bool    Enable debug logs (default false)

    MIT License — github.com/VelvetUi
--]]

return function(config)
    config = config or {}

    -- ── Inline bootstrap constants ────────────────────────────────────────────
    -- These are resolved before Env.lua and Loader.lua themselves are loaded,
    -- so they must be self-contained (no require, no external dependencies).

    local BASE_URL  = config.baseUrl  or "https://raw.githubusercontent.com/VelvetUi/VelvetUi/main/"
    local BASE_PATH = config.basePath or "VelvetUi/"

    -- ── Inline capability sniff ───────────────────────────────────────────────
    -- Minimal detection to decide HOW to bootstrap Env.lua and Loader.lua.
    -- The full capability table comes from Env.lua once it's loaded.

    local _hasFS = (
        typeof(readfile)  == "function" and
        typeof(writefile) == "function" and
        typeof(isfile)    == "function"
    )

    local _forceStrategy = config.strategy  -- may be nil (auto)
    local _useFS = _forceStrategy == "filesystem"
               or (_forceStrategy == nil and _hasFS)

    -- ── Inline fetch (used ONLY during bootstrap of Env + Loader) ─────────────
    -- After Env is loaded, all further HTTP goes through Env.httpGet().

    local function _fetch(relativePath)
        if _useFS then
            -- FileSystem path
            local fullPath = BASE_PATH .. relativePath
            assert(isfile(fullPath),
                "[Velvet/loader] File not found during bootstrap: " .. fullPath
                .. "\n  Ensure the VelvetUi folder is in: " .. BASE_PATH)
            return readfile(fullPath)

        else
            -- HTTP path — try all backends
            local url = BASE_URL .. relativePath
            local src

            -- game:HttpGet (works in-game and some executors)
            local ok, result = pcall(function()
                return game:HttpGet(url, true)
            end)
            if ok and type(result) == "string" and #result > 0 then
                src = result

            -- Synapse X
            elseif typeof(syn) == "table" and typeof(syn.request) == "function" then
                local res = syn.request({ Url = url, Method = "GET" })
                if res and res.StatusCode == 200 then src = res.Body end

            -- Generic request()
            elseif typeof(request) == "function" then
                local res = request({ Url = url, Method = "GET" })
                if res and res.StatusCode == 200 then src = res.Body end

            -- http.request
            elseif typeof(http) == "table" and typeof(http.request) == "function" then
                local res = http.request({ Url = url, Method = "GET" })
                if res and res.StatusCode == 200 then src = res.Body end
            end

            assert(src,
                "[Velvet/loader] HTTP bootstrap failed for: " .. url
                .. "\n  Make sure the executor has internet access or use FileSystem mode.")
            return src
        end
    end

    -- ── Inline loadstring helper ──────────────────────────────────────────────

    local function _exec(relativePath)
        local src = _fetch(relativePath)
        local fn, err = loadstring(src, "@" .. relativePath)
        assert(fn, "[Velvet/loader] Syntax error in '" .. relativePath .. "': " .. tostring(err))
        return fn()
    end

    -- ── Step 1: Bootstrap Env and Loader ──────────────────────────────────────
    -- These two are loaded inline — they have zero VelvetUi deps.

    local Env    = _exec("src/Env.lua")
    local Loader = _exec("src/Loader.lua")

    -- Pre-populate Loader's cache with our already-loaded copies so it won't
    -- re-fetch Env or Loader if something else tries to load them later.
    -- (Loader._cache is internal, so we do this via a dummy load that returns cached)
    -- Not needed since MANIFEST doesn't include Env or Loader — but good practice.

    -- ── Step 2: Configure Loader with full capabilities ───────────────────────

    local resolvedStrategy = _forceStrategy
        or (_useFS and "filesystem" or "http")

    Loader.configure(Env, {
        strategy = resolvedStrategy,
        baseUrl  = BASE_URL,
        basePath = BASE_PATH,
    })

    -- ── Step 3: Load all manifest modules ─────────────────────────────────────

    local state = {
        windows    = {},
        globalFont = Enum.Font.Gotham,
        scaleMode  = config.scaleMode or "Auto",
        debugMode  = config.debugMode or false,
        version    = "1.0.0",
    }

    local modules = Loader.loadAll()

    -- ── Step 4: Wire dependencies ─────────────────────────────────────────────

    Loader.wire(modules, state)

    -- ── Step 5: Build and return public API ───────────────────────────────────

    local Velvet = Loader.buildAPI(modules, state)

    -- Expose executor-only extras on the returned API
    Velvet._env      = Env
    Velvet._loader   = Loader
    Velvet._strategy = resolvedStrategy

    -- Apply initial scale mode if overridden in config
    if config.scaleMode then
        modules.Utils.setScaleMode(config.scaleMode)
    end

    -- Apply debug mode if set in config
    if config.debugMode then
        modules.Utils.setDebug(true)
        print("[Velvet] Executor loader ready — strategy: " .. resolvedStrategy
            .. " | executor: " .. Env.executorName
            .. " | v" .. state.version)
    end

    return Velvet
end
