local roll = require("policy.combat.roll")
local player_health = require("policy.combat.player_health")
local magic_damage = require("policy.magic.damage")
local resistances = require("constants.resistance_ids")

local brand = {
    after_death = true,
}

function brand.apply(ctx, hit)
    if hit.damage_done == 0 then
        return
    end

    local bonus = 1 + math.floor(roll.melee(ctx, hit.damage_done) / 2)
    bonus = magic_damage.player_elemental(ctx, hit.defender,
        bonus, resistances.COLD)
    hit.health = player_health.damage(ctx, hit.defender, bonus,
        false, hit.attacker)
    ctx:emit("combat", "The " .. hit.attacker_name .. " freezes you.")
end

return brand
