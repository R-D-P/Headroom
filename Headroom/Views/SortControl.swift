import SwiftUI

/// "Sort by RAM | CPU" and a button that flips between largest and smallest first.
struct SortControl: View {
  @Binding var sort: ListSort

  var body: some View {
    HStack(spacing: 6) {
      Text("Sort by")
        .font(.caption)
        .foregroundStyle(.secondary)
      Picker("Sort by", selection: $sort.key) {
        ForEach(ListSort.Key.allCases) { key in
          Text(key.title).tag(key)
        }
      }
      .pickerStyle(.segmented)
      .labelsHidden()
      .controlSize(.small)
      .frame(width: 90)
      Button {
        sort.ascending.toggle()
      } label: {
        Image(systemName: sort.ascending ? "arrow.up" : "arrow.down")
          .font(.caption.weight(.semibold))
      }
      .buttonStyle(.borderless)
      .help(sort.ascending ? "Smallest first" : "Largest first")
    }
  }
}
