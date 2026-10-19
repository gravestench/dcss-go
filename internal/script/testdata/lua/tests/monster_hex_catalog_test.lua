local catalog = require("policy.catalog")
local effects = require("policy.combat.monster_spells")
local harness = require("tests.harness")
local spells = require("ids.spells")

local test = {}

local names = {
    "AGONY",
    "AGONY_RANGE",
    "BANISHMENT",
    "CONFUSE",
    "CORONA",
    "DIMENSION_ANCHOR",
    "DRAIN_MAGIC",
    "MINDBURST",
    "PAIN",
    "PARALYSE",
    "POLYMORPH",
    "SENTINEL_MARK",
    "SLOW",
    "STRIP_WILLPOWER",
    "VIRULENCE",
    "SAP_MAGIC",
}

function test.run()
    for _, name in ipairs(names) do
        local id = spells["SPELL_" .. name]
        local profile = catalog.get("monster_beams", id)
        local effect = effects.effect(id)

        harness.equal(profile.id, id,
            "source hex profile uses the canonical spell ID")
        harness.equal(type(effect.plan), "function",
            "source hex has a planning method")
        harness.equal(type(effect.resolve), "function",
            "source hex has a resolution method")
    end
end

return test
