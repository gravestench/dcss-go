local catalog = require("policy.catalog")
local items = require("policy.inventory.items")
local equipment = require("policy.inventory.equipment")
local traits = require("policy.character.traits")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local potion_rules = require("policy.character.potion_rules")
local classes = require("ids.object_classes")
local item_ids = require("ids.items")
local skill_ids = require("ids.skills")
local size = require("constants.size")
local weapon_choices = require("constants.weapon_choices")

local gear = {}
local job_rules = {}

function gear.register(job_id, rule)
    catalog.get("jobs", job_id)

    if job_rules[job_id] then
        error("duplicate starting-gear rule for " .. job_id)
    end

    if type(rule) ~= "table" then
        error("starting-gear rule for " .. job_id .. " must be a table")
    end

    if rule.prepare_weapon ~= nil and
        type(rule.prepare_weapon) ~= "function" then
        error("starting-gear prepare_weapon must be a function for " .. job_id)
    end

    if rule.extra ~= nil and type(rule.extra) ~= "function" then
        error("starting-gear extra must be a function for " .. job_id)
    end

    job_rules[job_id] = rule
end

local function can_use(ctx, player, species, kind)
    if kind.class == classes.OBJ_WEAPONS then
        return mutation_levels.effective(ctx, player,
            mutations.MUT_NO_GRASPING) == 0 and
            size.rank[species.size] >=
            size.rank[kind.weapon.min_2h_size_id]
    end

    if kind.class ~= classes.OBJ_ARMOUR then
        return true
    end

    return equipment.can_wear(ctx, player, species, kind)
end

local function useful_kind(ctx, player, species, kind)
    if kind.class == classes.OBJ_POTIONS and
        not potion_rules.can_drink(ctx, player) then
        return nil
    end

    if kind.id == item_ids.POT_MAGIC and
        mutation_levels.effective(ctx, player, mutations.MUT_HP_CASTING) > 0 then
        return nil
    end

    if (kind.id == item_ids.SCR_BLINKING or
        kind.id == item_ids.SCR_TELEPORTATION) and
        traits.stasis(species) then
        return nil
    end

    if kind.id == item_ids.ARM_KITE_SHIELD and
        size.rank[species.size] < size.rank[size.MEDIUM] then
        kind = catalog.get("items", item_ids.ARM_BUCKLER)
    end

    if kind.class == classes.OBJ_ARMOUR and
        not can_use(ctx, player, species, kind) then
        local replacement = item_ids.ARM_ROBE

        if kind.id == item_ids.ARM_HELMET or
            kind.id == item_ids.ARM_HAT then
            replacement = item_ids.ARM_HAT
        elseif kind.id == item_ids.ARM_BUCKLER then
            replacement = item_ids.ARM_KITE_SHIELD
        elseif kind.slot == "shield" then
            replacement = item_ids.ARM_BUCKLER
        end

        kind = catalog.get("items", replacement)
    end

    if not can_use(ctx, player, species, kind) then
        return nil
    end

    return kind
end

local function add_grant(ctx, player, species, grant, occupied)
    local kind = useful_kind(ctx, player, species,
        catalog.get("items", grant.kind_id))

    if not kind then
        return
    end

    local item = {
        kind_id = kind.id,
        quantity = grant.quantity,
        plus = grant.plus or 0,
        charges = grant.charges or 0,
        ego = grant.ego or "",
    }

    items.validate(item, kind)

    local entity = ctx:create()
    ctx:add(entity, "core.item", item)
    ctx:add(entity, "core.carried_by", { holder = player })

    local hand_conflict = kind.slot == "shield" and occupied.weapon and
        equipment.needs_second_hand(ctx, player, occupied.weapon, species) or
        kind.slot == "weapon" and occupied.shield and
        equipment.needs_second_hand(ctx, player, kind, species)

    if kind.slot and kind.slot ~= "" and not occupied[kind.slot] and
        not hand_conflict then
        ctx:add(entity, "core.equipped", { slot = kind.slot })
        occupied[kind.slot] = kind
    end
end

function gear.give(ctx, player, species, job, weapon_id, generated)
    local grants = generated and generated.equipment or job.starting_grants
    local rule = job_rules[job.id]

    if not grants then
        error("unknown starting gear job " .. job.id)
    end

    local occupied = {}

    if job.weapon_choice ~= weapon_choices.NONE and
        weapon_id ~= item_ids.WPN_UNARMED then
        local chosen = {
            kind_id = weapon_id,
            quantity = 1,
        }

        if rule and rule.prepare_weapon then
            rule.prepare_weapon(chosen)
        end

        add_grant(ctx, player, species, chosen, occupied)
    end

    if type(grants) == "table" then
        for _, grant in ipairs(grants) do
            add_grant(ctx, player, species, grant, occupied)
        end
    end

    if rule and rule.extra then
        for _, grant in ipairs(rule.extra(species, generated, occupied)) do
            add_grant(ctx, player, species, grant, occupied)
        end
    end

    return occupied.weapon and occupied.weapon.weapon_skill or
        skill_ids.SK_UNARMED_COMBAT
end

return gear
