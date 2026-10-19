
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

    -- Validate every effective profile rather than pinning a count. New
    -- source or modded beams can register without editing this test.
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

    local flame = catalog.get("monster_beams",
        spells.SPELL_FLAMING_CLOUD)
    local dust = catalog.get("monster_beams",
        spells.SPELL_PETRIFYING_CLOUD)

    harness.equal(flame.zap_id, zaps.ZAP_FLAMING_CLOUD,
        "Flaming Cloud uses its source zap")
    harness.truthy(flame.natural_power and flame.can_beam,
        "Flaming Cloud is a natural penetrating breath")
    harness.equal(flame.monster_damage.args[4], 8,
        "Flaming Cloud has source 1d(power/8) damage")
    harness.equal(dust.zap_id, zaps.ZAP_PETRIFYING_CLOUD,
        "Petrifying Cloud uses its source zap")
    harness.equal(dust.monster_damage.args[1], 2,
        "Petrifying Cloud rolls two damage dice")
    harness.equal(dust.monster_damage.args[2], 6,
        "Petrifying Cloud uses fixed six-sided dice")
    harness.equal(dust.flavour, flavours.BEAM_PETRIFYING_CLOUD,
        "Petrifying Cloud has a distinct cloud-trail flavour")

    local spectral = catalog.get("monster_beams",
        spells.SPELL_SPECTRAL_CLOUD)

    harness.equal(spectral.monster_damage.args[1], 0,
        "Spectral Cloud's ray does no direct damage")
    harness.truthy(spectral.can_beam,
        "Spectral Cloud pierces before leaving mist")
end

return test
