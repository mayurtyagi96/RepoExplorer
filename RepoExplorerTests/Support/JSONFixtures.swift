//
//  JSONFixtures.swift
//  RepoExplorerTests
//

import Foundation

enum JSONFixtures {
    /// Full repository exercising acronym keys (html_url, avatar_url, spdx_id).
    static let repositoryFull = """
    {
      "id": 12345,
      "name": "swift",
      "full_name": "apple/swift",
      "owner": {
        "login": "apple",
        "avatar_url": "https://avatars.githubusercontent.com/u/10639145?v=4",
        "html_url": "https://github.com/apple"
      },
      "html_url": "https://github.com/apple/swift",
      "description": "The Swift Programming Language",
      "stargazers_count": 67000,
      "forks_count": 10300,
      "watchers_count": 67000,
      "open_issues_count": 8100,
      "language": "C++",
      "topics": ["swift", "compiler"],
      "license": { "key": "apache-2.0", "name": "Apache License 2.0", "spdx_id": "Apache-2.0" },
      "updated_at": "2026-06-18T00:00:00Z"
    }
    """

    /// Repository with null description/language/license and an ABSENT topics key.
    static let repositoryMinimal = """
    {
      "id": 7,
      "name": "mystery",
      "full_name": "octocat/mystery",
      "owner": {
        "login": "octocat",
        "avatar_url": "https://example.com/a.png",
        "html_url": "https://github.com/octocat"
      },
      "html_url": "https://github.com/octocat/mystery",
      "description": null,
      "stargazers_count": 3,
      "forks_count": 0,
      "watchers_count": 3,
      "open_issues_count": 0,
      "language": null,
      "license": null,
      "updated_at": "2026-01-01T00:00:00Z"
    }
    """

    static let searchResponse = """
    {
      "total_count": 2,
      "incomplete_results": false,
      "items": [\(repositoryFull), \(repositoryMinimal)]
    }
    """

    static let rateLimitBody = """
    {
      "message": "API rate limit exceeded for 1.2.3.4.",
      "documentation_url": "https://docs.github.com/rest/overview/rate-limits-for-the-rest-api"
    }
    """

    static let validationBody = """
    {
      "message": "Validation Failed",
      "errors": [{ "resource": "Search", "field": "q", "code": "invalid" }],
      "documentation_url": "https://docs.github.com/v3/search"
    }
    """
}
