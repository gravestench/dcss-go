-- Exercise the source decision points without duplicating their DES maps.
-- These assertions pin the actual emitted directive arguments as well as
-- each handler's source probability branch and output order.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local harness = require("tests.harness")
local loot = require("policy.generation.vaults.spider_end.shared")
local water = require("policy.generation.vaults.spider_end.spider_rune_water")
local arachne = require(
    "policy.generation.vaults.spider_end.johnstein_spider_rune_arachne_lair")
local ruins = require(
    "policy.generation.vaults.spider_end.hellmonk_spider_rune_bug_friends")
local tomb = require(
    "policy.generation.vaults.spider_end.floodkiller_spider_rune_tomb")

local test = {}

-- Feed source chance results in order and capture only the public hook API.
local function run(method, decisions)
    local emitted = {}
    local recorded = {}
    local api = {}
    local index = 0

    function api:one_in(bound)
        index = index + 1
        harness.truthy(bound == 2 or bound == 3,
            "source decision uses one-in-two or one-in-three")

        return decisions[index]
    end

    function api:coinflip()
        index = index + 1

        return decisions[index]
    end

    function api:emit(kind, argument)
        emitted[#emitted + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    function api:record(kind, arguments)
        recorded[#recorded + 1] = {
            kind = kind,
            arguments = arguments,
        }
    end

    method(api)

    return emitted, recorded, index
end

-- Check the shared rewards and both source water alternatives.
local function check_shared_and_water()
    local rewards = run(loot.loot, {})

    harness.equal(#rewards, 3, "three source loot requests")
    harness.equal(rewards[1].kind, directives.ITEM, "ambrosia request")
    harness.equal(rewards[1].argument, "potion of ambrosia ident:all",
        "source ambrosia text")
    harness.equal(rewards[2].kind, directives.ITEM, "weighted potions")
    harness.equal(rewards[3].kind, directives.ITEM, "auxiliary gear")

    local flooded = run(water.choose_water, { true })
    local open = run(water.choose_water, { false })

    harness.equal(flooded[1].argument, "W = WW.", "flooded water branch")
    harness.equal(open[1].argument, "W = W..", "open water branch")
end

-- Check all themes and both independent three-way source decisions.
local function check_themes()
    local blue = run(arachne.choose_theme, { true })
    local red = run(arachne.choose_theme, { false, true })
    local brown = run(arachne.choose_theme, { false, false })

    harness.equal(#blue, 7, "blue theme directives")
    harness.equal(#red, 7, "red theme directives")
    harness.equal(#brown, 7, "brown theme directives")
    harness.equal(blue[3].argument, "Y = FLOOR_HALL", "blue hall floor")
    harness.equal(red[3].argument, "Y = FLOOR_ROUGH_RED", "red rough floor")
    harness.equal(brown[3].argument, "Y = FLOOR_SANDSTONE",
        "brown sandstone floor")

    local monsters_first = run(ruins.choose_monsters, { true })
    local monsters_second = run(ruins.choose_monsters, { false, true })
    local monsters_third = run(ruins.choose_monsters, { false, false })
    local terrain_first = run(ruins.choose_ruins, { true })
    local terrain_second = run(ruins.choose_ruins, { false, true })
    local terrain_third = run(ruins.choose_ruins, { false, false })

    harness.equal(monsters_first[1].argument, "7 = 44456",
        "first monster bias")
    harness.equal(monsters_second[1].argument, "7 = 45556",
        "second monster bias")
    harness.equal(monsters_third[1].argument, "7 = 45666",
        "third monster bias")
    harness.equal(terrain_first[1].argument, "A = cc.", "first ruin bias")
    harness.equal(terrain_second[1].argument, "A = c.", "second ruin bias")
    harness.equal(terrain_third[1].argument, "A = c..", "third ruin bias")
end

-- A feature label is a saved typed record, not a change to collision terrain.
local function check_tomb_name()
    local emitted, recorded = run(tomb.sarcophagus_name, {})

    harness.equal(#emitted, 0, "tomb does not replace terrain")
    harness.equal(#recorded, 1, "one feature name record")
    harness.equal(recorded[1].kind, effects.FEATURE_NAME, "typed name")
    harness.equal(recorded[1].arguments.name, "sarcophagus", "source name")
end

-- Keep source choices and the named feature effect in one slice test.
function test.run()
    check_shared_and_water()
    check_themes()
    check_tomb_name()
end

return test
