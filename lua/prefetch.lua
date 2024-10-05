local _M = {}
local ngx = ngx

local function get_next_segment(current_segment)
    local res = ngx.location.capture("/prefetch" .. current_segment, { method = ngx.HTTP_HEAD })
    if res.status == ngx.HTTP_OK then
        local link_header = res.header["Link"]
        if link_header then
            local next_segment = link_header:match("<(.-)>; rel=\"next\"")
            if next_segment and not next_segment:match("^/") then
                next_segment = "/" .. next_segment
            end
            return next_segment
        end
    end
    return nil
end

function _M.handle()
    local current_segment = ngx.var.request_uri
    local prefetch_cache = ngx.shared.prefetch_cache

    -- Check if we need to prefetch based on the previous request
    local to_prefetch = prefetch_cache:get(current_segment)
    if to_prefetch then
        prefetch_cache:delete(current_segment)
        ngx.timer.at(0, function()
            local prefetch_res = ngx.location.capture("/prefetch" .. to_prefetch)
            ngx.log(ngx.INFO, "Prefetched segment: " .. to_prefetch .. ", status: " .. prefetch_res.status)
        end)
    end

    local next_segment = get_next_segment(current_segment)
    if next_segment then
        prefetch_cache:set(next_segment, current_segment, 60)
    end
end

function _M.set_cache_status()
    local current_segment = ngx.var.request_uri
    local cache_status = ngx.var.upstream_cache_status
    ngx.log(ngx.INFO, "Cache status for " .. current_segment .. ": " .. tostring(cache_status))

    if cache_status == "MISS" or cache_status == "EXPIRED" then
        local prefetch_cache = ngx.shared.prefetch_cache
        local next_segment = prefetch_cache:get(current_segment)
        if next_segment then
            prefetch_cache:set(next_segment, current_segment, 60)
        end
    end
end

return _M
