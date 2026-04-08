# Voice-Controlled Figma Canvas: Product + Technical Blueprint

## Goal
Let a user speak natural language, synthesize that intent into exactly **two Tinder-style options**, then execute the chosen option as deterministic Figma canvas actions.

## End-to-end experience
1. User speaks request (Realtime API session).
2. System transcribes + extracts intent.
3. System returns 2 option cards:
   - binary, mutually exclusive
   - visually distinct style directions
   - each card includes rationale + expected output
4. User taps one card.
5. System generates structured JSON action plan.
6. Executor applies actions to canvas through Figma plugin bridge.
7. If user selects a specific slide and asks for edits, system repeats steps 1-6 with `selectedNodeIds` context.

## Model split (recommended)
- **gpt-4o-realtime**: low-latency voice turn-taking + streaming transcripts.
- **gpt-4.1-mini**: option synthesis (fast + cost-efficient).
- **gpt-4.1**: final JSON action plan generation with strict schema adherence.
- **gpt-4.1** (optional second pass): plan validation/repair before execution.

## Required contracts

### 1) Intent object
```json
{
  "sessionId": "sess_123",
  "requestType": "create_deck",
  "rawTranscript": "I want to create a presentation summarizing facts about the solar system for a 10 year old",
  "userGoal": "Build an age-appropriate educational deck",
  "audience": "10-year-old students",
  "topic": "solar system facts",
  "constraints": ["easy language", "visually engaging"],
  "selectedNodeIds": []
}
```

### 2) Option card object
```json
{
  "id": "opt_a",
  "title": "Scientist Explorer",
  "subtitle": "Evidence-first visuals",
  "designTone": "clean, data-rich, astronomy diagrams",
  "contentTone": "accurate, concise, confidence-building",
  "tradeoff": "Higher information density",
  "preview": ["Fact box per planet", "Scale comparison chart"]
}
```

### 3) Action plan object (executor input)
```json
{
  "planVersion": "1.0",
  "target": {
    "fileId": "fig_file_abc",
    "pageId": "0:1",
    "selectedNodeIds": ["123:456"]
  },
  "operations": [
    {
      "op": "createSlide",
      "id": "slide_1",
      "payload": {
        "title": "Our Solar System",
        "layout": "title_plus_visual"
      }
    },
    {
      "op": "addText",
      "payload": {
        "slideId": "slide_1",
        "styleToken": "body_md",
        "text": "The Sun is a star at the center of our solar system."
      }
    }
  ]
}
```

## Slide-edit loop
When user selects a canvas node/slide and says “make this more playful”:
- Include selected IDs in context.
- Synthesize 2 edit options (e.g., "Playful cartoons" vs "Comic infographic").
- Generate patch-style action JSON (`updateText`, `replaceImage`, `retokenizeColors`) limited to selected nodes.

## Safety + quality guardrails
- Reject non-binary option output; must always be exactly 2 cards.
- Enforce JSON schema before execution.
- Include idempotency key per apply request.
- Dry-run preview available before mutating canvas.
- Log: transcript, option ids shown, chosen id, model versions, execution result.

## Latency target
- Voice stop -> option cards: < 1.5s median.
- Option tap -> executable action plan: < 1.2s median.
- Execution ack: < 500ms (excluding heavy asset generation).
