local ranged = require("policy.combat.ranged")

local stone = {}
stone.show_damage = true

function stone.validate(item)
    if item.ego ~= "" then
        error("unsupported monster stone ego " .. item.ego)
    end
end

function stone.resolve(ctx, definition, defense, kind)
    return ranged.shot(ctx, {
        hd = definition.hd,
        weapon_damage = 0,
        projectile_damage = kind.missile.damage,
        natural_damage = definition.attacks[1].damage,
    }, defense), 0, kind.name
end

return stone
