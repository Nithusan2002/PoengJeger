import SwiftUI

struct AdminQueueView: View {
    @State private var viewModel: AdminQueueViewModel

    init(viewModel: AdminQueueViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        List {
            if let sourceLabel = viewModel.sourceLabel {
                Section {
                    Label(sourceLabel, systemImage: viewModel.isPreview ? "wrench.and.screwdriver" : "lock")
                        .font(DesignTokens.Typography.footnote)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }

            if let message = viewModel.infoMessage {
                Section {
                    Text(message)
                        .font(DesignTokens.Typography.footnote)
                        .foregroundStyle(DesignTokens.Colors.textSecondary)
                }
            }

            Section("Filter") {
                Picker("Status", selection: $viewModel.selectedStatusFilter) {
                    Text("Alle").tag(IngestionCandidate.Status?.none)
                    ForEach(IngestionCandidate.Status.allCases, id: \.self) { status in
                        Text(status.title).tag(IngestionCandidate.Status?.some(status))
                    }
                }
                .pickerStyle(.segmented)
                .minimumTouchTarget()
            }

            Section("Kandidater") {
                ForEach(viewModel.filteredCandidates) { candidate in
                    AdminCandidateRow(
                        candidate: candidate,
                        note: noteBinding(for: candidate.id),
                        showsActions: viewModel.isPreview,
                        isProcessing: viewModel.isProcessing(candidate.id),
                        onSetStatus: { status in
                            Task { await viewModel.setStatus(status, for: candidate) }
                        },
                        onPromote: {
                            Task { await viewModel.promote(candidate) }
                        }
                    )
                }
            }
        }
        .navigationTitle("Admin-kø")
        .toolbar(.visible, for: .navigationBar)
        .task {
            await viewModel.loadIfNeeded()
        }
        .refreshable {
            await viewModel.refresh()
        }
        .overlay {
            switch viewModel.loadState {
            case .loading where viewModel.candidates.isEmpty:
                ProgressView("Laster admin-kø")
            case let .failed(message) where viewModel.candidates.isEmpty:
                ContentUnavailableView(
                    "Kunne ikke laste admin-kø",
                    systemImage: "exclamationmark.triangle",
                    description: Text(message)
                )
            case _ where viewModel.candidates.isEmpty:
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
            get: { viewModel.note(for: candidateID) },
            set: { viewModel.setNote($0, for: candidateID) }
        )
    }
}

private struct AdminCandidateRow: View {
    let candidate: IngestionCandidate
    @Binding var note: String
    let showsActions: Bool
    let isProcessing: Bool
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
                    isProcessing: isProcessing,
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
    let isProcessing: Bool
    let onSetStatus: (IngestionCandidate.Status) -> Void
    let onPromote: () -> Void

    var body: some View {
        HStack {
            if isProcessing {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityLabel("Oppdaterer kandidat")
            }

            if candidate.canReview {
                Button("Godkjenn") {
                    onSetStatus(.approved)
                }
                .buttonStyle(.bordered)
                .minimumTouchTarget()
                .disabled(isProcessing)

                Button("Avvis", role: .destructive) {
                    onSetStatus(.rejected)
                }
                .buttonStyle(.bordered)
                .minimumTouchTarget()
                .disabled(isProcessing)
            }

            Spacer()

            if candidate.canPromote {
                Button("Promoter til draft") {
                    onPromote()
                }
                .buttonStyle(.borderedProminent)
                .minimumTouchTarget()
                .tint(DesignTokens.Colors.brandPrimaryButton)
                .disabled(isProcessing)
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
        AdminQueueView(
            viewModel: AdminQueueViewModel(repository: MockAdminRepository())
        )
    }
}
