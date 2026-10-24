local ranged = require("policy.combat.ranged")
local monster_stats = require("policy.combat.monster_stats")
local brands = require("constants.weapon_brands")

local sling_bullet = {}
sling_bullet.reflectable = true

local supported_brands = {
    [brands.NORMAL] = true,
    [brands.FLAMING] = true,
    [brands.FREEZING] = true,
    [brands.VORPAL] = true,
    [brands.CHAOS] = true,
}

-- Example: sling_bullet.validate_launcher(item) with launcher ego = 'SPWPN_FLAMING' -> validation succeeds
-- Sling bullets require a compatible launcher rather than behaving as generic thrown stones.
function sling_bullet.validate_launcher(item)
    if item.ego ~= "" and not supported_brands[item.ego] then
        error("unsupported monster launcher brand " .. item.ego)
    end
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
    }, defense)
end

return sling_bullet
