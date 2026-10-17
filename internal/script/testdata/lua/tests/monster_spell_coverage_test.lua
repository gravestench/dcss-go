local coverage = require("policy.combat.monster_spell_coverage")
local catalog = require("policy.catalog")
local effects = require("policy.combat.monster_spells")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local roster = require("policy.population.roster")
local spells = require("ids.spells")

local test = {}

local function active_roster_has_effects()
    local ids = roster.allowed("generated-dungeon-basic-v1")
    local missing = coverage.missing(ids)

    harness.equal(#missing, 0,
        "every active generated monster has its spell effects")
end

local function unused_book_does_not_block_launch()
    local missing = coverage.missing({
        [monsters.MONS_ORC_WIZARD] = true,
    })
    local found = false

    for _, record in ipairs(missing) do
        if record.monster_id == monsters.MONS_ORC_WIZARD and
            record.spell_id == spells.SPELL_MAGIC_DART then
            found = true
            harness.truthy(record.reason:find("missing", 1, true),
                "missing effect has an explicit reason")
        end
    end

    harness.truthy(found, "unimplemented source book is reported")
end

local function malformed_effect_is_reported()
    local original = effects.effect

    effects.effect = function()
        return {
            can_cast = function()
                return true
            end,
        }
    end

    local missing = coverage.missing({
        [monsters.MONS_ENDOPLASM] = true,
    })

    effects.effect = original

    harness.equal(#missing, 1, "malformed effect is counted")
    harness.equal(missing[1].spell_id, spells.SPELL_FREEZE,
        "malformed effect names its spell")
    harness.truthy(missing[1].reason:find("resolve", 1, true),
        "malformed effect names the missing method")
end

local function newly_admitted_monster_requires_effects()
    local wizard = catalog.get("monsters", monsters.MONS_ORC_WIZARD)
    local original_get = register.get

    wizard.population[#wizard.population + 1] = {
        scenario_id = "generated-dungeon-basic-v1",
    }

    register.get = function(category, id)
        if category == "monsters" and id == monsters.MONS_ORC_WIZARD then
            return wizard
        end

        return original_get(category, id)
    end

    local okay, problem = pcall(roster.allowed,
        "generated-dungeon-basic-v1")

    register.get = original_get

    harness.falsy(okay, "newly admitted caster needs live effects")
    harness.truthy(tostring(problem):find(monsters.MONS_ORC_WIZARD,
        1, true), "coverage error names the monster")
end

function test.run()
    active_roster_has_effects()
    unused_book_does_not_block_launch()
    malformed_effect_is_reported()
    newly_admitted_monster_requires_effects()
end

return test
