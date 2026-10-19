local component = require("constants.component")
local mutations = require("ids.mutations")
local levels = require("policy.mutations.levels")
local zap_ids = require("policy.magic.effects.zaps.ids")
local monster_flags = require("constants.monster_flags")
local hex_status = require("policy.combat.monster_hexes.status")

local invisibility = {}

-- Visibility depends on backlighting as well as invisibility duration.
function invisibility.backlit(ctx, player)
    if hex_status.backlit(ctx, player) then
        return true
    end

    if ctx:has(player, component.STICKY_FLAME) then
        return true
    end

    if levels.effective(ctx, player, mutations.MUT_GLOWING) > 0 then
        return true
    end

    local contamination = ctx:get(player,
        zap_ids.component.CONTAMINATION)

    return contamination ~= nil and contamination.amount > 5000
end

-- Read the potion timer rather than optical visibility, which other effects can change.
function invisibility.active(ctx, player)
    local state = ctx:get(player, component.POTION_INVISIBILITY)

    return state ~= nil and state.remaining_aut > 0 and
        not invisibility.backlit(ctx, player)
end

-- Observer sight and contamination can reveal an invisible player; active duration alone is insufficient.
-- Example: a high contamination glow can reveal a player despite an active invisibility potion.
function invisibility.visible_to(ctx, player, observer)
    if not invisibility.active(ctx, player) then
        return true
    end

    local actor = ctx:get(observer, component.ACTOR)

    if not actor then
        return false
    end

    local illusion = ctx:get(observer, component.PLAYER_ILLUSION)

    if illusion and illusion.see_invisible then
        return true
    end

    local catalog = require("policy.catalog")
    local definition = catalog.get("monsters", actor.kind_id)

    for _, flag in ipairs(definition.flags or {}) do
        if flag == monster_flags.SEE_INVISIBLE then
            return true
        end
    end

    return false
end

-- Remove the potion component only after its remaining aut reaches zero.
function invisibility.tick(ctx, player, aut)
    local state = ctx:get(player, component.POTION_INVISIBILITY)

    if not state or aut <= 0 then
        return
    end

    state.remaining_aut = math.max(0, state.remaining_aut - aut)

    if state.remaining_aut == 0 then
        ctx:remove(player, component.POTION_INVISIBILITY)
        ctx:emit("duration", "You flicker back into view.")
    else
        ctx:set(player, component.POTION_INVISIBILITY, state)
    end
end

return invisibility
