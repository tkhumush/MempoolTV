import Foundation

struct MosaicCell: Identifiable, Sendable {
    let id: String
    let band: Int
    let vsize: Double
    let count: Int
    let rect: CGRect
}
enum MosaicLayout {
    private struct Group { let id: String; let size: Double; let count: Int }
    /// Exact area conservation, including aggregated tiny transactions. Bands run hot-left.
    static func make(_ transactions: [TemplateTransaction], width: Double, height: Double) -> [MosaicCell] {
        let total = transactions.reduce(0) { $0 + $1.vsize }
        guard total > 0, width > 0, height > 0 else { return [] }
        let minimum = total * 144 / (width * height)
        var result: [MosaicCell] = [], x = 0.0
        for band in (0..<5).reversed() {
            let members = transactions.filter { TelemetryMath.band($0.rate) == band }.sorted { $0.id < $1.id }
            let bandSize = members.reduce(0) { $0 + $1.vsize }
            guard bandSize > 0 else { continue }
            var groups: [Group] = [], small = 0.0, count = 0, first = ""
            for tx in members {
                if tx.vsize >= minimum { groups.append(Group(id: tx.id, size: tx.vsize, count: 1)) }
                else {
                    if count == 0 { first = tx.id }
                    small += tx.vsize; count += 1
                    if small >= minimum {
                        groups.append(Group(id: "group-" + first, size: small, count: count)); small = 0; count = 0
                    }
                }
            }
            if count > 0 { groups.append(Group(id: "group-" + first, size: small, count: count)) }
            let bandWidth = width * bandSize / total
            partition(groups[...], rect: CGRect(x: x, y: 0, width: bandWidth, height: height), band: band, into: &result)
            x += bandWidth
        }
        return result
    }
    private static func partition(_ groups: ArraySlice<Group>, rect: CGRect, band: Int, into output: inout [MosaicCell]) {
        guard let first = groups.first else { return }
        if groups.count == 1 {
            output.append(MosaicCell(id: first.id, band: band, vsize: first.size, count: first.count, rect: rect)); return
        }
        let total = groups.reduce(0) { $0 + $1.size }
        var partial = 0.0, split = groups.startIndex
        while split < groups.endIndex - 1 {
            partial += groups[split].size; split += 1
            if partial >= total / 2 { break }
        }
        let fraction = partial / total
        let vertical = rect.width >= rect.height
        let a = CGRect(x: rect.minX, y: rect.minY, width: vertical ? rect.width * fraction : rect.width, height: vertical ? rect.height : rect.height * fraction)
        let b = CGRect(x: vertical ? a.maxX : rect.minX, y: vertical ? rect.minY : a.maxY, width: vertical ? rect.width - a.width : rect.width, height: vertical ? rect.height : rect.height - a.height)
        partition(groups[..<split], rect: a, band: band, into: &output)
        partition(groups[split...], rect: b, band: band, into: &output)
    }
}
