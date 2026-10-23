-- The Abyss uses ordinary DES files for both Depths entrances and interior
-- furniture. This test walks the same layered VFS and parser as gameplay so
-- an omitted source definition cannot silently change the weighted pools.
local des = require("policy.generation.vaults.des")
local harness = require("tests.harness")
local hooks = require("policy.generation.vaults.hooks")
local chance = require("policy.generation.vaults.chance")
local branches = require("ids.branches")
local families = require("constants.vault_families")
local used = require("policy.generation.vaults.used")

local test = {}

-- Depths:3 is the source's guaranteed entrance roll. This asks the
-- production chance selector, not a test-only list of the nine names.
local function depths_entrance_is_selected()
    local random = {}

    function random:roll()
        return 0
    end

    local selected = chance.select(random, {
        branch_id = branches.BRANCH_DEPTHS,
        depth = 3,
        branch_bottom = 4,
        absolute_depth = 18,
        layout_family = "halls",
        used = used.new({}),
    })
    local found = false

    for _, definition in ipairs(selected) do
        if definition.family == families.ABYSS_ENTRY then
            found = true
        end
    end

    harness.truthy(found, "source Depths chance selects an Abyss gate")
end

-- A committed digest protects every source MAP row without requiring the
-- C++ checkout during ordinary Go builds or modded runs.
local function geometry_digest(definitions)
    local parts = {}

    for id, definition in pairs(definitions) do
        if #definition.rows > 0 then
            parts[#parts + 1] = id .. ":" ..
                table.concat(definition.rows, "\n")
        end
    end

    table.sort(parts)

    local digest = 0

    for byte in table.concat(parts, "\n"):gmatch(".") do
        digest = (digest * 31 + string.byte(byte)) % 4294967296
    end

    return digest
end

-- Count and validate one role without copying the production DES schema.
local function inspect_role(directory, expected_count)
    local paths = mod.paths(directory, ".des")
    local definitions = {}

    harness.equal(#paths, expected_count, directory .. " source count")

    for _, path in ipairs(paths) do
        local definition = des.parse(path, mod.read(path))

        hooks.validate(definition)
        definitions[definition.id] = definition
    end

    return definitions
end

-- Mapless weighted dummies deliberately consume a selection draw without
-- placing a vault. They must remain in the interior pool beside real maps.
function test.run()
    local entries = inspect_role("vaults/abyss_entry", 9)
    local interior = inspect_role("vaults/abyss", 91)
    local interior_maps = 0
    local dummies = 0

    for id, definition in pairs(interior) do
        harness.falsy(entries[id], "duplicate Abyss vault " .. id)

        if #definition.rows == 0 then
            dummies = dummies + 1
        else
            interior_maps = interior_maps + 1
        end
    end

    harness.equal(interior_maps, 88, "all interior MAP blocks")
    harness.equal(dummies, 3, "all mapless weighted definitions")
    harness.truthy(entries.abyss_entry, "Depths entrance backup")
    harness.truthy(interior.abyss_rune_dummy, "rune mapless choice")
    harness.truthy(interior.abyss_exit_dummy, "exit mapless choice")

    for id, definition in pairs(entries) do
        interior[id] = definition
    end

    harness.equal(geometry_digest(interior), 804139389,
        "all 97 source MAP blocks")
    depths_entrance_is_selected()
end

return test
