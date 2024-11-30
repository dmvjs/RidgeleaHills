//
//  FormView.swift
//  RidgeleaHills
//
//  Created by Kirk Elliott on 11/29/24.
//


import SwiftUI

struct FormView: View {
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var streetAddress: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zipCode: String
    @Binding var birthday: Date
    @Binding var phoneNumber: String
    @Binding var isFormComplete: Bool
    var completeSignIn: () -> Void

    var body: some View {
        Form {
            Section(header: Text("Personal Information")) {
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)
                    .autocapitalization(.words)
                    .onChange(of: firstName) { _ in validateForm() }
                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
                    .autocapitalization(.words)
                    .onChange(of: lastName) { _ in validateForm() }
            }
            Section(header: Text("Address Information")) {
                TextField("Street Address", text: $streetAddress)
                    .textContentType(.streetAddressLine1)
                    .autocapitalization(.words)
                    .onChange(of: streetAddress) { _ in validateForm() }
                TextField("City", text: $city)
                    .textContentType(.addressCity)
                    .autocapitalization(.words)
                    .onChange(of: city) { _ in validateForm() }
                TextField("State", text: $state)
                    .textContentType(.addressState)
                    .autocapitalization(.words)
                    .onChange(of: state) { _ in validateForm() }
                TextField("Zip Code", text: $zipCode)
                    .keyboardType(.numberPad)
                    .textContentType(.postalCode)
                    .onChange(of: zipCode) { _ in validateForm() }
            }
            Section(header: Text("Additional Information")) {
                DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .onChange(of: birthday) { _ in validateForm() }
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
                    .onChange(of: phoneNumber) { _ in validateForm() }
            }
        }
        .padding()
    }

    private func validateForm() {
        isFormComplete = !firstName.isEmpty && !lastName.isEmpty && !streetAddress.isEmpty && !city.isEmpty && !state.isEmpty && !zipCode.isEmpty && !phoneNumber.isEmpty
    }
}
