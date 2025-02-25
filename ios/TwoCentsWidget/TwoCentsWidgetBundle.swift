//
//  TwoCentsWidgetBundle.swift
//  TwoCentsWidget
//
//  Created by Joshua Shen on 2/25/25.
//

import WidgetKit
import SwiftUI

@main
struct TwoCentsWidgetBundle: WidgetBundle {
    var body: some Widget {
        TwoCentsWidget()
        TwoCentsWidgetControl()
        TwoCentsWidgetLiveActivity()
    }
}
