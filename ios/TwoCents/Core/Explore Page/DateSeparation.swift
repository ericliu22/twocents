//
//  DateSeparation.swift
//  TwoCents
//
//  Created by Eric Liu on 4/7/25.
//
import SwiftUI

struct DateSeparatorView: View {
    let date: Date
    
    // A date formatter that displays your chosen format.
    private static let formatter: DateFormatter = {
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        return fmt
    }()
    
    var body: some View {
        Text(Self.formatter.string(from: date))
            .font(.caption)
            .padding(8)
            .background(Color.secondary.opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            // Rotate the text to make it vertical if desired.
            .rotationEffect(.degrees(90))
    }
}

extension Array {
    /// Splits the array into chunks of the given size.
    func chunks(of size: Int) -> [[Element]] {
        var chunks: [[Element]] = []
        var index = 0
        while index < self.count {
            let chunk = Array(self[index ..< Swift.min(index + size, self.count)])
            chunks.append(chunk)
            index += size
        }
        return chunks
    }
}

