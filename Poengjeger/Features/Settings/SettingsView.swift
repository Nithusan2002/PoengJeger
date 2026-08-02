import SwiftUI

struct SettingsView: View {
    @Environment(AppEnvironment.self) private var environment

    var body: some View {
        @Bindable var environment = environment

        Form {
            Section("Varsler") {
                Toggle("Aktiver varsler", isOn: $environment.userSession.notificationsEnabled)
            }

            Section("Valgte programmer") {
                ForEach(environment.campaignRepository.fetchPrograms()) { program in
                    HStack {
                        Text(program.name)
                        Spacer()
                        if environment.userSession.selectedProgramIDs.contains(program.id) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(PoengjegerTheme.accent)
                        }
                    }
                }
            }
        }
        .navigationTitle("Innstillinger")
    }
}
