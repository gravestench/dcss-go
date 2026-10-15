local catalog = require("policy.catalog")
local items = require("policy.inventory.items")
local equipment = require("policy.inventory.equipment")
local traits = require("policy.character.traits")

local gear = {}
local jobs = {}

for _, job in ipairs(require("data.starting_gear").jobs) do
    jobs[job.job_id] = job.grants
end

local sizes = {
    SIZE_TINY = 0,
    SIZE_LITTLE = 1,
    SIZE_SMALL = 2,
    SIZE_MEDIUM = 3,
    SIZE_LARGE = 4,
    SIZE_GIANT = 5,
}

local function has_mutation(species, id)
    for _, mutation in ipairs(species.mutations or {}) do
        if mutation.id == id and mutation.level <= 1 and mutation.amount > 0 then
            return true
        end
    end

    return false
end

local function can_use(species, kind)
    if kind.class == "OBJ_WEAPONS" then
        return not has_mutation(species, "MUT_NO_GRASPING") and
            sizes[species.size] >= sizes[kind.weapon.min_2h_size_id]
    end

    if kind.class ~= "OBJ_ARMOUR" then
        return true
    end

    return equipment.can_wear(species, kind)
end

local function useful_kind(species, kind)
    if kind.class == "OBJ_POTIONS" and has_mutation(species, "MUT_NO_DRINK") then
        return nil
    end

    if kind.id == "POT_MAGIC" and has_mutation(species, "MUT_HP_CASTING") then
        return nil
    end

    if (kind.id == "SCR_BLINKING" or kind.id == "SCR_TELEPORTATION") and
        traits.stasis(species) then
        return nil
    end

    if kind.id == "ARM_KITE_SHIELD" and sizes[species.size] < sizes.SIZE_MEDIUM then
        kind = catalog.get("items", "ARM_BUCKLER")
    end

    if kind.class == "OBJ_ARMOUR" and not can_use(species, kind) then
        local replacement = "ARM_ROBE"

        if kind.id == "ARM_HELMET" or kind.id == "ARM_HAT" then
            replacement = "ARM_HAT"
        elseif kind.id == "ARM_BUCKLER" then
            replacement = "ARM_KITE_SHIELD"
        elseif kind.slot == "shield" then
            replacement = "ARM_BUCKLER"
        end

        kind = catalog.get("items", replacement)
    end

    if not can_use(species, kind) then
        return nil
    end

    return kind
end

local function add_grant(ctx, player, species, grant, occupied)
    local kind = useful_kind(species, catalog.get("items", grant.kind_id))

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
        equipment.needs_second_hand(occupied.weapon, species) or
        kind.slot == "weapon" and occupied.shield and
        equipment.needs_second_hand(kind, species)

    if kind.slot and kind.slot ~= "" and not occupied[kind.slot] and
        not hand_conflict then
        ctx:add(entity, "core.equipped", { slot = kind.slot })
        occupied[kind.slot] = kind
    end
end

function gear.give(ctx, player, species, job, weapon_id, generated)
    local grants = generated or job.starting_grants or jobs[job.id]

    if not grants then
        error("unknown starting gear job " .. job.id)
    end

    local occupied = {}

    if job.weapon_choice ~= "WCHOICE_NONE" and weapon_id ~= "WPN_UNARMED" then
        local chosen = {
            kind_id = weapon_id,
            quantity = 1,
        }

        if job.id == "JOB_ABYSSAL_KNIGHT" then
            chosen.plus = 1
        elseif job.id == "JOB_CHAOS_KNIGHT" then
            chosen.ego = "SPWPN_CHAOS"
        elseif job.id == "JOB_CINDER_ACOLYTE" then
            chosen.plus = -1
            chosen.ego = "SPWPN_FLAMING"
        end

        add_grant(ctx, player, species, chosen, occupied)
    end

    if type(grants) == "table" then
        for _, grant in ipairs(grants) do
            add_grant(ctx, player, species, grant, occupied)
        end
    end

    if job.id == "JOB_GLADIATOR" then
        local ammo
        local quantity

        if sizes[species.size] >= sizes.SIZE_LARGE then
            ammo = "MI_LARGE_ROCK"
            quantity = 1
        elseif sizes[species.size] <= sizes.SIZE_SMALL then
            ammo = "MI_BOOMERANG"
            quantity = 2
        else
            ammo = "MI_JAVELIN"
            quantity = 1
        end

        add_grant(ctx, player, species, {
            kind_id = ammo,
            quantity = quantity,
        }, occupied)
    end

    if job.id == "JOB_WANDERER" then
        local attributes = generated and generated.attributes or {}
        local strength = species.strength + (attributes.strength or 0)
        local intelligence = species.intelligence + (attributes.intelligence or 0)
        local dexterity = species.dexterity + (attributes.dexterity or 0)

        if not occupied.body then
            local armour = strength > intelligence and "ARM_LEATHER_ARMOUR" or "ARM_ROBE"
            add_grant(ctx, player, species, {
                kind_id = armour,
                quantity = 1,
            }, occupied)
        end

        if not occupied.weapon then
            local weapon = dexterity > strength and "WPN_DAGGER" or "WPN_CLUB"
            add_grant(ctx, player, species, {
                kind_id = weapon,
                quantity = 1,
            }, occupied)
        end
    end

    return occupied.weapon and occupied.weapon.weapon_skill or "SK_UNARMED_COMBAT"
end

return gear
