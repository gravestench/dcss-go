-- Holy Wrath reaches undead, demonic, and Lich-form players. Their live
-- holiness can change after creation, so a species-only table is wrong.
local holiness = require("policy.character.holiness")
local health = require("policy.combat.player_health")
local roll = require("policy.combat.roll")

local brand = {}

-- The source adds one plus up to one and a half times the base hit against
-- susceptible survivors. Ordinary living players take no holy bonus.
function brand.apply(ctx, hit)
    if hit.damage_done <= 0 or
        not holiness.undead_or_demonic(ctx, hit.defender) then
        return
    end

    local bonus = 1 + math.floor(
        roll.melee(ctx, hit.damage_done * 15) / 10)

    hit.health = health.damage(ctx, hit.defender, bonus,
        false, hit.attacker)
    ctx:emit("combat", "You convulse!")
end

return brand
