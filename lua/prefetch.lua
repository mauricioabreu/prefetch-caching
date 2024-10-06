local _M = {}
local ngx = ngx
local http = require "resty.http"

local prefetch_cache = ngx.shared.prefetch_cache

function _M.handle()
    local uri = ngx.var.request_uri
    local cache_key = "prefetched:" .. uri

    local prefetched = prefetch_cache:get(cache_key)
    if prefetched then
        ngx.log(ngx.INFO, "Using prefetched segment: ", uri)
        prefetch_cache:delete(cache_key)
    else
        ngx.log(ngx.INFO, "Segment was not prefetched: ", uri)
    end
end

local function prefetch_segment(premature, uri, host_port)
    if premature then return end

    local httpc = http.new()

    local url = string.format("http://127.0.0.1:80%s", uri)

    ngx.log(ngx.INFO, "Prefetching URL: ", url)

    local res, err = httpc:request_uri(url, {
        method = "GET",
        headers = {
            ["Host"] = host_port,
            ["X-Prefetch"] = "true",  -- identify prefetch reqs
        }
    })

    if not res then
        ngx.log(ngx.ERR, "Failed to prefetch: ", uri, " Error: ", err)
        return
    end

    if res.status == 200 then
        ngx.log(ngx.INFO, "Prefetched next segment: ", uri)
        prefetch_cache:set("prefetched:" .. uri, true, 60)
    else
        ngx.log(ngx.ERR, "Failed to prefetch: ", uri, " Status: ", res.status)
    end
end

function _M.set_cache_status()
    -- Check if this is a prefetch request
    if ngx.req.get_headers()["X-Prefetch"] == "true" then
        ngx.log(ngx.INFO, "Skipping prefetch for a prefetch request")
        return
    end

    local link_header = ngx.header["Link"]
    if not link_header then
        ngx.log(ngx.WARN, "No Link header found")
        return
    end

    ngx.log(ngx.INFO, "Link header: ", link_header)

    local next_uri = link_header:match('<(.-)>; rel="next"')
    if not next_uri then
        ngx.log(ngx.WARN, "No next URI found in Link header")
        return
    end
    if not next_uri:match("^/") then
        next_uri = "/" .. next_uri
    end

    ngx.log(ngx.INFO, "Next URI: ", next_uri)

    local cache_key = "prefetched:" .. next_uri
    if prefetch_cache:get(cache_key) then
        ngx.log(ngx.INFO, "Next segment already prefetched or being prefetched: ", next_uri)
        return
    end

    prefetch_cache:set(cache_key, true, 60)

    ngx.timer.at(0, prefetch_segment, next_uri, ngx.var.http_host)
end

return _M
