import SwiftUI

struct AdminQueueView: View {
    @Environment(AppEnvironment.self) private var environment
    @State private var selectedStatusFilter: IngestionCandidate.Status?
    @State private var noteDrafts: [UUID: String] = [:]

    private var candidates: [IngestionCandidate] {
        let source = environment.adminCandidates
        guard let selectedStatusFilter else {
            return source
        }

        return source.filter { $0.status == selectedStatusFilter }
    }

    var body: some View {
        List {
            if let adminSourceLabel = environment.adminSourceLabel {
                Section {
                    Label(adminSourceLabel, systemImage: environment.isAdminPreview ? "wrench.and.screwdriver" : "lock")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if let message = environment.adminInfoMessage {
                Section {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Filter") {
                Picker("Status", selection: $selectedStatusFilter) {
                    Text("Alle").tag(IngestionCandidate.Status?.none)
                    ForEach(IngestionCandidate.Status.allCases, id: \.self) { status in
                        Text(status.title).tag(IngestionCandidate.Status?.some(status))
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Kandidater") {
                ForEach(candidates) { candidate in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(candidate.title)
                                    .font(.headline)

                                Text(candidate.summary)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: 12)
                            AdminStatusBadge(status: candidate.status)
                        }

                        HStack(spacing: 8) {
                            AdminTag(title: candidate.sourceName)

                            if let suggestedProgramName = candidate.suggestedProgramName {
                                AdminTag(title: suggestedProgramName, tint: PoengjegerTheme.accent)
                            }

                            if let suggestedCategoryName = candidate.suggestedCategoryName {
                                AdminTag(title: suggestedCategoryName, tint: .secondary)
                            }
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            MetadataLine(title: "Oppdaget", value: candidate.detectedAt.formatted(date: .abbreviated, time: .shortened))
                            MetadataLine(title: "Ingest", value: candidate.ingestKind)
                            MetadataLine(title: "Kilde", value: candidate.sourceURL.absoluteString)

                            if let reviewNote = candidate.reviewNote, !reviewNote.isEmpty {
                                MetadataLine(title: "Notat", value: reviewNote)
                            }
                        }

                        if candidate.canReview || candidate.canPromote {
                            TextField("Kort notat til review", text: noteBinding(for: candidate.id), axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                        }

                        if environment.isAdminPreview {
                            HStack {
                                if candidate.canReview {
                                    Button("Needs review") {
                                        Task { await setStatus(.needsReview, for: candidate) }
                                    }
                                    .buttonStyle(.bordered)

                                    Button("Godkjenn") {
                                        Task { await setStatus(.approved, for: candidate) }
                                    }
                                    .buttonStyle(.bordered)

                                    Button("Avvis", role: .destructive) {
                                        Task { await setStatus(.rejected, for: candidate) }
                                    }
                                    .buttonStyle(.bordered)
                                }

                                Spacer()

                                if candidate.canPromote {
                                    Button("Promoter til draft") {
                                        Task { await promote(candidate) }
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle("Admin-kø")
        .task {
            await environment.loadAdminQueueIfNeeded()
        }
        .refreshable {
            await environment.refreshAdminQueue()
        }
        .overlay {
            switch environment.adminLoadState {
            case .loading where environment.adminCandidates.isEmpty:
                ProgressView("Laster admin-kø")
            case let .failed(message) where environment.adminCandidates.isEmpty:
                ContentUnavailableView(
                    "Kunne ikke laste admin-kø",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            case _ where environment.adminCandidates.isEmpty:
                ContentUnavailableView(
                    "Ingen kandidater ennå",
                    systemImage: "tray",
                    description: Text("Når ingestion-kilder begynner å sende inn kandidater, dukker de opp her.")
                )
            default:
                EmptyView()
            }
        }
    }

    private func noteBinding(for candidateID: UUID) -> Binding<String> {
        Binding(
            get: { noteDrafts[candidateID, default: ""] },
            set: { noteDrafts[candidateID] = $0 }
        )
    }

    private func setStatus(_ status: IngestionCandidate.Status, for candidate: IngestionCandidate) async {
        await environment.setAdminCandidateStatus(
            candidateID: candidate.id,
            status: status,
            note: noteDrafts[candidate.id]
        )
    }

    private func promote(_ candidate: IngestionCandidate) async {
        await environment.promoteAdminCandidate(
            candidateID: candidate.id,
            note: noteDrafts[candidate.id]
        )
    }
}

private struct AdminStatusBadge: View {
    let status: IngestionCandidate.Status

    var body: some View {
        Text(status.title)
            .font(.caption)
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }

    private var tint: Color {
        switch status {
        case .new:
            return .blue
        case .needsReview:
            return .orange
        case .approved:
            return .green
        case .rejected:
            return .red
        case .promoted:
            return PoengjegerTheme.accent
        }
    }
}

private struct AdminTag: View {
    let title: String
    var tint: Color = .secondary

    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
    }
}

private struct MetadataLine: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .foregroundStyle(.primary)
                .textSelection(.enabled)
        }
    }
}

#Preview {
    NavigationStack {
        AdminQueueView()
            .environment(AppEnvironment.mock())
    }
}
