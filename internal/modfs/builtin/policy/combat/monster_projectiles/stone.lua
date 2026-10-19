local ranged = require("policy.combat.ranged")
local monster_stats = require("policy.combat.monster_stats")

local stone = {}
stone.show_damage = true
stone.reflectable = true

-- Example: stone.validate(item) with item.ego = 'poisoned' -> validation error
-- Thrown stones validate missile identity before the ranged action uses its combat profile.
function stone.validate(item)
    if item.ego ~= "" then
        error("unsupported monster stone ego " .. item.ego)
    end
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
