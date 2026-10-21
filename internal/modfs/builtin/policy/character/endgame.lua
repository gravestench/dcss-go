-- Theory of operation: the player's saved chapter owns the normal Orb run.
-- Source DCSS does not place the Orb in an inventory slot. Its pickup changes
-- CHAPTER_ESCAPING and removes the floor item; later travel and spawning
-- read that chapter instead of searching inventory or transient map data.
local catalog = require("policy.catalog")
local component = require("constants.component")
local phases = require("constants.endgame")
local classes = require("ids.object_classes")
local items = require("ids.items")
local noise = require("policy.world.noise")

local endgame = {}

-- A new character starts before the Orb run. The component is attached at
-- creation so saves and mod policies can always read one explicit phase.
function endgame.initialise(ctx, player)
    ctx:add(player, component.PLAYER_ENDGAME, {
        phase = phases.EXPLORING,
    })
end

-- Refuse a missing or malformed chapter instead of interpreting it as an
-- ordinary game. That makes a damaged save fail before a false victory.
function endgame.phase(ctx, player)
    local state = ctx:get(player, component.PLAYER_ENDGAME)

    if not state then
        error("player endgame phase is missing")
    end

    return state.phase
end

-- Consume only the defined Orb of Zot. The source's 30-volume pickup noise
-- wakes nearby monsters unless Silence suppresses sound at this cell.
function endgame.take_orb(ctx, player, item, position)
    local definition = catalog.get("items", item.kind_id)

    if item.kind_id ~= items.ORB_ZOT or
        definition.class ~= classes.OBJ_ORBS or
        endgame.phase(ctx, player) ~= phases.EXPLORING then
        error("cannot start Orb run from this item or chapter")
    end

    ctx:set(player, component.PLAYER_ENDGAME, {
        phase = phases.ESCAPING,
    })

    local volume = noise.emit(ctx, position, 30, player)

    ctx:emit("pickup", "You pick up the Orb of Zot!")

    if volume > 0 then
        ctx:emit("orb", "The Orb lets out a hideous shriek!")
    else
        ctx:emit("orb", "The Orb lets out a furious burst of light!")
    end

    ctx:emit("orb", "The lords of Pandemonium are not amused. Beware!")
    ctx:emit("orb", "Now all you have to do is get back out of the dungeon!")
end

-- D:1's source exit ends a run in place. The Go session observes this saved
-- phase and stops scheduling, while the actor retains its final floor data.
function endgame.leave(ctx, player)
    local previous = endgame.phase(ctx, player)

    if previous ~= phases.EXPLORING and
        previous ~= phases.ESCAPING then
        error("cannot leave a finished Dungeon run")
    end

    local final = previous == phases.ESCAPING and
        phases.WON or phases.LEFT

    ctx:set(player, component.PLAYER_ENDGAME, {
        phase = final,
    })
    ctx:emit("escape", "You have escaped!")

    return final
end

-- Save validation accepts only the chapters this port can enter. Later
-- source chapters can be added deliberately with their own transitions.
function endgame.validate(state)
    if not state or (state.phase ~= phases.EXPLORING and
        state.phase ~= phases.ESCAPING and
        state.phase ~= phases.WON and
        state.phase ~= phases.LEFT) then
        error("invalid player endgame phase")
    end
end

return endgame
