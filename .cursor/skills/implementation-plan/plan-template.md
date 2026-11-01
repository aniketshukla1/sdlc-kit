# <KEY> plan

## Summary
<2–3 sentences: what changes and why>

## Approach
- <max 5 bullets>

## Roadmap (one row per open sub-task; None if there are none)
| Order | Sub-task | Summary | Plan tasks | Depends on | Status (todo / branch / MR !iid / merged) |
|-------|----------|---------|------------|------------|-------------------------------------------|

## Files
| Path | New/Edit | Lines now → expected | Purpose |
|------|----------|----------------------|---------|

## Tasks
- [ ] T1: <one AC end to end> (calls: <METHOD /path, function(args) -> type, or Component props>; files: ...)
- [ ] T2: ...

## Data changes
- Migration: <yes/no; tables/columns>
- NOT NULL on existing table: <server_default / 3-step / n/a>
- Downgrade: <how it reverses>
- Indexes: <new indexes and why>
- Elasticsearch: <none / proposal for human, see Human actions>

## API contract
| Method | Path | Request | Response | Status codes | Auth (required / public: ticket line) |
|--------|------|---------|----------|--------------|---------------------------------------|

## UI
- Screen/route: ...
- States: loading / empty / error / success: <what each shows>
- shadcn components used: ...

## Edge and abuse cases
Checklist. Keep the ones that apply and give the exact result of each:
- Abuse (tested first): someone else's id → 403/404, a huge input → 422, `<script>` in text stays text,
  a role without access
- Input: empty, too long, wrong type, boundary values (0, max), special characters
- Not found / deleted / belongs to another user
- Duplicate / unique conflict
- Permission: role without access, unauthenticated
- Empty list, one item, max page size
- Concurrent update of the same record
- Null/optional fields in DB and UI
- Timezones, money precision
- Slow network / server error / double submit in UI

| # | Case | Exact result (status, message, UI text) |
|---|------|------------------------------------------|

## Test plan
| Covers (AC#/Edge#) | Test name | Type (unit/integration/component/e2e) | Task | Expected (exact) | File |
|--------------------|-----------|----------------------------------------|------|------------------|------|

## New dependencies
<None, or: package, why the existing stack can't do it, size, last release, licence>

## Risks
- ...
- Ask first (the human approves these with the plan; None if none): new auth flow; new kind of personal data
  (why it's needed, how it's deleted); new external service, or a server fetch of a user-given URL; CORS change;
  file upload (type allowlist, size cap); new role or permission; new feature flag (owner, removal ticket)

## Human actions required
None

## Out of scope
- ...
