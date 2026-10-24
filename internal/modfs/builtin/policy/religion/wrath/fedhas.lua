-- Fedhas chooses between corpse spores, a nature spell, and surrounding
-- plants. Each outcome has its own placement or god-avatar owner.
local avatar = require("policy.religion.wrath.avatar")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local corpse_spores = require("policy.religion.wrath.fedhas.corpses")
local plants = require("policy.religion.wrath.fedhas.plants")
local gods = require("constants.gods")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local fedhas = {}
local nature_spells = {
    spells.SPELL_CORROSIVE_BOLT,
    spells.SPELL_PRIMAL_WAVE,
    spells.SPELL_THORN_VOLLEY,
}

-- The avatar is obtained before random_choose in source. An occupied
-- player cell therefore prevents the spell draw but not the wrath turn.
local function nature(ctx, player)
    if not avatar.available(ctx, player, gods.FEDHAS) then
        return true
    end

    local choice = ctx:random(streams.CARDS, #nature_spells) + 1
    local name = catalog.get(categories.GODS, gods.FEDHAS).name

    avatar.cast(ctx, player, gods.FEDHAS,
        nature_spells[choice], name .. " invokes nature against you.")

    return true
end

-- Current worship limits Fedhas to spores and nature spells. No visible
-- corpse falls through to nature without redrawing the branch choice.
function fedhas.apply(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local options = worship.god_id == gods.FEDHAS and 2 or 3
    local choice = ctx:random(streams.CARDS, options)

    if choice == 0 then
        if corpse_spores.apply(ctx, player) then
            local name = catalog.get(categories.GODS, gods.FEDHAS).name

            ctx:emit("religion", name .. " produces spores.")
            return true
        end

        return nature(ctx, player)
    elseif choice == 1 then
        return nature(ctx, player)
    end

    return plants.apply(ctx, player)
end

return fedhas
