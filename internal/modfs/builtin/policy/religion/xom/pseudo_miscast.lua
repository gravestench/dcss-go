-- A zero-power Xom miscast changes no game state. Its effect is a misleading
-- sensory line chosen from the features the player can currently see.
-- Priority lines make rare landmarks more memorable than the fallback.
local component = require("constants.component")
local terrain = require("constants.terrain")
local streams = require("constants.rng_streams")

local miscast = {}

-- Read only the player's live line of sight. A map feature elsewhere on
-- the floor cannot narrate itself as though the player saw it move.
local function visible_features(ctx, position)
    local present = {}

    for _, cell in ipairs(ctx:visible_cells(position.level_id,
        position.x, position.y, 7)) do
        local feature = ctx:cell(position.level_id, cell.x, cell.y)

        if feature then
            present[feature] = true
        end
    end

    return present
end

-- Keep the source's landmark-specific illusions together. These lines do
-- not mutate terrain: the player only *thinks* a feature responded to Xom.
local function terrain_lines(present, messages, priority)
    if present[terrain.DNGN_LAVA] then
        messages[#messages + 1] = "The lava spits out sparks!"
    end

    if present[terrain.DNGN_SHALLOW_WATER] or
        present[terrain.DNGN_DEEP_WATER] then
        messages[#messages + 1] = "The water briefly bubbles."
        messages[#messages + 1] = "The water briefly swirls."
        messages[#messages + 1] = "The water briefly glows."
    end

    if present[terrain.DNGN_DEEP_WATER] then
        messages[#messages + 1] =
            "From the corner of your eye you spot something lurking " ..
            "in the deep water."
    end

    if present[terrain.DNGN_ORCISH_IDOL] then
        priority[#priority + 1] =
            "The idol of Beogh turns to glare at you."
    end

    if present[terrain.DNGN_GRANITE_STATUE] then
        priority[#priority + 1] =
            "The granite statue turns to stare at you."
    end

    if present[terrain.DNGN_CLEAR_ROCK_WALL] or
        present[terrain.DNGN_CLEAR_STONE_WALL] or
        present[terrain.DNGN_CLEAR_PERMAROCK_WALL] then
        messages[#messages + 1] =
            "Dim shapes swim through the translucent wall."
    end

    if present[terrain.DNGN_CRYSTAL_WALL] then
        messages[#messages + 1] =
            "Dim shapes swim through the crystal wall."
    end

    if present[terrain.DNGN_METAL_WALL] then
        messages[#messages + 1] =
            "Tendrils of electricity crawl over the metal wall!"
    end

    if present[terrain.DNGN_FOUNTAIN_BLUE] or
        present[terrain.DNGN_FOUNTAIN_MAGIC] then
        priority[#priority + 1] =
            "The water in the fountain briefly bubbles."
        priority[#priority + 1] =
            "The water in the fountain briefly swirls."
        priority[#priority + 1] =
            "The water in the fountain briefly glows."
    end

    if present[terrain.DNGN_FOUNTAIN_DRY] then
        priority[#priority + 1] =
            "Water briefly sprays from the dry fountain."
        priority[#priority + 1] =
            "Dust puffs up from the dry fountain."
    end

    if present[terrain.DNGN_STONE_ARCH] then
        priority[#priority + 1] =
            "The stone arch briefly shows a sunny meadow on the other side."
    end
end

-- The fallback guarantees a message when no landmark is visible. The
-- source also imagines a monocle, spending its side draw before selection.
local function ordinary_lines(ctx, stream, messages)
    messages[#messages + 1] = "Nothing appears to happen... Ominous!"

    local side = ctx:random(stream, 2) == 0 and "right" or "left"

    messages[#messages + 1] =
        "A monocle briefly appears over your " .. side .. " eye."
end

-- A priority pool wins half the time when present. The final draw picks
-- one line from the chosen pool, preserving Xom's flavor variability.
local function choose(ctx, stream, messages, priority)
    if #priority > 0 and ctx:random(stream, 2) == 0 then
        return priority[ctx:random(stream, #priority) + 1]
    end

    return messages[ctx:random(stream, #messages) + 1]
end

-- Return the line to the Xom status owner, which emits it exactly once.
-- This keeps the illusion independent of the outer action and mood clock.
function miscast.message(ctx, player, stream)
    stream = stream or streams.RELIGION

    local position = ctx:get(player, component.POSITION)
    local messages = {}
    local priority = {}

    ordinary_lines(ctx, stream, messages)

    if position then
        terrain_lines(visible_features(ctx, position), messages, priority)
    end

    return choose(ctx, stream, messages, priority)
end

return miscast
