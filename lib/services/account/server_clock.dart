/// The time on the server's clock, as well as this device can tell.
///
/// [LibrarySync] measures [offset] from each write's server stamp. Removals
/// and the entries they are compared with (a Continue Watching session, a My
/// List title, a taste sighting) are all stamped with [now], so a device
/// whose clock is off by minutes cannot have its additions lose to, or beat,
/// a removal made on another device in the meantime.
abstract final class ServerClock {
  /// The server's clock minus this device's; zero until first measured.
  static Duration offset = Duration.zero;

  /// Now on the server's clock, as a local time like [DateTime.now], so
  /// what shows it (a "last watched" date) reads the same as before.
  static DateTime now() => DateTime.now().add(offset);
}
