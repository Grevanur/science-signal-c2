# Verification Notes

Verified on November 12, 2026.

## Required behavior

| Requirement | Verification result |
|---|---|
| Fetch five medium Science & Nature boolean questions | Passed on the Android emulator with live Open Trivia Database data. |
| Validate HTTP and API response | `fetchScienceQuestions` requires HTTP 200, `response_code` 0, and exactly five results. |
| Decode returned text | Model test confirmed percent-encoded question text is decoded before use. |
| Loading state | Widget test held the request open and confirmed the progress indicator and loading message. |
| Failure and retry | Widget test forced a `FormatException`, confirmed the readable error, then retried successfully. |
| Correct and incorrect feedback | Verified in widget tests and screenshots. Feedback uses text plus green/red styling. |
| One-answer rule | After the first selection, both answer controls are disabled. A repeated tap cannot change the stored answer or score. |
| Continue rule | The continue button stays disabled until an answer is selected. |
| Score and five review entries | Widget test completed the round and confirmed all five review cards. Emulator evidence shows live results. |
| Replay | Replay resets quiz/submission state and starts a new live request. |
| Submission payload | Displays score, total 5, and category `Science & Nature`. |
| Submission truthfulness | The action and result both say simulation and explicitly state that no data was sent to a server. |
| Duplicate submission prevention | The submission button is disabled while pending and remains disabled after completion. |

## Evidence index

| File | What it demonstrates |
|---|---|
| `evidence/01_answer_feedback.png` | Controlled incorrect-answer case: question number, progress, green correct answer, red wrong selection, text feedback, enabled continue action. |
| `evidence/02_results_and_submission.png` | Controlled full-height view of the score, all five review entries, payload, completed simulation, and replay action. |
| `evidence/03_android_runtime_question.png` | Android 17 emulator running the app with a live Open Trivia Database question. |
| `evidence/04_android_runtime_feedback.png` | Android emulator answer-feedback state. |
| `evidence/05_android_runtime_results.png` | Android emulator score and live-question answer review. |
| `evidence/06_android_runtime_submission.png` | Android emulator payload and completed simulation, including the no-server-write statement. |
| `evidence/07_android_runtime_demo.mp4` | Short Android emulator recording showing the running app and replay/feedback interaction. |

The first two screenshots use fixed test questions so the expected state is
repeatable. The Android screenshots use the real network response returned
during the verification run.

## Read versus write

The question request is a GET: it reads quiz data and does not submit a score.
The score action in this project is a local asynchronous simulation because no
write endpoint was provided. A confirmed remote write would require a separate
POST request, the instructor's payload format, a pending state, visible failure
handling, and a success response from the backend.
