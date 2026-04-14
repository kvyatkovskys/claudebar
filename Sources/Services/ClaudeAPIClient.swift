import Foundation

struct ClaudeAPIClient {
    private static let baseURL = "https://claude.ai"

    let sessionKey: String
    let orgId: String

    // MARK: - Request Builders

    func buildUsageRequest() -> URLRequest {
        let url = URL(string: "\(Self.baseURL)/api/organizations/\(orgId)/usage")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("sessionKey=\(sessionKey)", forHTTPHeaderField: "Cookie")
        return request
    }

    static func buildOrganizationsRequest(sessionKey: String) -> URLRequest {
        let url = URL(string: "\(baseURL)/api/organizations")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("sessionKey=\(sessionKey)", forHTTPHeaderField: "Cookie")
        return request
    }

    // MARK: - Response Parsers

    static func parseUsageResponse(data: Data) throws -> UsageResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            let formatters = [ISO8601DateFormatter.withFractionalSeconds, ISO8601DateFormatter.standard]
            for formatter in formatters {
                if let date = formatter.date(from: dateString) { return date }
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot parse date: \(dateString)")
        }
        return try decoder.decode(UsageResponse.self, from: data)
    }

    static func parseOrganizationsResponse(data: Data) throws -> [Organization] {
        return try JSONDecoder().decode([Organization].self, from: data)
    }

    // MARK: - Network Calls

    func fetchUsage() async throws -> UsageResponse {
        let (data, response) = try await URLSession.shared.data(for: buildUsageRequest())
        try Self.validateHTTPResponse(response)
        return try Self.parseUsageResponse(data: data)
    }

    static func fetchOrganizations(sessionKey: String) async throws -> [Organization] {
        let request = buildOrganizationsRequest(sessionKey: sessionKey)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateHTTPResponse(response)
        return try parseOrganizationsResponse(data: data)
    }

    private static func validateHTTPResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        switch http.statusCode {
        case 200: return
        case 401, 403: throw APIError.sessionExpired
        case 429: throw APIError.rateLimited
        default: throw APIError.httpError(http.statusCode)
        }
    }
}

enum APIError: Error, Equatable {
    case invalidResponse
    case sessionExpired
    case rateLimited
    case httpError(Int)
}

extension ISO8601DateFormatter {
    static let withFractionalSeconds: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static let standard: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
