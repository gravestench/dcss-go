-- The cross market changes both its shop positions and its wall fill.
-- Two separate source coinflips stay at their original DES positions.
local directives = require("constants.vault_directives")

local handler = {}

-- Pick either two strong shops or a wider three-shop cross. The stair
-- glyphs change with that choice, so shop identities move with them.
local function choose_shop_layout(api)
    if api:coinflip() then
        api:emit(directives.SUBST, [=[A = <, B = >]=])
        api:emit(directives.KFEAT, [=[C = jewellery shop / book shop]=])
        api:emit(directives.KFEAT, [=[D = antique armour shop / book shop]=])
    else
        api:emit(directives.SUBST, [=[T = <, A = >]=])
        api:emit(directives.KFEAT, [=[B = antique weapon shop]=])
        api:emit(directives.KFEAT, [=[C = antique armour shop]=])
        api:emit(directives.KFEAT, [=[D = general shop / distillery shop]=])
    end
end

-- The second coinflip opens one crossing and seals the opposite wall;
-- it never rerolls the shops selected above.
local function choose_wall_fill(api)
    if api:coinflip() then
        api:emit(directives.SUBST, [=[' = .]=])
        api:emit(directives.SUBST, [=[G : G.]=])
    else
        api:emit(directives.SUBST, [=[' = x]=])
        api:emit(directives.SUBST, [=[G = .]=])
    end
end

handler.choose_shop_layout = choose_shop_layout
handler.choose_wall_fill = choose_wall_fill

return handler
