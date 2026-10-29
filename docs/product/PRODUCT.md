# Product

## Problem

Parents receive school information across PDFs, emails, newsletters, screenshots, messages, and calendars. Important details are easy to miss, duplicate, or misunderstand—especially when a new message changes an existing schedule.

## Users and vision

The target user is a parent or guardian managing one or more children, potentially across multiple schools. ParentPilot should become a trusted companion that converts school communication into explainable calendar items, tasks, and reminders without presenting guesses as facts.

## Value proposition

ParentPilot reduces manual interpretation while keeping parents in control: each derived item shows its source, conflicts are visible, and uncertain or high-impact changes require review.

## MVP scope

- Authentication, child and school context
- PDF upload and school email ingestion
- Backend text extraction, classification, structured extraction, validation, and confidence
- Review of extracted event/task/reminder candidates with provenance
- Smart school calendar, one-day schedule overrides, and reminders
- Conflict, duplicate, and change detection with confirmation where required

Email provider/connectivity details are **TBD**.

## Non-goals

- School portal scraping or official school API integrations
- WhatsApp share extension, screenshot/image ingestion, or public-web crawling
- Fully autonomous action when evidence is uncertain or impact is high
- Replacing the school's authoritative systems or providing emergency guarantees
- General family calendar or learning-management features

## Key scenarios

- A parent uploads a timetable PDF, reviews extracted recurring events, and accepts them.
- An official email changes Thursday pickup from 14:30 to 12:30 for one date; ParentPilot proposes a dated override, updates the linked reminder after confirmation/policy checks, and retains both sources.
- Two sources disagree; the app shows the conflict and trust context rather than silently overwriting data.
- A parent manages applicable information separately for multiple children/classes.

## Principles

Accuracy over automation; provenance by default; explicit conflicts; least-privilege privacy; backend-owned AI; official sources preferred; calendar and reminders as core capabilities; pragmatic architecture.

## Success criteria

**Proposed:** measure reviewed-candidate precision, correction rate, important-item recall, provenance completeness, schedule-override accuracy, time-to-review, and successful reminder delivery. Numerical targets are **TBD** pending baseline evaluation and user research. See [AI_EVALUATION.md](../ai/AI_EVALUATION.md) and [ANALYTICS.md](../operations/ANALYTICS.md).
