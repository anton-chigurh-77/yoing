import Foundation

public enum TranscriptionError: LocalizedError {
    case missingAPIKey
    case emptyAudio
    case invalidResponse
    case providerError(statusCode: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Add an xAI API key in Settings before dictating."
        case .emptyAudio:
            return "The recording did not contain audio."
        case .invalidResponse:
            return "xAI returned a response Yoing could not read."
        case .providerError(let statusCode, let message):
            return "xAI error \(statusCode): \(message)"
        }
    }
}

public struct XAITranscriptionClient {
    private let endpoint: URL
    private let transport: HTTPTransport

    public init(
        endpoint: URL = URL(string: "https://api.x.ai/v1/stt")!,
        transport: HTTPTransport = URLSession.shared
    ) {
        self.endpoint = endpoint
        self.transport = transport
    }

    public func transcribe(
        _ audio: RecordedAudio,
        apiKey: String,
        language: String = "en"
    ) async throws -> String {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw TranscriptionError.missingAPIKey
        }

        guard !audio.data.isEmpty else {
            throw TranscriptionError.emptyAudio
        }

        var form = MultipartFormData()
        form.appendField(name: "format", value: "true")
        form.appendField(name: "language", value: language)
        form.appendFile(
            name: "file",
            filename: audio.filename,
            mimeType: audio.mimeType,
            data: audio.data
        )
        form.finalize()

        var request = URLRequest(url: endpoint, timeoutInterval: 90)
        request.httpMethod = "POST"
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=\(form.boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = form.body

        let (data, response) = try await transport.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TranscriptionError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw TranscriptionError.providerError(
                statusCode: httpResponse.statusCode,
                message: Self.errorMessage(from: data)
            )
        }

        let decoded = try JSONDecoder().decode(XAITranscriptionResponse.self, from: data)
        let transcript = decoded.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transcript.isEmpty else {
            throw TranscriptionError.emptyAudio
        }

        return transcript
    }

    private static func errorMessage(from data: Data) -> String {
        if let decoded = try? JSONDecoder().decode(XAIErrorEnvelope.self, from: data) {
            if let nested = decoded.error?.message, !nested.isEmpty {
                return nested
            }

            if let message = decoded.message, !message.isEmpty {
                return message
            }
        }

        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            return text
        }

        return "Request failed."
    }
}

private struct XAITranscriptionResponse: Decodable {
    let text: String
}

private struct XAIErrorEnvelope: Decodable {
    struct NestedError: Decodable {
        let message: String
    }

    let message: String?
    let error: NestedError?
}
