//
//  Binding+Recipe.swift
//  ASCookBook
//
//  Created by Klaus Dresbach on 04.10.25.
//
import SwiftUI

extension Bindable where Value == Recipe {
    func binding(for kind: Kind) -> Binding<Bool> {
        Binding(
            get: { wrappedValue.kinds.contains(kind) },
            set: { isOn in
                if isOn {
                    wrappedValue.kinds.insert(kind)
                } else {
                    wrappedValue.kinds.remove(kind)
                }
            }
        )
    }
    
    func binding(for special: Special) -> Binding<Bool> {
        Binding (
            get: { wrappedValue.specials.contains(special) },
            set: { isOn in
                if isOn {
                    wrappedValue.specials.insert(special)
                } else {
                    wrappedValue.specials.remove(special)
                }
            }
        )
    }
}
