local ranged = require("policy.combat.ranged")
local monster_stats = require("policy.combat.monster_stats")
local missile_egos = require("policy.combat.monster_missile_egos")

local stone = {}
stone.show_damage = true
stone.reflectable = true

-- Stones have no ordinary coating pool, but Chaos may give one a
-- temporary brand on contact. The common validator knows that exception.
function stone.validate(item, kind_id)
    missile_egos.validate(kind_id, item)
end

-- Thrown stones use missile damage without launcher bonuses and remain eligible for reflection.
function stone.resolve(ctx, attacker, definition, defense, kind)
    return ranged.shot(ctx, {
        hd = monster_stats.hit_dice(ctx, attacker, definition),
        weapon_damage = 0,
        projectile_damage = kind.missile.damage,
        natural_damage = definition.attacks[1].damage,
    }, defense), 0, kind.name
end

return stone
