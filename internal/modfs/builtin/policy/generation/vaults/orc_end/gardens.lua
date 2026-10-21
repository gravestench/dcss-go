-- Theory of operation: the source garden finale is a mapless controller.
-- It rolls one shared monster theme, then draws four child gardens with
-- different shop choices. Only the first is a boss garden. The children
-- receive those choices as placement-local settings and save their own
-- terrain, monster, and shop records.
local families = require("constants.vault_families")
local catalog = require("policy.generation.vaults.catalog")
local settings = require("constants.orc_gardens")
local tags = require("constants.vault_tags")

local gardens = {}

-- A failed child fit rejects this base floor, retaining the selected
-- finale while generation tries a new layout and connector geometry.
local function place_child(api, giant, boss, shop)
    local options = {
        family = families.ORC,
        settings = {
            [settings.GIANT] = giant,
            [settings.BOSS] = boss,
            [settings.SHOP] = shop,
        },
    }

    if api:place_maps(tags.ORC_GARDEN, 1, options) ~= 1 then
        error("end vault could not fit on base layout: " ..
            "Orc garden has no fitting helper")
    end
end

-- Draw shop descriptions without replacement so each of the four gardens
-- gets one distinct source store, even if its helper map ID repeats.
local function place(api)
    local giant = api:one_in(8)
    local shops = {}

    for index, shop in ipairs(settings.SHOPS) do
        shops[index] = shop
    end

    for index = 1, 4 do
        local shop_index = api:roll(#shops) + 1
        local shop = table.remove(shops, shop_index)

        place_child(api, giant, index == 1, shop)
    end
end

gardens.place = place

-- A saved mapless primary has no terrain of its own. Four helper IDs from
-- the Orc family prove that its source composition survived restore.
local function validate(level)
    local count = 0

    for _, id in ipairs(level.vault_ids or {}) do
        local okay, definition = pcall(catalog.get, id)

        if okay and definition.family == families.ORC and
            definition.tags[tags.ORC_GARDEN] then
            count = count + 1
        end
    end

    if count ~= 4 then
        error("Orc gardens need four source garden helpers")
    end
end

gardens.validate = validate

return gardens
