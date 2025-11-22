import Foundation

/// Extremely lightweight API client placeholder.
struct APIClient {
    enum APIError: Error {
        case invalidURL
        case transportError
        case serverError(statusCode: Int)
    }

    var baseURL: URL?

    func request(path: String) async throws -> Data {
        guard let url = baseURL?.appendingPathComponent(path) else {
            throw APIError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) {
            return data
        } else {
            throw APIError.serverError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? -1)
        }
    }
}
