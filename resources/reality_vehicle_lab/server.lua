-- Catalog is read from disk per request: adding a vehicle does not restart this resource.
RegisterNetEvent('rvl:getCatalog', function()
    local src = source
    local raw = LoadResourceFile(GetCurrentResourceName(), 'vehicles.json') or '[]'
    TriggerClientEvent('rvl:catalog', src, raw)
end)
