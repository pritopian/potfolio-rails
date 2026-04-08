# Voice Canvas Orchestration (Figma)

This repository now contains a Rails-oriented scaffold for a voice-to-canvas workflow:

1. Capture voice intent from Realtime API.
2. Convert request into exactly 2 Tinder-style option cards.
3. Turn selected card into a strict JSON action plan. 
4. Execute plan on a Figma bridge.

## Key files
- `app/services/voice_canvas/intent_pipeline.rb`
- `app/services/voice_canvas/option_synthesizer.rb`
- `app/services/voice_canvas/action_plan_executor.rb`
- `app/services/voice_canvas/schemas.rb`
- `app/controllers/api/voice_canvas_controller.rb`
- `docs/voice_control_figma_canvas.md`

## API shape
- `POST /api/voice_canvas/options` -> returns 2 option cards.
- `POST /api/voice_canvas/execute` -> plans + executes chosen option.

## Notes
- `llm_client`, `realtime_client`, and `figma_bridge` are dependency-injected via `Rails.configuration.x.voice_canvas.*`.
- JSON schema enforcement is embedded in the service layer for both option synthesis and execution plan generation.
