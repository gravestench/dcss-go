-- Kikubaaqudgha offers Forbidden Knowledge instead of a pain-branded
-- weapon. Both choices spend the same saved, lifetime one-time flag.
local abilities = require("ids.abilities")
local availability = require("policy.character.skill_availability")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local records = require("policy.character.spell_records")
local registry = require("policy.abilities.registry")
local spells = require("ids.spells")
local traits = require("policy.character.traits")
local undead = require("constants.undead_states")

local knowledge = {}

local candidates = {
    spells.SPELL_HAUNT,
    spells.SPELL_BORGNJORS_REVIVIFICATION,
    spells.SPELL_INFESTATION,
    spells.SPELL_NECROMUTATION,
    spells.SPELL_DEATHS_DOOR,
}

-- The source's capstone gate is shared with the pain weapon. No Grasping
-- prevents that weapon action but does not prevent receiving spell knowledge.
function knowledge.available(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local spent = worship and worship.one_time_abilities or {}

    return costs.available(ctx, player, gods.KIKUBAAQUDGHA, 6) and
        not spent[gods.KIKUBAAQUDGHA]
end

-- Return only spells useful to this character's current species, form,
-- mutations, and god. The source still lists an already memorised spell;
-- granting it again simply leaves its existing library record in place.
function knowledge.usable(ctx, player)
    local identity = ctx:get(player, component.PLAYER)
    local species = catalog.get(categories.SPECIES, identity.species_id)
    local selected = {}
    local permanently_undead = species.undead_type ~= undead.ALIVE

    for _, id in ipairs(candidates) do
        local spell = catalog.get(categories.SPELLS, id)
        local forbidden_to_undead = id == spells.SPELL_BORGNJORS_REVIVIFICATION or
            id == spells.SPELL_NECROMUTATION or
            id == spells.SPELL_DEATHS_DOOR

        if not availability.forbidden_spell(ctx, player, spell) and
            traits.start_spell_usable(ctx, player, species, id) and
            not (permanently_undead and forbidden_to_undead) then
            selected[#selected + 1] = id
        end
    end

    return selected
end

-- The confirmation names the exact currently usable spells. Cancellation
-- is free and creates no pending state because there is no item identity.
function knowledge.prepare(ctx, player, input)
    if input.cancelled then
        return "Okay."
    end

    local selected = knowledge.usable(ctx, player)

    if #selected == 0 then
        return "Kikubaaqudgha has no more spells that you can make use of!"
    end

    if not input.forced then
        local names = {}

        for _, id in ipairs(selected) do
            names[#names + 1] = catalog.get(categories.SPELLS, id).name
        end

        return {
            confirmation = "Do you wish to receive knowledge of " ..
                table.concat(names, ", ") .. "?",
        }
    end

    return nil
end

-- Re-evaluate the live list at commitment. A stale forced command cannot
-- grant an unusable spell or spend the capstone when nothing remains.
function knowledge.resolve(ctx, player)
    local selected = knowledge.usable(ctx, player)

    if #selected == 0 then
        error("forbidden knowledge has no usable spells")
    end

    records.grant_library(ctx, player, selected)

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.one_time_abilities[gods.KIKUBAAQUDGHA] = true
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    ctx:emit("religion", "Kikubaaqudgha grants you forbidden knowledge!")
end

registry.add(abilities.KIKU_GIFT_CAPSTONE_SPELLS, {
    name = "Receive Forbidden Knowledge",
    available = knowledge.available,
    prepare = knowledge.prepare,
    resolve = knowledge.resolve,
})

return knowledge
