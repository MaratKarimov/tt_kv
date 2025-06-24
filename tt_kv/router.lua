local vshard = require('vshard')
local log = require('log')
local crud = require('crud')

-- Bootstrap the vshard router
while true do
    local ok, err = vshard.router.bootstrap({
        if_not_bootstrapped = true,
    })
    if ok then
        break
    end
    log.info(('Router bootstrap error: %s'):format(err))
end

-- Объявление функций для пространства key_value
local key_value = {
    get_by_prefix = function(prefix)
        -- init results
        local results = {}
        -- find all storages
        local storages = require('vshard').router.routeall()
        -- on each storage
        for _, storage in pairs(storages) do
            -- call local function
            local result, err = storage:callro('key_value.get_by_prefix_locally', { prefix })
            -- check for error
            if err then
                error("Failed to call function on storage: " .. tostring(err))
            end
            -- add to results
            for _, tuple in ipairs(result) do
                table.insert(results, tuple)
            end
        end
        -- return
        return results
    end,
}

rawset(_G, 'key_value', key_value)

-- Регистрация функций для пространства key_value, определение прав на эти функции
for name, _ in pairs(key_value) do
    box.schema.func.create('key_value.' .. name, { if_not_exists = true })
    box.schema.user.grant('app', 'execute', 'function', 'key_value.' .. name, { if_not_exists = true })
    box.schema.user.grant('client', 'execute', 'function', 'key_value.' .. name, { if_not_exists = true })
end