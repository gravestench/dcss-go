local effect = {}

function effect.trigger(ctx)
    ctx:emit("trap", "The custom echo answers.")
end

return effect
