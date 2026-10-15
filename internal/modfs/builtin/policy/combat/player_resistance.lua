local catalog = require("policy.catalog")
local equipment = require("policy.combat.equipment")
local effects = require("policy.mutations.effects.registry")
local capabilities = require("constants.mutation_capabilities")
local armour_egos = require("constants.armour_egos")
local armour_flags = require("constants.armour_flags")
local component = require("constants.component")
local item_ids = require("ids.items")
local spell_ids = require("ids.spells")
local form_catalog = require("policy.magic.effects.forms.catalog")
local potion_resistance = require("policy.potions.resistance")

local resistance = {}
local willpower_pip = 40

local form_poison = {
    spider = -1,
    ice_beast = 1,
    dragon = 1,
    tree = 1,
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

    local value = effects.sum(ctx, player,
        capabilities.POISON_RESISTANCE)

    if potion_resistance.active(ctx, player) then
        value = value + 1
    end

    if value >= 3 then
        return 3
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
function resistance.clarity(ctx, player)
    return effects.sum(ctx, player, capabilities.CLARITY) > 0
end

local function armour_willpower(entry)
    local value = 0

    if not entry.definition.armour then
        return value
    end

    local source = entry.definition.armour.flags
    local flags = type(source) == "table" and source or {}

    for _, flag in ipairs(flags) do
        if flag.id == armour_flags.WILLPOWER then
            value = value + flag.level
        end
    end

    return value
end

-- Source: player.cc:player_willpower. Equipment and mutations contribute
-- forty-point pips after the species' per-level base.
function resistance.willpower(ctx, player)
    local choice = ctx:get(player, component.PLAYER)
    local progress = ctx:get(player, component.PROGRESSION)
    local species = catalog.get("species", choice.species_id)
    local pips = effects.sum(ctx, player, capabilities.WILLPOWER_PIPS)
    local worn = equipment.worn(ctx, player, {
        body = true,
        cloak = true,
        head = true,
        gloves = true,
        boots = true,
        ring_left = true,
        ring_right = true,
    })

    for slot, entry in pairs(worn) do
        if slot == "body" then
            pips = pips + armour_willpower(entry)
        end

        if entry.item.ego == armour_egos.WILLPOWER then
            pips = pips + 1
        elseif entry.item.ego == armour_egos.GUILE then
            pips = pips - 2
        end

        if (slot == "ring_left" or slot == "ring_right") and
            entry.item.kind_id == item_ids.RING_WILLPOWER then
            pips = pips + 1
        end
    end

    return math.max(0, progress.level * species.mr +
        pips * willpower_pip)
end

local function active_form(ctx, player, spell_id)
    local state = ctx:get(player, component.PLAYER_FORM)

    if not state or state.remaining_aut <= 0 then
        return false
    end

    return state.form_id == form_catalog[spell_id].id
end

-- Source: player.cc:player::res_torment and player::res_petrify.
function resistance.torment(ctx, player)
    local petrification = ctx:get(player,
        component.PLAYER_PETRIFICATION)

    local forms = require("policy.magic.effects.forms.player")

    return effects.sum(ctx, player,
        capabilities.TORMENT_RESISTANCE) >= 2 or
        forms.torment_immune(ctx, player) or
        active_form(ctx, player, spell_ids.SPELL_NECROMUTATION) or
        (petrification and petrification.petrified_aut > 0) or false
end

function resistance.petrification(ctx, player)
    return effects.sum(ctx, player,
        capabilities.PETRIFICATION_RESISTANCE) > 0 or
        active_form(ctx, player, spell_ids.SPELL_STATUE_FORM) or
        active_form(ctx, player, spell_ids.SPELL_STORM_FORM)
end

-- Source: spl-goditem.cc:torment_player. God shielding and undead blood
-- states wait for their gameplay domains; current HP and rN are live reads.
function resistance.torment_loss(ctx, player, current_hp)
    if resistance.torment(ctx, player) then
        return 0
    end

    local damage = require("policy.magic.damage")
    local resistance_ids = require("constants.resistance_ids")
    local negative = damage.player_resistance(ctx, player,
        resistance_ids.NEGATIVE_ENERGY)
    local loss = math.max(0,
        math.floor(current_hp * (50 - negative * 5) / 100) - 1)

    if active_form(ctx, player, spell_ids.SPELL_STATUE_FORM) then
        loss = math.floor(loss / 2)
    end

    if effects.sum(ctx, player, capabilities.TORMENT_RESISTANCE) > 0 then
        loss = math.floor(loss / 2)
    end

    return loss
end

return resistance
