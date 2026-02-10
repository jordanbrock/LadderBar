import Foundation

actor CricketAPIService {
    static let shared = CricketAPIService()

    private let baseURL = "https://grassrootsapiproxy.cricket.com.au"
    private let searchBaseURL = "https://api.playcommunity.pulselive.com"
    private let session: URLSession
    private let decoder: JSONDecoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
    }

    func fetchOrganisation(orgId: String) async throws -> OrganisationResponse {
        let url = "\(baseURL)/orgsproducts/organisation/\(orgId)?responseModifier=includePrograms&jsconfig=eccn:true"
        return try await fetch(url: url)
    }

    func fetchSeasons(orgId: String) async throws -> SeasonsResponse {
        let url = "\(baseURL)/fixturesladders/organisations/\(orgId)/seasons?jsconfig=eccn:true"
        return try await fetch(url: url)
    }

    func fetchTeams(orgId: String, seasonId: String) async throws -> TeamsResponse {
        let url = "\(baseURL)/fixturesladders/organisations/\(orgId)/teams?seasonId=\(seasonId)&jsconfig=eccn:true"
        return try await fetch(url: url)
    }

    func searchClubs(term: String) async throws -> ClubSearchResponse {
        let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? term
        let url = "\(searchBaseURL)/ca-search/v1/playCommunity?types=PLAYCOMM_CLUB&term=\(encoded)&size=20&page=0&sorting=ASC&tags=search"
        return try await fetch(url: url)
    }

    func fetchLadders(gradeId: String) async throws -> LaddersResponse {
        let url = "\(baseURL)/fixturesladders/grades/\(gradeId)/ladders?jsconfig=eccn:true"
        return try await fetch(url: url)
    }

    private func fetch<T: Decodable>(url urlString: String) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL(urlString)
        }
        let (data, response) = try await session.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
}

enum APIError: LocalizedError {
    case invalidURL(String)
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL(let url): return "Invalid URL: \(url)"
        case .invalidResponse: return "Invalid response from server"
        case .httpError(let code): return "HTTP error \(code)"
        case .decodingError(let error): return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
