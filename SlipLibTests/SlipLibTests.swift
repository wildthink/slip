//
//  SlipLibTests.swift
//  SlipLibTests
//
//  Created by Jason Jobe on 11/28/18.
//  Copyright © 2018 Jason Jobe. All rights reserved.
//

import XCTest
@testable import SlipLib

class SlipLibTests: XCTestCase {

    let env = Environment()

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {

        if let map = try? env.read("{a: 1 :b 2}" )! {
            Swift.print (map)
        }
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
