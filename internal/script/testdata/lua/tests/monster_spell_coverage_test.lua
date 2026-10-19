
local coverage = require("policy.combat.monster_spell_coverage")
local catalog = require("policy.catalog")
local effects = require("policy.combat.monster_spells")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local roster = require("policy.population.roster")
local spells = require("ids.spells")

local test = {}

-- These source spellbook IDs form the self and ally support families. Their own modules
-- must expose both phases, so content can become castable without a dispatcher
-- accumulating a branch for every individual spell.
local support_ids = {
    spells.SPELL_MIGHT,
    spells.SPELL_INVISIBILITY,
    spells.SPELL_HASTE,
    spells.SPELL_MINOR_HEALING,
    spells.SPELL_MAJOR_HEALING,
    spells.SPELL_REPEL_MISSILES,
    spells.SPELL_BERSERKER_RAGE,
    spells.SPELL_SPRINT,
    spells.SPELL_TROGS_HAND,
    spells.SPELL_INJURY_MIRROR,
    spells.SPELL_WOODWEAL,
    spells.SPELL_STILL_WINDS,
    spells.SPELL_AURA_OF_BRILLIANCE,
    spells.SPELL_HASTE_OTHER,
    spells.SPELL_MIGHT_OTHER,
    spells.SPELL_INVISIBILITY_OTHER,
    spells.SPELL_HEAL_OTHER,
}

-- The source book slots cannot enter active rosters until both phases exist.
local function support_has_complete_resolvers()
    for _, spell_id in ipairs(support_ids) do
        local okay, effect = pcall(effects.effect, spell_id)

        harness.truthy(okay, spell_id .. " resolver loads")
        harness.truthy(type(effect.plan) == "function",
            spell_id .. " has a plan phase")
        harness.truthy(type(effect.resolve) == "function",
            spell_id .. " has a resolve phase")
    end
end

-- The active generated roster must have resolvers for every castable slot.
local function active_roster_has_effects()
    local ids = roster.allowed("generated-dungeon-basic-v1")
    local missing = coverage.missing(ids)

    harness.equal(#missing, 0,
        "every active generated monster has its spell effects")
end

-- The Orc Wizard's source book is complete once its self-support effect
-- joins the already implemented beam slots.
local function imported_beam_book_is_covered()
    local missing = coverage.missing({
        [monsters.MONS_ORC_WIZARD] = true,
    })

    harness.equal(#missing, 0,
        "the orc wizard has every committed book resolver")

    for _, record in ipairs(missing) do
        harness.falsy(record.spell_id == spells.SPELL_MAGIC_DART or
            record.spell_id == spells.SPELL_THROW_FLAME,
            "the imported beam slots no longer appear missing")
    end
end

-- Substitute an incomplete effect module and require coverage to report its missing resolver.
local function malformed_effect_is_reported()
    local original = effects.effect

    -- Advertise a deliberately incomplete effect module to test startup coverage.
    effects.effect = function()
        return {
            -- Provide a plan but omit resolve so coverage names the missing method.
            plan = function()
                return {}
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

-- Adding a caster to the roster surfaces its missing effects with its ID.
local function newly_admitted_monster_requires_effects()
    local sorcerer = catalog.get("monsters", monsters.MONS_ORC_SORCERER)
    local original_get = register.get

    sorcerer.population[#sorcerer.population + 1] = {
        scenario_id = "generated-dungeon-basic-v1",
    }

    -- Expose the newly admitted Sorcerer while all other monster IDs use the real registry.
    register.get = function(category, id)
        if category == "monsters" and id ==
            monsters.MONS_ORC_SORCERER then
            return sorcerer
        end

        return original_get(category, id)
    end

    local okay, problem = pcall(roster.allowed,
        "generated-dungeon-basic-v1")

    register.get = original_get

    harness.falsy(okay, "newly admitted caster needs live effects")
    harness.truthy(tostring(problem):find(monsters.MONS_ORC_SORCERER,
        1, true), "coverage error names the monster")
end

-- Generated monsters cannot carry a spellbook slot without a Lua effect module.
function test.run()
    support_has_complete_resolvers()
    active_roster_has_effects()
    imported_beam_book_is_covered()
    malformed_effect_is_reported()
    newly_admitted_monster_requires_effects()
end

return test
