local ranged = require("policy.combat.ranged")
local monster_stats = require("policy.combat.monster_stats")

local sling_bullet = {}

local supported_brands = {
    SPWPN_NORMAL = true,
    SPWPN_FLAMING = true,
    SPWPN_FREEZING = true,
    SPWPN_VORPAL = true,
}

function sling_bullet.validate_launcher(item)
    if item.ego ~= "" and not supported_brands[item.ego] then
        error("unsupported monster launcher brand " .. item.ego)
    end
end

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
