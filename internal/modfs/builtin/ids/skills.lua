-- Skill IDs key aptitudes, training state, and spell/weapon calculations.

-- Aptitude declarations are the authoritative list of trainable skills.
-- Pinned source names are available while content loads; species may add
-- skills after that, and those new IDs join this table at policy load.
local pinned = require("ids.pinned_skills")
local skills = {}

for id, value in pairs(pinned) do
    skills[id] = value
end

for _, species_id in ipairs(register.ids("species")) do
    local species = register.get("species", species_id)

    for skill_id in pairs(species.aptitudes or {}) do
        skills[skill_id] = skill_id
    end
end

-- A starting-job instruction that resolves to the chosen weapon skill.
skills.WEAPON_CHOICE = "SK_WEAPON"

return skills
