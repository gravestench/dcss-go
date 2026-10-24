local ranged = require("policy.combat.ranged")
local monster_stats = require("policy.combat.monster_stats")
local brands = require("policy.combat.launcher_brands")
local weapon_brands = require("constants.weapon_brands")

local sling_bullet = {}
sling_bullet.reflectable = true

-- Example: sling_bullet.validate_launcher(item) with launcher ego = 'SPWPN_FLAMING' -> validation succeeds
-- Sling bullets require a compatible launcher rather than behaving as generic thrown stones.
function sling_bullet.validate_launcher(item)
    brands.check(item.ego)
end

-- Combine launcher enchantment and bullet damage in the shared ranged contact roll.
function sling_bullet.resolve_launcher(ctx, attacker, definition, defense,
    weapon, launcher, projectile)
    return ranged.shot(ctx, {
        hd = monster_stats.hit_dice(ctx, attacker, definition),
        weapon_damage = weapon.damage,
        weapon_hit = weapon.hit,
        weapon_plus = launcher.plus,
        projectile_damage = projectile.missile.damage,
        natural_damage = definition.attacks[1].damage,
        penetrating = launcher.ego == weapon_brands.PENETRATION,
    }, defense)
end

return sling_bullet
