//
//  ContentView.swift
//  restaurantFinder
//
//  Created by Aayush Bharti on 10/28/25.
//

import SwiftUI
import MapKit
import SwiftData

// location struct for map
struct Location: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

// main content view
struct ContentView: View {
    @Environment(\.modelContext) private var context
    
    @State private var loggedIn = false
    @State private var currentUser: User?
    
    var body: some View {
        // if the user is logged in, go to the home view
        if loggedIn, currentUser != nil {
            HomeView(loggedIn: $loggedIn, currentUser: $currentUser)
        }
        // if not, go to login screen
        else {
            LoginView(loggedIn: $loggedIn, currentUser: $currentUser)
        }
    }
}

// login screen
struct LoginView: View {
    // get the context and users
    @Environment(\.modelContext) private var context
    @Query var users: [User]
    
    // get the binding variables
    @Binding var loggedIn: Bool
    @Binding var currentUser: User?
    
    // get the user view model
    @StateObject private var viewModel = UserViewModel()
    
    // create the username and password fields
    @State private var username = ""
    @State private var password = ""
    
    // create the booleans
    @State private var loggingIn = false
    @State private var creatingAccount = false
    
    // view for login
    var body: some View {
        NavigationView {
            // create vertical stack for the items
            VStack {
                // logo of the application
                Image("Logo")
                    .resizable()
                    .frame(height: 400)
                
                Spacer().frame(height: 30)
                
                // button to login to an account
                Button(action: {
                    loggingIn = true
                }) {
                    Text("Login to Account")
                }
                .buttonStyle(.borderedProminent)
                
                Spacer().frame(height: 30)
            
                // button to create a new account
                Button(action: {
                    creatingAccount = true
                }) {
                    Text("Create New Account")
                }
                .buttonStyle(.borderedProminent)
            }
            // presents the sheet for logging in
            .sheet(isPresented: $loggingIn) {
                NavigationView {
                    VStack {
                        // creates the field to enter username
                        HStack {
                            Text("Enter Username: ")
                            TextField("Username", text: $username)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                        }
                        .padding()
                        
                        // creates the field to enter password
                        HStack {
                            Text("Enter Password: ")
                            TextField("Password", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                        }
                        .padding()
                        
                        // shows the error if there is one when logging in
                        Text("\(viewModel.loginError)")
                            .foregroundColor(.red)
                        
                        // button to login
                        Button(action: {
                            // calls the login function to verify username and passsword
                            viewModel.login(username: username, password: password, users: users, context: context)
                            // if user is logged in successfuly, reset the fields and update the current user
                            loggedIn = viewModel.successfulLogin
                            if loggedIn {
                                currentUser = viewModel.currentUser
                                loggingIn = false
                                username = ""
                                password = ""
                            }
                        }) {
                            Text("Login")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    // cancel button when logging in
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                loggingIn = false
                            }) {
                                Text("Cancel")
                            }
                        }
                    }
                }
            }
            // page for when the user creates their account
            .sheet(isPresented: $creatingAccount) {
                NavigationView {
                    VStack {
                        // creates the field to enter username
                        HStack {
                            Text("Enter Username: ")
                            TextField("Username", text: $username)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                        }
                        .padding()
                        
                        // creates the field to enter password
                        HStack {
                            Text("Enter Password: ")
                            TextField("Password", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                        }
                        .padding()
                        
                        // shows error if there is one
                        Text("\(viewModel.accountCreationError)")
                            .foregroundColor(.red)
                        
                        // button to create the account
                        Button(action: {
                            // calls the create account function to check if values are valid and creates account
                            viewModel.createAccount(username: username, password: password, users: users, context: context)
                            loggedIn = viewModel.successfulLogin
                            
                            // if successful, update current user and reset fields
                            if loggedIn {
                                currentUser = viewModel.currentUser
                                creatingAccount = false
                                username = ""
                                password = ""
                            }
                        }) {
                            Text("Create Account")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    // cancel button
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                creatingAccount = false
                            }) {
                                Text("Cancel")
                            }
                        }
                    }
                }
            }
        }
    }
}

