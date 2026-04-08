# frozen_string_literal: true

require "json"
require "ostruct"

require_relative "../app/services/voice_canvas/schemas"
require_relative "../app/services/voice_canvas/intent_pipeline"
require_relative "../app/services/voice_canvas/option_synthesizer"
require_relative "../app/services/voice_canvas/action_plan_executor"

class FakeRealtimeClient
  def final_transcript(session_id:)
    "I want a solar system deck for 10 year olds (session=#{session_id})"
  end
end

class FakeLlmClient
  def generate_json(model:, system:, input:, json_schema:)
    return two_option_cards if json_schema.dig(:properties, :options)

    action_plan(input)
  end

  private

  def two_option_cards
    {
      options: [
        {
          id: "opt_a",
          title: "Scientist Explorer",
          subtitle: "Evidence-first visuals",
          designTone: "clean, data-rich",
          contentTone: "accurate + concise",
          tradeoff: "Higher info density",
          preview: ["Planet fact cards", "Scale chart"]
        },
        {
          id: "opt_b",
          title: "Cosmic Cartoon",
          subtitle: "Bright and playful",
          designTone: "colorful, rounded shapes",
          contentTone: "simple and fun",
          tradeoff: "Less numerical depth",
          preview: ["Mascot planets", "Big icon labels"]
        }
      ]
    }
  end

  def action_plan(input)
    {
      planVersion: "1.0",
      target: input.fetch(:target),
      operations: [
        {
          op: "createSlide",
          id: "slide_1",
          payload: {
            title: "Our Solar System",
            layout: "title_plus_visual"
          }
        },
        {
          op: "addText",
          payload: {
            slideId: "slide_1",
            styleToken: "body_md",
            text: "The Sun is the center of our solar system."
          }
        }
      ]
    }
  end
end

class FakeFigmaBridge
  attr_reader :applied

  def apply_operations(operations)
    @applied = operations
    {
      status: "applied",
      appliedOperationCount: operations.count
    }
  end
end

def assert!(condition, message)
  raise "Assertion failed: #{message}" unless condition
end

realtime = FakeRealtimeClient.new
llm = FakeLlmClient.new
bridge = FakeFigmaBridge.new

intent = VoiceCanvas::IntentPipeline.new(realtime_client: realtime).capture_intent(
  session_id: "sess_demo"
)

cards = VoiceCanvas::OptionSynthesizer.new(llm_client: llm).call(intent: intent)
assert!(cards.fetch(:options).size == 2, "must return exactly two option cards")

chosen = cards.fetch(:options).first
target = { fileId: "fig_file_abc", pageId: "0:1", selectedNodeIds: [] }

executor = VoiceCanvas::ActionPlanExecutor.new(llm_client: llm, figma_bridge: bridge)
plan = executor.plan(intent: intent, chosen_option: chosen, target: target)

assert!(plan.fetch(:operations).any?, "action plan should contain operations")

preview = executor.execute!(plan: plan, dry_run: true)
assert!(preview.fetch(:status) == "preview", "dry_run should not mutate")

apply_result = executor.execute!(plan: plan)
assert!(apply_result.fetch(:status) == "applied", "apply should execute operations")

puts "Smoke test passed."
puts JSON.pretty_generate(
  intent: intent,
  options: cards.fetch(:options).map { |option| option.slice(:id, :title) },
  planned_ops: plan.fetch(:operations).map { |operation| operation.fetch(:op) },
  execution: apply_result
)
