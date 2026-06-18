//
//  RepositoryDecodingTests.swift
//  RepoExplorerTests
//

import XCTest
@testable import RepoExplorer

final class RepositoryDecodingTests: XCTestCase {
    private let decoder = JSONDecoder()

    func test_decodesAcronymAndNestedKeys() throws {
        let repo = try decoder.decode(Repository.self, from: Data(JSONFixtures.repositoryFull.utf8))

        XCTAssertEqual(repo.id, 12345)
        XCTAssertEqual(repo.fullName, "apple/swift")
        XCTAssertEqual(repo.htmlURL, "https://github.com/apple/swift")
        XCTAssertEqual(repo.webURL?.absoluteString, "https://github.com/apple/swift")
        XCTAssertEqual(repo.stargazersCount, 67000)
        XCTAssertEqual(repo.owner?.login, "apple")
        XCTAssertEqual(repo.owner?.avatarURL, "https://avatars.githubusercontent.com/u/10639145?v=4")
        XCTAssertNotNil(repo.owner?.avatarImageURL)
        XCTAssertEqual(repo.license?.spdxID, "Apache-2.0")
        XCTAssertEqual(repo.license?.shortName, "Apache-2.0")
        XCTAssertEqual(repo.topicList, ["swift", "compiler"])
    }

    func test_handlesNullAndAbsentFields() throws {
        let repo = try decoder.decode(Repository.self, from: Data(JSONFixtures.repositoryMinimal.utf8))

        XCTAssertNil(repo.description)
        XCTAssertNil(repo.language)
        XCTAssertNil(repo.license)
        XCTAssertEqual(repo.topicList, [])   // "topics" key absent -> coalesced to []
    }

    func test_decodesSearchResponseEnvelope() throws {
        let response = try decoder.decode(SearchResponse.self, from: Data(JSONFixtures.searchResponse.utf8))

        XCTAssertEqual(response.totalCount, 2)
        XCTAssertFalse(response.incompleteResults)
        XCTAssertEqual(response.items.count, 2)
        XCTAssertEqual(response.items.first?.name, "swift")
    }

    func test_licenseShortName_fallsBackToNameForNoAssertion() throws {
        let json = #"{ "key": "other", "name": "Other", "spdx_id": "NOASSERTION" }"#
        let license = try decoder.decode(License.self, from: Data(json.utf8))
        XCTAssertEqual(license.shortName, "Other")
    }
}
