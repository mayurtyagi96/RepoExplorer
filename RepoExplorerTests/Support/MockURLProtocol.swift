//
//  MockURLProtocol.swift
//  RepoExplorerTests
//
//  Intercepts requests on an ephemeral URLSession so LiveGitHubAPIClient can be tested
//  without the network. Register via config.protocolClasses = [MockURLProtocol.self].
//

import Foundation

final class MockURLProtocol: URLProtocol {
    /// Returns the canned (response, body) for a request, or throws to simulate transport failure.
    /// `nonisolated(unsafe)` because URLProtocol's hooks are nonisolated; tests run serially and
    /// reset this in tearDown.
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
