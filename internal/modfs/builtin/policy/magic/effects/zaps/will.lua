local will = {}

-- Source: actor.cc:check_willpower and beam.cc:ench_power_stepdown.
function will.resists(ctx, definition, enchant_power)
    local resistance = definition.willpower or 0

    if resistance >= 5000 then
        return true
    end

    local stepped = math.floor(35 *
        math.log(1 + enchant_power / 35) / math.log(2) + 0.5)
    local threshold = 100 + resistance - stepped
    local roll = ctx:random("spell", 100) + ctx:random("spell", 101)

    return threshold - roll > 0
end

return will
