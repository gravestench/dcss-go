
local catalog = require("policy.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local hex = require("policy.combat.monster_spells.hex")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local beam_power = require("policy.combat.monster_beams.power")

local test = {}

local caster = 101
local foe = 202

-- Sap Magic keeps its separate source power factor.
function test.run()
    local definition = catalog.get("monsters", monsters.MONS_ORC_WIZARD)
    local ctx = {}

    -- Expose the Orc Wizard caster stats used by Sap Magic power scaling.
    function ctx:get(entity, id)
        if entity == caster and id == component.ACTOR then
            return {
                kind_id = definition.id,
            }
        end

        if entity == foe and id == component.ACTOR then
            return {
                kind_id = monsters.MONS_RAT,
            }
        end

        return nil
    end

    -- Deny optional status components so only spell profile power matters.
    function ctx:has()
        return false
    end

    -- Choose the low roll for the source power-factor boundary.
    function ctx:random(_, bound)
        return 0
    end

    local slow = catalog.get("monster_beams", spells.SPELL_SLOW)
    local agony = catalog.get("monster_beams", spells.SPELL_AGONY)
    local sap = catalog.get("monster_beams", spells.SPELL_SAP_MAGIC)
    local pain = catalog.get("monster_beams", spells.SPELL_PAIN)

    harness.equal(hex.enchantment_power(ctx, caster, slow),
        definition.hd * 4,
        "ordinary hexes use four enchantment power per caster HD")
    harness.equal(hex.enchantment_power(ctx, caster, agony),
        definition.hd * 6,
        "Agony uses the explicit source hex power factor")
    harness.equal(hex.enchantment_power(ctx, caster, sap),
        math.floor(definition.hd * 10 / 3),
        "Sap Magic keeps its separate source power factor")
    harness.equal(beam_power.caster_power(ctx, caster, pain), 150,
        "Pain has a source power floor for weak monsters")
    harness.equal(hex.enchantment_power(ctx, caster, pain), 50,
        "Pain's power floor also controls its willpower check")

    harness.truthy(hex.resisted(ctx, caster, foe, slow),
        "a monster can resist an ordinary source hex")

    -- Choose the high roll for the alternate Sap Magic resistance boundary.
    function ctx:random(_, bound)
        return bound - 1
    end

    harness.falsy(hex.resisted(ctx, caster, foe, slow),
        "a monster can fail the same source hex")
end

return test
