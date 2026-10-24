-- Theory of operation: the grid can hold more than one actor, but only
-- Fedhas policy grants passage through stationary plants. The worship
-- passive controls entering a cell; the plant's source traits control
-- whether a shared cell remains structurally valid in a saved game.
local attitudes = require("constants.attitude")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local monsters = require("ids.monsters")
local fedhas = require("policy.religion.gods.fedhas")
local targets = require("policy.ai.targets")

local passage = {}

-- These two plant actors are mobile attack bodies despite the shared
-- plant holiness. DCSS expressly excludes them from Fedhas passage.
local excluded = {
    [monsters.MONS_SNAPLASHER_VINE] = true,
    [monsters.MONS_SNAPLASHER_VINE_SEGMENT] = true,
}

-- Imported catalog traits let a mod add another stationary plant without
-- editing the god policy. Neither name nor summon origin is enough.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- A plant-shaped monster must satisfy both source traits. The kind check
-- is also used before an actor exists when Grow targets the player's cell.
function passage.kind(kind_id)
    if excluded[kind_id] then
        return false
    end

    local definition = catalog.get(categories.MONSTERS, kind_id)

    return definition and
        fedhas.plant_class(definition) and
        has(definition.flags, flags.STATIONARY) or false
end

-- Source hostile Oklobs are the one stationary plant exception. The live
-- attitude matters because Fedhas may later neutralize a hostile plant.
function passage.plant(ctx, entity)
    local actor = ctx:get(entity, component.ACTOR)

    if not actor or not passage.kind(actor.kind_id) then
        return false
    end

    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    -- Source checks the species, which includes Oklob Saplings. A hostile
    -- sapling must still be a bump target despite its distinct kind ID.
    return definition.species_id ~= monsters.MONS_OKLOB_PLANT or
        targets.real_attitude(ctx, entity) ~= attitudes.HOSTILE
end

-- Return the single plant the player can enter. Other occupants, or a
-- second plant already sharing the cell, keep ordinary collision rules.
function passage.at(ctx, player, level_id, x, y)
    if player ~= ctx:player() or
        not fedhas.passive_active(ctx, player) then
        return nil
    end

    local actors = ctx:actors_at(level_id, x, y)

    if #actors ~= 1 or not passage.plant(ctx, actors[1]) then
        return nil
    end

    return actors[1]
end

-- Growth under the worshiper is source-authorized only for a stationary
-- plant and only while the passive is active. The actor is placed second
-- so the player remains the primary target and screen glyph.
function passage.growth_under_player(ctx, player, kind_id, x, y)
    local position = ctx:get(player, component.POSITION)

    return position and position.x == x and position.y == y and
        fedhas.passive_active(ctx, player) and passage.kind(kind_id) or false
end

return passage
