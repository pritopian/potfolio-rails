# frozen_string_literal: true

module VoiceCanvas
  class ActionPlanExecutor
    PLAN_PROMPT = <<~PROMPT
      You generate executable Figma action plans.
      Use the selected option to create a slide sequence or targeted edits.
      Return strict JSON only.
    PROMPT

    def initialize(llm_client:, figma_bridge:, schema: Schemas.action_plan)
      @llm_client = llm_client
      @figma_bridge = figma_bridge
      @schema = schema
    end

    def plan(intent:, chosen_option:, target:)
      @llm_client.generate_json(
        model: "gpt-4.1",
        system: PLAN_PROMPT,
        input: {
          intent: intent,
          chosenOption: chosen_option,
          target: target
        },
        json_schema: @schema
      )
    end

    def execute!(plan:, dry_run: false)
      return { status: "preview", plan: plan } if dry_run

      @figma_bridge.apply_operations(plan.fetch(:operations))
    end
  end
end
