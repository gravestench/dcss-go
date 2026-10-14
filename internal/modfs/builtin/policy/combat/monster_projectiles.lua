local monster_projectiles = {}

function monster_projectiles.effect(kind_id)
    local name = kind_id:match("^MI_(.+)$")

    if not name then
        error("invalid monster missile " .. tostring(kind_id))
    end

    return require("policy.combat.monster_projectiles." .. name:lower())
end

return monster_projectiles
