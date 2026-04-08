# Voice Canvas Demo App (Runnable)

This repository now includes a **runnable local app** for your requested flow:

1. speak/type request,
2. synthesize into exactly two Tinder-style options,
3. choose one,
4. generate structured action JSON,
5. execute operations.

## Run the app

```bash
ruby app_runner.rb
```

Open: `http://localhost:4567`

## What works right now

- Voice input (via browser SpeechRecognition when supported) or typed transcript
- `POST /api/voice_canvas/transcript`: stores transcript for a session
- `POST /api/voice_canvas/options`: returns exactly 2 option cards
- `POST /api/voice_canvas/execute`: creates action plan JSON and executes it
- Selected slide/node IDs influence behavior:
  - no selected IDs => create slide operations
  - selected IDs present => emit targeted edit operations

## Files

- `app_runner.rb` – tiny TCP HTTP server + JSON API routing
- `public/index.html` – demo UI with voice button + two-card choice UX
- `app/services/voice_canvas/*` – intent/options/plan executor services
- `lib/voice_canvas/runtime/*` – in-memory runtime adapters for realtime, LLM, and Figma bridge
- `script/voice_canvas_smoke_test.rb` – command-line smoke test

## Quick CLI test

```bash
ruby script/voice_canvas_smoke_test.rb
```

## Example API calls (without UI)

```bash
curl -s -X POST http://localhost:4567/api/voice_canvas/transcript \
  -H 'Content-Type: application/json' \
  -d '{"session_id":"demo1","transcript":"Create a solar system deck for 10 year olds"}'

curl -s -X POST http://localhost:4567/api/voice_canvas/options \
  -H 'Content-Type: application/json' \
  -d '{"session_id":"demo1","selected_node_ids":[]}'
```

## Notes

- This runnable app uses a rule-based local LLM adapter so you can test now without external API keys.
- To go production, replace runtime adapters with OpenAI Realtime + Responses clients and your real Figma bridge.
