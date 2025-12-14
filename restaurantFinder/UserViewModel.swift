//
//  UserViewModel.swift
//  restaurantFinder
//
//  Created by Aayush Bharti on 11/20/25.
//

import Foundation
import SwiftData
import Combine

// user view model
class UserViewModel: ObservableObject {
    // creates the published variables
    @Published var currentUser: User?
    @Published var loginError: String = ""
    @Published var accountCreationError: String = ""
    @Published var successfulLogin: Bool = false
    
    init() {}
    
    // login function to handle successful and failed login attempts
    func login(username: String, password: String, users: [User], context: ModelContext) {
        // if password and username are correct, update current user and reset other values
        if let user = users.first(where: {$0.username == username && $0.password == password}) {
            currentUser = user
            loginError = ""
            successfulLogin = true
        }
        // else show the error
        else {
            // if password wrong
            if let user = users.first(where: {$0.username == username && $0.password != password}) {
                loginError = "Wrong Password."
            }
            // if username wrong
            else {
                loginError = "Username not found."
            }
        }
    }
    
    // function to create a new account
    func createAccount(username: String, password: String, users: [User], context: ModelContext) {
        // if username already in use, try a new one
        if let user = users.first(where: {$0.username == username}) {
            accountCreationError = "Username already in use. Try a different username."
        }
        // else create the account
        else {
            // create the user and add it to database and save
            let newUser = User(username: username, password: password)
            context.insert(newUser)
            try? context.save()
            
            // update current user
            currentUser = newUser
            accountCreationError = ""
            successfulLogin = true
        }
    }
}
