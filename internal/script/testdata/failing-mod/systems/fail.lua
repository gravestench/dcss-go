register.system{
    id = "test.fail",
    update = function(ctx, entity)
        ctx:add(entity, "test.counter", { value = 1 })
        error("intentional failure")
    end,
}
