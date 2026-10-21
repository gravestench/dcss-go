-- Theory of operation: four Shoals endings are mapless DES controllers.
-- Each chooses one real rune island, sometimes an Ilsuiw island or false
-- rune island, then enough ordinary islands to match the source finale.
-- Tagged child selection keeps authored geometry in its own DES files.
local categories = require("constants.catalog")
local effects = require("constants.vault_effects")
local item_ids = require("ids.items")
local tags = require("constants.vault_tags")

local finale = {}

-- Source dgn.place_maps uses die_on_error for every Shoals child request.
-- A failed fit therefore redraws the base floor with the same selected
-- controller instead of silently publishing a finale with missing islands.
local function require_maps(api, tag, count)
    local placed = api:place_maps(tag, count)

    if placed ~= count then
        error("end vault could not fit on base layout: " .. tag ..
            " placed " .. placed .. " of " .. count)
    end
end

-- Match the source draw order: rune, guardian, mimic, then ordinary decoys.
-- The mimic replaces two ordinary huts because it poses an extra threat.
function finale.assemble(api, theme)
    local decoys = api:random_range(theme.minimum, theme.maximum)

    require_maps(api, theme.rune, 1)

    if api:one_in(5) then
        require_maps(api, tags.SHOAL_GUARDIAN, 1)
    end

    if api:one_in(10) then
        require_maps(api, theme.mimic, 1)
        decoys = decoys - 2
    end

    require_maps(api, theme.hut, decoys)
end

-- Reuse this exact invariant for generation and save restore. A forged
-- history cannot borrow a rune from another finale, nor list a helper ID
-- without a matching typed rune record owned by that helper.
function finale.require_rune(result, theme)
    local helper_ids = {}
    local rune_helpers = 0
    local rune_records = 0

    for _, id in ipairs(result.vault_ids or {}) do
        local helper = register.get(categories.VAULTS, id)

        if helper.tags[theme.rune] then
            helper_ids[id] = true
            rune_helpers = rune_helpers + 1
        end
    end

    for _, record in ipairs(result.records or result.vault_records or {}) do
        if record.kind == effects.ITEM and record.arguments and
            record.arguments.kind_id == item_ids.RUNE_SHOALS and
            not record.arguments.mimic then
            rune_records = rune_records + 1

            -- Placement calls this before Go projects vault_id into the
            -- saved source_id field; restore sees the saved field instead.
            local owner = record.source_id or record.vault_id

            if not helper_ids[owner] then
                error("Shoals end rune is not owned by its selected helper")
            end
        end
    end

    if rune_helpers ~= 1 or rune_records ~= 1 then
        error("Shoals end needs exactly one matching rune helper and item")
    end

    return true
end

return finale
