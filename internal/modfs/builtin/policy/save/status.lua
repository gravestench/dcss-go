local poison_sources = require("policy.save.poison_sources")

local abyss = require("policy.world.abyss")
local component = require("constants.component")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local stats = require("constants.stats")
local restrictions = require("constants.safety_restrictions")
local rage = require("policy.character.rage")
local zot_clock = require("policy.world.zot_clock")

local module = {}

function module.run(ctx)
    local player = ctx:player()
    local durations = ctx:get(player, "core.durations")
    local poison = ctx:get(player, "core.poison")
    local regeneration = ctx:get(player, "core.regeneration")
    local drain = ctx:get(player, "status.drain")
    local stat_loss = ctx:get(player, component.STAT_LOSS)
    local icy_defense = ctx:get(player, component.ICY_DEFENSE)
    local sanguine_armour = ctx:get(player, component.SANGUINE_ARMOUR)
    local agility = ctx:get(player, component.AGILITY)
    local damage_safety = ctx:get(player, component.DAMAGE_SAFETY)
    local potion_resistance = ctx:get(player,
        component.POTION_RESISTANCE)
    local potion_brilliance = ctx:get(player,
        component.POTION_BRILLIANCE)
    local potion_ambrosia = ctx:get(player,
        component.POTION_AMBROSIA)
    local potion_attraction = ctx:get(player,
        component.POTION_ATTRACTION)
    local potion_invisibility = ctx:get(player,
        component.POTION_INVISIBILITY)
    local powered = ctx:get(player, component.POWERED_BY_DEATH)
    local banishment = ctx:get(player, "world.banishment")
    local petrification = ctx:get(player,
        component.PLAYER_PETRIFICATION)
    local horror = ctx:get(player, component.HORROR)
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
        not poison_sources.valid(poison.source_monster_id)) then
        error("invalid player poison")
    end

    if regeneration and (regeneration.hp_progress < 0 or
        regeneration.hp_progress >= 100 or regeneration.mp_progress < 0 or
        regeneration.mp_progress >= 100) then
        error("invalid player regeneration counters")
    end

    if potion_resistance and
        (potion_resistance.remaining_aut < 1 or
            potion_resistance.remaining_aut > 2147483647) then
        error("invalid potion resistance duration")
    end

    if potion_brilliance and
        (potion_brilliance.remaining_aut < 1 or
            potion_brilliance.remaining_aut > 800) then
        error("invalid potion brilliance duration")
    end

    if potion_ambrosia and
        (potion_ambrosia.remaining_aut < 1 or
            potion_ambrosia.remaining_aut > 2147483647) then
        error("invalid potion ambrosia duration")
    end

    if potion_attraction and
        (potion_attraction.remaining_aut < 1 or
            potion_attraction.remaining_aut > 2147483647) then
        error("invalid potion attraction duration")
    end

    if potion_invisibility and
        (potion_invisibility.remaining_aut < 1 or
            potion_invisibility.remaining_aut > 1000) then
        error("invalid potion invisibility duration")
    end

    if drain and (drain.amount < 1 or drain.amount > 32767) then
        error("invalid player HP drain")
    end

    if stat_loss then
        local drained = false

        for _, field in ipairs(stats.ORDER) do
            local amount = stat_loss[field]

            if amount < 0 or amount > 100 then
                error("invalid player stat loss")
            end

            drained = drained or amount > 0
        end

        if (drained and stat_loss.remaining_xp <= 0) or
            (not drained and stat_loss.remaining_xp ~= 0) then
            error("invalid player stat loss recovery timer")
        end
    end

    if icy_defense and (icy_defense.remaining_aut < 0 or
        icy_defense.remaining_aut > 300) then
        error("invalid player icy defense depletion")
    end

    if sanguine_armour and (sanguine_armour.remaining_aut < 0 or
        sanguine_armour.remaining_aut > 100) then
        error("invalid player sanguine armour duration")
    end

    if agility and (agility.remaining_aut < 0 or
        agility.remaining_aut > 800) then
        error("invalid player Agility duration")
    end

    if damage_safety then
        for _, restriction in ipairs({
            restrictions.POTIONS,
            restrictions.SCROLLS,
        }) do
            local remaining = damage_safety[restriction]

            if remaining < 0 or remaining > 300 then
                error("invalid player damage safety duration")
            end
        end
    end

    if powered and (powered.strength < 0 or powered.strength > 12 or
        powered.remaining_aut < 0 or powered.remaining_aut > 50 or
        (powered.strength > 0 and powered.remaining_aut == 0)) then
        error("invalid player Powered by Death state")
    end

    if petrification and (
        petrification.petrifying_aut < 0 or
        petrification.petrifying_aut > 30 or
        petrification.petrified_aut < 0 or
        petrification.petrified_aut > 99 or
        (petrification.petrifying_aut == 0 and
            petrification.petrified_aut == 0) or
        (petrification.petrifying_aut > 0 and
            petrification.petrified_aut > 0)) then
        error("invalid player petrification")
    end

    if horror and (horror.penalty <= 0 or
        mutation_levels.effective(ctx, player,
            mutations.MUT_COWARDICE) == 0) then
        error("invalid player horror")
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

    rage.validate(ctx, player)
    zot_clock.validate(ctx, player)

    return {}
end

register.policy({
    id = "save.validate_status",
    run = module.run,
})

return module
