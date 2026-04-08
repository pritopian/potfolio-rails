# frozen_string_literal: true

module VoiceCanvas
  class IntentPipeline
    def initialize(realtime_client:)
      @realtime_client = realtime_client
    end

    # Returns normalized intent hash from live voice input.
    def capture_intent(session_id:, selected_node_ids: [])
      transcript = @realtime_client.final_transcript(session_id: session_id)

      {
        sessionId: session_id,
        requestType: selected_node_ids.empty? ? "create_deck" : "edit_selected_slides",
        rawTranscript: transcript,
        selectedNodeIds: selected_node_ids
      }
    end
  end
end
