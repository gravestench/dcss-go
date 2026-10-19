
local catalog = require("policy.catalog")
local harness = require("tests.harness")
local effects = require("policy.combat.monster_spells")
local spells = require("ids.spells")
local flavours = require("constants.beam_flavours")
local zaps = require("constants.zap_ids")

local test = {}

-- Freezing Cloud keeps its source flavor.
function test.run()
    local profiles = catalog.all("monster_beams")

    harness.equal(#profiles, 67,
        "every source monster zap has a committed profile")

    for _, profile in ipairs(profiles) do
        harness.equal(spells[profile.id], profile.id,
            "beam profile names a registered source spell")
        harness.truthy(profile.monster_tohit or profile.is_enchantment,
            "beam profile has a source hit rule")

        local effect = effects.effect(profile.id)

        harness.equal(type(effect.plan), "function",
            "beam spell has a discoverable planning method")
        harness.equal(type(effect.resolve), "function",
            "beam spell has a discoverable resolution method")
    end

    local dart = catalog.get("monster_beams", spells.SPELL_MAGIC_DART)

    harness.equal(dart.zap_id, zaps.ZAP_MAGIC_DART,
        "Magic Dart uses its source zap")
    harness.equal(dart.monster_damage.args[1], 3,
        "Magic Dart uses the monster calculator")

    local cloud = catalog.get("monster_beams", spells.SPELL_FREEZING_CLOUD)

    harness.equal(cloud.zap_id, zaps.ZAP_FREEZING_BLAST,
        "Freezing Cloud keeps its mon-cast override")
    harness.equal(cloud.flavour, flavours.BEAM_COLD,
        "Freezing Cloud keeps its source flavor")

    -- Source zap-data.h gives the metal and wooden sprays different dice,
    -- accuracy, and glyphs. Both are piercing fragmentation rays.
    local fragment_cases = {
        {
            spell_id = spells.SPELL_METAL_SPLINTERS,
            zap_id = zaps.ZAP_METAL_SPLINTERS,
            base_sides = 20,
            hit_base = 19,
        },

        {
            spell_id = spells.SPELL_SPLINTERSPRAY,
            zap_id = zaps.ZAP_SPLINTERSPRAY,
            base_sides = 15,
            hit_base = 17,
        },
    }

    for _, expected in ipairs(fragment_cases) do
        local profile = catalog.get("monster_beams", expected.spell_id)

        harness.equal(profile.zap_id, expected.zap_id,
            expected.spell_id .. " uses the source zap")
        harness.equal(profile.monster_damage.args[2], expected.base_sides,
            expected.spell_id .. " uses source base sides")
        harness.equal(profile.monster_damage.args[4], 20,
            expected.spell_id .. " scales damage by one per 20 power")
        harness.equal(profile.monster_tohit.args[1], expected.hit_base,
            expected.spell_id .. " uses source hit base")
        harness.equal(profile.flavour, flavours.BEAM_FRAG,
            expected.spell_id .. " uses triple-armour fragments")
        harness.truthy(profile.can_beam,
            expected.spell_id .. " can pierce targets")
    end
end

return test
