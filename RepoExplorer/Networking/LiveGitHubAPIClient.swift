//
//  LiveGitHubAPIClient.swift
//  RepoExplorer
//
//  URLSession-backed implementation of GitHubAPIClient.
//

import Foundation

/// Live client hitting https://api.github.com/search/repositories (unauthenticated by default).
///
/// `nonisolated` so the whole type stays off the main actor; `searchRepositories` is additionally
/// `@concurrent` so its body — request building, the network await, and JSON decoding — runs on the
/// concurrent executor rather than the caller's (the view model's main actor). With
/// `SWIFT_APPROACHABLE_CONCURRENCY = YES`, a plain `nonisolated async` func would otherwise run on
/// the caller's actor, putting the decode back on the main thread.
nonisolated struct LiveGitHubAPIClient: GitHubAPIClient {
    /// Injection point for a future bearer token. Returns `nil` today (unauthenticated).
    private let tokenProvider: @Sendable () -> String?

    init(tokenProvider: @escaping @Sendable () -> String? = { nil }) {
        self.tokenProvider = tokenProvider
    }

    private static let endpoint = "https://api.github.com/search/repositories"

    /// Shared stateless decoder, reused across requests.
    private static let decoder = JSONDecoder()

    @concurrent
    nonisolated func searchRepositories(query: String, page: Int, perPage: Int) async throws -> SearchResponse {
        try Task.checkCancellation()
        let request = try makeRequest(query: query, page: page, perPage: perPage)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw GitHubAPIError.transport
        }

        guard let http = response as? HTTPURLResponse else { throw GitHubAPIError.transport }

        switch http.statusCode {
        case 200..<300:
            do {
                return try Self.decoder.decode(SearchResponse.self, from: data)
            } catch {
                throw GitHubAPIError.decoding
            }
        case 403, 429:
            throw GitHubAPIError.rateLimited(retryAfter: Self.retryAfter(from: http))
        case 422:
            throw GitHubAPIError.invalidQuery(message: Self.message(from: data))
        case 500..<600:
            throw GitHubAPIError.server(status: http.statusCode)
        default:
            throw GitHubAPIError.http(status: http.statusCode, message: Self.message(from: data))
        }
    }

    /// Builds the search request, percent-encoding the `q` value explicitly so qualifiers
    /// (`language:swift`, `stars:>100`) and `+` survive correctly.
    private nonisolated func makeRequest(query: String, page: Int, perPage: Int) throws -> URLRequest {
        guard var components = URLComponents(string: Self.endpoint) else { throw GitHubAPIError.invalidURL }
        components.queryItems = [
            URLQueryItem(name: "sort", value: "stars"),
            URLQueryItem(name: "order", value: "desc"),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page", value: String(page)),
        ]
        // Encode the q VALUE only (not the whole query string). Allow RFC 3986 unreserved chars;
        // everything else (space, ':', '>', '+', ...) is percent-encoded and GitHub decodes it back.
        let encodedQ = query.addingPercentEncoding(withAllowedCharacters: Self.queryValueAllowed) ?? ""
        let tail = components.percentEncodedQuery.map { "&\($0)" } ?? ""
        components.percentEncodedQuery = "q=\(encodedQ)\(tail)"

        guard let url = components.url else { throw GitHubAPIError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        if let token = tokenProvider() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    /// Alphanumerics + RFC 3986 unreserved marks. Notably excludes space and `+`.
    private static let queryValueAllowed: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-._~")
        return set
    }()

    private static func message(from data: Data) -> String? {
        (try? decoder.decode(GitHubErrorBody.self, from: data))?.message
    }

    /// Prefer `Retry-After` (secondary limit); fall back to `x-ratelimit-reset` (primary search limit).
    private static func retryAfter(from response: HTTPURLResponse) -> TimeInterval? {
        if let value = response.value(forHTTPHeaderField: "Retry-After"), let seconds = Double(value) {
            return seconds
        }
        if let reset = response.value(forHTTPHeaderField: "x-ratelimit-reset"), let resetEpoch = Double(reset) {
            return max(0, resetEpoch - Date().timeIntervalSince1970)
        }
        return nil
    }
}
