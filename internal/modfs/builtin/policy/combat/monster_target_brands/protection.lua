-- Source attack.cc refreshes a short player aura on each qualifying hit.
local component = require("constants.component")
local flags = require("constants.monster_flags")
local protection = require("policy.combat.player_weapon_protection")

local brand = {
    after_death = true,
}

-- Harmless stationary monsters are source firewood and cannot refresh
-- the aura; a lethal hit against a real monster still can.
local function firewood(definition)
    local stationary = false
    local harmless = false

    for _, flag in ipairs(definition.flags or {}) do
        stationary = stationary or flag == flags.STATIONARY
        harmless = harmless or flag == flags.NO_THREAT
    end

    return stationary and harmless
end

-- Protection is triggered by contact rather than damage, so a zero-damage
-- strike on a real target can still raise the player's defense.
function brand.apply(ctx, hit)
    if ctx:has(hit.attacker, component.PLAYER) and
        not firewood(hit.definition) then
        protection.refresh(ctx, hit.attacker)
    end
end

return brand
