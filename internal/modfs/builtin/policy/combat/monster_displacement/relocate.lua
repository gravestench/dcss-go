local catalog = require("policy.catalog")
local cloud = require("policy.clouds.placement")
local cloud_ids = require("ids.clouds")
local component = require("constants.component")
local habitat = require("policy.combat.monster_habitat")
local net = require("policy.combat.net")
local player_constriction = require("policy.combat.player_constriction")
local display = require("policy.combat.monster_support.display")
local channels = require("constants.message_channels")
local streams = require("constants.rng_streams")
local teleport = require("policy.magic.effects.zaps.teleport_other")
local translocation = require("policy.scrolls.translocation")

local relocate = {}

-- The same saved anchor, stasis, and constriction state gates every blink
-- variant before an actor can leave its cell.
function relocate.can_move(ctx, mover)
    if ctx:has(mover, component.PLAYER) then
        return translocation.restriction(ctx, mover) == nil
    end

    local actor = ctx:get(mover, component.ACTOR)

    if not actor then
        return false
    end

    local definition = catalog.get("monsters", actor.kind_id)

    return not teleport.no_tele(actor, definition, ctx, mover)
end

-- Movement stays on the grid owner. Nets are released before leaving and a
-- short source cloud records a blink's origin. Recall uses the same movement
-- checks without a blink cloud, matching its distinct source visual effect.
function relocate.move(ctx, mover, x, y, source, clouded)
    local origin = ctx:get(mover, component.POSITION)

    if not origin or not relocate.can_move(ctx, mover) or
        ctx:actor_at(origin.level_id, x, y) then
        return false
    end

    local valid = false

    if ctx:has(mover, component.PLAYER) then
        valid = translocation.can_land(ctx, mover, origin.level_id, x, y)
    else
        valid = habitat.at(ctx, mover, origin.level_id, x, y)
    end

    if not valid then
        return false
    end

    -- Monster Blink makes two escape attempts at resolution. Planning
    -- cannot reject a held actor because its saved grip may be broken.
    if ctx:has(mover, component.PLAYER_CONSTRICTION) and
        not player_constriction.escape(ctx, mover, 2) then
        return false
    end

    net.release(ctx, mover)
    ctx:move_actor(mover, origin.level_id, x, y)

    if ctx:has(mover, component.CONSTRICTION) then
        ctx:remove(mover, component.CONSTRICTION)
    end

    if clouded ~= false then
        cloud.place(ctx, cloud_ids.CLOUD_TLOC_ENERGY, source or mover,
            origin.level_id, origin.x, origin.y,
            (1 + ctx:random(streams.MONSTER_SPELL, 3)) * 10)

        local player = ctx:player()
        local player_pos = player and ctx:get(player,
            component.POSITION)

        if player == mover then
            ctx:emit(channels.SPELL, "You blink.")
        elseif player_pos and player_pos.level_id == origin.level_id and
            (ctx:visible(origin.level_id, player_pos.x,
                player_pos.y, 7, origin.x, origin.y) or
                ctx:visible(origin.level_id, player_pos.x,
                    player_pos.y, 7, x, y)) then
            ctx:emit(channels.SPELL, "The " ..
                display.name(ctx, mover) .. " blinks.")
        end
    end

    return true
end

return relocate
