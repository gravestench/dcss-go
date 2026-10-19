-- cloud.cc:CLOUD_MUTAGENIC. Contamination and wretchedness reuse their
-- existing saved status components rather than inventing cloud-local state.
local categories = require("constants.catalog")
local streams = require("constants.rng_streams")
local ids = require("policy.magic.effects.zaps.ids")
local component = require("constants.component")
local catalog = require("policy.catalog")
local irradiate = require("policy.combat.monster_area.irradiate")

local mutagenic = {}

-- Player contact accumulates contamination; monster contact follows its separate wretchedness path.
-- Example: a mutagenic cloud adds player contamination or makes a separate monster wretchedness roll.
function mutagenic.apply(ctx, actor)
    if actor == ctx:player() then
        local state = ctx:get(actor, ids.component.CONTAMINATION)
        local added = 1300 + ctx:random(streams.CLOUDS, 1250)

        if state then
            state.amount = math.min(250000, state.amount + added)
            ctx:set(actor, ids.component.CONTAMINATION, state)
        else
            ctx:add(actor, ids.component.CONTAMINATION, {
                amount = added,
            })
        end

        ctx:emit("cloud", "The mutagenic energy flows into you.")

        return 0
    end

    if ctx:random(streams.CLOUDS, 2) ~= 0 then
        return 0
    end

    local state = ctx:get(actor, component.ACTOR)

    if state then
        local definition = catalog.get(categories.MONSTERS, state.kind_id)
        irradiate.wretch(ctx, actor, definition)
    end

    return 0
end

return mutagenic
