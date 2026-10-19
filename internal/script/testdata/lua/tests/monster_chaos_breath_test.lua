local clouds = require("ids.clouds")
local component = require("constants.component")
local contact = require("policy.combat.monster_beams.contact")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local flavours = require("constants.beam_flavours")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local effect = require("policy.combat.monster_spells.chaos_breath")

local test = {}

-- A natural chaos breath keeps its contacted victim and cloud endpoint
-- on the same saved ray, with source cloud size in the 8..12 interval.
function test.run(ctx)
    local caster = fixture.actor(ctx, monsters.MONS_APOCALYPSE_CRAB, 5, 8)
    local victim = fixture.actor(ctx, monsters.MONS_ORC, 10, 8)
    local game = fixture.context(ctx, victim)
    local plan = effect.plan(game, caster, victim)

    harness.truthy(plan, "Chaos Breath has a live ray plan")
    effect.resolve(game, caster, victim, nil, plan)
    local count = 0

    for _, cloud in ipairs(ctx:query({ component.WORLD_CLOUD })) do
        local state = ctx:get(cloud, component.WORLD_CLOUD)

        harness.equal(state.kind_id, clouds.CLOUD_CHAOS,
            "breath endpoint places only chaos clouds")
        harness.equal(state.source_actor_id, ctx:id(caster),
            "chaos clouds credit their caster")
        count = count + 1
    end

    harness.truthy(count >= 8 and count <= 12,
        "chaos cloud uses source variable size")

    local old_contact = contact.resolve
    local selected

    contact.resolve = function(_, _, _, source_profile)
        selected = source_profile

        return { kind = "hit" }
    end
    effect.contact(game, caster, victim,
        catalog.get(categories.MONSTER_BEAMS,
            spells.SPELL_CHAOS_BREATH), 20, 30, flavours.BEAM_FIRE)
    contact.resolve = old_contact
    harness.equal(selected.flavour, flavours.BEAM_FIRE,
        "chaos contact replaces flavour before resistance")
    harness.equal(selected.monster_damage.args[4], 8,
        "chaos contact retains breath's 1d8 dice")
end

return test
