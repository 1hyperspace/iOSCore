//
//  Constants.swift
//  Core
//
//  Created by LL on 12/31/22.
//

import Foundation

public enum Constants {
    static let pageSize = pageTriggerGap * 5
    static let pageTriggerGap = 20
    // this value should be less than 1/5th
    // because the page gets moved 100/2=50
    // so if pageTriggerGap is 30, then it starts
    // firing back and forth in the middle because
    // readingItem(index:) gets called on indexes that
    // are on both sides of the page
}
