import SwiftUI
import AuthenticationServices
import CloudKit

struct ContentView: View {
    @State private var userIdentifier: String?
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var userEmail: String?
    @State private var streetAddress: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var birthday: Date = Calendar.current.date(from: DateComponents(year: 1980)) ?? Date()
    @State private var phoneNumber: String = ""
    @State private var isSignedIn: Bool = false
    @State private var isExclusiveMember: Bool = false
    @State private var isFormComplete: Bool = false
    @State private var showSubmissionStatus: Bool = false
    @State private var submissionError: String? = nil
    @State private var showSettings: Bool = false
    @State private var avatarImage: UIImage? = nil
    
    private let arrayOfExclusiveIds: [String] = ["001238.f786016f521b47ae9c336ccfc43bfa94.1609", "YOUR_ID_1", "YOUR_ID_2"]
    
    var body: some View {
        VStack {
            if isExclusiveMember {
                Text("Welcome to the Exclusive Club, \(firstName) \(lastName)!")
                    .font(.largeTitle)
                    .padding()
                Button("Settings") {
                    showSettings.toggle()
                }
                .buttonStyle(.bordered)
                .padding()
                .sheet(isPresented: $showSettings) {
                    SettingsView(
                        firstName: $firstName,
                        lastName: $lastName,
                        streetAddress: $streetAddress,
                        city: $city,
                        state: $state,
                        zipCode: $zipCode,
                        birthday: $birthday,
                        phoneNumber: $phoneNumber,
                        userIdentifier: $userIdentifier
                    )
                }
            } else if isSignedIn {
                Text("Exclusive Access Application")
                    .font(.title)
                    .padding(.top)
                Text("Please fill out the form below for exclusive access to the app once you are verified.")
                    .multilineTextAlignment(.center)
                    .padding([.leading, .trailing, .bottom])
                
                FormView(
                    firstName: $firstName,
                    lastName: $lastName,
                    streetAddress: $streetAddress,
                    city: $city,
                    state: $state,
                    zipCode: $zipCode,
                    birthday: $birthday,
                    phoneNumber: $phoneNumber,
                    isFormComplete: $isFormComplete,
                    completeSignIn: completeSignIn
                )
                .padding()
                
                if isFormComplete {
                    Button("Submit") {
                        completeSignIn()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                
                Button("Sign Out") {
                    signOut()
                }
                .padding()
            } else {
                SignInWithAppleButton(.signIn, onRequest: configureRequest, onCompletion: handleCompletion)
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .padding()
            }
        }
        .onAppear {
            checkExistingSignIn()
        }
        .sheet(isPresented: $showSubmissionStatus) {
            SubmissionStatusView(submissionError: $submissionError, showSubmissionStatus: $showSubmissionStatus)
        }
    }
    
    // Configure the Apple sign-in request
    private func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }
    
    // Handle the sign-in completion
    private func handleCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authResult):
            switch authResult.credential {
            case let appleIDCredential as ASAuthorizationAppleIDCredential:
                self.userIdentifier = appleIDCredential.user
                self.firstName = appleIDCredential.fullName?.givenName ?? ""
                self.lastName = appleIDCredential.fullName?.familyName ?? ""
                self.userEmail = appleIDCredential.email
                
                if let userIdentifier = self.userIdentifier, arrayOfExclusiveIds.contains(userIdentifier) {
                    self.isExclusiveMember = true
                }
                
                self.isSignedIn = true
                fetchUserDataFromCloudKit()
            default:
                break
            }
        case .failure(let error):
            print("Authentication failed: \(error.localizedDescription)")
        }
    }
    
    // Complete the sign-in process by saving all user information to iCloud
    private func completeSignIn() {
        saveToCloudKit()
    }
    
    // Check if the user has already signed in
    private func checkExistingSignIn() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        appleIDProvider.getCredentialState(forUserID: userIdentifier ?? "") { (credentialState, error) in
            switch credentialState {
            case .authorized:
                // User is still signed in
                if let userIdentifier = self.userIdentifier {
                    fetchUserDataFromCloudKit(userIdentifier: userIdentifier)
                }
                self.isSignedIn = true
            case .revoked, .notFound:
                // User is not signed in
                self.isSignedIn = false
                self.isExclusiveMember = false
            default:
                break
            }
        }
    }
    
    // Fetch user data from CloudKit
    private func fetchUserDataFromCloudKit(userIdentifier: String? = nil) {
        guard let userIdentifier = userIdentifier ?? self.userIdentifier else { return }
        let recordID = CKRecord.ID(recordName: userIdentifier)
        let privateDatabase = CKContainer(identifier: "iCloud.RidgeleaHills").privateCloudDatabase
        privateDatabase.fetch(withRecordID: recordID) { (record, error) in
            if let error = error {
                print("Error fetching user data from CloudKit: \(error.localizedDescription)")
            } else if let record = record {
                DispatchQueue.main.async {
                    self.firstName = record["firstName"] as? String ?? ""
                    self.lastName = record["lastName"] as? String ?? ""
                    self.userEmail = record["userEmail"] as? String
                    self.streetAddress = record["streetAddress"] as? String ?? ""
                    self.city = record["city"] as? String ?? ""
                    self.state = record["state"] as? String ?? ""
                    self.zipCode = record["zipCode"] as? String ?? ""
                    self.birthday = record["birthday"] as? Date ?? Calendar.current.date(from: DateComponents(year: 1980)) ?? Date()
                    self.phoneNumber = record["phoneNumber"] as? String ?? ""
                    if let userIdentifier = self.userIdentifier, arrayOfExclusiveIds.contains(userIdentifier) {
                        self.isExclusiveMember = true
                    }
                    if let avatarAsset = record["avatar"] as? CKAsset, let fileURL = avatarAsset.fileURL {
                        if let imageData = try? Data(contentsOf: fileURL), let image = UIImage(data: imageData) {
                            self.avatarImage = image
                        }
                    }
                }
            }
        }
    }
    
    // Save user information to iCloud using CloudKit
    private func saveToCloudKit() {
        guard let userIdentifier = userIdentifier else { return }
        let recordID = CKRecord.ID(recordName: userIdentifier)
        let record = CKRecord(recordType: "User", recordID: recordID)
        record["firstName"] = firstName as CKRecordValue?
        record["lastName"] = lastName as CKRecordValue?
        record["userEmail"] = userEmail as CKRecordValue?
        record["streetAddress"] = streetAddress as CKRecordValue?
        record["city"] = city as CKRecordValue?
        record["state"] = state as CKRecordValue?
        record["zipCode"] = zipCode as CKRecordValue?
        record["birthday"] = birthday as CKRecordValue?
        record["phoneNumber"] = phoneNumber as CKRecordValue?

        // Save avatar image if available
        if let avatarImage = avatarImage, let imageData = avatarImage.pngData() {
            record["avatar"] = CKAsset(fileURL: saveImageToTemporaryLocation(data: imageData))
        }

        let privateDatabase = CKContainer(identifier: "iCloud.RidgeleaHills").privateCloudDatabase
        privateDatabase.save(record) { (record, error) in
            if let error = error {
                self.submissionError = error.localizedDescription
            } else {
                self.submissionError = nil
            }
            self.showSubmissionStatus = true
        }
    }

    // Helper function to save image data to a temporary location
    private func saveImageToTemporaryLocation(data: Data) -> URL {
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent(UUID().uuidString + ".png")
        try? data.write(to: tempFileURL)
        return tempFileURL
    }

    
    // Sign out the user
    private func signOut() {
        self.isSignedIn = false
        self.userIdentifier = nil
        self.firstName = ""
        self.lastName = ""
        self.userEmail = nil
        self.streetAddress = ""
        self.city = ""
        self.state = ""
        self.zipCode = ""
        self.birthday = Calendar.current.date(from: DateComponents(year: 1980)) ?? Date()
        self.phoneNumber = ""
        self.isExclusiveMember = false
        self.isFormComplete = false
    }
    
    // Validate the form to ensure all fields are filled out
    private func validateForm() {
        isFormComplete = !firstName.isEmpty && !lastName.isEmpty && !streetAddress.isEmpty && !city.isEmpty && !state.isEmpty && !zipCode.isEmpty && !phoneNumber.isEmpty
    }
}
