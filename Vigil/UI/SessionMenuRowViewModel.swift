struct SessionMenuRowViewModel: Equatable {
    let sessionId: String
    let title: String
    let projectName: String
    let iconState: MenuBarIconState
    let statusText: String
    let relativeUpdatedText: String
    let requiresAttention: Bool
}
