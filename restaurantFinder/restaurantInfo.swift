//
//  restaurantInfo.swift
//  restaurantFinder
//
//  Created by Aayush Bharti on 10/28/25.
//

import Foundation
import SwiftData
import SwiftUI

// user class
@Model
class User {
    // creates teh variables
    var id: UUID = UUID()
    var username: String
    var password: String
    // creates relatinoship between user and restaurant info
    @Relationship(deleteRule: .cascade)
    var favorites: [restaurantInfo] = []
    
    // initializes the values
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    // function to add restaurant to the favorites list
    func addRestaurant(context: ModelContext, details: PlaceDetails) {
        // gets the rating string
        let ratingString = details.rating != nil ? String(format: "%.2f", details.rating!) : "N/A"
        
        // creates the new restaurant
        let newRest = restaurantInfo(
            name: details.name, rating: ratingString, addr: details.address, hours: details.hours ?? []
        )
        
        // adds to the list and saves
        favorites.append(newRest)
        try? context.save()
    }
}

@Model
// class to store informaiton about a restaurant
class restaurantInfo {
    var name: String
    var rating: String
    var address: String
    var hours: [String]
    var favorite_items: [String] = []
    
    // initializes the variables
    init(name: String, rating: String, addr: String, hours: [String]) {
        self.name = name
        self.rating = rating
        self.address = addr
        self.hours = hours
    }
    
    // function to add food items
    func addFavoriteItem(item: String) {
        // if item is given, then add it to the list
        if !(item.isEmpty) {
            if !favorite_items.contains(item) {
                favorite_items.append(item)
                favorite_items.sort()
            }
        }
    }
    
    // function to delete items from list
    func deleteFavoriteItem(at offsets: IndexSet) {
        favorite_items.remove(atOffsets: offsets)
    }
}
