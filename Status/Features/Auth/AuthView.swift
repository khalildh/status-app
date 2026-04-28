import SwiftUI

struct AuthView: View {
    @Environment(AuthService.self) private var auth
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo
            VStack(spacing: 12) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.primary)

                Text("Status")
                    .font(.system(size: 40, weight: .bold, design: .default))

                Text("Your social capital, quantified.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Form
            VStack(spacing: 16) {
                if isSignUp {
                    TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }

                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(isSignUp ? .newPassword : .password)

                if let error = auth.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task {
                        if isSignUp {
                            await auth.signUp(email: email, password: password, username: username)
                        } else {
                            await auth.signIn(email: email, password: password)
                        }
                    }
                } label: {
                    Group {
                        if auth.isLoading {
                            ProgressView()
                        } else {
                            Text(isSignUp ? "Create Account" : "Sign In")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(.primary)
                .disabled(auth.isLoading || email.isEmpty || password.isEmpty || (isSignUp && username.isEmpty))

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSignUp.toggle()
                        auth.error = nil
                    }
                } label: {
                    Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
    }
}

#Preview {
    AuthView()
        .environment(AuthService.preview)
}
