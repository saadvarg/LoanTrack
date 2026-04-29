//
//  Extensions.swift
//  LoanTrack
//
//  Created by Saad EL Mouataz on 20/4/2026.
//
import Foundation

extension Double {
    var currencyFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "$0.00"
    }
}

