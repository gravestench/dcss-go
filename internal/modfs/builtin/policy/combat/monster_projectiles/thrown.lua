-- Ordinary monster-thrown missiles share contact, damage, reflection,
-- and Chaos post-hit effects. The catalog supplies each missile's damage;
-- an authored specialty can still replace this policy with its own file.
local missile_egos = require("policy.combat.monster_missile_egos")
local monster_stats = require("policy.combat.monster_stats")
local ranged = require("policy.combat.ranged")

local thrown = {
    reflectable = true,
    show_damage = true,
}

-- Source boomerangs and javelins share contact, then dispatch their saved
-- missile ego through the same post-hit owner as other thrown stacks.
function thrown.validate(item, kind_id)
    missile_egos.validate(kind_id, item)
end

-- Thrown ammo has no launcher bonus; its item catalog damage and the
-- monster's ordinary attack profile feed the same ranged contact rule.
function thrown.resolve(ctx, attacker, definition, defense, kind)
    local outcome = ranged.shot(ctx, {
        hd = monster_stats.hit_dice(ctx, attacker, definition),
        weapon_damage = 0,
        projectile_damage = kind.missile.damage,
        natural_damage = definition.attacks[1].damage,
    }, defense)

    return outcome, 0, kind.name
end

return thrown
