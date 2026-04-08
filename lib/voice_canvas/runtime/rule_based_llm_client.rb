# frozen_string_literal: true

module VoiceCanvas
  module Runtime
    class RuleBasedLlmClient
      def generate_json(model:, system:, input:, json_schema:)
        return option_cards(input.fetch(:intent)) if json_schema.dig(:properties, :options)

        action_plan(input)
      end

      private

      def option_cards(intent)
        transcript = intent.fetch(:rawTranscript, "")
        playful = transcript.match?(/kid|fun|playful|colorful|young|child/i)

        left = {
          id: "opt_a",
          title: "Scientist Explorer",
          subtitle: "Metrics-first and structured",
          designTone: "clean, high-contrast, chart-friendly",
          contentTone: "precise, factual, concise",
          tradeoff: "More dense information",
          preview: ["Data callouts", "Comparison chart"]
        }

        right = {
          id: "opt_b",
          title: playful ? "Cosmic Playground" : "Storytelling Visual",
          subtitle: playful ? "Kid-friendly and colorful" : "Narrative, lighter density",
          designTone: playful ? "bright palette, icon-heavy" : "warm palette, balanced visuals",
          contentTone: playful ? "simple and fun" : "engaging and easy to scan",
          tradeoff: playful ? "Lower technical depth" : "Less analytical detail",
          preview: playful ? ["Mascot planets", "Big labels"] : ["Hero illustrations", "Short facts"]
        }

        { options: [left, right] }
      end

      def action_plan(input)
        intent = input.fetch(:intent)
        chosen = input.fetch(:chosenOption)
        target = input.fetch(:target)

        title = chosen.fetch(:title)
        transcript = intent.fetch(:rawTranscript)
        selected_ids = target.fetch(:selectedNodeIds)

        operations = if selected_ids.empty?
          build_create_sequence(title: title, transcript: transcript)
        else
          build_edit_sequence(title: title, selected_ids: selected_ids)
        end

        {
          planVersion: "1.0",
          target: target,
          operations: operations
        }
      end

      def build_create_sequence(title:, transcript:)
        [
          {
            op: "createSlide",
            id: "slide_1",
            payload: { title: "Generated from voice", layout: "title_plus_visual" }
          },
          {
            op: "addText",
            payload: {
              slideId: "slide_1",
              styleToken: "body_md",
              text: "Mode: #{title}. Request: #{transcript}"
            }
          },
          {
            op: "addBulletList",
            payload: {
              slideId: "slide_1",
              bullets: [
                "Audience-tuned language",
                "Two-option workflow",
                "Editable by selected slide context"
              ]
            }
          }
        ]
      end

      def build_edit_sequence(title:, selected_ids:)
        selected_ids.map.with_index(1) do |node_id, idx|
          {
            op: "updateText",
            id: "edit_#{idx}",
            payload: {
              nodeId: node_id,
              text: "Updated with #{title} style via voice command"
            }
          }
        end
      end
    end
  end
end
