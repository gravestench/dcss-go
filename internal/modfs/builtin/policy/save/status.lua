local poison_sources = {
    MONS_ADDER = true,
    MONS_GOBLIN = true,
    MONS_KOBOLD = true,
}

register.policy({
    id = "save.validate_status",
    run = function(ctx)
        local player = ctx:player()
        local durations = ctx:get(player, "core.durations")
        local poison = ctx:get(player, "core.poison")
        local regeneration = ctx:get(player, "core.regeneration")

        if durations then
            if durations.might_aut < 0 or durations.might_aut > 800 then
                error("invalid player might duration")
            end

            if durations.haste_aut < 0 or durations.haste_aut > 400 then
                error("invalid player haste duration")
            end
        end

        if poison and (poison.amount_scaled < 1000 or
            poison.amount_scaled > 2147483647 or
            not poison_sources[poison.source_monster_id]) then
            error("invalid player poison")
        end

        if regeneration and (regeneration.hp_progress < 0 or
            regeneration.hp_progress >= 100 or regeneration.mp_progress < 0 or
            regeneration.mp_progress >= 100) then
            error("invalid player regeneration counters")
        end

        return {}
    end,
})
