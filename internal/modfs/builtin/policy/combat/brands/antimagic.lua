local roll = require("policy.combat.roll")

local brand = {}

function brand.apply(ctx, hit)
    local magic = ctx:get(hit.defender, "core.magic")

    if not magic or magic.current <= 0 then
        return
    end

    -- attack.cc:1543-1545 passes damage * 8 to BEAM_DRAIN_MAGIC.
    -- beam.cc:3578-3585 drains random2avg(power / 8, 3) MP.
    local amount = roll.average_three(ctx, "melee", hit.damage_done)
    amount = math.min(magic.current, amount)

    if amount == 0 then
        return
    end

    magic.current = magic.current - amount
    ctx:set(hit.defender, "core.magic", magic)
    ctx:emit("combat", "You feel your power leaking away.")
end

return brand
