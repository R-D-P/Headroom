/// Reads the fixed-size `char[]` fields C structs import into Swift as tuples.
enum CStringTuple {
  static func string<Tuple>(from tuple: Tuple) -> String {
    withUnsafeBytes(of: tuple) { raw in
      String(decoding: raw.prefix(while: { $0 != 0 }), as: UTF8.self)
    }
  }
}