// home screen view
struct HomeView: View {
    // binding variables
    @Binding var loggedIn: Bool
    @Binding var currentUser: User?
    
    var body: some View {
        NavigationView {
            // if there is a current user
            if let user = currentUser {
                // gives the option to go to the map or the favorites
                VStack {
                    // link to the map to find nearby restaurants
                    NavigationLink(destination: MapView(currentUser: currentUser!)) {
                        Text("Find Nearby Restaurant")
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer().frame(height: 50)
                    
                    // link to the saved restaurants
                    NavigationLink(destination: SavedView(currentUser: currentUser!)) {
                        Text("View Saved Restaurants")
                    }
                    .buttonStyle(.borderedProminent)
                }
                .navigationTitle("Restaurant Finder")
                // sign out button to sign the user out
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            currentUser = nil
                            loggedIn = false
                        }) {
                            Text("Sign Out")
                        }
                    }
                }
            }
        }
    }
}


// view to find nearby restaurants
struct MapView: View {
    
    @Query var restaurants: [restaurantInfo]
    
    let currentUser: User
    // variable to store search text in
    @State private var searchText = ""
    
    // default location
    private static let defaultLocation = CLLocationCoordinate2D(
        latitude: 33.4255, longitude: -111.9400
    )
    
    // sets region to default
    private static var region = MKCoordinateRegion(
        center: defaultLocation,
        span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
    )
    
    // position for the map
    @State private var position: MapCameraPosition = .region(region)
    
    // creates the default marker
    @State private var markers = [
        Location(name: "Tempe", coordinate: defaultLocation)
    ]
    
    // variables needed for clicking on marker
    @State private var currentMarker: Location?
    @State private var showingInfo = false
    
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationView {
            // creates the map view
            VStack {
                // creates the map
                Map(position: $position) {
                    // for each marker, create the marker and annotation
                    ForEach(markers) { location in
                        Marker(location.name, coordinate: location.coordinate)
                        
                        Annotation("", coordinate: location.coordinate) {
                            // this creates a button to allow the marker to be clicked on
                            Button(action: {
                                // sets the current marker and showing info to show the page
                                currentMarker = location
                                showingInfo = true
                            }, label: {
                                Color.clear
                                    .frame(width: 35, height: 35)
                                    .contentShape(Rectangle())
                            })
                        }
                    }
                }
                .ignoresSafeArea()
                
                // shows the search bar below the map
                search
            }
            // initially searches for restaurants in the area
            .onAppear {
                initialSearch()
            }
            // calls the restaurant detail view to show more details about the clicked on restaurant
            .sheet(item: $currentMarker) { marker in
                RestaurantDetailView(mapLocation: marker, currentUser: currentUser)
            }
        }
    }
    
    // handles the initial searchin to show to user
    func initialSearch() {
        // creates teh request and the search text of restaurants
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "Restaurants"
        request.region = MapView.region
        
        // start the search based off of the request
        MKLocalSearch(request: request).start { response, error in
            // if there is no response then show the error
            guard let response = response else {
                print("Error: \(error?.localizedDescription ?? "Unknown Error")")
                return
            }
            // update the region, position, and markers from the request response
            MapView.region = response.boundingRegion
            position = .region(response.boundingRegion)
            markers = response.mapItems.map { item in
                Location(
                    name: item.name ?? "",
                    coordinate: item.location.coordinate
                )
            }
        }
    }
    
    // creates the search bar for the map
    private var search: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.blue)
            
            TextField("Search for Places", text: $searchText)
                .disableAutocorrection(true)
                .overlay {
                    HStack {
                        Spacer()
                        if !(self.searchText.isEmpty) {
                            Button(action: {
                                self.searchText = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                            }
                        }
                    }
                }
            
            // create a button to search for restaurants
            Button {
                // get the request from the search text
                let request = MKLocalSearch.Request()
                request.naturalLanguageQuery = searchText
                request.region = MapView.region
                
                // start the search based off of the request
                MKLocalSearch(request: request).start { response, error in
                    // if there is no response then show the error
                    guard let response = response else {
                        print("Error: \(error?.localizedDescription ?? "Unknown Error")")
                        return
                    }
                    // update the region, position, and markers from the request response
                    MapView.region = response.boundingRegion
                    position = .region(response.boundingRegion)
                    markers = response.mapItems.map { item in
                        Location(
                            name: item.name ?? "",
                            coordinate: item.location.coordinate
                        )
                    }
                }
            } label: {
                // creates the search button
                Text("Search")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(10)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }
}

