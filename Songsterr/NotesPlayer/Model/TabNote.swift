//
//  TabNote.swift
//  Songsterr
//
//  Created by Andrei Rauh on 03.09.2025.
//

import Foundation

struct TabNote: Identifiable {
    let id = UUID()
    let string: Int   // струна (1 = тонкая, 6 = басовая)
    let fret: Int     // лад
    let position: Int // позиция по горизонтали
    let duration: Double
}
