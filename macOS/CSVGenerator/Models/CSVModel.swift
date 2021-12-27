//
//  CSVModel.swift
//  CSVCreator
//
//  Created by Cole M on 12/25/21.
//  Copyright © 2021 Cole M. All rights reserved.
//

import Foundation


struct CSVModel: Codable, Hashable, Equatable {
    
    var id: UUID
    var name: String? = ""
    var floor: String? = ""
    var unit: String? = ""
    var address: String? = ""
    var district: String? = ""
    var phoneNumber: String? = ""
    
    init(
        id: UUID,
        name: String? = "",
        floor: String? = "",
        unit: String? = "",
        address: String? = "",
        district: String? = "",
        phoneNumber: String? = ""
    ) {
        self.id = id
        self.name = name
        self.floor = floor
        self.unit = unit
        self.address = address
        self.district = district
        self.phoneNumber = phoneNumber
    }
    
    static func ==(lhs: CSVModel, rhs: CSVModel) -> Bool {
        return lhs.phoneNumber == rhs.phoneNumber && lhs.name == lhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
    
}
