local catalog = require("policy.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local power = require("policy.combat.monster_beams.power")
local effects = require("policy.combat.monster_spells")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local zaps = require("constants.zap_ids")

local test = {}

local caster = 101

-- Supply real catalog identities and one live status without restating any
-- production monster or component schemas in this focused power test.
local function context(kind_id)
    local ctx = {}

    function ctx:get(entity, id)
        if entity ~= caster then
            return nil
        end

        if id == component.ACTOR then
            return { kind_id = kind_id }
        end

        if id == component.MONSTER_EMPOWERED_SPELLS then
            return { remaining_aut = 50 }
        end

        return nil
    end

    return ctx
end

-- These four zaps have distinct source damage dice, but all use the same
-- penetrating ray and natural monster HD instead of empowered spell HD.
local function source_profiles()
    local expected = {
        {
            id = spells.SPELL_FIRE_BREATH,
            zap = zaps.ZAP_FIRE_BREATH,
            divisor = 6,
        },
        {
            id = spells.SPELL_COLD_BREATH,
            zap = zaps.ZAP_COLD_BREATH,
            divisor = 6,
        },
        {
            id = spells.SPELL_SEARING_BREATH,
            zap = zaps.ZAP_SEARING_BREATH,
            divisor = 9,
        },
        {
            id = spells.SPELL_CHILLING_BREATH,
            zap = zaps.ZAP_BREATHE_FROST,
            divisor = 9,
        },
    }

    for _, entry in ipairs(expected) do
        local profile = catalog.get("monster_beams", entry.id)
        local effect = effects.effect(entry.id)

        harness.equal(profile.zap_id, entry.zap,
            entry.id .. " uses its source zap")
        harness.equal(profile.monster_damage.args[4], entry.divisor,
            entry.id .. " keeps its source damage scale")
        harness.equal(profile.monster_tohit.args[1], 30,
            entry.id .. " uses the source breath accuracy")
        harness.truthy(profile.can_beam and profile.natural_power,
            entry.id .. " pierces using natural HD")
        harness.equal(type(effect.plan), "function",
            entry.id .. " has a planning rule")
        harness.equal(type(effect.resolve), "function",
            entry.id .. " has a resolution rule")
    end

    local orc = catalog.get("monsters", monsters.MONS_ORC_WIZARD)
    local fire = catalog.get("monster_beams", spells.SPELL_FIRE_BREATH)
    local holy = catalog.get("monster_beams", spells.SPELL_HOLY_BREATH)
    local bolt = catalog.get("monster_beams", spells.SPELL_BOLT_OF_FIRE)

    harness.equal(power.caster_power(context(orc.id), caster, fire),
        orc.hd * 12,
        "natural breath ignores spell-HD brilliance")
    harness.equal(power.caster_power(context(orc.id), caster, holy),
        orc.hd * 12,
        "existing Holy Breath also uses ordinary HD")
    harness.equal(power.caster_power(context(orc.id), caster, bolt),
        (orc.hd + 5) * 12,
        "ordinary fire bolt still receives spell-HD brilliance")
end

-- Source mon-cast.cc changes breath power for draconians and Xtahua, so
-- those exceptions remain visible at the owning spell instead of a Go switch.
local function source_caster_exceptions()
    local cold = effects.effect(spells.SPELL_COLD_BREATH)
    local searing = effects.effect(spells.SPELL_SEARING_BREATH)
    local white = catalog.get("monsters", monsters.MONS_WHITE_DRACONIAN)
    local tiamat = catalog.get("monsters", monsters.MONS_TIAMAT)
    local xtahua = catalog.get("monsters", monsters.MONS_XTAHUA)

    harness.equal(power.caster_power(context(white.id), caster,
        cold.profile_for(context(white.id), caster)), white.hd * 8,
        "draconian cold breath has two-thirds source power")
    harness.equal(power.caster_power(context(tiamat.id), caster,
        cold.profile_for(context(tiamat.id), caster)), tiamat.hd * 12,
        "Tiamat is outside the source draconian range")
    harness.equal(power.caster_power(context(xtahua.id), caster,
        searing.profile_for(context(xtahua.id), caster)), xtahua.hd * 18,
        "Xtahua searing breath has three-halves source power")

    local white_ctx = context(white.id)
    local cold_profile = cold.profile_for(white_ctx, caster)

    harness.equal(cold_profile.power_multiplier.numerator, 2,
        "draconian effect carries the source multiplier")
    harness.equal(cold_profile.power_hd_factor, 12,
        "draconian effect retains the effective base factor")

    -- Work on a copy; a test must never mutate the registered content.
    local tuned = power.with_multiplier(
        catalog.get("monster_beams", spells.SPELL_COLD_BREATH), 2, 3)

    tuned.power_hd_factor = 11

    harness.equal(power.caster_power(white_ctx, caster, tuned),
        math.floor(white.hd * 11 * 2 / 3),
        "caster multiplier preserves an overlaid base power factor")
end

-- Exercise both ordinary and exceptional profiles through production Lua.
function test.run()
    source_profiles()
    source_caster_exceptions()
end

return test
