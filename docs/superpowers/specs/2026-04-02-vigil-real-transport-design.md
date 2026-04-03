# Vigil Real Transport Design

## Summary

Replace the current placeholder local transport shell with a real localhost listener so the `Vigil` macOS app can receive actual OpenCode session events. The implementation should use Apple’s native `Network.framework`, keep HTTP support intentionally minimal, preserve the existing business-layer `EventIngestionController`, and surface real listener and ingestion health through diagnostics.

This work is about making the current architecture real, not broadening the product scope. It should not redesign the event schema, the plugin payload contract, the session store, or Ghostty integration.

## Goals

- Run a real localhost listener in the macOS app.
- Accept authenticated plugin events over HTTP.
- Reuse the existing `EventIngestionController` request boundary.
- Update `SessionStore` and UI from real incoming events.
- Provide enough diagnostics to debug transport issues quickly.

## Non-Goals

- No general-purpose HTTP server.
- No support for chunked transfer encoding or keep-alive reuse.
- No server-side compression, multipart, or streaming.
- No change to the plugin event schema.
- No redesign of preview/mock data beyond avoiding confusion during real-event testing.

## Current Gap

The current `EmbeddedHTTPServer` only allocates a token and writes the bridge file. It does not actually bind to a port or read requests. The plugin transport is therefore structurally complete but not yet capable of reaching a real app listener.

## Architecture

The real transport should be split into four explicit layers.

### 1. Listener Layer

Use `NWListener` from `Network.framework`.

Responsibilities:

- bind to `127.0.0.1`
- choose or accept a local port
- accept inbound connections
- read request bytes
- write response bytes
- close the connection after each request

Non-responsibilities:

- JSON decoding
- auth decisions
- session updates
- diagnostics string formatting

### 2. Minimal HTTP Decode Layer

Add a small parser that transforms raw bytes into `EventIngestionRequest`.

Supported request features:

- HTTP/1.1 request line
- ordinary headers
- `Content-Length`
- UTF-8 request body
- single request per connection

Unsupported features:

- chunked transfer encoding
- persistent connection reuse
- pipelining
- multipart bodies
- compressed request bodies

### 3. Existing Business Ingestion Layer

Keep `EventIngestionController` as the business boundary.

Responsibilities remain:

- validate bearer token
- route request by method/path
- decode event JSON
- update `SessionStore`
- return response model

This layer should remain independent of `Network.framework`.

### 4. Lifecycle and Diagnostics Layer

The server lifecycle should expose transport facts to the rest of the app:

- listener status
- active port
- bridge file write success
- last successfully received event timestamp
- last ingestion error

These facts can then be surfaced through `AppState` diagnostics.

## HTTP Support Scope

The server must support exactly these routes:

- `POST /v1/events`
- `GET /v1/health`

### Route Semantics

#### `POST /v1/events`

- requires `Authorization: Bearer <token>`
- requires a valid JSON body matching the existing schema
- returns `202` on accepted event

#### `GET /v1/health`

- lightweight health probe
- no body parsing needed
- returns `200` with a tiny JSON body

### Response Codes

- `200` successful health response
- `202` accepted event
- `400` malformed request or invalid JSON
- `401` bad or missing bearer token
- `404` unknown route
- `405` unsupported method for known route

### Payload Size Policy

The listener should reject oversized requests.

Suggested limit:

- 64 KB total raw request size

This prevents accidental complexity while remaining ample for the current event schema.

## Framing and Connection Rules

To keep the raw `Network.framework` implementation deterministic, the listener must follow these explicit rules:

- read until the HTTP header terminator `\r\n\r\n` is found or the request size limit is exceeded
- parse `Content-Length` and treat it as required for `POST /v1/events`
- after headers are parsed, continue reading until exactly `Content-Length` body bytes have been received
- if the connection closes early or the declared body length is not fully received, return `400`
- if request bytes do not complete within a short read timeout, terminate the connection and record a timeout-class transport error
- every response must include `Connection: close`
- after sending the response, the server closes the connection unconditionally

This phase supports exactly one request per connection.

## Data Flow

The real event path should be:

1. OpenCode plugin builds full event snapshot
2. plugin transport sends HTTP request to localhost
3. `NWListener` accepts connection
4. listener reads bytes and decodes a minimal HTTP request
5. `EventIngestionController` handles the request
6. controller updates `SessionStore`
7. `AppState` / presentation layers refresh UI
8. diagnostics update `lastReceivedEventAt` and clear any transient transport error state

No extra source of truth should be introduced.

## Plugin Compatibility Assumptions

This design assumes and now explicitly requires that the existing plugin transport continues to behave as follows:

- every request is sent with a bounded JSON body and a concrete `Content-Length`
- the plugin does not rely on chunked transfer encoding
- the plugin does not rely on keep-alive or multiple requests per connection
- the plugin treats HTTP status code as the primary success signal and does not require a rich response body contract

If the plugin implementation diverges from any of these assumptions, the listener implementation must stop and be adjusted before shipping.

## Diagnostics Requirements

The app should surface these transport facts:

- whether the listener is currently active
- which port is bound
- whether the bridge file exists and was written successfully
- the last successfully received event time
- the last categorized transport or ingestion error if present

These diagnostics must make it easy to distinguish:

- server not listening
- bridge missing
- token mismatch
- malformed request
- valid transport but downstream Ghostty action failure

To make that distinction reliable, the error fact should include both:

- error stage: `listener`, `parse`, `auth`, `route`, `ingestion`, `action`
- short human-readable message

## Preview Data Behavior

The current debug preview sessions are useful for UI work, but they can obscure real transport testing.

The real transport design should ensure:

- preview data is only seeded when there are no real sessions and preview mode is explicitly desired
- once a real event arrives, preview content must not be confused with real session state

It is acceptable for this phase to keep preview mode development-only as long as real-event testing is clearly distinguishable.

## Error Handling

### Listener Errors

If the listener fails to bind or enters a failed state:

- diagnostics should reflect the failure
- the app should not crash
- bridge file writing should not falsely claim a working listener

### Parse Errors

If a request cannot be parsed:

- return `400`
- record a categorized error fact with stage `parse`
- leave session state untouched

### Auth Errors

If the token is missing or invalid:

- return `401`
- record a categorized error fact with stage `auth`
- leave session state untouched

### Route and Method Errors

- return `404` for unknown route
- return `405` for wrong method on supported route
- record a categorized error fact with stage `route`
- leave session state untouched

## Testing Strategy

Add tests at three levels.

### Unit Tests

- HTTP parser tests
- listener lifecycle helper tests where feasible
- `EventIngestionController` tests remain as-is or expand for `/v1/health` and `/v1/sessions`

### Command-Line Verification

- `curl http://127.0.0.1:<port>/v1/health`
- authenticated `curl` to `POST /v1/events`

### End-to-End Manual Verification

- app starts and writes bridge file
- health endpoint responds
- manual event POST updates UI
- plugin can deliver a real event through the bridge-configured port
- malformed request, bad token, and route mismatch each show distinct diagnostics categories

## Implementation Sequence

1. Add minimal HTTP parser and response serializer
2. Replace `EmbeddedHTTPServer` placeholder with real `NWListener`
3. Wire `/v1/health` and `/v1/events`
4. Expose listener and categorized ingestion diagnostics
5. Verify manual `curl` flow
6. Connect plugin to real listener and verify real event delivery

## Success Criteria

This work is successful if:

- the app actually listens on localhost
- the bridge file points to a working listener
- `curl` can hit `health` and `events`
- a real plugin event updates the app UI
- diagnostics clearly report listener and ingestion state
- the existing event schema and session logic remain unchanged
