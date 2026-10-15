local catalog = require("policy.catalog")
local equipment = require("policy.combat.equipment")
local fighter = require("policy.combat.fighter")

local resistance = {}

local form_poison = {
    spider = -1,
    ice_beast = 1,
    dragon = 1,
}

-- Source: player.cc:player_res_poison and form-data.h. Only live equipment
-- and mutations count; melded gear is excluded by equipment.worn.
function resistance.poison(ctx, player)
    local choice = ctx:get(player, "core.player")
    local species = catalog.get("species", choice.species_id)
    local form = ctx:get(player, "magic.player_form")

    if choice.species_id == "SP_GARGOYLE" or
        choice.species_id == "SP_DJINNI" or
        species.undead_type == "US_UNDEAD" or
        (form and form.form_id == "lich") then
        return 3
    end

    local value = fighter.mutation(ctx, "MUT_POISON_RESISTANCE")

    if fighter.mutation(ctx, "MUT_SLIMY_GREEN_SCALES") >= 3 then
        value = value + 1
    end

    local worn = equipment.worn(ctx, player, {
        weapon = true,
        body = true,
        cloak = true,
        head = true,
        gloves = true,
        boots = true,
        ring_left = true,
        ring_right = true,
    })

    for _, entry in pairs(worn) do
        if entry.item.kind_id == "RING_POISON_RESISTANCE" or
            entry.item.kind_id == "STAFF_POISON" or
            entry.item.ego == "SPARM_POISON_RESISTANCE" then
            value = value + 1
        end
    end

    value = math.min(1, value)

    if form then
        value = value + (form_poison[form.form_id] or 0)
    end

    return math.max(-1, value)
end

-- The current item model has no artefact property record. Species mutations
-- are the represented source of clarity until artefacts join the catalog.
function resistance.clarity(ctx)
    return fighter.mutation(ctx, "MUT_CLARITY") > 0
end

return resistance
