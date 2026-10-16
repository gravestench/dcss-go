local handler = {}

local function choose_subst(api)
    api:emit("SUBST", "1 = .")
end

handler.choose_subst = choose_subst

return handler
