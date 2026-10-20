-- DCSS can spend an ambient spawn roll without creating a monster.
-- Keep that weighted outcome in the source table instead of treating it as
-- an undefined monster or silently renormalizing the remaining choices.
local sentinels = {
    NO_MONSTER = "MONS_NO_MONSTER",
}

return sentinels
