import SwiftUI
import CloudKit

struct SettingsView: View {
    @State private var showDeleteConfirmation: Bool = false
    @Binding var firstName: String
    @Binding var lastName: String
    @Binding var streetAddress: String
    @Binding var city: String
    @Binding var state: String
    @Binding var zipCode: String
    @Binding var birthday: Date
    @Binding var phoneNumber: String
    @Binding var userIdentifier: String?
    @State private var avatarImage: UIImage? = UIImage(systemName: "person.crop.circle")
    @State private var showImagePicker: Bool = false
    @State private var showDeleteAvatarConfirmation: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                        .autocapitalization(.words)
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                        .autocapitalization(.words)
                }
                Section(header: Text("Profile Picture")) {
                    if let avatarImage = avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                            .padding()

                        Button("Change Profile Picture") {
                            showImagePicker = true
                        }
                        .padding(.top, 5)

                        Button("Delete Profile Picture", role: .destructive) {
                            showDeleteAvatarConfirmation = true
                        }
                        .padding(.top, 5)
                        .alert(isPresented: $showDeleteAvatarConfirmation) {
                            Alert(
                                title: Text("Delete Profile Picture"),
                                message: Text("Are you sure you want to delete your profile picture?"),
                                primaryButton: .destructive(Text("Delete")) {
                                    self.avatarImage = UIImage(systemName: "person.circle.fill") // Assign a placeholder image instead of nil
                                    saveAvatarToCloudKit(delete: true)
                                },
                                secondaryButton: .cancel()
                            )
                        }
                    } else {
                        Button("Select Profile Picture") {
                            showImagePicker = true
                        }
                    }
                }
                Section(header: Text("Address Information")) {
                    TextField("Street Address", text: $streetAddress)
                        .textContentType(.streetAddressLine1)
                        .autocapitalization(.words)
                    TextField("City", text: $city)
                        .textContentType(.addressCity)
                        .autocapitalization(.words)
                    TextField("State", text: $state)
                        .textContentType(.addressState)
                        .autocapitalization(.words)
                    TextField("Zip Code", text: $zipCode)
                        .keyboardType(.numberPad)
                        .textContentType(.postalCode)
                }
                Section(header: Text("Additional Information")) {
                    DatePicker("Birthday", selection: $birthday, displayedComponents: .date)
                        .datePickerStyle(.compact)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
                Section {
                    Button("Delete Account", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                    .alert(isPresented: $showDeleteConfirmation) {
                        Alert(
                            title: Text("Delete Account"),
                            message: Text("Are you sure you want to delete your account? This action cannot be undone."),
                            primaryButton: .destructive(Text("Delete")) {
                                deleteAccount()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $avatarImage)
            }
            .onChange(of: showImagePicker) { isPresented in
                if !isPresented {
                    saveAvatarToCloudKit()
                }
            }
            .onAppear(perform: fetchAvatarFromCloudKit)
        }
    }
    
    @Environment(\.dismiss) var dismiss
    
    private func saveAvatarToCloudKit(delete: Bool = false) {
        guard let userIdentifier = userIdentifier else { return }
        let recordID = CKRecord.ID(recordName: userIdentifier)
        let privateDatabase = CKContainer(identifier: "iCloud.RidgeleaHills").privateCloudDatabase
        
        privateDatabase.fetch(withRecordID: recordID) { (record, error) in
            if let error = error {
                print("Error fetching user data from CloudKit: \(error.localizedDescription)")
                return
            }
            
            guard let record = record else { return }
            
            if delete {
                record["avatar"] = nil
            } else if let avatarImage = avatarImage, let imageData = avatarImage.jpegData(compressionQuality: 0.8) {
                let tempDirectory = FileManager.default.temporaryDirectory
                let fileURL = tempDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
                do {
                    try imageData.write(to: fileURL)
                    let avatarAsset = CKAsset(fileURL: fileURL)
                    record["avatar"] = avatarAsset
                } catch {
                    print("Error writing image data to temporary file: \(error.localizedDescription)")
                    return
                }
            }
            
            privateDatabase.save(record) { (savedRecord, error) in
                if let error = error {
                    print("Error saving avatar to CloudKit: \(error.localizedDescription)")
                } else {
                    print("Avatar successfully saved to CloudKit.")
                }
            }
        }
    }
    
    private func fetchAvatarFromCloudKit() {
        guard let userIdentifier = userIdentifier else { return }
        let recordID = CKRecord.ID(recordName: userIdentifier)
        let privateDatabase = CKContainer(identifier: "iCloud.RidgeleaHills").privateCloudDatabase
        
        privateDatabase.fetch(withRecordID: recordID) { (record, error) in
            if let error = error {
                print("Error fetching user data from CloudKit: \(error.localizedDescription)")
                return
            }
            
            guard let record = record, let avatarAsset = record["avatar"] as? CKAsset, let fileURL = avatarAsset.fileURL else { return }
            
            do {
                let imageData = try Data(contentsOf: fileURL)
                if let fetchedImage = UIImage(data: imageData) {
                    DispatchQueue.main.async {
                        self.avatarImage = fetchedImage
                    }
                }
            } catch {
                print("Error loading image data from file: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteAccount() {
        guard let userIdentifier = userIdentifier else { return }
        let recordID = CKRecord.ID(recordName: userIdentifier)
        let privateDatabase = CKContainer(identifier: "iCloud.RidgeleaHills").privateCloudDatabase
        privateDatabase.delete(withRecordID: recordID) { (recordID, error) in
            if let error = error {
                print("Error deleting user data from CloudKit: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    dismiss()
                }
            }
        }
    }
}
