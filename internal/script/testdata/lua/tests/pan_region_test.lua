-- Region construction uses the same committed Pan map, layout catalog,
-- placement rules, and source records that portal travel will install.
local branches = require("ids.branches")
local catalog = require("policy.generation.vaults.catalog")
local harness = require("tests.harness")
local region = require("policy.generation.pan.region")
local scenario = require("policy.generation.scenario")
local component = require("constants.component")
local rune_ids = require("constants.runes")
local species = require("ids.species")

local test = {}

-- Supply the saved layout stream without making filesystem traversal or
-- module-load order part of the Pan region's random sequence.
local function context()
    local state = 91
    local result = {}

    function result:random_u64()
        state = (state * 48271) % 2147483647
        local high = state

        state = (state * 48271) % 2147483647

        return high, state
    end

    function result:random(_, bound)
        return self:random_u64() % bound
    end

    return result
end

-- A regular source primary overlays a Pan layout and contributes its
-- authored records; its entry is a traversable cell on the finished grid.
local function check_regular_primary()
    local source = context()
    local map = catalog.get("rand_demon_1")
    local built = region.build_primary(source, map, {
        prior_vault_ids = {},
        collected_runes = {},
        pan_rune_count = 0,
    })

    harness.equal(built.map.id, map.id, "selected Pan primary was placed")
    harness.truthy(built.layout_id, "regular Pan primary has a base layout")
    harness.truthy(built.builder:cell(built.entry.x, built.entry.y) == ".",
        "Pan entry is traversable")
    harness.truthy(#built.records > 0, "Pan source records survive placement")
end

-- An encompassing source primary supplies the whole region, so another
-- layout cannot obscure its authored geometry or duplicate its primary.
local function check_encompassing_primary()
    local source = context()
    local map = catalog.get("evilmike_holy_pan")
    local built = region.build_primary(source, map, {
        prior_vault_ids = {},
        collected_runes = {},
        pan_rune_count = 0,
    })

    harness.equal(built.map.id, map.id, "holy Pan map is primary")
    harness.equal(built.layout_id, nil,
        "encompassing Pan primary has no second layout")
    harness.truthy(built.builder:cell(built.entry.x, built.entry.y) == ".",
        "encompassing Pan entry is traversable")
end

-- Each named lord realm must fit a source Pan base independently. These
-- four paths exercise source orientation and lord hook facts before travel
-- can request one of them from the mandatory primary selector.
local function check_lord_primaries()
    local ids = {
        "mnoleg",
        "lom_lobon",
        "cerebov",
        "gloorx_vloq",
    }

    for _, id in ipairs(ids) do
        local built = region.build_primary(context(), catalog.get(id), {
            prior_vault_ids = {},
            collected_runes = {},
            pan_rune_count = 0,
        })

        harness.equal(built.map.id, id, "Pan lord primary " .. id)
        harness.truthy(built.builder:cell(built.entry.x, built.entry.y) == ".",
            "Pan lord entry is traversable " .. id)
    end
end

-- The assembled record is consumable by the same level decoder and
-- population owner as another generated branch floor. Selection, geometry,
-- extras, and the source three-die budget share a single saved RNG context.
local function check_generated_region()
    local result = scenario.pan(context(), {
        levels_seen = 0,
        prior_vault_ids = {},
        collected_runes = {},
        pan_rune_count = 0,
    })
    local generated = result.level

    harness.equal(generated.branch_id, branches.BRANCH_PANDEMONIUM,
        "Pan region branch")
    harness.equal(generated.local_depth, 1, "Pan repeats local depth one")
    harness.equal(#generated.cells, 70, "Pan grid height")
    harness.equal(#generated.cells[1], 80, "Pan grid width")
    harness.truthy(generated.vault_id, "Pan has a primary vault")
    harness.truthy(#generated.vault_ids > 0, "Pan stores map history")
    harness.truthy(generated.initial_monsters >= 3 and
        generated.initial_monsters <= 24, "Pan uses three eight-sided dice")
end

-- Live generation reads the saved ECS rune set rather than trusting a
-- duplicate Go-side rune count. This is the call shape portal travel uses.
local function check_live_player_facts()
    local source = context()
    local player = 7
    local progress = {
        collected = {
            [rune_ids.DEMONIC] = true,
        },
    }

    function source:player()
        return player
    end

    function source:get(entity, schema)
        harness.equal(entity, player, "Pan reads the live player")

        if schema == component.PLAYER then
            return {
                species_id = species.SP_HUMAN,
                name = "Pan Tester",
            }
        end

        if schema == component.PLAYER_RUNES then
            return progress
        end

        return nil
    end

    local result = scenario.pan(source, {
        levels_seen = 1,
        prior_vault_ids = {},
    })

    harness.truthy(result.level.vault_id,
        "Pan generation accepts live character facts")
    harness.equal(result.level.id, region.level_id(1),
        "a later live region uses its own storage ID")
end

-- Staging a second region beside the still-live first one requires a
-- distinct storage ID. The old region is retired only after population and
-- travel succeed, so generation cannot overwrite its level in place.
local function check_region_ids()
    local first = region.level_id(0)
    local second = region.level_id(1)

    harness.truthy(first ~= second,
        "successive Pan regions have distinct storage IDs")
end

function test.run()
    harness.truthy(branches.BRANCH_PANDEMONIUM, "Pan branch exists")
    catalog.load()
    check_regular_primary()
    check_encompassing_primary()
    check_lord_primaries()
    check_generated_region()
    check_live_player_facts()
    check_region_ids()
end

return test
