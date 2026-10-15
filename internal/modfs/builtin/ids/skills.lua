-- Aptitude declarations are the authoritative list of trainable skills.
local skills = {}

for _, species_id in ipairs(register.ids("species")) do
    local species = register.get("species", species_id)

    for skill_id in pairs(species.aptitudes or {}) do
        skills[skill_id] = skill_id
    end
end

-- A starting-job instruction that resolves to the chosen weapon skill.
skills.WEAPON_CHOICE = "SK_WEAPON"

return skills
