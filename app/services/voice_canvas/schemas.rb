# frozen_string_literal: true

module VoiceCanvas
  module Schemas
    module_function

    def option_cards
      {
        type: "object",
        required: %w[options],
        properties: {
          options: {
            type: "array",
            minItems: 2,
            maxItems: 2,
            items: {
              type: "object",
              required: %w[id title subtitle designTone contentTone tradeoff preview],
              properties: {
                id: { type: "string" },
                title: { type: "string" },
                subtitle: { type: "string" },
                designTone: { type: "string" },
                contentTone: { type: "string" },
                tradeoff: { type: "string" },
                preview: {
                  type: "array",
                  minItems: 2,
                  items: { type: "string" }
                }
              }
            }
          }
        }
      }
    end

    def action_plan
      {
        type: "object",
        required: %w[planVersion target operations],
        properties: {
          planVersion: { type: "string" },
          target: {
            type: "object",
            required: %w[fileId pageId selectedNodeIds],
            properties: {
              fileId: { type: "string" },
              pageId: { type: "string" },
              selectedNodeIds: {
                type: "array",
                items: { type: "string" }
              }
            }
          },
          operations: {
            type: "array",
            minItems: 1,
            items: {
              type: "object",
              required: %w[op payload],
              properties: {
                op: { type: "string" },
                id: { type: "string" },
                payload: { type: "object" }
              }
            }
          }
        }
      }
    end
  end
end
