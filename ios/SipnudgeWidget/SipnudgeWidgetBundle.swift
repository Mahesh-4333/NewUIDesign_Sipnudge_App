//
//  SipnudgeWidgetBundle.swift
//  SipnudgeWidget
//
//  Created by Akshay Vishwakarma on 06/06/26.
//

import WidgetKit
import SwiftUI

@main
struct SipnudgeWidgetBundle: WidgetBundle {
    var body: some Widget {
        SipnudgeWidget()
        SipnudgeWidgetControl()
        SipnudgeWidgetLiveActivity()
    }
}
