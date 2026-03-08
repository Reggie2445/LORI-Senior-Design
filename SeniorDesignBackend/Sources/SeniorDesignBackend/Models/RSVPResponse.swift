import Vapor

struct RSVPResponse: Content {
    var message: String
    var attendanceCount: Int
    var alreadyRSVPed: Bool
}