local holiness = require("constants.monster_holiness")
local monsters = require("ids.monsters")
local roll = require("policy.combat.roll")

local brand = {
    requires_damage = true,
}

local function susceptible(definition)
    -- Source: monster.cc:3748-3760. The profane servitor is undead but
    -- has exceptional positive holy-energy resistance.
    if definition.id == monsters.MONS_PROFANE_SERVITOR then
        return false
    end

    for _, kind in ipairs(definition.holiness or {}) do
        if kind == holiness.UNDEAD or kind == holiness.DEMONIC then
            return true
        end
    end

    return false
end

brand.susceptible = susceptible

function brand.apply(ctx, hit, brands)
    -- Source: attack.cc:1393-1397. Holy wrath has no roll on living foes.
    if not susceptible(hit.definition) then
        return
    end

    local bonus = 1 + math.floor(roll.melee(ctx, hit.damage_done * 15) / 10)
    brands.damage(ctx, hit, bonus)
    ctx:emit("combat", "The " .. hit.definition.name .. " convulses!")
end

return brand