// detailed view for the restaurant that was clicked
struct RestaurantDetailView: View {
    // variables passed
    let mapLocation: Location
    let currentUser: User
    
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel = googlePlacesVM()
    
    @State private var isSaved = false
    
    // main view
    var body: some View {
        NavigationView {
            VStack {
                // if the api is loading, show that to user
                if viewModel.isLoading {
                    ProgressView("Fetching details...")
                        .padding()
                }
                
                // if details are sent back from api, display them
                else if let details = viewModel.placeDetails {
                    List {
                        // shows whether the place is open or closed
                        Section("Open/Closed") {
                            if details.open_now ?? false {
                                Text("Open!!")
                                    .foregroundColor(.green)
                            }
                            else {
                                Text("Closed.")
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // shows the rating of the place
                        Section("Rating") {
                            if let rating = details.rating {
                                HStack {
                                    Text("\(rating, specifier: "%.2f")")
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                }
                            }
                            
                            else {
                                Text("N/A")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // shows teh address
                        Section("Address") {
                            Text(details.address)
                        }
                        
                        // shows the hours it is open
                        Section("Hours of Operation") {
                            if let h = details.hours {
                                if !(h.isEmpty) {
                                    ForEach(h, id: \.self) { item in
                                        Text("\(item)")
                                    }
                                }
                            }
                        }
                    }
                }
                
                // if there was an error, show that to user
                else if let e = viewModel.errorMessage {
                    VStack {
                        // shows error and image of error
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text(e)
                            .font(.caption)
                    }
                    .padding()
                }
            }
            // puts restaurant name as title
            .navigationTitle(mapLocation.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // adds the save restaurant button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action:  {
                        // if we have teh details of teh place, call the function to add it to favorites
                        if let details = viewModel.placeDetails {
                            currentUser.addRestaurant(context: context, details: details)
                            isSaved = true
                        }
                    }) {
                        HStack {
                            Image(systemName: isSaved ? "heart.fill": "heart")
                            Text(isSaved ? "Saved": "Save")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                
                // adds the close button
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                    }
                }
            }
        }
        // get the address and api response when the user clicks on a marker
        .onAppear {
            viewModel.getAddress(name: mapLocation.name, coordinates: mapLocation.coordinate)
        }
    }
}


// view for the saved/favorited restaurants
struct SavedView: View {
    // gets the context and user
    @Environment(\.modelContext) private var context
    let currentUser: User
    
    // variable to store whether the add view is showing or not
    @State private var showingAdd: Bool = false

    var body: some View {
        VStack {
            List {
                ForEach(currentUser.favorites) { restaurant in
                    // create a navigation link to the restaurant view which will display more details
                    NavigationLink(destination: RestaurantView(restaurant: restaurant)) {
                        // shows some information about the restaurant such as name, address, rating
                        HStack {
                            VStack(alignment: .leading) {
                                Text(restaurant.name)
                                    .font(.headline)
                                Text(restaurant.address)
                                    .font(.subheadline)
                            }
                            Spacer()
                            Text("\(restaurant.rating) ⭐️")
                        }
                    }
                }
                // allow for deletion/removal from the saved list
                .onDelete { indexSet in
                    for index in indexSet {
                        let deleteRest = currentUser.favorites[index]
                        context.delete(deleteRest)
                    }
                    try? context.save()
                }
            }
        }
        .toolbar {
            // the title for the favorites list page
            ToolbarItem(placement: .principal) {
                Text("Favorites List")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            // add symbol to allow for users to add a new restaurant to favorites
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // set showingAdd to true
                    showingAdd = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddView(showingAdd: $showingAdd, currentUser: currentUser)
        }
    }
}

// view that allows users to add new restaurants to favorites
struct AddView: View {
    // gets the restaurant dictionary
    @Binding var showingAdd: Bool
    
    let currentUser: User
    @Environment(\.modelContext) private var context
    
    // variables to store values in
    @State private var newName: String = ""
    @State private var newAddress: String = ""
    @State private var newRating: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // form to get information from user
                Form {
                    // restaurant name
                    HStack {
                        Text("Name:")
                        TextField("Enter Restaurant Name", text: $newName)
                            .disableAutocorrection(true)
                    }
                    
                    // restaurant address
                    HStack {
                        Text("Address:")
                        TextField("Enter Restaurant Address", text: $newAddress)
                            .disableAutocorrection(true)
                    }
                    
                    // restaurant rating
                    HStack {
                        Text("Rating:")
                        TextField("Enter Restaurant Rating", text: $newRating)
                            .disableAutocorrection(true)
                    }
                }
            }
            .navigationTitle("Add Restaurant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // check mark to save the new restaurant
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // checks if all the fields are entered
                        if !(newName.isEmpty) && !(newAddress.isEmpty) && !(newRating.isEmpty) {
                            // if entered, add it
                            let details = PlaceDetails(name: newName, address: newAddress, rating: Double(newRating), hours: nil, open_now: nil)
                            currentUser.addRestaurant(context: context, details: details)
                            
                            // reset all the other variables
                            showingAdd = false
                            newName = ""
                            newAddress = ""
                            newRating = ""
                        }
                        
                    }) {
                        Image(systemName: "checkmark")
                    }
                }
                
