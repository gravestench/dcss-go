-- Theory of operation: arrows and bolts use the same monster launcher
-- formula. Their catalog definitions supply projectile damage while the
-- equipped bow or crossbow supplies weapon damage, accuracy, enchantment,
-- and brand. Reflection reuses this exact resolver against the shooter.
local brands = require("policy.combat.launcher_brands")
local weapon_brands = require("constants.weapon_brands")
local ranged = require("policy.combat.ranged")
local monster_stats = require("policy.combat.monster_stats")

local launched = {
    reflectable = true,
}

-- Reject an ego whose post-hit policy is absent before the monster spends
-- a turn or consumes contact rolls on a shot that cannot resolve.
local function validate_launcher(item)
    brands.check(item.ego or "")
end

-- Apply source launcher and ammunition stats through the shared ranged
-- contact calculation; it already handles EV, shield, armour, and repulsion.
local function resolve_launcher(ctx, attacker, definition, defense,
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

launched.validate_launcher = validate_launcher
launched.resolve_launcher = resolve_launcher

return launched
