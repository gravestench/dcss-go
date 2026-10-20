-- Theory of operation: Crazy Yiuf's authored cottage is a fixed DES map,
-- but the front gate and one rare hammer tile are chosen when it is placed.
-- Keeping these rolls in named Lua methods preserves the source geometry
-- while letting a mod replace this one cottage policy by path.
local directives = require("constants.vault_directives")
local cottage = {}

-- One third of cottages have a narrow gate; the other two thirds leave
-- the front as a destructible, plant-filled approach.
local function cottage_gate(api)
    if api:roll(3) == 0 then
        api:emit(directives.SUBST, "A:AAA+")
        api:emit(directives.SUBST, "A=x")

        return
    end

    api:emit(directives.SUBST, "A:;;;x")
    api:emit(directives.SUBST, "a=;")
end

-- The source gives one cottage in 300 a decorative hammer glyph. This
-- happens after the common floor and door substitutions, so it is a
-- per-map draw and not a global generation setting.
local function cottage_hammer(api)
    if api:roll(300) == 0 then
        api:emit(directives.SUBST, 't="')
    end
end

cottage.cottage_gate = cottage_gate
cottage.cottage_hammer = cottage_hammer

return cottage
