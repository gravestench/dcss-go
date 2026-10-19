local monster_projectiles = {}

-- Example: monster_projectiles.effect(kind_id) with invalid missile ID -> resolver lookup error
-- MI_ missile ids map to dedicated projectile policies; invalid ids fail before a ranged action resolves.
function monster_projectiles.effect(kind_id)
    local name = kind_id:match("^MI_(.+)$")

    if not name then
        error("invalid monster missile " .. tostring(kind_id))
    end

    return require("policy.combat.monster_projectiles." .. name:lower())
end

return monster_projectiles
