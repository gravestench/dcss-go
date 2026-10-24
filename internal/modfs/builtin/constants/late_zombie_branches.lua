-- These branches share the source's generic late-game corpse roster. Their
-- ambient demons and undead are usually unsuitable bodies for a zombie.
local branches = require("ids.branches")

return {
    [branches.BRANCH_VESTIBULE] = true,
    [branches.BRANCH_DIS] = true,
    [branches.BRANCH_GEHENNA] = true,
    [branches.BRANCH_COCYTUS] = true,
    [branches.BRANCH_TARTARUS] = true,
    [branches.BRANCH_CRYPT] = true,
    [branches.BRANCH_TOMB] = true,
    [branches.BRANCH_ABYSS] = true,
    [branches.BRANCH_PANDEMONIUM] = true,
}
