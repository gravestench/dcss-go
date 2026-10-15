local component = require("constants.component")
local hex = require("policy.combat.monster_spells.hex")
local petrification = require("policy.combat.player_petrification")
local resistance = require("policy.combat.player_resistance")

local petrify = {}

function petrify.can_cast(ctx, caster_pos, player_pos)
    if caster_pos.level_id ~= player_pos.level_id then
        return false
    end

    local distance = math.max(math.abs(caster_pos.x - player_pos.x),
        math.abs(caster_pos.y - player_pos.y))

    return distance <= 7 and ctx:projectile_clear(caster_pos.level_id,
        caster_pos.x, caster_pos.y, player_pos.x, player_pos.y)
end

function petrify.resolve(ctx, caster, player, definition)
    if resistance.petrification(ctx, player) then
        ctx:emit("spell", "You are unaffected by the petrifying gaze.")

        return
    end

    if hex.resisted(ctx, caster, player, definition) then
        ctx:emit("spell", "You resist the petrifying gaze.")

        return
    end

    petrification.apply(ctx, player)
end

return petrify
