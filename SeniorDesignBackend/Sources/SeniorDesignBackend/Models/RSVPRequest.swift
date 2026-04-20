import Vapor

struct RSVPRequest: Content {
    var Event_ID: String
    var User_UID: String
}