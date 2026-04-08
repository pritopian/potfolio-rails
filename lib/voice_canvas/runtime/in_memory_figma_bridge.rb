# frozen_string_literal: true

module VoiceCanvas
  module Runtime
    class InMemoryFigmaBridge
      attr_reader :history

      def initialize
        @history = []
      end

      def apply_operations(operations)
        @history << operations
        {
          status: "applied",
          appliedOperationCount: operations.count,
          operations: operations
        }
      end
    end
  end
end