                // button to cancel the new input
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingAdd = false
                        newName = ""
                        newAddress = ""
                        newRating = ""
                    }) {
                        Text("Cancel")
                    }
                }
            }
        }
    }
}


// detailed view about the restaurants
struct RestaurantView: View {
    // gets the variables
    let restaurant: restaurantInfo
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    // creates the value to add new food items
    @State private var newItem = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // creates sections which will display the details about the restaurant
                Form {
                    // address
                    Section("Address: ") {
                        Text(restaurant.address)
                    }
                    // rating
                    Section("Rating: ") {
                        Text("\(restaurant.rating) ⭐️")
                    }
                    // hours
                    Section("Hours of Operation: ") {
                        List {
                            ForEach(restaurant.hours, id: \.self) { item in
                                Text("\(item)")
                            }
                        }
                    }
                    // favorite food items
                    Section("Favorite Food Items: ") {
                        // if there are items, show them in a list
                        if !(restaurant.favorite_items.isEmpty) {
                            List {
                                ForEach(restaurant.favorite_items, id: \.self) { item in
                                    Text("\(item)")
                                }
                                .onDelete { indexSet in
                                    restaurant.deleteFavoriteItem(at: indexSet)
                                }
                            }
                        }
                        // allow the user to add items
                        HStack {
                            TextField("Enter Item", text: $newItem)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                            // on button click, call the function to add to their favorite items
                            Button(action: {
                                restaurant.addFavoriteItem(item: newItem)
                                newItem = ""
                            }) {
                                Text("Add Favorite")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .toolbar {
                // shows the restaurant name in the title
                ToolbarItem(placement: .principal) {
                    Text(restaurant.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: restaurantInfo.self, inMemory: true)
    }
}
