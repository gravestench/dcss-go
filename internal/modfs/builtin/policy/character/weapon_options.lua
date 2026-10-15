local catalog = require("policy.catalog")
local choice = require("policy.character_choice")
local weapon_choices = require("constants.weapon_choices")

local weapons = {}

local bases = {
    "WPN_SHORT_SWORD",
    "WPN_MACE",
    "WPN_HAND_AXE",
    "WPN_SPEAR",
    "WPN_FALCHION",
    "WPN_QUARTERSTAFF",
    "WPN_UNARMED",
}

local upgrades = {
    WPN_SHORT_SWORD = "WPN_RAPIER",
    WPN_MACE = "WPN_FLAIL",
    WPN_HAND_AXE = "WPN_WAR_AXE",
    WPN_SPEAR = "WPN_TRIDENT",
    WPN_FALCHION = "WPN_LONG_SWORD",
}

local function contains(values, target)
    for _, value in ipairs(values or {}) do
        if value == target then
            return true
        end
    end

    return false
end

local function has_mutation(species, id)
    for _, mutation in ipairs(species.mutations or {}) do
        if mutation.id == id and mutation.amount > 0 then
            return true
        end
    end

    return false
end

local function upgrade(id, job_id, size)
    if id == "WPN_SPEAR" and job_id == "JOB_FIGHTER" and
        (size == "SIZE_TINY" or size == "SIZE_LITTLE" or size == "SIZE_SMALL") then
        return id
    end

    return upgrades[id] or id
end

function weapons.options(species_id, job_id)
    local species = catalog.get("species", species_id)
    local job = catalog.get("jobs", job_id)

    if not choice.allowed(species, job) then
        error(species_id .. "/" .. job_id .. " is not a legal normal Dungeon start")
    end

    if job.weapon_choice == weapon_choices.NONE then
        return {}
    end

    local options = {}

    for _, base in ipairs(bases) do
        local id = base

        if job.weapon_choice == weapon_choices.GOOD then
            id = upgrade(id, job_id, species.size)
        end

        if not has_mutation(species, "MUT_NO_GRASPING") or id == "WPN_UNARMED" then
            local staff_allowed = job_id == "JOB_GLADIATOR" or
                (job_id == "JOB_FIGHTER" and has_mutation(species, "MUT_QUADRUMANOUS"))

            if id ~= "WPN_QUARTERSTAFF" or staff_allowed then
                local name = "unarmed"
                local skill = "SK_UNARMED_COMBAT"

                if id ~= "WPN_UNARMED" then
                    local item = catalog.get("items", id)
                    name = item.name
                    skill = item.weapon_skill
                end

                local recommended = contains(species.recommended_weapons, skill) and
                    not (job_id == "JOB_FIGHTER" and skill == "SK_SHORT_BLADES")
                options[#options + 1] = {
                    id = id,
                    name = name,
                    restriction = recommended and "recommended" or "restricted",
                }
            end
        end
    end

    return options
end

function weapons.run_options(_, input)
    return { options = weapons.options(input.species_id, input.job_id) }
end

register.policy({
    id = "character.weapon_options",
    run = weapons.run_options,
})

return weapons
