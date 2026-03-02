import Foundation

#if DEBUG
enum content_card_preview_item {
    static let document = FeedItem(
        id: "preview-document",
        contentType: .document,
        title: "Anthropic Responds to Competitor Advances With Claude Opus 4.5",
        behaviour: FeedItemBehaviour(
            summary: "Workers' ability and ambition to use AI for better outcomes is the single greatest defining factor for prosperity.",
            media: FeedItemMedia(
                imageURL: "https://www.gartner.com/resources/836200/836261/Figure_1_CIO_Leadership_of_People_Culture_and_Change_Overview.png",
                imageURLs: [
                    "https://www.gartner.com/resources/836200/836261/Figure_1_CIO_Leadership_of_People_Culture_and_Change_Overview.png"
                ],
                showImage: true
            ),
            schedule: FeedItemSchedule(
                publishedDate: "02 December 2025"
            ),
            primaryAction: FeedItemAction(title: "Save")
        )
    )

    static let on_demand_webinar = FeedItem(
        id: "preview-on-demand-webinar",
        contentType: .onDemandWebinar,
        title: "Client Webinar: M&A Trends & Emerging Practices Webinar",
        behaviour: FeedItemBehaviour(
            summary: "M&A activity is in slow recovery mode, with macroeconomic, AI and regulatory challenges reinforcing the trend.",
            media: FeedItemMedia(
                imageURL: "https://static.gartner.com/multimedia/assets/Mzc2NzQwQUo0ZTBhMTM1NQ/replay.0000001.jpg",
                imageURLs: [
                    "https://static.gartner.com/multimedia/assets/Mzc2NzQwQUo0ZTBhMTM1NQ/replay.0000001.jpg"
                ],
                showImage: true
            ),
            schedule: FeedItemSchedule(
                publishedDate: "08 October 2024"
            ),
            statusText: "On Demand",
            primaryAction: FeedItemAction(title: "Watch Replay")
        )
    )

    static let upcoming_webinar = FeedItem(
        id: "preview-upcoming-webinar",
        contentType: .upcomingWebinar,
        title: "Accelerate Product Delivery With AI-Driven Design-to-Code Workflows",
        behaviour: FeedItemBehaviour(
            summary: "With AI, design to code is now a reality, enabling teams to rapidly turn prompts into designs and working front-end code.",
            media: FeedItemMedia(
                imageURL: "https://www.gartner.com/resources/822300/822375/Figure_1_Software_Engineering_for_Technical_Professionals_Overview.png",
                imageURLs: [
                    "https://www.gartner.com/resources/822300/822375/Figure_1_Software_Engineering_for_Technical_Professionals_Overview.png"
                ],
                showImage: true
            ),
            schedule: FeedItemSchedule(
                eventDate: "24 February 2026",
                eventStartDate: "24 February 2026",
                eventTime: "11:00 AM - 11:45 AM EST",
                eventLocation: "Virtual Event",
                displayTimeZone: "EST"
            ),
            statusText: "Upcoming",
            isRegistered: false,
            primaryAction: FeedItemAction(title: "Register")
        )
    )

    static let video = FeedItem(
        id: "preview-video",
        contentType: .video,
        title: "4 Generative AI Skills to Master in 2025",
        behaviour: FeedItemBehaviour(
            summary: "Workers' ability and ambition to use AI for better outcomes is the single greatest defining factor for prosperity.",
            media: FeedItemMedia(
                imageURL: "https://www.gartner.com/resources/836200/836261/Figure_1_CIO_Leadership_of_People_Culture_and_Change_Overview.png",
                imageURLs: [
                    "https://www.gartner.com/resources/836200/836261/Figure_1_CIO_Leadership_of_People_Culture_and_Change_Overview.png"
                ],
                showImage: true
            ),
            schedule: FeedItemSchedule(
                publishedDate: "02 December 2025"
            ),
            primaryAction: FeedItemAction(title: "Watch")
        )
    )

    static let podcast = FeedItem(
        id: "preview-podcast",
        contentType: .podcast,
        title: "A World of AI Excess: The Tech Outcomes That Matter for 2025",
        behaviour: FeedItemBehaviour(
            summary: "Tune in to hear what organizations need to understand to navigate a world of AI excess.",
            media: FeedItemMedia(
                imageURL: "https://www.gartner.com/images/podcast/55928.png",
                imageURLs: [
                    "https://www.gartner.com/images/podcast/55928.png"
                ],
                showImage: true
            ),
            schedule: FeedItemSchedule(
                publishedDate: "23 April 2025"
            ),
            primaryAction: FeedItemAction(title: "Listen")
        )
    )

    static let inquiry = FeedItem(
        id: "18565652",
        contentType: .inquiry,
        title: "Contact Gartner",
        behaviour: FeedItemBehaviour(
            summary: "Expert advice inquiry currently in progress.",
            schedule: FeedItemSchedule(
                eventDate: "30 April 2025",
                eventStartDate: "30 April 2025",
                eventTime: "2:16 AM EST",
                eventLocation: "Expert Advice",
                displayTimeZone: "EST"
            ),
            statusText: "In Progress",
            isRegistered: true,
            primaryAction: FeedItemAction(title: "Scheduled"),
            secondaryAction: FeedItemAction(title: "Edit Inquiry")
        )
    )

    static let conference = FeedItem(
        id: "/en/conferences/emea/human-resource-uk",
        contentType: .conference,
        title: "ReimagineHR Conference",
        behaviour: FeedItemBehaviour(
            summary: "Customize your experience based on your mission-critical priorities with Conference Navigator.",
            schedule: FeedItemSchedule(
                eventStartDate: "17 September 2024",
                eventEndDate: "19 September 2024",
                eventTime: "11:00 AM - 12:00 PM EDT",
                eventLocation: "Sydney, Australia"
            ),
            statusText: "Registered",
            isRegistered: true,
            primaryAction: FeedItemAction(title: "Build Agenda", url: "https://www.gartner.com"),
            secondaryAction: FeedItemAction(title: "See Highlights", url: "https://www.gartner.com")
        )
    )
}
#endif
