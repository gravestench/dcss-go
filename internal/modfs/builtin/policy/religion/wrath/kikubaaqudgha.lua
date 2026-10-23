-- Kikubaaqudgha's high-level punishment uses the saved Torment area owner.
-- Death curses require their weighted curse and miscast owner.
local area = require("policy.combat.torment_area")
local component = require("constants.component")
local gods = require("constants.gods")
local resistance = require("policy.combat.player_resistance")
local streams = require("constants.rng_streams")

local kikubaaqudgha = {}

-- god-wrath.cc chooses the speech first, then the XL/27 Torment gate. A
-- resisted Torment substitutes three maximum-power death curses in source.
function kikubaaqudgha.apply(ctx, player)
    local level = math.max(1,
        ctx:get(player, component.PROGRESSION).level)

    ctx:emit("religion", ctx:random(streams.CARDS, 2) == 0 and
        "You hear Kikubaaqudgha cackling." or
        "Kikubaaqudgha's malice focuses upon you.")

    if ctx:random(streams.CARDS, 27) < level then
        if resistance.torment(ctx, player) then
            error("unimplemented Kikubaaqudgha death curse wrath")
        end

        -- Source passes no actor caster; the player's cell is only the
        -- Torment origin and must not credit the player as its attacker.
        area.apply(ctx, nil, "religion",
            ctx:get(player, component.POSITION))
    elseif ctx:random(streams.CARDS, level) >= 4 then
        error("unimplemented Kikubaaqudgha death curse wrath")
    end

    return true
end

return kikubaaqudgha
