# frozen_string_literal: true

module VoiceCanvas
  class OptionSynthesizer
    SYSTEM_PROMPT = <<~PROMPT
      You are a Figma design copilot.
      Produce exactly two mutually-exclusive option cards.
      Keep each option short and concrete.
      Return strict JSON matching the provided schema.
    PROMPT

    def initialize(llm_client:, schema: Schemas.option_cards)
      @llm_client = llm_client
      @schema = schema
    end

    def call(intent:)
      @llm_client.generate_json(
        model: "gpt-4.1-mini",
        system: SYSTEM_PROMPT,
        input: {
          intent: intent,
          instruction: "Create exactly 2 tinder-style choices and no extras"
        },
        json_schema: @schema
      )
    end
  end
end
