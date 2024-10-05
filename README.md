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

...
