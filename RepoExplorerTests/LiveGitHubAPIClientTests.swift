//
//  LiveGitHubAPIClientTests.swift
//  RepoExplorerTests
//

import XCTest
@testable import RepoExplorer

final class LiveGitHubAPIClientTests: XCTestCase {

    private func makeClient() -> LiveGitHubAPIClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return LiveGitHubAPIClient(session: URLSession(configuration: config))
    }

    override func tearDown() {
        MockURLProtocol.handler = nil
        super.tearDown()
    }

    func test_success_decodesResponse() async throws {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (response, Data(JSONFixtures.searchResponse.utf8))
        }

        let result = try await makeClient().searchRepositories(query: "swift", page: 1, perPage: 30)

        XCTAssertEqual(result.totalCount, 2)
        XCTAssertEqual(result.items.count, 2)
    }

    func test_rateLimit_throwsRateLimitedWithRetryAfter() async {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 403, httpVersion: nil,
                                           headerFields: ["Retry-After": "30"])!
            return (response, Data(JSONFixtures.rateLimitBody.utf8))
        }

        do {
            _ = try await makeClient().searchRepositories(query: "swift", page: 1, perPage: 30)
            XCTFail("expected an error")
        } catch let error as GitHubAPIError {
            guard case .rateLimited(let retryAfter) = error else { return XCTFail("got \(error)") }
            XCTAssertEqual(retryAfter, 30)
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func test_validationFailure_throwsInvalidQuery() async {
        MockURLProtocol.handler = { request in
            let response = HTTPURLResponse(url: request.url!, statusCode: 422, httpVersion: nil, headerFields: nil)!
            return (response, Data(JSONFixtures.validationBody.utf8))
        }

        do {
            _ = try await makeClient().searchRepositories(query: "bad", page: 1, perPage: 30)
            XCTFail("expected an error")
        } catch let error as GitHubAPIError {
            guard case .invalidQuery = error else { return XCTFail("got \(error)") }
        } catch {
            XCTFail("unexpected error \(error)")
        }
    }

    func test_request_encodesQueryAndSetsHeaders() throws {
        let request = try makeClient().makeRequest(query: "json parser language:swift", page: 2, perPage: 50)
        let url = try XCTUnwrap(request.url?.absoluteString)

        XCTAssertTrue(url.contains("q=json%20parser%20language%3Aswift"), "unexpected URL: \(url)")
        XCTAssertTrue(url.contains("per_page=50"))
        XCTAssertTrue(url.contains("page=2"))
        XCTAssertTrue(url.contains("sort=stars"))
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept"), "application/vnd.github+json")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-GitHub-Api-Version"), "2022-11-28")
        XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))   // unauthenticated by default
    }
}
