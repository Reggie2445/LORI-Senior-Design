import Vapor
@preconcurrency import AWSS3
@preconcurrency import AWSDynamoDB
import AWSClientRuntime
import Foundation

func routes(_ app: Application) throws {

    let bucket = "event-photos-test"
    let eventsTable = "Events"
    let attendanceTable = "Event_Attendance"

    let s3 = try S3Client(region: "us-east-1")
    let dynamo = try DynamoDBClient(region: "us-east-1")

    // MARK: - Helpers

    @Sendable
    func stringValue(
        from item: [String: DynamoDBClientTypes.AttributeValue],
        key: String
    ) -> String {
        if case let .s(value)? = item[key] {
            return value
        }
        return ""
    }

    @Sendable
    func getAttendanceCount(eventID: String) async throws -> Int {
        let result = try await dynamo.query(
            input: QueryInput(
                expressionAttributeValues: [
                    ":eventId": .s(eventID)
                ],
                keyConditionExpression: "Event_ID = :eventId",
                tableName: attendanceTable
            )
        )

        return result.items?.count ?? 0
    }

    // MARK: - CREATE EVENT

    app.post("events") { req async throws -> HTTPStatus in
        let event = try req.content.decode(Event.self)

        var item: [String: DynamoDBClientTypes.AttributeValue] = [
            "Event_ID": .s(event.Event_ID),
            "Event_Title": .s(event.Event_Title),
            "Event_Date": .s(event.Event_Date),
            "Event_Time": .s(event.Event_Time),
            "Event_Location": .s(event.Event_Location),
            "Event_Description": .s(event.Event_Description),
            "User_UID": .s(event.User_UID)
        ]

        if let base64 = event.image_base64,
           let imageData = Data(base64Encoded: base64) {

            let key = "\(event.Event_ID).jpg"

            _ = try await s3.putObject(
                input: PutObjectInput(
                    body: .data(imageData),
                    bucket: bucket,
                    contentType: "image/jpeg",
                    key: key,
                    serverSideEncryption: .aes256
                )
            )

            item["Photo_Key"] = .s(key)
        }

        _ = try await dynamo.putItem(
            input: PutItemInput(
                item: item,
                tableName: eventsTable
            )
        )

        return .created
    }

    // MARK: - LIST EVENTS

    app.get("events") { req async throws -> [Event] in
        let result = try await dynamo.scan(
            input: ScanInput(tableName: eventsTable)
        )

        guard let items = result.items else { return [] }

        var events: [Event] = []

        for item in items {
            let eventID = stringValue(from: item, key: "Event_ID")
            let attendanceCount = try await getAttendanceCount(eventID: eventID)

            let event = Event(
                Event_ID: eventID,
                Event_Title: stringValue(from: item, key: "Event_Title"),
                Event_Date: stringValue(from: item, key: "Event_Date"),
                Event_Time: stringValue(from: item, key: "Event_Time"),
                Event_Location: stringValue(from: item, key: "Event_Location"),
                Event_Description: stringValue(from: item, key: "Event_Description"),
                User_UID: stringValue(from: item, key: "User_UID"),
                Event_Attendance: attendanceCount,
                image_base64: nil
            )

            events.append(event)
        }

        return events
    }

    // MARK: - RSVP TO EVENT

    app.post("events", "rsvp") { req async throws -> RSVPResponse in
        let body = try req.content.decode(RSVPRequest.self)

        let existing = try await dynamo.getItem(
            input: GetItemInput(
                key: [
                    "Event_ID": .s(body.Event_ID),
                    "User_UID": .s(body.User_UID)
                ],
                tableName: attendanceTable
            )
        )

        if existing.item != nil {
            let count = try await getAttendanceCount(eventID: body.Event_ID)

            return RSVPResponse(
                message: "User already RSVP'd",
                attendanceCount: count,
                alreadyRSVPed: true
            )
        }

        _ = try await dynamo.putItem(
            input: PutItemInput(
                item: [
                    "Event_ID": .s(body.Event_ID),
                    "User_UID": .s(body.User_UID)
                ],
                tableName: attendanceTable
            )
        )

        let count = try await getAttendanceCount(eventID: body.Event_ID)

        return RSVPResponse(
            message: "RSVP successful",
            attendanceCount: count,
            alreadyRSVPed: false
        )
    }

    // MARK: - DELETE EVENT

    app.delete("events", ":id") { req async throws -> HTTPStatus in
        guard let id = req.parameters.get("id") else {
            throw Abort(.badRequest)
        }

        let attendanceResult = try await dynamo.query(
            input: QueryInput(
                expressionAttributeValues: [
                    ":eventId": .s(id)
                ],
                keyConditionExpression: "Event_ID = :eventId",
                tableName: attendanceTable
            )
        )

        if let attendanceItems = attendanceResult.items {
            for item in attendanceItems {
                let userID = stringValue(from: item, key: "User_UID")

                _ = try await dynamo.deleteItem(
                    input: DeleteItemInput(
                        key: [
                            "Event_ID": .s(id),
                            "User_UID": .s(userID)
                        ],
                        tableName: attendanceTable
                    )
                )
            }
        }

        _ = try await dynamo.deleteItem(
            input: DeleteItemInput(
                key: [
                    "Event_ID": .s(id)
                ],
                tableName: eventsTable
            )
        )

        _ = try? await s3.deleteObject(
            input: DeleteObjectInput(
                bucket: bucket,
                key: "\(id).jpg"
            )
        )

        return .ok
    }
}