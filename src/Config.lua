--[[
    Velvet UI — Config.lua
    Automatic per-flag save / load system.
    Tries writefile/readfile (executor environments) first;
    falls back to in-memory storage for standard Roblox sessions.
    MIT License
--]]

local HttpService = game:GetService("HttpService")

local Config = {}

-- ── Storage backend ───────────────────────────────────────────────────────────

local CONFIG_FILE = "velvet_config.json"
local _mem        = {}         -- in-memory fallback
local _callbacks  = {}         -- flag → callback (registered by elements)
local _values     = {}         -- flag → current value (loaded or live)

-- Detect if executor file APIs are available.
local _hasFileIO = (typeof(writefile) == "function" and typeof(readfile) == "function")

-- Save the full config to persistent storage or memory.
local function persist()
    if _hasFileIO then
        local ok, err = pcall(function()
            writefile(CONFIG_FILE, HttpService:JSONEncode(_values))
        end)
        if not ok then
            warn("[Velvet/Config] writefile failed: " .. tostring(err))
        end
    else
        -- In-memory only — values survive the session
        _mem = {}
        for k, v in pairs(_values) do _mem[k] = v end
    end
end

-- Load all saved values from persistent storage or memory.
local function hydrate()
    if _hasFileIO then
        local ok, result = pcall(readfile, CONFIG_FILE)
        if ok and result and result ~= "" then
            local decoded = pcall(function()
                _values = HttpService:JSONDecode(result)
            end)
            if not decoded then
                _values = {}
            end
        end
    else
        for k, v in pairs(_mem) do _values[k] = v end
    end
end

-- ── Public API ────────────────────────────────────────────────────────────────

-- Register an element's callback under a flag.
-- Called by Elements.lua when an element with a Flag is created.
function Config.register(flag, defaultValue, callback)
    if not flag or flag == "" then return end

    if _values[flag] == nil then
        _values[flag] = defaultValue
    end

    -- Multiple callbacks per flag are supported (though uncommon).
    if not _callbacks[flag] then _callbacks[flag] = {} end
    table.insert(_callbacks[flag], { cb = callback, default = defaultValue })
end

-- Persist a new value for a flag (called whenever an element value changes).
function Config.save(flag, value)
    if not flag or flag == "" then return end
    _values[flag] = value
    persist()
end

-- Return the stored value for a flag (or nil if not found).
function Config.get(flag)
    return _values[flag]
end

-- Call all registered element callbacks with their stored value.
-- Invoked by Velvet:LoadConfig().
function Config.LoadAll()
    hydrate()
    for flag, entries in pairs(_callbacks) do
        local stored = _values[flag]
        for _, entry in ipairs(entries) do
            if stored ~= nil then
                local ok, err = pcall(entry.cb, stored)
                if not ok then
                    warn("[Velvet/Config] LoadAll callback error for flag '" .. flag .. "': " .. tostring(err))
                end
            end
        end
    end
end

-- Clear a specific flag from storage.
function Config.clear(flag)
    if not flag then return end
    _values[flag] = nil
    persist()
end

-- Wipe everything.
function Config.clearAll()
    _values = {}
    _callbacks = {}
    persist()
end

-- Pre-load on require so LoadAll() has data immediately.
hydrate()

return Config
