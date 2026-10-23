-- Theory of operation: an Abyss level is a saved moving window. Before
-- the next movement intent runs, a player near its edge brings a radius
-- ten neighborhood back to the center. The region and its procedural
-- clock are staged together, so failed actions leave the old window.
local abyss = require("constants.abyss")
local component = require("constants.component")
local shift = require("policy.world.abyss.shift")
local morph = require("policy.world.abyss.morph")

local system = {}

-- The source shifts when the player leaves the window's safe interior.
-- Testing the current committed cell before movement also lets a move
-- begun at the edge use the freshly centered pending grid view.
local function needs_shift(position)
    return position.x < abyss.SHIFT_MARGIN or
        position.y < abyss.SHIFT_MARGIN or
        position.x >= abyss.WIDTH - abyss.SHIFT_MARGIN or
        position.y >= abyss.HEIGHT - abyss.SHIFT_MARGIN
end

-- Only player actions advance the window; monsters never drag the map.
-- The procedural record may be absent while the neutral storage has
-- received banished monsters but the player has never entered.
function system.update(ctx, actor, elapsed_aut)
    if actor ~= ctx:player() or elapsed_aut <= 0 then
        return
    end

    local position = ctx:get(actor, component.POSITION)

    if not position or position.level_id ~= abyss.LEVEL_ID then
        return
    end

    local state = ctx:session_state(abyss.SESSION_STATE)

    if not state then
        return
    end

    local updated

    if needs_shift(position) then
        updated = shift.apply(ctx, state, actor)
    else
        updated = morph.advance(ctx, state, actor, elapsed_aut)
    end

    ctx:replace_session_state(abyss.SESSION_STATE, updated)
end

register.system({
    id = "world.abyss_shift",
    scope = "active",
    query = {},
    before = { "world.movement" },
    update = system.update,
})

return system
