-- Theory of operation: a god gift first checks whether an item can remain
-- at the player's feet. Direct acquirement then rolls a usable class and
-- materializes the result as an ordinary positioned ECS item. This owner
-- does not decide when any god is generous or which class it chooses.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local generation = require("policy.item_generation")
local habitats = require("constants.monster_habitats")
local offers = require("policy.scrolls.acquirement_offers")
local terrain = require("constants.terrain")

local items = {}

-- Lava destroys a dropped item. Deep water hides it permanently from
-- species without native water habitat; a temporary form does not change
-- this source check.
function items.safe_floor(ctx, player)
    local position = ctx:get(player, component.POSITION)

    if not position then
        return false
    end

    local feature = ctx:cell(position.level_id, position.x, position.y)

    if feature == terrain.DNGN_LAVA then
        return false
    end

    if feature ~= terrain.DNGN_DEEP_WATER then
        return true
    end

    local identity = ctx:get(player, component.PLAYER)
    local species = catalog.get(categories.SPECIES, identity.species_id)

    return species.habitat == habitats.WATER or
        species.habitat == habitats.AMPHIBIOUS
end

-- Example: a Sif book rolls with GOD_GIFT provenance and appears on the
-- player's current tile; it never occupies a scroll offer reservation.
function items.grant(ctx, player, class_id, god_id)
    if not items.safe_floor(ctx, player) then
        return nil
    end

    local position = ctx:get(player, component.POSITION)
    local rolled = offers.roll_for_gift(ctx, class_id,
        position.level_id, god_id)

    if not rolled then
        return nil
    end

    local entity = generation.create(ctx, rolled, {
        position = {
            level_id = position.level_id,
            x = position.x,
            y = position.y,
        },
    })

    return entity
end

return items
