import SwiftUI

struct FeedbackView: View {
    @EnvironmentObject var sensor: SensorManager

    @State private var rating: Int = 0
    @State private var matched: Bool = true
    @State private var perceived: ActivityClass = .walking
    @State private var note: String = ""
    @State private var showSaved: Bool = false

    private var latestSession: Session? { sensor.sessions.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {

                    if let s = latestSession {
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Rate the latest session",
                                          subtitle: Fmt.date(s.createdAt))

                            HStack(spacing: 6) {
                                ForEach(1...5, id: \.self) { i in
                                    Image(systemName: i <= rating ? "star.fill" : "star")
                                        .font(.title2)
                                        .foregroundStyle(i <= rating ? Color.yellow : Color.gray.opacity(0.5))
                                        .onTapGesture {
                                            UISelectionFeedbackGenerator().selectionChanged()
                                            rating = i
                                        }
                                }
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Did the detected activity match what you actually did?")
                                    .font(.callout.weight(.semibold))
                                HStack(spacing: 8) {
                                    ChoiceChip(text: "Yes, accurate", selected: matched == true) {
                                        matched = true
                                    }
                                    ChoiceChip(text: "No, off",       selected: matched == false) {
                                        matched = false
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("What were you actually doing?")
                                    .font(.callout.weight(.semibold))
                                FlowChips(selection: $perceived)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes (optional)")
                                    .font(.callout.weight(.semibold))
                                TextEditor(text: $note)
                                    .frame(minHeight: 90)
                                    .padding(8)
                                    .background(Color(uiColor: .systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.gray.opacity(0.2))
                                    )
                            }

                            PrimaryButton(title: "Submit feedback",
                                          systemImage: "paperplane.fill") {
                                guard rating > 0 else { return }
                                sensor.submitFeedback(
                                    sessionId: s.id,
                                    rating: rating,
                                    matchedActivity: matched,
                                    perceivedActivity: perceived,
                                    note: note
                                )
                                rating = 0
                                note = ""
                                matched = true
                                perceived = .walking
                                withAnimation { showSaved = true }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation { showSaved = false }
                                }
                            }

                            if showSaved {
                                Label("Thanks — feedback saved.", systemImage: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.callout.weight(.semibold))
                            }
                        }
                        .padding(16)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    } else {
                        EmptyState(systemImage: "bubble.left",
                                   title: "Record a session first",
                                   subtitle: "Once you save a session, you can rate it here to help improve detection.")
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionHeader(title: "Past feedback")
                        if sensor.feedback.isEmpty {
                            EmptyState(systemImage: "tray",
                                       title: "No feedback yet",
                                       subtitle: "Submitted ratings appear here.")
                        } else {
                            ForEach(sensor.feedback) { f in
                                FeedbackRow(item: f)
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Feedback")
        }
    }
}

struct ChoiceChip: View {
    let text: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.callout.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(selected ? Color.accentColor : Color.gray.opacity(0.15))
                .foregroundStyle(selected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct FlowChips: View {
    @Binding var selection: ActivityClass

    var body: some View {
        let cols = [GridItem(.adaptive(minimum: 110), spacing: 8)]
        LazyVGrid(columns: cols, alignment: .leading, spacing: 8) {
            ForEach(ActivityClass.allCases) { a in
                Button {
                    UISelectionFeedbackGenerator().selectionChanged()
                    selection = a
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: a.systemImage)
                        Text(a.label)
                    }
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(selection == a ? Color.accentColor : Color.gray.opacity(0.15))
                    .foregroundStyle(selection == a ? .white : .primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct FeedbackRow: View {
    let item: Feedback

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= item.rating ? "star.fill" : "star")
                            .font(.caption2)
                            .foregroundStyle(i <= item.rating ? .yellow : .gray.opacity(0.4))
                    }
                }
                Spacer()
                Text(Fmt.relative(item.createdAt))
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                Pill(icon: item.matchedActivity ? "checkmark.circle" : "xmark.circle",
                     text: item.matchedActivity ? "Matched" : "Off",
                     tone: item.matchedActivity ? .success : .warning)
                Pill(icon: item.perceivedActivity.systemImage,
                     text: item.perceivedActivity.label,
                     tone: .primary)
            }
            if let n = item.note, !n.isEmpty {
                Text(n).font(.callout).foregroundStyle(.primary)
            }
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
