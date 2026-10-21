-- Read the live catalog rather than copying Swamp definitions into tests.
-- Missing or malformed source files must fail through normal game loading.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local grid = require("policy.generation.grid")
local hooks = require("policy.generation.vaults.hooks")
local monsters = require("ids.monsters")
local placement = require("policy.generation.vaults.placement")
local tags = require("constants.vault_tags")
local regular = require("policy.generation.vaults.regular")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Give every source map its own deterministic level stream so a failed
-- directive reports the vault that produced it.
local function random_context()
    local state = 71
    local context = {}

    function context:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    return context
end

-- Run every MAP through the actual DES operation and Lua hook path. The
-- three mapless controllers are exercised by the composition test instead.
local function place_all()
    local placed = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local definition = vaults.get(id)

        if definition.family == "swamp" and #definition.rows > 0 then
            local builder = grid.new(random_context())
            local player = {
                branch_id = branches.BRANCH_SWAMP,
                depth = 2,
                branch_bottom = 4,
                absolute_depth = 16,
            }
            local okay, result = pcall(placement.place, nil, builder,
                definition, player)

            harness.truthy(okay, id .. " placement: " .. tostring(result))
            harness.truthy(result and #result.occupied > 0,
                id .. " placed no source cells")
            placed = placed + 1
        end
    end

    harness.equal(placed, 104, "every ordinary Swamp MAP places")
end

-- One source map is also eligible in Zot, where its Lua branch writes a
-- different monster palette and spells hydra head counts as words.
local function place_shared_zot_map()
    local definition = vaults.get("hangedman_swamp_dais")
    local builder = grid.new(random_context())
    local player = {
        branch_id = branches.BRANCH_ZOT,
        depth = 2,
        branch_bottom = 5,
        absolute_depth = 27,
    }
    local okay, placed = pcall(placement.place, nil, builder,
        definition, player)

    harness.truthy(okay, "shared Swamp/Zot dais: " .. tostring(placed))

    local found_role = false

    for _, record in ipairs(placed.records) do
        if record.kind == effects.MONSTER and
            record.arguments and
            record.arguments.kind_id ==
                monsters.MONS_DRACONIAN_STORMCALLER then
            harness.equal(record.arguments.base_id,
                monsters.MONS_GREEN_DRACONIAN,
                "Zot role retains its source draconian colour")
            found_role = true
        end
    end

    harness.truthy(found_role, "Zot dais placed its coloured stormcaller")
end

-- Controllers keep their source child counts and tags after splitting the
-- mapless DES declarations from their named post-place Lua handlers.
local function controller_counts()
    local expected = {
        {
            id = "swamp_ruins_default",
            tag = tags.SERIAL_SWAMP_RUIN,
            count = 1,
        },
        {
            id = "serial_swamp_ruin",
            tag = tags.SERIAL_SWAMP_RUIN,
            count = 2,
        },
        {
            id = "swamp_other_decor",
            tag = tags.DECOR,
            count = 1,
        },
    }

    for _, case in ipairs(expected) do
        local requested
        local api = {}

        function api:roll(bound)
            harness.equal(bound, 2, "serial Swamp extra-child draw")

            return 0
        end

        function api:place_maps(tag, count)
            requested = {
                tag = tag,
                count = count,
            }
        end

        hooks.run(vaults.get(case.id), "assemble", api)

        harness.equal(requested.tag, case.tag,
            case.id .. " child selection tag")
        harness.equal(requested.count, case.count,
            case.id .. " source child count")
    end
end

-- Source-authored favored scrolls must survive the named Lua hook. Merely
-- placing every MAP can miss an option inside a weighted loot declaration.
local function standing_stones_scrolls()
    local definition = vaults.get("nicolae_swamp_standing_stones")
    local operations = hooks.expand(definition, {})
    local found = false

    for _, operation in ipairs(operations) do
        if operation.kind == directives.KITEM and
            operation.argument:match("^e%s*=") then
            harness.truthy(operation.argument:find(
                "scroll of vulnerability", 1, true),
                "standing stones retains the source vulnerability scroll")
            found = true
        end
    end

    harness.truthy(found, "standing stones emits its scroll glyph")
end

-- The source rolls the head count early, then declares the hydra after the
-- plant. That declaration order is observable in saved placement records.
local function hydra_declaration_order()
    local definition = vaults.get("nicolae_swamp_hydra_murder_den")
    local builder = grid.new(random_context())
    local player = {
        branch_id = branches.BRANCH_SWAMP,
        depth = 2,
        branch_bottom = 4,
        absolute_depth = 16,
    }
    local placed = placement.place(nil, builder, definition, player)
    local plant_index
    local hydra_index

    for index, record in ipairs(placed.records) do
        if record.kind == effects.MONSTER then
            if record.identity == "plant" then
                plant_index = plant_index or index
            elseif record.identity and
                record.identity:find("-headed hydra", 1, true) then
                hydra_index = hydra_index or index
            end
        end
    end

    harness.truthy(plant_index, "murder den has its plant declaration")
    harness.truthy(hydra_index, "murder den has its hydra declaration")
    harness.truthy(plant_index < hydra_index,
        "source declares the plant before its hydra")
end

-- The complete ordinary family includes decorations, encounters and three
-- mapless controllers; their effective IDs join one ordered catalog.
function test.run()
    vaults.load()

    local count = 0

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        if vaults.get(id).family == "swamp" then
            count = count + 1
        end
    end

    harness.equal(count, 107, "all source ordinary Swamp definitions")

    local candidates = regular.candidates({
        branch_id = branches.BRANCH_SWAMP,
        depth = 2,
        branch_bottom = 4,
        absolute_depth = 16,
        branch_vault_family = "swamp",
    })

    harness.truthy(#candidates > 0,
        "ordinary Swamp maps enter the weighted live selector")

    place_all()
    place_shared_zot_map()
    controller_counts()
    standing_stones_scrolls()
    hydra_declaration_order()
end

return test
