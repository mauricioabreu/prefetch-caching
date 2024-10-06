# Prefetch Caching

This is a proof of concept for a pretech caching system designed to download TS (Transport Stream) files by folliwng the `Link` header in the HTTP response for the current segment being downloaded.

## How to run

Starting the NGINX and the origin server is easy as:
```bash
make run
```

If you want to stop the services:
```bash
make stop
```

## How it works

When a request for a segment comes, this modules tries to prefetch the next segment by following the `Link` header in the HTTP response. If the next segment is successfully prefetched, it is stored in the cache and served when requested - so it will be a HIT, not a MISS.

The prefetching is done asynchronously, so the client does not have to wait for the next segment to be downloaded. It reduces the round-trip made by clients to to every server in the cache layer.

A simple workflow:

- Check if each requested segment was prefetched;
- After serving a segment, it looks for information about the next segment (`Link` header);
- If a next segment is identified, it starts an asynchronous prefetch of that segment;
- When the next segment is actually requested, serving it from the cache if it was successfully prefetched.

```mermaid
sequenceDiagram
    participant Client
    participant OriginShield as Origin Shield
    participant Prefetch
    participant Origin

    Client->>OriginShield: Request segment N
    activate OriginShield
    OriginShield->>Prefetch: handle()
    activate Prefetch
    Prefetch-->>OriginShield: Check if prefetched
    deactivate Prefetch
    alt Segment prefetched
        OriginShield->>Client: Serve segment N from cache
    else Segment not prefetched
        OriginShield->>Origin: Request segment N
        activate Origin
        Origin->>OriginShield: Return segment N
        deactivate Origin
        OriginShield->>Client: Serve segment N
    end
    OriginShield->>Prefetch: set_cache_status()
    activate Prefetch
    Prefetch->>Prefetch: Extract next segment info
    Prefetch->>OriginShield: Schedule prefetch
    deactivate Prefetch
    deactivate OriginShield
    OriginShield->>Origin: Prefetch segment N+1
    activate Origin
    Origin->>OriginShield: Return segment N+1
    deactivate Origin
    OriginShield->>Prefetch: Store prefetched segment
    activate Prefetch
    deactivate Prefetch

    Client->>OriginShield: Request segment N+1
    activate OriginShield
    OriginShield->>Prefetch: handle()
    activate Prefetch
    Prefetch-->>OriginShield: Confirm prefetched
    deactivate Prefetch
    OriginShield->>Client: Serve segment N+1 from cache
    deactivate OriginShield
```
