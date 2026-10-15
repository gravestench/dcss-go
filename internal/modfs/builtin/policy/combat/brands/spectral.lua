-- The pinned source leaves monster-wielded spectral weapons inactive
-- (mon-act.cc:2222-2226). Player spectral weapons summon after player
-- attacks, which is a separate player-attack effect path.
return {
    apply = function()
    end,
}
