local poison_sources = {
    MONS_ADDER = true,
    MONS_GOBLIN = true,
    MONS_KOBOLD = true,
}

local abyss = require("policy.world.abyss")

local module = {}

function module.run(ctx)
    local player = ctx:player()
    local durations = ctx:get(player, "core.durations")
    local poison = ctx:get(player, "core.poison")
    local regeneration = ctx:get(player, "core.regeneration")
    local drain = ctx:get(player, "status.drain")
    local banishment = ctx:get(player, "world.banishment")
    local position = ctx:get(player, "core.position")

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

    if drain and (drain.amount < 1 or drain.amount > 32767) then
        error("invalid player HP drain")
    end

    if position and position.level_id == abyss.level_id then
        if not banishment then
            error("Abyss player has no banishment origin")
        end
    elseif banishment then
        error("Dungeon player retains banishment origin")
    end

    if banishment and (banishment.origin_level_id < 1 or
        banishment.origin_level_id > 2 or
        not ctx:walkable(banishment.origin_level_id,
            banishment.origin_x, banishment.origin_y)) then
        error("invalid player banishment origin")
    end

    return {}
end

register.policy({
    id = "save.validate_status",
    run = module.run,
})

return module
