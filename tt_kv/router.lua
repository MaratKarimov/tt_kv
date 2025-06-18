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
        -- Вызываем функцию на всех шардах
        local result, err = crud.map_call(
            'key_value.get_by_prefix_locally',      -- имя функции
            { prefix },                             -- аргументы
            {
                timeout = 5                         -- таймаут выполнения (опционально)
            }
        )

        if not result then
            return nil, "Error during map_call: " .. tostring(err)
        end

        -- Результат уже объединён в result.data
        return result.data
    end,
}

rawset(_G, 'key_value', key_value)

-- Регистрация функций для пространства key_value, определение прав на эти функции
for name, _ in pairs(key_value) do
    box.schema.func.create('key_value.' .. name, { if_not_exists = true })
    box.schema.user.grant('app', 'execute', 'function', 'key_value.' .. name, { if_not_exists = true })
    box.schema.user.grant('client', 'execute', 'function', 'key_value.' .. name, { if_not_exists = true })
end