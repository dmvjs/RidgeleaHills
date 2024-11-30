//
//  SubmissionStatusView.swift
//  RidgeleaHills
//
//  Created by Kirk Elliott on 11/29/24.
//


import SwiftUI

struct SubmissionStatusView: View {
    @Binding var submissionError: String?
    @Binding var showSubmissionStatus: Bool

    var body: some View {
        VStack {
            if let error = submissionError {
                Text("Submission Failed")
                    .font(.title)
                    .padding()
                Text(error)
                    .multilineTextAlignment(.center)
                    .padding()
            } else {
                Text("Application Submitted")
                    .font(.title)
                    .padding()
                Text("Your application is being reviewed. We will get back to you soon.")
                    .multilineTextAlignment(.center)
                    .padding()
            }
            Button("Close") {
                showSubmissionStatus = false
            }
            .padding()
        }
    }
}
