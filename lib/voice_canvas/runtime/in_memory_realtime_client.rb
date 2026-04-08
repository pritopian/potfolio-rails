# frozen_string_literal: true

module VoiceCanvas
  module Runtime
    class InMemoryRealtimeClient
      def initialize
        @transcripts = {}
      end

      def submit_transcript(session_id:, transcript:)
        @transcripts[session_id] = transcript
      end

      def final_transcript(session_id:)
        @transcripts.fetch(session_id) do
          raise KeyError, "No transcript stored for session_id=#{session_id}"
        end
      end
    end
  end
end
