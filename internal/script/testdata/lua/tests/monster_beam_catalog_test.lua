local catalog = require("policy.catalog")
local harness = require("tests.harness")
local effects = require("policy.combat.monster_spells")
local spells = require("ids.spells")
local flavours = require("constants.beam_flavours")
local zaps = require("constants.zap_ids")

local test = {}

function test.run()
    local profiles = catalog.all("monster_beams")

    harness.equal(#profiles, 44,
        "every source beam spell has a committed profile")

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
end

return test
