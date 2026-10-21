-- Theory of operation: the town hall is the main source map. After it
-- fits, two larger homes and four to six smaller homes join its streets.
-- Child selectors use the effective catalog so a mod can add a house.
local families = require("constants.vault_families")
local catalog = require("policy.generation.vaults.catalog")
local tags = require("constants.vault_tags")

local community = {}

-- Every requested house must fit for this ending to be complete. A failed
-- group asks the floor builder for another base layout, not a partial town.
local function place_group(api, tag, count)
    local options = {
        family = families.ORC,
    }

    if api:place_maps(tag, count, options) ~= count then
        error("end vault could not fit on base layout: " ..
            "Orc community has missing houses")
    end
end

-- The source rolls before map placement, then consumes the stored choice
-- after the town hall fits. Placement itself draws substitutions and entity
-- choices, so deferring this roll would change the source random sequence.
local function roll_house_count(api)
    api:remember("small_house_count", 4 + api:roll(3))
end

community.roll_house_count = roll_house_count

-- Use the earlier draw when placing the dependent house maps.
local function place(api)
    local small_count = api:recall("small_house_count")

    place_group(api, tags.ORC_BIG_HOUSE, 2)
    place_group(api, tags.ORC_HOUSE, small_count)
end

community.place = place

-- A town hall without its two large homes and four to six small homes is
-- an incomplete ending even when the primary map itself still resolves.
local function validate(level)
    -- A mapful validator also runs once on its local DES cells, before
    -- post-place children exist. Their composition is checked later when
    -- the complete saved level is passed to this same named method.
    if level.cells and not level.vault_records then
        return true
    end

    local big = 0
    local small = 0

    for _, id in ipairs(level.vault_ids or {}) do
        local okay, definition = pcall(catalog.get, id)

        if okay and definition.family == families.ORC then
            if definition.tags[tags.ORC_BIG_HOUSE] then
                big = big + 1
            elseif definition.tags[tags.ORC_HOUSE] then
                small = small + 1
            end
        end
    end

    if big ~= 2 or small < 4 or small > 6 then
        error("Orc community needs two big and four to six small houses")
    end

    return true
end

community.validate = validate

return community
