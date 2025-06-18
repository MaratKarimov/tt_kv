box.watch('box.status', function()
    if box.info.ro then
        return
    end

    -- ====================================
    -- Создание пространства key_value
    -- ====================================
    box.schema.create_space('key_value', {
        format = {
            { name = 'key', type = 'string' },
            { name = 'bucket_id', type = 'unsigned' },
            { name = 'value', type = 'string' },
            { name = 'expire_at', type = 'unsigned' }
        },
        if_not_exists = true
    })

    -- Создание первичного индекса
    box.space.key_value:create_index('id', {type = 'tree', parts = { 'key' }, unique = true, if_not_exists = true})

    -- Создание индекса шардирования
    box.space.key_value:create_index('bucket_id', { type = 'tree', parts = { 'bucket_id' }, unique = false, if_not_exists = true })

    -- Создание индекса для проверки истечения TTL
    box.space.key_value:create_index('expire_at_idx', { type = 'tree', parts = { 'expire_at' }, unique = false, if_not_exists = true})
end)

-- Объявление функций для пространства key_value
local key_value = {
    is_expired = function(args, tuple)
        return (tuple[4] > 0) and (require('fiber').time() > tuple[4])
    end,
    get_by_prefix_locally = function(prefix)
        -- Инициализируем пустой массив для хранения результатов
        local result = {}
        -- Получаем курсор с итератором GE по первичному индексу 'id'
        local index = box.space.key_value.index.id
        local iter = index:iterator('GE', { prefix })

        for tuple in iter do
            local key = tuple[1]

            -- Проверяем, начинается ли ключ с заданного префикса
            if string.sub(key, 1, #prefix) == prefix then
                table.insert(result, {
                    key = key,
                    value = tuple[3],
                    expire_at = tuple[4]
                })
            else
                break  -- Вышли за диапазон — завершаем обход
            end
        end

        return result
    end
}

-- Регистрация функций для пространства key_value, определение прав на эти функции
rawset(_G, 'key_value', key_value)
for name, _ in pairs(key_value) do
    box.schema.func.create('key_value.' .. name, { setuid = true, if_not_exists = true })
    box.schema.user.grant('storage', 'execute', 'function', 'key_value.' .. name, { if_not_exists = true })
end