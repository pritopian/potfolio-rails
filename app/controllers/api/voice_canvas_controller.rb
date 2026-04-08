# frozen_string_literal: true

module Api
  class VoiceCanvasController < ApplicationController
    # POST /api/voice_canvas/options
    def options
      intent = intent_pipeline.capture_intent(
        session_id: params.require(:session_id),
        selected_node_ids: params.fetch(:selected_node_ids, [])
      )

      cards = option_synthesizer.call(intent: intent)
      render json: cards
    end

    # POST /api/voice_canvas/execute
    def execute
      plan = executor.plan(
        intent: params.require(:intent).to_h.symbolize_keys,
        chosen_option: params.require(:chosen_option).to_h.symbolize_keys,
        target: params.require(:target).to_h.symbolize_keys
      )

      result = executor.execute!(plan: plan, dry_run: params[:dry_run] == true)
      render json: result
    end

    private

    def intent_pipeline
      @intent_pipeline ||= VoiceCanvas::IntentPipeline.new(realtime_client: realtime_client)
    end

    def option_synthesizer
      @option_synthesizer ||= VoiceCanvas::OptionSynthesizer.new(llm_client: llm_client)
    end

    def executor
      @executor ||= VoiceCanvas::ActionPlanExecutor.new(
        llm_client: llm_client,
        figma_bridge: figma_bridge
      )
    end

    # Adapters below are placeholders to be wired in your app container.
    def llm_client
      Rails.configuration.x.voice_canvas.llm_client
    end

    def realtime_client
      Rails.configuration.x.voice_canvas.realtime_client
    end

    def figma_bridge
      Rails.configuration.x.voice_canvas.figma_bridge
    end
  end
end
