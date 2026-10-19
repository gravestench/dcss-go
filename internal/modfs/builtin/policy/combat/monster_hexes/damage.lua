local component = require("constants.component")
local monster_health = require("policy.combat.monster_health")
local player_health = require("policy.combat.player_health")

local damage = {}

function damage.apply(ctx, caster, defender, amount)
    if amount <= 0 then
        return
    end

    if ctx:has(defender, component.PLAYER) then
        player_health.damage(ctx, defender, amount, false, caster)

        return
    end

    monster_health.damage(ctx, defender, amount, caster)
end

return damage
