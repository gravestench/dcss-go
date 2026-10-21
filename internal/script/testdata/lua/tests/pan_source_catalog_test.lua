-- The committed Pan corpus is the runtime source of truth. Check every
-- active split file through the production DES parser and hook resolver,
-- including maps a particular seed may never select.
local des = require("policy.generation.vaults.des")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")

local test = {}

-- Count active source maps by family and validate their named Lua methods.
-- The one source-tagged removed controller is intentionally absent.
function test.run()
    local entry_paths = mod.paths("vaults/pan_entry", ".des")
    local pan_paths = mod.paths("vaults/pan", ".des")
    local seen = {}

    harness.equal(#entry_paths, 12, "all active Depths Pan entries are committed")
    harness.equal(#pan_paths, 129, "all active Pan maps are committed")

    for _, paths in ipairs({ entry_paths, pan_paths }) do
        for _, path in ipairs(paths) do
            local map = des.parse(path, mod.read(path))

            harness.falsy(seen[map.id], "duplicate Pan map " .. map.id)
            harness.truthy(#map.rows > 0, map.id .. " has no source MAP")
            hooks.validate(map)
            seen[map.id] = true
        end
    end

    harness.falsy(seen.pan_demonic_rune_highlights,
        "source-removed double-vault controller was imported")
    harness.truthy(seen.pan_exit, "direct Pan exit is missing")
    harness.truthy(seen.pan_to_abyss, "Abyss exit is missing")
    harness.truthy(seen.cerebov, "named lord realm is missing")
end

return test
