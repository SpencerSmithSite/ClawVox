enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
}
