-- Bailey entry hooks make the weapon choice once, then use that same
-- choice for decorations and the saved marker. A second independent
-- choice would let the gate send the player to the wrong themed map.
local directives = require("constants.vault_directives")
local harness = require("tests.harness")

local test = {}

-- Exercise the real Lua hook with a known source RNG stream. The collector
-- only captures the production directives that placement would consume.
local function run_entry(method, draws)
    local shared = require("policy.generation.vaults.bailey_entry.shared")
    local emitted = {}
    local records = {}
    local index = 0
    local api = {}

    function api:roll(bound)
        index = index + 1

        harness.truthy(draws[index] < bound,
            "Bailey hook draw is outside its source bound")

        return draws[index]
    end

    function api:emit(kind, argument)
        emitted[#emitted + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    function api:record(kind, value)
        records[#records + 1] = {
            kind = kind,
            value = value,
        }
    end

    shared[method](api)

    harness.equal(index, 2,
        "Bailey entrance must draw theme then duration once")

    return emitted, records
end

-- The source's small weapon room leaves a hand axe for an axe gate and
-- a spear or halberd for a polearm gate, before the timed marker exists.
function test.run()
    local axe = run_entry("entry_2", { 0, 0 })
    local polearm = run_entry("entry_2", { 1, 200 })

    harness.equal(axe[1].kind, directives.ITEM,
        "axe room emits its weapon before the gate")
    harness.equal(axe[1].argument, "hand axe",
        "axe room keeps source weapon")
    harness.equal(polearm[1].argument, "halberd / spear",
        "polearm room keeps source weapon alternatives")

    harness.truthy(axe[2].argument:find('bailey_type = "axe"', 1, true),
        "axe marker retains the chosen theme")
    harness.truthy(axe[2].argument:find("low = 600", 1, true),
        "minimum lifetime follows the theme draw")
    harness.truthy(polearm[2].argument:find(
        'bailey_type = "polearm"', 1, true),
        "polearm marker retains the chosen theme")
    harness.truthy(polearm[2].argument:find("low = 800", 1, true),
        "maximum lifetime follows the theme draw")

    -- The source defines this shared support loadout even though no
    -- built-in destination currently calls it. A modded axe Bailey may.
    local destinations = require("policy.generation.vaults.bailey.shared")
    local support = {}

    destinations.axe_returning({
        emit = function(_, kind, argument)
            support[#support + 1] = {
                kind = kind,
                argument = argument,
            }
        end,
    })

    harness.equal(support[1].kind, directives.MONS,
        "returning support remains a monster loadout")
    harness.truthy(support[1].argument:find("hobgoblin", 1, true),
        "returning support retains the source hobgoblin alternative")

    -- This one axe keep writes scrolls before potions in its source
    -- expression. Reversing the alternatives changes seeded rewards.
    local reward

    destinations.loot_scrolls_then_potions({
        emit = function(_, _, argument)
            reward = argument
        end,
    })

    harness.truthy(reward:find("scroll of teleportation", 1, true) <
        reward:find("potion of haste", 1, true),
        "the axe keep keeps the source loot alternative order")

    -- The two statue approaches record a local name and tile from the
    -- same theme draw used by their portal marker.
    local statue, names = run_entry("entry_6", { 1, 100 })

    harness.equal(names[1].value.name,
        "granite statue wielding a fearsome trident",
        "polearm statue keeps its source name")
    harness.equal(statue[1].argument,
        "G = dngn_statue_polearm",
        "polearm statue keeps its source tile")
    harness.truthy(statue[2].argument:find(
        'bailey_type = "polearm"', 1, true),
        "statue and marker share one theme")

    -- The vampire castle keeps its delayed skeleton and gravestone
    -- intent as typed records for population and save/restore.
    local castle = require("policy.generation.vaults.bailey." ..
        "bailey_polearm_vampire_castle_hellmonk")
    local effects = require("constants.vault_effects")
    local castle_records = {}
    local record_api = {
        record = function(_, kind, value)
            castle_records[#castle_records + 1] = {
                kind = kind,
                value = value,
            }
        end,
    }

    castle.decay(record_api)
    castle.dead_tree(record_api)
    castle.gravestone(record_api)

    harness.equal(castle_records[1].kind, effects.DELAYED_DECAY,
        "vampire castle retains delayed skeletons")
    harness.equal(castle_records[1].value.alternatives, "orc skeleton",
        "vampire castle skeleton species")
    harness.equal(castle_records[3].value.name, "a gravestone",
        "vampire castle retains local statue name")
end

return test
