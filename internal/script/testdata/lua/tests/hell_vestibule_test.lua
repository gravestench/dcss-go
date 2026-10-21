-- The pinned hell.des gives the Vestibule one encompassing map, five
-- independently selected wings, and authored Hell gates. Exercise the
-- production catalogs and placement path so the source files cannot drift
-- into a parsed-but-unused collection.
local branches = require("ids.branches")
local monsters = require("ids.monsters")
local catalog = require("policy.generation.layouts.catalog")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local placement = require("policy.generation.vaults.placement")
local resolve = require("policy.generation.vaults.specs.resolve")
local vaults = require("policy.generation.vaults.catalog")
local monster_requests = require("constants.vault_monster_requests")

local test = {}

local wing_tags = {
    vestibule_dis = true,
    vestibule_tar = true,
    vestibule_coc = true,
    vestibule_geh = true,
    vestibule_geryon = true,
}

-- Use the production grid RNG contract with a repeatable seed. The test
-- inspects placed wings rather than reimplementing source tag selection.
local function context_for(seed)
    local state = seed
    local context = {}

    -- Advance two words per bounded draw like the production grid service.
    function context:random_u64(stream)
        harness.equal(stream, "layout", "Vestibule layout stream")
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- Parsing alone misses malformed substitutions and nested feature
-- resolution. Place each source map through the real operation engine,
-- with a fresh grid so one map cannot mask another map's blocked cells.
local function place_corpus(family, branch_id)
    local paths = mod.paths("vaults/" .. family, ".des")

    for index, path in ipairs(paths) do
        local id = path:match("/([^/]+)%.des$")
        local definition = vaults.get(id)
        local builder = grid.new(context_for(1901 + index))

        -- The one-cell source fallback replaces existing floor; give every
        -- candidate the same legal parent-floor cell instead of a rock-only
        -- builder that production would never offer to that map.
        builder:set(40, 35, ".")

        local player = {
            branch_id = branch_id,
            depth = 1,
            branch_bottom = branch_id == branches.BRANCH_VESTIBULE and
                1 or 5,
            absolute_depth = 27,
        }
        local okay, result = pcall(placement.place, nil, builder,
            definition, player)

        harness.truthy(okay, path .. " placement: " .. tostring(result))
        harness.equal(result.id, id, id .. " placed identity")
    end
end

-- A bare Vestibule simulacrum uses the shared late-game zombie roster.
-- The first bounded draw selects the roster's anaconda, which cannot be
-- obtained from the Vestibule's ordinary ambient spawn list.
local function check_undead_roster()
    local context = {}

    function context:random(_, bound)
        harness.truthy(bound > 0, "zombie roster has a positive total")

        return 0
    end

    local selected = {
        name = monster_requests.RANDOM_SIMULACRUM,
        source = "Vestibule simulacrum",
    }
    local site = {
        branch_id = branches.BRANCH_VESTIBULE,
        local_depth = 1,
    }
    local result = resolve.monster(context, selected, 27, site)

    harness.equal(result.base_id, monsters.MONS_ANACONDA,
        "Vestibule corpse species comes from late zombie roster")
end

-- The source map family is complete before generation chooses a wing.
-- Each chosen wing must contribute its actual authored map to the result.
function test.run()
    check_undead_roster()
    harness.equal(#mod.paths("vaults/hell_entry", ".des"), 23,
        "pinned Hell entrance count")
    harness.equal(#mod.paths("vaults/vestibule", ".des"), 36,
        "pinned Vestibule wing count")

    place_corpus("hell_entry", branches.BRANCH_DEPTHS)
    place_corpus("vestibule", branches.BRANCH_VESTIBULE)

    local definition = catalog.get("vestibule_of_hell_subvaulted")
    local result = catalog.execute(context_for(2187), definition,
        branches.BRANCH_VESTIBULE, 1, {
            up = 0,
            down = 0,
        })
    local selected = {}

    for _, id in ipairs(result.vault_ids or {}) do
        local map = vaults.get(id)

        for tag in pairs(wing_tags) do
            if map.tags[tag] then
                selected[tag] = (selected[tag] or 0) + 1
            end
        end
    end

    for tag in pairs(wing_tags) do
        harness.equal(selected[tag], 1, tag .. " appears once")
    end

    harness.equal(result.id, definition.id, "Vestibule layout identity")
    harness.equal(#result.rows, 70, "full-sized Vestibule layout")
end

return test
