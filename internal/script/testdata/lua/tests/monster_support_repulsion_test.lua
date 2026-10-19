local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local player_attack = require("policy.combat.player_attack")
local repulsion = require("policy.combat.monster_support.repulsion")
local spells = require("ids.spells")

local test = {}

-- Keep the attack's actual ECS reads while choosing fixed hit dice so the
-- repulsion modifier can be isolated from unrelated player accuracy rolls.
local function attack_context(ctx, player)
    local proxy = setmetatable({}, { __index = ctx })
    local draws = { 12, 50, 0 }
    local index = 0

    function proxy.player()
        return player
    end

    function proxy.random(_, _, bound)
        index = index + 1

        return math.min(draws[index] or 0, bound - 1)
    end

    return proxy
end

-- Source Repel Missiles reduces a projectile's post-roll accuracy and
-- persists until dispelled; it does not need a guessed duration timer.
function test.run(ctx)
    local monster = ctx:create()
    local player = ctx:create()

    ctx:add(monster, component.ACTOR, {
        kind_id = monsters.MONS_ORC_SORCERER,
        speed = 10,
    })

    local effect = effects.effect(spells.SPELL_REPEL_MISSILES)
    local plan = effect.plan(ctx, monster)

    effect.resolve(ctx, monster, player, nil, plan)

    harness.truthy(repulsion.active(ctx, monster),
        "Repel Missiles is saved on its caster")
    harness.falsy(effect.plan(ctx, monster),
        "active repulsion does not waste another spell slot")

    local input = {
        dexterity = 10,
        fighting100 = 0,
        weapon100 = 0,
        using_weapon = false,
        defender_ev = 8,
    }

    local ordinary = player_attack.contact(
        attack_context(ctx, player), input)

    harness.equal(ordinary.kind, "hit",
        "the fixed projectile contacts without protection")

    input.missile_repulsion = repulsion.active(ctx, monster)

    local protected = player_attack.contact(
        attack_context(ctx, player), input)

    harness.equal(protected.kind, "miss",
        "repulsion turns that same projectile into a miss")
end

return test
