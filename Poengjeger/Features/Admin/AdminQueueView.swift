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
                        .font(DesignTokens.Typography.footnote)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }

            if let message = environment.adminInfoMessage {
                Section {
                    Text(message)
                        .font(DesignTokens.Typography.footnote)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
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
                .minimumTouchTarget()
            }

            Section("Kandidater") {
                ForEach(candidates) { candidate in
                    AdminCandidateRow(
                        candidate: candidate,
                        note: noteBinding(for: candidate.id),
                        showsActions: environment.isAdminPreview,
                        onSetStatus: { status in
                            Task { await setStatus(status, for: candidate) }
                        },
                        onPromote: {
                            Task { await promote(candidate) }
                        }
                    )
                }
            }
        }
        .navigationTitle("Admin-kø")
        .toolbar(.visible, for: .navigationBar)
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

private struct AdminCandidateRow: View {
    let candidate: IngestionCandidate
    @Binding var note: String
    let showsActions: Bool
    let onSetStatus: (IngestionCandidate.Status) -> Void
    let onPromote: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.standard) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
                    Text(candidate.title)
                        .font(DesignTokens.Typography.headline)

                    Text(candidate.summary)
                        .font(DesignTokens.Typography.subheadline)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }

                Spacer(minLength: DesignTokens.Spacing.standard)
                AdminStatusBadge(status: candidate.status)
            }

            HStack(spacing: DesignTokens.Spacing.medium) {
                AdminTag(title: candidate.sourceName)

                if let suggestedProgramName = candidate.suggestedProgramName {
                    AdminTag(title: suggestedProgramName, tint: DesignTokens.Colors.brandPrimary)
                }

                if let suggestedCategoryName = candidate.suggestedCategoryName {
                    AdminTag(title: suggestedCategoryName, tint: DesignTokens.Colors.textSecondary)
                }
            }

            CandidateMetadata(candidate: candidate)

            if candidate.canReview || candidate.canPromote {
                TextField("Kort notat til review", text: $note, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .minimumTouchTarget()
            }

            if showsActions {
                AdminCandidateActions(
                    candidate: candidate,
                    onSetStatus: onSetStatus,
                    onPromote: onPromote
                )
            }
        }
        .padding(.vertical, DesignTokens.Spacing.medium)
    }
}

private struct CandidateMetadata: View {
    let candidate: IngestionCandidate

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.small) {
            MetadataLine(title: "Oppdaget", value: candidate.detectedAt.formatted(date: .abbreviated, time: .shortened))
            MetadataLine(title: "Ingest", value: candidate.ingestKind)
            MetadataLine(title: "Kilde", value: candidate.sourceURL.absoluteString)

            if let reviewNote = candidate.reviewNote, !reviewNote.isEmpty {
                MetadataLine(title: "Notat", value: reviewNote)
            }
        }
    }
}

private struct AdminCandidateActions: View {
    let candidate: IngestionCandidate
    let onSetStatus: (IngestionCandidate.Status) -> Void
    let onPromote: () -> Void

    var body: some View {
        HStack {
            if candidate.canReview {
                Button("Godkjenn") {
                    onSetStatus(.approved)
                }
                .buttonStyle(.bordered)
                .minimumTouchTarget()

                Button("Avvis", role: .destructive) {
                    onSetStatus(.rejected)
                }
                .buttonStyle(.bordered)
                .minimumTouchTarget()
            }

            Spacer()

            if candidate.canPromote {
                Button("Promoter til draft") {
                    onPromote()
                }
                .buttonStyle(.borderedProminent)
                .minimumTouchTarget()
                .tint(DesignTokens.Colors.brandPrimaryButton)
            }
        }
    }
}

private struct AdminStatusBadge: View {
    let status: IngestionCandidate.Status

    var body: some View {
        Text(status.title)
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(tint)
            .padding(.horizontal, DesignTokens.Spacing.controlGap)
            .padding(.vertical, DesignTokens.Spacing.small)
            .background(tint.opacity(DesignTokens.Opacity.soft))
            .clipShape(Capsule())
    }

    private var tint: Color {
        switch status {
        case .new:
            return DesignTokens.Colors.statusNew
        case .needsReview:
            return DesignTokens.Colors.statusNeedsReview
        case .approved:
            return DesignTokens.Colors.statusApproved
        case .rejected:
            return DesignTokens.Colors.statusRejected
        case .promoted:
            return DesignTokens.Colors.statusPromoted
        }
    }
}

private struct AdminTag: View {
    let title: String
    var tint: Color = DesignTokens.Colors.textSecondary

    var body: some View {
        Text(title)
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(tint)
            .padding(.horizontal, DesignTokens.Spacing.medium)
            .padding(.vertical, DesignTokens.Spacing.xSmall)
            .background(tint.opacity(DesignTokens.Opacity.soft))
            .clipShape(Capsule())
    }
}

private struct MetadataLine: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxSmall) {
            Text(title)
                .font(DesignTokens.Typography.caption2)
                .foregroundStyle(DesignTokens.Colors.textSecondary)
            Text(value)
                .font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Colors.textPrimary)
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
