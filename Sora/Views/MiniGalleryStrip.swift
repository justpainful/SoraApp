import SwiftUI

struct MiniGalleryStrip: View {
    let urls: [URL]
    var onSelect: ((URL) -> Void)?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(urls, id: \.self) { url in
                    Button {
                        onSelect?(url)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.12))

                                Image(systemName: "video.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                            .frame(width: 128, height: 84)

                            Text(url.deletingPathExtension().lastPathComponent)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Text(relativeDate(for: url))
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.58))
                        }
                        .padding(10)
                        .frame(width: 148, alignment: .leading)
                        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(.white.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)
        }
        .frame(maxHeight: 154)
    }

    private func relativeDate(for url: URL) -> String {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .creationDateKey])
        let date = values?.contentModificationDate ?? values?.creationDate ?? .now
        return date.formatted(.relative(presentation: .named))
    }
}
