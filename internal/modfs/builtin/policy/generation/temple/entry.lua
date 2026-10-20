-- The scheduled Dungeon entrance uses one source temple_entry vault. Its
-- O feature is the actual linked stair, so no unrelated stair is painted.
local catalog = require("policy.generation.temple.catalog")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local features = require("constants.vault_features")
local extra = require("policy.generation.vaults.extra")

local entry = {}

-- Effective file IDs are sorted by the Temple catalog. Remove a rejected
-- candidate so bounded retries cannot draw the same unplaceable map again.
local function candidates()
    local choices = {}

    for _, id in ipairs(catalog.entry_ids()) do
        local definition = catalog.entry(id)

        if definition.weight > 0 then
            choices[#choices + 1] = {
                definition = definition,
                weight = definition.weight,
            }
        end
    end

    return choices
end

-- Preserve source WEIGHT values when choosing among the entries that have
-- not failed a protected-stair fit on this Dungeon floor.
local function draw(builder, choices)
    local total = 0

    for _, candidate in ipairs(choices) do
        total = total + candidate.weight
    end

    if total <= 0 then
        error("Temple entry catalog has no positive-weight map")
    end

    local pick = builder:roll(total)

    for index, candidate in ipairs(choices) do
        pick = pick - candidate.weight

        if pick < 0 then
            table.remove(choices, index)

            return candidate.definition
        end
    end

    error("Temple entry weighted draw exceeded its candidates")
end

-- The source KFEAT binds O after substitutions and rotation. Require one
-- final feature record instead of guessing a coordinate from raw MAP rows.
local function entrance_point(placed)
    local found

    for _, record in ipairs(placed.records) do
        if record.kind == effects.FEATURE and
            record.directive == directives.KFEAT and
            record.identity == features.ENTER_TEMPLE then
            if found then
                error("Temple entry " .. placed.id ..
                    " has more than one entrance feature")
            end

            found = {
                x = record.x,
                y = record.y,
            }
        end
    end

    if not found then
        error("Temple entry " .. placed.id ..
            " has no entrance feature")
    end

    return found
end

-- The shared extra-vault fitter already snapshots and restores failed
-- placements. Keep trying weighted source entries until one connects to
-- the required Dungeon stairs without overwriting another branch link.
function entry.place(ctx, builder, protected, required, player)
    local choices = candidates()
    local last_error

    while #choices > 0 do
        local definition = draw(builder, choices)
        local placed, reason = extra.place(ctx, builder, definition, {
            protected = protected,
            required = required,
            player = player,
        })

        if placed then
            local point = entrance_point(placed)

            builder:set(point.x, point.y, ">")
            protected[point.x .. ":" .. point.y] = true

            return placed, point
        end

        last_error = reason
    end

    error("no source Temple entry fits this Dungeon floor: " ..
        tostring(last_error))
end

return entry
