-- Theory of operation: an altar asks whether its resolved god definition can
-- accept this player's current species and mutations. Permanent checks answer
-- whether worship is ever possible; temporary checks also inspect form and
-- wallet facts that may change on a later turn. No candidate list is copied
-- here, so a layered god definition can add or change an eligibility rule.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local forms = require("constants.form_ids")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local mutation_records = require("policy.mutations.records")
local species_ids = require("ids.species")
local undead = require("constants.undead_states")

local eligibility = {}

-- Source No Love's permanent query counts innate ranks alone; its current
-- query includes acquired and temporary ranks as well. Other mutations use
-- their full base level in both checks.
local function no_love(ctx, player, temporary)
    local entry = mutation_records.find(ctx, player, mutations.MUT_NO_LOVE)

    if not entry then
        return false
    end

    if temporary then
        return entry.state.innate + entry.state.acquired +
            entry.state.temporary > 0
    end

    return entry.state.innate > 0
end

-- Let a god's own module reject current circumstances, such as Gozag's fee,
-- without adding a god-ID switch to the shared eligibility owner.
local function god_reason(ctx, player, definition, temporary)
    if not definition.behavior_module then
        return nil
    end

    local behavior = require(definition.behavior_module)

    if behavior.check then
        return behavior.check(ctx, player, temporary)
    end

    return nil
end

-- Example: eligibility.check(ctx, player, gods.ZIN, true) rejects Tree Form,
-- while the permanent query may allow that same living human to join later.
function eligibility.check(ctx, player, god_id, temporary)
    if temporary == nil then
        temporary = true
    end

    local definition = catalog.get(categories.GODS, god_id)
    local identity = ctx:get(player, component.PLAYER)

    if not identity then
        error("worship eligibility requires player identity")
    end

    if mutation_levels.base(ctx, player, mutations.MUT_FORLORN) > 0 then
        return "A being of your status worships no god."
    end

    local species = catalog.get(categories.SPECIES, identity.species_id)
    local form = ctx:get(player, component.PLAYER_FORM)
    local current_form = form and form.form_id or ""

    if definition.good and
        (species.undead_type ~= undead.ALIVE or
            identity.species_id == species_ids.SP_DEMONSPAWN or
            (temporary and current_form == forms.LICH)) then
        return definition.name .. " does not accept the undead or demonic."
    end

    if definition.rejects_innate_caster and
        mutation_levels.base(ctx, player, mutations.MUT_INNATE_CASTER) > 0 then
        return definition.name .. " does not accept innate casters."
    end

    if definition.requires_orc and
        identity.species_id ~= species_ids.SP_HILL_ORC then
        return definition.name .. " accepts only orcs."
    end

    local special = god_reason(ctx, player, definition, temporary)

    if special then
        return special
    end

    if definition.requires_love and no_love(ctx, player, temporary) then
        return definition.name .. " does not accept the loveless."
    end

    if temporary and definition.rejects_all_forms and current_form ~= "" then
        return definition.name .. " rejects your current form."
    end

    return nil
end

return eligibility
