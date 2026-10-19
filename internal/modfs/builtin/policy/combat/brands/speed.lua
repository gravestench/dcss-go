-- Example: brand.apply() has no on-hit effect because policy.monster_energy
-- already shortened the attack delay before this hit resolved.
local brand = {}

-- Speed changes attack timing before contact and adds no post-hit effect.
function brand.apply()
end

return brand
