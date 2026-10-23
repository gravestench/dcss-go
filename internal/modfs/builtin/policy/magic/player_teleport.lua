-- Source: spl-transloc.cc:you_teleport and _teleport_player.
local cloud = require("policy.clouds.placement")
local cloud_ids = require("ids.clouds")
local component = require("constants.component")
local translocation = require("policy.scrolls.translocation")
local vision = require("policy.character.vision")
local trap_held = require("policy.traps.held")
local abyss = require("policy.world.abyss")
local abyss_constants = require("constants.abyss")
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local flags = require("constants.monster_flags")
local targets = require("policy.ai.targets")

local teleport = {}
local MAX_ATTEMPTS = 500
local SIGHT_RADIUS = 7

-- Teleportitis and Lugonu's wrath accept only the first sampled landing
-- when a threatening hostile monster can see that destination. An empty
-- landing check fails this attempt; it does not reroll the 500-cell search.
local function threats_near(ctx, player, level_id, x, y)
    local count = 0

    for _, monster in ipairs(ctx:query({
        component.ACTOR,
        component.POSITION,
        component.HEALTH,
    })) do
        if monster ~= player then
            local position = ctx:get(monster, component.POSITION)
            local health = ctx:get(monster, component.HEALTH)
            local distance = math.max(math.abs(position.x - x),
                math.abs(position.y - y))

            if health.current > 0 and position.level_id == level_id and
                distance <= SIGHT_RADIUS and
                targets.attitude(ctx, monster) == attitudes.HOSTILE and
                ctx:visible_no_trans(level_id, x, y, SIGHT_RADIUS,
                    position.x, position.y) then
                local actor = ctx:get(monster, component.ACTOR)
                local definition = catalog.get(categories.MONSTERS,
                    actor.kind_id)
                local threatening = true

                for _, flag in ipairs(definition.flags or {}) do
                    if flag == flags.NO_THREAT then
                        threatening = false
                        break
                    end
                end

                if threatening then
                    count = count + 1
                end
            end
        end
    end

    return count
end

-- Candidate landing cells must pass walkability and safety checks before a
-- queued teleport can move its actor.
local function destination(ctx, player, origin)
    local width, height = ctx:level_size(origin.level_id)

    for _ = 1, MAX_ATTEMPTS do
        local x = ctx:random("teleport", width)
        local y = ctx:random("teleport", height)

        if translocation.can_land(ctx, player, origin.level_id, x, y) and
            not cloud.at(ctx, origin.level_id, x, y) then
            return x, y
        end
    end

    return nil, nil
end

-- Example: teleport.toggle(ctx, player) starts a delayed jump; calling it
-- again while queued cancels that state instead of adding another timer.
-- Store a 30-to-50-aut timer only on a new request; the second request removes that pending state.
function teleport.toggle(ctx, player, stream)
    local current = ctx:get(player, component.PLAYER_TELEPORT)

    if current and current.remaining_aut > 0 then
        ctx:remove(player, component.PLAYER_TELEPORT)
        ctx:emit("read", "You feel strangely stable.")

        return
    end

    ctx:add(player, component.PLAYER_TELEPORT, {
        remaining_aut = (3 + ctx:random(stream or "teleport", 3)) * 10,
    })
    ctx:emit("read", "You feel strangely unstable.")
end

-- Delayed teleport counts down in a player component and chooses its destination only when due.
function teleport.tick(ctx, player, aut)
    local current = ctx:get(player, component.PLAYER_TELEPORT)

    if not current or aut <= 0 then
        return
    end

    current.remaining_aut = current.remaining_aut - aut

    if current.remaining_aut > 0 then
        ctx:set(player, component.PLAYER_TELEPORT, current)

        return
    end

    ctx:remove(player, component.PLAYER_TELEPORT)

    teleport.now(ctx, player)
end

-- Immediate teleports reuse destination selection and leave source effects
-- without waiting for the delayed player's timer.
function teleport.now(ctx, player, options)
    options = options or {}
    local channel = options.channel or "read"
    local reason = not options.near_monsters and
        translocation.restriction(ctx, player)

    if reason then
        ctx:emit(channel, reason)

        return false
    end

    local origin = ctx:get(player, component.POSITION)

    if origin.level_id == abyss_constants.LEVEL_ID then
        abyss.teleport(ctx, player)

        return true
    end

    local x, y = destination(ctx, player, origin)

    if not x then
        return false
    end

    if options.near_monsters then
        local count = threats_near(ctx, player, origin.level_id, x, y)

        if count == 0 then
            return false
        end

        reason = translocation.restriction(ctx, player)

        if reason then
            if options.reason then
                ctx:emit(channel, options.reason)
            end

            ctx:emit(channel, reason)

            return false
        end

        if options.reason then
            ctx:emit(channel, options.reason)
        end

        ctx:emit(channel, count == 1 and
            "You are yanked towards a nearby monster!" or
            "You are yanked towards some nearby monsters!")
    end

    local message = "Your surroundings suddenly seem different."

    if x == origin.x and y == origin.y then
        message = "Your surroundings flicker for a moment."
    elseif ctx:visible(origin.level_id, origin.x, origin.y,
        vision.radius(ctx, player), x, y) then
        message = "Your surroundings seem slightly different."
    end

    cloud.place(ctx, cloud_ids.CLOUD_TLOC_ENERGY, player,
        origin.level_id, origin.x, origin.y,
        (1 + ctx:random("teleport", 3)) * 10)

    if x ~= origin.x or y ~= origin.y then
        trap_held.release(ctx, player)
        ctx:move_actor(player, origin.level_id, x, y)
    end

    ctx:emit(channel, message)

    return true
end

-- Restore rejects impossible queued state before the timer resumes.
function teleport.validate(ctx, player)
    local current = ctx:get(player, component.PLAYER_TELEPORT)

    if current and current.remaining_aut <= 0 then
        error("invalid player teleport delay")
    end
end

return teleport
