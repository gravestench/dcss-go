local items = require("ids.items")
local monster_projectiles = {}

-- Bows and crossbows differ in their catalog weapon stats but use one
-- contact-and-damage rule. Other missile IDs still discover their own Lua
-- policy module by name, so mods can add a new behavior with one file.
local shared_policies = {
    [items.MI_ARROW] = "launched",
    [items.MI_BOLT] = "launched",
}

-- Example: monster_projectiles.effect(kind_id) with invalid missile ID -> resolver lookup error
-- MI_ missile ids map to dedicated projectile policies; invalid ids fail before a ranged action resolves.
function monster_projectiles.effect(kind_id)
    local name = kind_id:match("^MI_(.+)$")

    if not name then
        error("invalid monster missile " .. tostring(kind_id))
    end

    local policy = shared_policies[kind_id] or name:lower()

    return require("policy.combat.monster_projectiles." .. policy)
end

return monster_projectiles
