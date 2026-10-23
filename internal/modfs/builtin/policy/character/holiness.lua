-- Player holiness is a live character fact: species supplies the base,
-- while blood state, forms, and petrification may change it during play.
-- Source: player.cc:player::holiness and player::can_feel_fear.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local forms = require("constants.form_ids")
local species_ids = require("ids.species")
local undead = require("constants.undead_states")
local vampire = require("policy.character.vampire")

local holiness = {}

-- Natural holiness admits living characters to fear and life theft. A
-- vampire uses current blood state, not its species definition alone.
-- Example: holiness.natural(ctx, player) becomes false in Lich Form.
function holiness.natural(ctx, player)
    local identity = ctx:get(player, component.PLAYER)
    local species = catalog.get(categories.SPECIES, identity.species_id)
    local form = ctx:get(player, component.PLAYER_FORM)
    local petrification = ctx:get(player,
        component.PLAYER_PETRIFICATION)

    if identity.species_id == species_ids.SP_GARGOYLE or
        identity.species_id == species_ids.SP_DJINNI or
        form and (form.form_id == forms.LICH or
            form.form_id == forms.WISP or
            form.form_id == forms.STORM) or
        petrification and petrification.petrified_aut > 0 then
        return false
    end

    if species.undead_type == undead.SEMI_UNDEAD then
        return vampire.alive(ctx, player)
    end

    return species.undead_type == undead.ALIVE
end

-- Holy Word and Torment cards use source undead_state(), which treats a
-- vampire's semi-undead species state as undead and Lich Form as fully
-- undead. Demonspawn count as demonic even though their base state lives.
function holiness.undead_or_demonic(ctx, player)
    local identity = ctx:get(player, component.PLAYER)
    local species = catalog.get(categories.SPECIES, identity.species_id)
    local form = ctx:get(player, component.PLAYER_FORM)

    return identity.species_id == species_ids.SP_DEMONSPAWN or
        species.undead_type ~= undead.ALIVE or
        form and form.form_id == forms.LICH or false
end

return holiness
