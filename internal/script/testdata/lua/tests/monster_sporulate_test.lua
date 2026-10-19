-- Sporulate tests production creation and detonation against a sparse
-- level; the saved target, summon HD, and blast all use real ECS schemas.
local attitudes = require("constants.attitude")
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local spore = require("policy.combat.monster_plants.spore")

local test = {}

-- A ballistomycete raises one short-lived spore. It detonates on contact
-- and cannot be fired a second time by the later death or expiry phases.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 20, 20, 40)
    local caster = fixture.actor(ctx,
        monsters.MONS_BALLISTOMYCETE, 5, 5, 40)
    local victim = fixture.actor(ctx, monsters.MONS_GOBLIN, 7, 5, 30)
    local game = fixture.context(ctx, player)
    local effect = effects.effect(spells.SPELL_SPORULATE)

    ctx:add(player, component.PLAYER, {})
    ctx:add(victim, component.SUMMON, {
        owner = player,
        source_id = spells.SPELL_SUMMON_SMALL_MAMMAL,
        attitude = attitudes.FRIENDLY,
        expires_aut = 500,
    })

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                game.walls[(5 + dx) .. ":" .. (5 + dy)] = true
            end
        end
    end

    game.walls["6:5"] = nil

    function game:random()
        return 0
    end

    local plan = effect.plan(game, caster, victim)

    harness.truthy(plan, "a free adjacent cell makes Sporulate legal")
    effect.resolve(game, caster, victim, nil, plan)

    local entity = ctx:query({ component.MONSTER_SPORE })[1]
    local saved = ctx:get(entity, component.MONSTER_SPORE)
    local summon = ctx:get(entity, component.SUMMON)
    local stats = ctx:get(entity, component.SUMMON_STATS)

    harness.equal(saved.target, victim, "the spore retains its foe")
    harness.equal(summon.owner, caster, "the caster owns the spore")
    harness.truthy(stats.hd >= 1,
        "the spore keeps source-derived explosion HD")
    harness.equal(summon.expires_aut, 60,
        "the spore has a short saved lifetime")

    spore.act(game, entity)

    harness.falsy(ctx:has(entity, component.ACTOR),
        "contact consumes the spore after one explosion")
    harness.truthy(ctx:get(victim, component.HEALTH).current < 30,
        "the radius-one blast deals real target damage")
    harness.falsy(spore.explode(game, entity),
        "later phases cannot detonate a consumed spore")
end

return test
