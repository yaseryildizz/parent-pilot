# Localization

Externalize user-facing strings from the start and use String Catalogs when implementation begins. Do not concatenate translated fragments. Provide translator context for school-specific concepts, confidence, recurrence, pickup/drop-off, and source provenance.

Use Foundation locale/calendar/timezone formatting. Keep machine instants, school-local timezone, all-day dates, and source wording distinct. Never parse displayed localized strings back into domain data. Support pluralization, grammatical variation, long text, and RTL mirroring; avoid embedding direction into icons or layout.

Source content may remain in its original language; any future translation must be labeled and preserve the original evidence. AI language support and translation are **TBD**, and unsupported/ambiguous content must route to review.

Initial app locales, fallback language, school-calendar variants, and localization QA process are **TBD**.
