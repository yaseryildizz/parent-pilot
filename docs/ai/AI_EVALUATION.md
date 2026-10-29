# AI Evaluation

Maintain a versioned corpus of synthetic, licensed, or rigorously de-identified school communications with ground-truth fields, evidence, applicability, conflicts, and expected actions. Partition by school format, language, document quality, source type, child/class ambiguity, and schedule-change type. Never use production content without explicit lawful approval.

## Metrics

- Date accuracy and time accuracy, including timezone/all-day semantics
- Event/announcement/task classification precision and recall
- Child/class applicability accuracy and unresolved-ambiguity rate
- Schedule-override detection and correct recurrence-exception linkage
- False-positive rate, especially for auto-action candidates
- Missed important information (impact-weighted recall)
- Provenance correctness and evidence-field coverage
- Duplicate/conflict detection, calibration, abstention, and human correction rate

Evaluate end-to-end as well as per pipeline stage. Slice results to reveal regressions masked by averages. Compare prompt/model/pipeline versions on a fixed holdout; require security prompt-injection cases and deterministic validator tests.

Dataset governance, importance labels, numerical release thresholds, supported languages, human adjudication, and production drift alerts are **TBD**. Initial policy is **Proposed:** no auto-action until evaluation supports explicit risk-based thresholds.

Evaluate the proposed 0.85 review threshold through calibration, correction, and impact-sliced metrics. High model confidence must never be evaluated as equivalent to factual correctness.
