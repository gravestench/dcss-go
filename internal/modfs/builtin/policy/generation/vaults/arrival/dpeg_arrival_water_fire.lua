local directives = require("constants.vault_directives")

local handler = {}

local water_fire_choices = {
    "A=*:., a=1:./*:l, b=1:./*:l",
    "B=*:., c=1:./*:l, d=1:./*:l, e=1:./*:l, f=1:./*:l, g=1:./*:l",
    "C=*:., h=1:./*:l, i=1:./*:l, j=1:./*:l, k=1:./*:l",
    "D=*:., m=1:./*:w, n=1:./*:w, o=1:./*:w, p=1:./*:w",
    "E=*:., q=1:./*:w, r=1:./*:w, s=1:./*:w",
    "F=*:., t=1:./*:w, u=1:./*:w, v=1:./*:w",
}

-- Port of arrival/twisted.des:17-33. One draw chooses the feature group.
local function choose_water_fire_layout(api)
    local choice = api:roll(12)

    if choice < #water_fire_choices then
        api:emit(directives.NSUBST, water_fire_choices[choice + 1])

        return
    end

    api:emit(directives.SUBST, "X=+, Y:YYY+")
    api:emit(directives.NSUBST, "Y=1:+/*:x")
end

-- The second coinflip only occurs if the first one fails.
local function choose_exit_layout(api)
    if api:coinflip() then
        api:emit(directives.SUBST, "Z=x, z=+, V=x")
    elseif api:coinflip() then
        api:emit(directives.SUBST, "Z=x, V=+")
        api:emit(directives.NSUBST, "z = 1:+ / *:x")
    else
        api:emit(directives.SUBST, "Zz=., V=x")
    end
end

local function check_exit_marker(api)
    local markers = api:marker_positions("arrival_stairs", 1)

    if markers == nil or markers[1] == nil then
        return false
    end

    return not api:has_exit(markers[1])
end

handler.choose_water_fire_layout = choose_water_fire_layout
handler.choose_exit_layout = choose_exit_layout
handler.check_exit_marker = check_exit_marker

return handler
