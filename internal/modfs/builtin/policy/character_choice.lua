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

-- Treat missing restriction lists as empty for mod-added species and jobs.
local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Only starting mutation levels can bar a job on the character-choice screen.
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

-- Bans represent combinations that cannot physically use a job's start,
-- plus source-specific species restrictions. An unavailable gameplay feature
-- is handled elsewhere, so it does not silently alter the menu's rule.
-- Example: choice.allowed(species, job) returns false when that species cannot grasp a Hunter's weapon.
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

-- Recommendation highlights depend on whether the species or job menu was chosen first.
function choice.policy(species, job, species_first)
    if not choice.allowed(species, job) then
        return "banned", false
    end

    local recommended

    -- The source menu highlights different recommendations depending on
    -- which side the player selected first. Preserve that presentation rule
    -- without duplicating the underlying legality check.
    if species_first then
        recommended = contains(species.recommended_jobs, job.id)
    else
        recommended = contains(job.recommended_species, species.id)
    end

    local restriction = recommended and "recommended" or "restricted"
    return restriction, true
end

register.choice_policy(choice.policy)

return choice
