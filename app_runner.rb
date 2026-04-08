# frozen_string_literal: true

require "json"
require "securerandom"
require "socket"

require_relative "app/services/voice_canvas/schemas"
require_relative "app/services/voice_canvas/intent_pipeline"
require_relative "app/services/voice_canvas/option_synthesizer"
require_relative "app/services/voice_canvas/action_plan_executor"

require_relative "lib/voice_canvas/runtime/in_memory_realtime_client"
require_relative "lib/voice_canvas/runtime/rule_based_llm_client"
require_relative "lib/voice_canvas/runtime/in_memory_figma_bridge"

class VoiceCanvasApp
  def initialize
    @realtime = VoiceCanvas::Runtime::InMemoryRealtimeClient.new
    @llm = VoiceCanvas::Runtime::RuleBasedLlmClient.new
    @figma_bridge = VoiceCanvas::Runtime::InMemoryFigmaBridge.new

    @intent_pipeline = VoiceCanvas::IntentPipeline.new(realtime_client: @realtime)
    @synthesizer = VoiceCanvas::OptionSynthesizer.new(llm_client: @llm)
    @executor = VoiceCanvas::ActionPlanExecutor.new(llm_client: @llm, figma_bridge: @figma_bridge)
  end

  def route(method:, path:, body:)
    case [method, path]
    when ["GET", "/"]
      html = File.read(File.join(__dir__, "public", "index.html"))
      response(200, "text/html", html)
    when ["POST", "/api/voice_canvas/transcript"]
      payload = JSON.parse(body)
      session_id = payload["session_id"] || SecureRandom.hex(8)
      transcript = payload.fetch("transcript")
      @realtime.submit_transcript(session_id: session_id, transcript: transcript)
      json(200, session_id: session_id, transcript: transcript)
    when ["POST", "/api/voice_canvas/options"]
      payload = JSON.parse(body)
      session_id = payload.fetch("session_id")
      selected_node_ids = payload.fetch("selected_node_ids", [])

      intent = @intent_pipeline.capture_intent(session_id: session_id, selected_node_ids: selected_node_ids)
      cards = @synthesizer.call(intent: intent)
      json(200, intent: intent, cards: cards)
    when ["POST", "/api/voice_canvas/execute"]
      payload = JSON.parse(body)
      plan = @executor.plan(
        intent: symbolize(payload.fetch("intent")),
        chosen_option: symbolize(payload.fetch("chosen_option")),
        target: symbolize(payload.fetch("target"))
      )

      result = @executor.execute!(plan: plan, dry_run: payload["dry_run"] == true)
      json(200, plan: plan, result: result)
    else
      json(404, error: "Not found")
    end
  rescue StandardError => e
    json(500, error: e.message)
  end

  private

  def symbolize(obj)
    case obj
    when Hash
      obj.each_with_object({}) { |(k, v), memo| memo[k.to_sym] = symbolize(v) }
    when Array
      obj.map { |v| symbolize(v) }
    else
      obj
    end
  end

  def json(status, payload)
    response(status, "application/json", JSON.pretty_generate(payload))
  end

  def response(status, content_type, body)
    [status, content_type, body]
  end
end

class TinyServer
  STATUS_TEXT = {
    200 => "OK",
    404 => "Not Found",
    500 => "Internal Server Error"
  }.freeze

  def initialize(port:, app:)
    @server = TCPServer.new(port)
    @app = app
    @port = port
  end

  def start
    puts "Voice Canvas app running at http://localhost:#{@port}"

    loop do
      socket = @server.accept
      handle(socket)
    rescue Interrupt
      puts "\nShutting down..."
      break
    ensure
      socket&.close
    end
  end

  private

  def handle(socket)
    request_line = socket.gets
    return if request_line.nil?

    method, full_path, = request_line.split(" ")
    path = full_path.split("?").first

    headers = {}
    while (line = socket.gets)
      break if line == "\r\n"

      key, value = line.split(":", 2)
      headers[key.downcase] = value.to_s.strip
    end

    length = headers.fetch("content-length", "0").to_i
    body = length.positive? ? socket.read(length) : ""

    status, content_type, response_body = @app.route(method: method, path: path, body: body)
    write_response(socket, status: status, content_type: content_type, body: response_body)
  end

  def write_response(socket, status:, content_type:, body:)
    socket.write("HTTP/1.1 #{status} #{STATUS_TEXT.fetch(status, 'OK')}\r\n")
    socket.write("Content-Type: #{content_type}\r\n")
    socket.write("Content-Length: #{body.bytesize}\r\n")
    socket.write("Connection: close\r\n")
    socket.write("\r\n")
    socket.write(body)
  end
end

port = ENV.fetch("PORT", "4567").to_i
TinyServer.new(port: port, app: VoiceCanvasApp.new).start
