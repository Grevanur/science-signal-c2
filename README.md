# Science Signal

Science Signal is a Flutter true-or-false quiz that requests five live,
medium-difficulty Science & Nature questions from Open Trivia Database.

## Run the app

```bash
flutter pub get
flutter run
```

An internet connection is required for each new round. The app sends this GET
request:

```text
https://opentdb.com/api.php?amount=5&category=17&difficulty=medium&type=boolean&encode=url3986
```

## Features

- Visible loading, error, and retry states
- Validation of HTTP 200, API `response_code` 0, and exactly five results
- URL-decoding before question display or answer comparison
- One answer per question with text and color feedback
- At most one point per question
- Five-entry results review with selected and correct answers
- Replay that requests a fresh round
- Clearly labeled asynchronous score-submission simulation
- Duplicate-submission prevention while the simulation is running

## Score submission

No instructor endpoint was supplied, so the score action is intentionally a
simulation. It displays this payload shape and does not send it to a server:

```json
{
  "score": 3,
  "total": 5,
  "category": "Science & Nature"
}
```

The trivia GET reads questions from Open Trivia Database. A real score write
would be a separate POST request to an instructor-provided endpoint, using its
required fields. The app would show success only after that server confirmed
the write.

## Verification

```bash
flutter analyze
flutter test
```

See `VERIFICATION.md` for the completed test notes and `evidence/` for the
screenshots and short Android emulator recording.

## Repository safety

This project contains no API keys, passwords, access tokens, private endpoints,
or local environment files. Open Trivia Database does not require a key for the
request used here.
