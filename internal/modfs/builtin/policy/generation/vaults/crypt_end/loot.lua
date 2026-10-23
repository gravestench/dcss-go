-- Theory of operation: every Crypt ending calls the same source bonus-loot
-- helper. Its keyed slots each roll one alternative when placement resolves;
-- the two substitutions make the strongest slots uncommon without changing
-- the source map. Keeping the helper in Lua lets an overlay alter incentives.
local directives = require("constants.vault_directives")

local loot = {}

-- Preserve each source item specification, including rarity weights and
-- item modifiers. The DES item resolver owns actual catalog identity.
function loot.apply(api)
    local drain = "ego:draining good_item ident:type"
    local pain = "ego:pain ident:type"
    local vamp = "ego:vampirism ident:type"
    local book = "randbook disc:necromancy numspells:6 spells:"
    local ring = "ring of positive energy randart good_item"
    local amulet = "amulet of regeneration randart good_item"

    api:emit(
        directives.KITEM,
        "d = double sword w:5 "
            .. drain
            .. " / triple sword w:5 "
            .. drain
            .. " / quick blade "
            .. drain
            .. " / executioner's axe "
            .. drain
            .. " / eveningstar "
            .. drain
            .. " / bardiche "
            .. drain
            .. " / lajatang "
            .. drain
    )
    api:emit(
        directives.KITEM,
        "e = great sword "
            .. pain
            .. " / battleaxe "
            .. pain
            .. " / great mace "
            .. pain
            .. " / glaive "
            .. pain
            .. " / quarterstaff "
            .. pain
    )
    api:emit(
        directives.KITEM,
        "f = great sword "
            .. vamp
            .. " / quick blade "
            .. vamp
            .. " / battleaxe "
            .. vamp
            .. " / great mace "
            .. vamp
            .. " / glaive "
            .. vamp
    )
    api:emit(
        directives.KITEM,
        "g = "
            .. ring
            .. ", "
            .. ring
            .. " / "
            .. amulet
            .. " w:2, "
            .. ring
            .. " / "
            .. amulet
            .. " w:2 / nothing"
    )
    api:emit(
        directives.KITEM,
        "h = vampires_tooth / morg / leech / sword_of_zonguldrok / "
            .. "finisher / scythe_of_curses / majin-bo / sceptre_of_torment / "
            .. "undeadhunter"
    )
    api:emit(
        directives.KITEM,
        "i = necronomicon / "
            .. book
            .. "necromutation / "
            .. book
            .. "death's_door / "
            .. book
            .. "haunt / "
            .. book
            .. "borgnjor's_revivification / "
            .. book
            .. "infestation"
    )
    api:emit(
        directives.KITEM,
        "j = phial of floods w:20 / tin of tremorstones / "
            .. "box of beasts, staff of death / any magical staff"
    )

    api:emit(directives.SUBST, "d = d:20 ef g:20")
    api:emit(directives.SUBST, "h = h:5 ij")
end

return loot
