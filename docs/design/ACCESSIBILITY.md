# Accessibility

Target platform accessibility requirements from the first feature, not as a release retrofit.

- Support all Dynamic Type sizes without truncating dates, actions, or evidence.
- Provide meaningful VoiceOver labels, values, hints, headings, grouping, and predictable focus after navigation/status changes.
- Keep interactive targets at least platform minimum; support keyboard/switch access where applicable.
- Meet contrast requirements in light, dark, increased-contrast, and disabled states; color is never the sole cue.
- Respect Reduce Motion and Reduce Transparency; avoid time-limited review interactions.
- Announce asynchronous progress and completion without excessive repetition.
- Make calendar alternatives available as accessible lists and express conflicts, confidence, and source trust in words.
- Use locale-aware dates/times and simple error/recovery language.

Include accessibility identifiers only where they improve UI testing, not as substitutes for accessible labels. Test with VoiceOver, largest text sizes, contrast modes, RTL, and reduced motion. Supported OS accessibility baseline and formal audit cadence are **TBD**.

Documents and Extraction Review use Dynamic Type semantic fonts, multi-line important text, combined filename/size announcements, labeled decision controls with selected values, textual status alongside color, explicit evidence disclosure, and a nearby explanation for disabled confirmation. Evidence and decision animations respect Reduce Motion. Development previews cover major states for light/dark and large-type inspection.
