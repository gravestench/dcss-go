-- Character restrictions follow the pinned DCSS species/job rules.

local no_grasping_jobs = {
    JOB_GLADIATOR = true,
    JOB_BRIGAND = true,
    JOB_HUNTER = true,
    JOB_ARCANE_MARKSMAN = true,
}

local forlorn_jobs = {
    JOB_BERSERKER = true,
    JOB_CHAOS_KNIGHT = true,
    JOB_ABYSSAL_KNIGHT = true,
    JOB_CINDER_ACOLYTE = true,
    JOB_MONK = true,
}

local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

local function has_mutation(species, wanted)
    for _, mutation in ipairs(species.mutations or {}) do
        if mutation.id == wanted and mutation.level <= 1 and
            mutation.amount > 0 then
            return true
        end
    end

    return false
end

local choice = {}

function choice.allowed(species, job)
    if not species.selectable or not job.selectable then
        return false
    end

    if has_mutation(species, "MUT_NO_GRASPING") and no_grasping_jobs[job.id] then
        return false
    end

    if has_mutation(species, "MUT_FORLORN") and forlorn_jobs[job.id] then
        return false
    end

    if job.id == "JOB_TRANSMUTER" and species.undead_type == "US_UNDEAD" then
        return false
    end

    return true
end

register.choice_policy(function(species, job, species_first)
    if not choice.allowed(species, job) then
        return "banned", false
    end

    local recommended

    if species_first then
        recommended = contains(species.recommended_jobs, job.id)
    else
        recommended = contains(job.recommended_species, species.id)
    end

    local restriction = recommended and "recommended" or "restricted"
    return restriction, true
end)

return choice
