//
//  SecureEncryptionApp.swift
//  SecureEncryption
//
//  Created by Yash on 2/1/25.
//

import SwiftUI
import CryptoKit
import Security
import LocalAuthentication
import MessageUI
import CommonCrypto

// several models

enum NavigationItem: String, CaseIterable, Identifiable {
    case encryption = "Encryption"
    case decryption = "Decryption"
    case history = "History"
    
    var id: String { self.rawValue }
}

enum EncryptionType: String, CaseIterable, Identifiable {
    case symmetric = "Symmetric"
    case asymmetric = "Asymmetric"
    
    var id: String { self.rawValue }
}

enum SymmetricAlgorithm: String, CaseIterable, Identifiable {
    case aesGCM = "AES-GCM"
    case chaChaPoly = "ChaChaPoly"
    case aesCBC = "AES-CBC"
    
    var id: String { self.rawValue }
}

enum AsymmetricAlgorithm: String, CaseIterable, Identifiable {
    case rsaPKCS1 = "RSA PKCS1"
    case rsaOAEP = "RSA OAEP"
    
    var id: String { self.rawValue }
}

struct EncryptionHistoryItem: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let plainText: String
    let encryptedText: String
    let decryptionKey: String
    let encryptionType: String
    let symmetricAlgorithm: String?
    let rsaKeySize: Int?
    let asymmetricAlgorithm: String?
}

// several obseravable objects are stored here

class EncryptionHistoryStore: ObservableObject {
    @Published var history: [EncryptionHistoryItem] = []
    private let key = "EncryptionHistoryStore"
    
    init() { loadHistory() }
    
    func add(item: EncryptionHistoryItem) {
        history.insert(item, at: 0)
        saveHistory()
    }
    
    // Remove items at specified offsets.
    func removeItems(at offsets: IndexSet) {
        history.remove(atOffsets: offsets)
        saveHistory()
    }
    
    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: key),
           let items = try? JSONDecoder().decode([EncryptionHistoryItem].self, from: data) {
            self.history = items
        }
    }
    
    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    
    func authenticate() {
        let context = LAContext()
        let reason = "Authenticate to access SecureEncryption"
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    self.isAuthenticated = success
                }
            }
        } else {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    self.isAuthenticated = success
                }
            }
        }
    }
}

// this provides custom views to the application
struct ConfidentialTextField: View {
    @Binding var text: String
    @State private var isSecure: Bool = true
    var placeholder: String
    
    var body: some View {
        HStack {
            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye.slash" : "eye")
            }
        }
    }
}

struct MessageComposeView: UIViewControllerRepresentable {
    var bodyText: String
    @Environment(\.presentationMode) var presentationMode
    
    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var parent: MessageComposeView
        init(_ parent: MessageComposeView) { self.parent = parent }
        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.body = bodyText
        return controller
    }
    
    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) { }
}

// MARK: - Animated Splash Screen

struct SplashView: View {
    @State private var opacity: Double = 0.0
    var body: some View {
        VStack(spacing: 20) {
            Text("Secure Encryption")
                .font(.largeTitle)
                .bold()
            Text("Developer: Yash")
                .font(.subheadline)
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeIn(duration: 1.5)) {
                opacity = 1.0
            }
        }
    }
}

struct LaunchView: View {
    @State private var isActive = false
    var body: some View {
        Group {
            if isActive {
                MainSplitView()
            } else {
                SplashView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
            }
        }
        .onAppear {
            // Show splash screen for 3 seconds.
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation(.easeOut) {
                    isActive = true
                }
            }
        }
    }
}

// split view

struct MainSplitView: View {
    @StateObject var historyStore = EncryptionHistoryStore()
    @StateObject var authVM = AuthenticationViewModel()
    @State private var selectedItem: NavigationItem? = .encryption
    
    var body: some View {
        NavigationSplitView {
            List(NavigationItem.allCases, selection: $selectedItem) { item in
                NavigationLink(value: item) {
                    Label(item.rawValue, systemImage: iconName(for: item))
                }
            }
            .navigationTitle("Menu")
        } detail: {
            NavigationStack {
                if let item = selectedItem {
                    switch item {
                    case .encryption:
                        EncryptView().navigationTitle("Encryption")
                    case .decryption:
                        DecryptView().navigationTitle("Decryption")
                    case .history:
                        HistoryView(historyStore: historyStore)
                            .navigationTitle("History")
                    }
                } else {
                    Text("Select an Option")
                }
            }
            .environmentObject(historyStore)
        }
        .onAppear {
            authVM.authenticate()
        }
        .fullScreenCover(isPresented: Binding<Bool>(
            get: { !authVM.isAuthenticated },
            set: { _ in }
        )) {
            UnlockView(authVM: authVM)
        }
    }
    
    func iconName(for item: NavigationItem) -> String {
        switch item {
        case .encryption: return "lock.fill"
        case .decryption: return "lock.open.fill"
        case .history: return "clock.fill"
        }
    }
}

struct UnlockView: View {
    @ObservedObject var authVM: AuthenticationViewModel
    var body: some View {
        VStack {
            Text("Locked")
                .font(.largeTitle)
                .padding()
            Button("Unlock") {
                authVM.authenticate()
            }
            .padding()
        }
    }
}

// ui and function for encryption activity

struct EncryptView: View {
    @EnvironmentObject var historyStore: EncryptionHistoryStore
    @AppStorage("symmetricAlgorithm") var symmetricAlgorithmSetting: String = SymmetricAlgorithm.aesGCM.rawValue
    @AppStorage("rsaKeySize") var rsaKeySize: Int = 2048
    @AppStorage("asymmetricAlgorithm") var asymmetricAlgorithmSetting: String = AsymmetricAlgorithm.rsaPKCS1.rawValue
    
    @State private var plainText: String = ""
    @State private var selectedEncryption: EncryptionType = .symmetric
    @State private var encryptedText: String = ""
    @State private var decryptionKey: String = ""
    @State private var statusMessage: String = ""
    
    @State private var showCopyAlert: Bool = false
    @State private var copyAlertMessage: String = ""
    @State private var isShareSheetPresented: Bool = false
    @State private var isMessageComposePresented: Bool = false
    
    var body: some View {
        Form {
            Section(header: Text("Enter Plain Text")) {
                ConfidentialTextField(text: $plainText, placeholder: "Enter text")
            }
            
            Section(header: Text("Encryption Options")) {
                Picker("Encryption Type", selection: $selectedEncryption) {
                    ForEach(EncryptionType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            Section {
                Button("Encrypt Text") { encryptAction() }
            }
            
            if !encryptedText.isEmpty {
                Section(header: Text("Encrypted Text (Base64)")) {
                    Text(encryptedText)
                        .font(.footnote)
                        .lineLimit(3)
                    
                    VStack(spacing: 8) {
                        Button(action: {
                            UIPasteboard.general.string = encryptedText
                            copyAlertMessage = "Encrypted text copied to clipboard."
                            showCopyAlert = true
                        }) {
                            Label("Copy", systemImage: "doc.on.doc")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            if MFMessageComposeViewController.canSendText() {
                                isMessageComposePresented = true
                            } else {
                                isShareSheetPresented = true
                            }
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 4)
                }
            }
            
            if !decryptionKey.isEmpty {
                Section(header: Text("Decryption Key (Base64)")) {
                    Text(decryptionKey)
                        .font(.footnote)
                    Button(action: {
                        UIPasteboard.general.string = decryptionKey
                        copyAlertMessage = "Decryption key copied to clipboard."
                        showCopyAlert = true
                    }) {
                        Label("Copy Key", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if !statusMessage.isEmpty {
                Section {
                    Text(statusMessage)
                        .foregroundColor(.gray)
                }
            }
            
            Section {
                Button("Clear") { clearFields() }
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Encryption")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: EncryptionSettingsView()) {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
        .alert(isPresented: $showCopyAlert) {
            Alert(title: Text("Copied"),
                  message: Text(copyAlertMessage),
                  dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $isShareSheetPresented) {
            ShareSheet(activityItems: [encryptedText])
        }
        .sheet(isPresented: $isMessageComposePresented) {
            MessageComposeView(bodyText: "Encrypted Text: \(encryptedText)\nDecryption Key: \(decryptionKey)")
        }
    }
    
    func encryptAction() {
        guard !plainText.isEmpty else {
            statusMessage = "Please enter text to encrypt."
            return
        }
        statusMessage = ""
        
        if selectedEncryption == .symmetric {
            guard let algo = SymmetricAlgorithm(rawValue: symmetricAlgorithmSetting) else {
                statusMessage = "Invalid symmetric algorithm setting."
                return
            }
            if let result = encryptSymmetric(plaintext: plainText, algorithm: algo) {
                encryptedText = result.ciphertext.base64EncodedString()
                decryptionKey = result.key
                statusMessage = "Encryption successful."
                let newHistoryItem = EncryptionHistoryItem(
                    id: UUID(),
                    timestamp: Date(),
                    plainText: plainText,
                    encryptedText: encryptedText,
                    decryptionKey: decryptionKey,
                    encryptionType: selectedEncryption.rawValue,
                    symmetricAlgorithm: algo.rawValue,
                    rsaKeySize: nil,
                    asymmetricAlgorithm: nil
                )
                historyStore.add(item: newHistoryItem)
            } else {
                statusMessage = "Symmetric encryption failed."
            }
        } else {
            guard let algo = AsymmetricAlgorithm(rawValue: asymmetricAlgorithmSetting) else {
                statusMessage = "Invalid asymmetric algorithm setting."
                return
            }
            if let result = encryptAsymmetric(plaintext: plainText, rsaKeySize: rsaKeySize, algorithm: algo) {
                encryptedText = result.ciphertext.base64EncodedString()
                decryptionKey = result.privateKey
                statusMessage = "Encryption successful."
                let newHistoryItem = EncryptionHistoryItem(
                    id: UUID(),
                    timestamp: Date(),
                    plainText: plainText,
                    encryptedText: encryptedText,
                    decryptionKey: decryptionKey,
                    encryptionType: selectedEncryption.rawValue,
                    symmetricAlgorithm: nil,
                    rsaKeySize: rsaKeySize,
                    asymmetricAlgorithm: algo.rawValue
                )
                historyStore.add(item: newHistoryItem)
            } else {
                statusMessage = "Asymmetric encryption failed."
            }
        }
    }
    
    func clearFields() {
        plainText = ""
        encryptedText = ""
        decryptionKey = ""
        statusMessage = ""
    }
}

// ui and function for decryption activity

struct DecryptView: View {
    @AppStorage("symmetricAlgorithm") var symmetricAlgorithmSetting: String = SymmetricAlgorithm.aesGCM.rawValue
    @AppStorage("asymmetricAlgorithm") var asymmetricAlgorithmSetting: String = AsymmetricAlgorithm.rsaPKCS1.rawValue
    
    @State private var encryptedText: String = ""
    @State private var decryptionKey: String = ""
    @State private var selectedEncryption: EncryptionType = .symmetric
    @State private var decryptionSymmetricAlgorithm: SymmetricAlgorithm = .aesGCM
    @State private var decryptionAsymmetricAlgorithm: AsymmetricAlgorithm = .rsaPKCS1
    @State private var decryptedText: String = ""
    @State private var statusMessage: String = ""
    
    @State private var showCopyAlert: Bool = false
    @State private var copyAlertMessage: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Encryption Type")) {
                Picker("Encryption Type", selection: $selectedEncryption) {
                    ForEach(EncryptionType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            
            if selectedEncryption == .symmetric {
                Section(header: Text("Symmetric Algorithm")) {
                    Picker("Algorithm", selection: $decryptionSymmetricAlgorithm) {
                        ForEach(SymmetricAlgorithm.allCases) { algo in
                            Text(algo.rawValue).tag(algo)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            } else {
                Section(header: Text("Asymmetric Algorithm")) {
                    Picker("Algorithm", selection: $decryptionAsymmetricAlgorithm) {
                        ForEach(AsymmetricAlgorithm.allCases) { algo in
                            Text(algo.rawValue).tag(algo)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            
            Section(header: Text("Encrypted Text (Base64)")) {
                TextField("Paste encrypted text", text: $encryptedText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Section(header: Text("Decryption Key (Base64)")) {
                TextField("Paste decryption key", text: $decryptionKey)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            
            Section {
                Button("Decrypt Text") { decryptAction() }
            }
            
            if !decryptedText.isEmpty {
                Section(header: Text("Decrypted Text")) {
                    Text(decryptedText)
                        .font(.footnote)
                    Button(action: {
                        UIPasteboard.general.string = decryptedText
                        copyAlertMessage = "Decrypted text copied to clipboard."
                        showCopyAlert = true
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            
            if !statusMessage.isEmpty {
                Section {
                    Text(statusMessage)
                        .foregroundColor(.gray)
                }
            }
            
            Section {
                Button("Clear") { clearFields() }
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Decryption")
        .alert(isPresented: $showCopyAlert) {
            Alert(title: Text("Copied"),
                  message: Text(copyAlertMessage),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    func decryptAction() {
        decryptedText = ""
        statusMessage = ""
        guard !encryptedText.isEmpty, !decryptionKey.isEmpty else {
            statusMessage = "Please provide both encrypted text and decryption key."
            return
        }
        guard let encryptedData = Data(base64Encoded: encryptedText) else {
            statusMessage = "Invalid Base64 for encrypted text."
            return
        }
        
        if selectedEncryption == .symmetric {
            if let result = decryptSymmetric(encryptedData: encryptedData, keyString: decryptionKey, algorithm: decryptionSymmetricAlgorithm) {
                decryptedText = result
                statusMessage = "Decryption successful."
            } else {
                statusMessage = "Symmetric decryption failed."
            }
        } else {
            if let result = decryptAsymmetric(encryptedData: encryptedData, privateKeyString: decryptionKey, algorithm: decryptionAsymmetricAlgorithm) {
                decryptedText = result
                statusMessage = "Decryption successful."
            } else {
                statusMessage = "Asymmetric decryption failed."
            }
        }
    }
    
    func clearFields() {
        encryptedText = ""
        decryptionKey = ""
        decryptedText = ""
        statusMessage = ""
    }
}

// ui and function for history activity

struct HistoryView: View {
    @ObservedObject var historyStore: EncryptionHistoryStore
    var body: some View {
        List {
            ForEach(historyStore.history) { item in
                NavigationLink(destination: HistoryDetailView(item: item)) {
                    VStack(alignment: .leading) {
                        Text(item.timestamp, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text("Type: \(item.encryptionType)")
                        if let algo = item.symmetricAlgorithm { Text("Symmetric Algo: \(algo)") }
                        if let keySize = item.rsaKeySize { Text("RSA Key Size: \(keySize)") }
                        if let asymAlgo = item.asymmetricAlgorithm { Text("Asymmetric Algo: \(asymAlgo)") }
                        Text("Encrypted: \(item.encryptedText)")
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
            .onDelete(perform: deleteItems)
        }
        .navigationTitle("History")
    }
    
    func deleteItems(at offsets: IndexSet) {
        historyStore.removeItems(at: offsets)
    }
}

struct HistoryDetailView: View {
    let item: EncryptionHistoryItem
    @State private var isRevealed: Bool = false
    @State private var showAuthError: Bool = false
    @State private var showCopyAlert: Bool = false
    @State private var copyAlertMessage: String = ""
    
    var body: some View {
        Form {
            Section(header: Text("Timestamp")) {
                Text(item.timestamp, style: .date)
                Text(item.timestamp, style: .time)
            }
            Section(header: Text("Encryption Type")) {
                Text(item.encryptionType)
            }
            if let algo = item.symmetricAlgorithm {
                Section(header: Text("Symmetric Algorithm")) {
                    Text(algo)
                }
            }
            if let keySize = item.rsaKeySize {
                Section(header: Text("RSA Key Size")) {
                    Text("\(keySize)")
                }
            }
            if let asymAlgo = item.asymmetricAlgorithm {
                Section(header: Text("Asymmetric Algorithm")) {
                    Text(asymAlgo)
                }
            }
            if isRevealed {
                Section(header: Text("Plain Text")) {
                    HStack {
                        Text(item.plainText)
                        Spacer()
                        Button("Copy") {
                            UIPasteboard.general.string = item.plainText
                            copyAlertMessage = "Plain text copied."
                            showCopyAlert = true
                        }
                    }
                }
                Section(header: Text("Decryption Key")) {
                    HStack {
                        Text(item.decryptionKey)
                        Spacer()
                        Button("Copy") {
                            UIPasteboard.general.string = item.decryptionKey
                            copyAlertMessage = "Decryption key copied."
                            showCopyAlert = true
                        }
                    }
                }
            } else {
                Section(header: Text("Plain Text")) { Text("••••••••") }
                Section(header: Text("Decryption Key")) { Text("••••••••") }
                Section {
                    Button("Reveal Sensitive Data") { authenticateAndReveal() }
                }
            }
            // Encrypted Text can be copied at any time.
            Section(header: Text("Encrypted Text")) {
                HStack {
                    Text(item.encryptedText)
                        .lineLimit(2)
                    Spacer()
                    Button("Copy") {
                        UIPasteboard.general.string = item.encryptedText
                        copyAlertMessage = "Encrypted text copied."
                        showCopyAlert = true
                    }
                }
            }
        }
        .navigationTitle("History Detail")
        .alert(isPresented: $showAuthError) {
            Alert(title: Text("Authentication Failed"),
                  message: Text("Unable to authenticate. Sensitive data remains hidden."),
                  dismissButton: .default(Text("OK")))
        }
        .alert(isPresented: $showCopyAlert) {
            Alert(title: Text("Copied"),
                  message: Text(copyAlertMessage),
                  dismissButton: .default(Text("OK")))
        }
    }
    
    func authenticateAndReveal() {
        let context = LAContext()
        let reason = "Authenticate to reveal sensitive data"
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
            DispatchQueue.main.async {
                if success {
                    isRevealed = true
                } else {
                    showAuthError = true
                }
            }
        }
    }
}

// ui and function for encryption settings

struct EncryptionSettingsView: View {
    @AppStorage("symmetricAlgorithm") var symmetricAlgorithm: String = SymmetricAlgorithm.aesGCM.rawValue
    @AppStorage("rsaKeySize") var rsaKeySize: Int = 2048
    @AppStorage("asymmetricAlgorithm") var asymmetricAlgorithm: String = AsymmetricAlgorithm.rsaPKCS1.rawValue
    
    var body: some View {
        Form {
            Section(header: Text("Symmetric Encryption")) {
                Picker("Algorithm", selection: $symmetricAlgorithm) {
                    ForEach(SymmetricAlgorithm.allCases) { algo in
                        Text(algo.rawValue).tag(algo.rawValue)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            Section(header: Text("Asymmetric Encryption")) {
                Picker("RSA Key Size", selection: $rsaKeySize) {
                    Text("2048").tag(2048)
                    Text("4096").tag(4096)
                }
                .pickerStyle(SegmentedPickerStyle())
                Picker("Algorithm", selection: $asymmetricAlgorithm) {
                    ForEach(AsymmetricAlgorithm.allCases) { algo in
                        Text(algo.rawValue).tag(algo.rawValue)
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
        }
        .navigationTitle("Encryption Settings")
    }
}

// ui and function for sharing information

struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems,
                                   applicationActivities: applicationActivities)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

// helper functions

struct SymmetricEncryptionResult {
    let ciphertext: Data
    let key: String
}

func encryptSymmetric(plaintext: String, algorithm: SymmetricAlgorithm) -> SymmetricEncryptionResult? {
    guard let data = plaintext.data(using: .utf8) else { return nil }
    switch algorithm {
    case .aesGCM:
        let symmetricKey = SymmetricKey(size: .bits256)
        do {
            let sealedBox = try AES.GCM.seal(data, using: symmetricKey)
            guard let combined = sealedBox.combined else { return nil }
            let keyData = symmetricKey.withUnsafeBytes { Data(Array($0)) }
            return SymmetricEncryptionResult(ciphertext: combined,
                                             key: keyData.base64EncodedString())
        } catch {
            print("AES-GCM encryption error: \(error)")
            return nil
        }
    case .chaChaPoly:
        let symmetricKey = SymmetricKey(size: .bits256)
        do {
            let sealedBox = try ChaChaPoly.seal(data, using: symmetricKey)
            let combined = sealedBox.combined
            let keyData = symmetricKey.withUnsafeBytes { Data(Array($0)) }
            return SymmetricEncryptionResult(ciphertext: combined,
                                             key: keyData.base64EncodedString())
        } catch {
            print("ChaChaPoly encryption error: \(error)")
            return nil
        }
    case .aesCBC:
        var keyBytes = Data(count: 32)
        let keyResult = keyBytes.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, 32, $0.baseAddress!)
        }
        if keyResult != errSecSuccess {
            print("Error generating AES-CBC key")
            return nil
        }
        var iv = Data(count: kCCBlockSizeAES128)
        let ivResult = iv.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, kCCBlockSizeAES128, $0.baseAddress!)
        }
        if ivResult != errSecSuccess {
            print("Error generating AES-CBC IV")
            return nil
        }
        if let cipherData = encryptAESCBC(plaintext: data, key: keyBytes, iv: iv) {
            let combinedKey = keyBytes + iv
            return SymmetricEncryptionResult(ciphertext: cipherData,
                                             key: combinedKey.base64EncodedString())
        } else {
            return nil
        }
    }
}

func decryptSymmetric(encryptedData: Data, keyString: String, algorithm: SymmetricAlgorithm) -> String? {
    switch algorithm {
    case .aesGCM:
        guard let keyData = Data(base64Encoded: keyString) else { return nil }
        let symmetricKey = SymmetricKey(data: keyData)
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("AES-GCM decryption error: \(error)")
            return nil
        }
    case .chaChaPoly:
        guard let keyData = Data(base64Encoded: keyString) else { return nil }
        let symmetricKey = SymmetricKey(data: keyData)
        do {
            let sealedBox = try ChaChaPoly.SealedBox(combined: encryptedData)
            let decryptedData = try ChaChaPoly.open(sealedBox, using: symmetricKey)
            return String(data: decryptedData, encoding: .utf8)
        } catch {
            print("ChaChaPoly decryption error: \(error)")
            return nil
        }
    case .aesCBC:
        guard let combinedKey = Data(base64Encoded: keyString) else {
            print("Invalid Base64 key for AES-CBC")
            return nil
        }
        if combinedKey.count != 32 + kCCBlockSizeAES128 {
            print("AES-CBC key/IV length mismatch")
            return nil
        }
        let keyPart = combinedKey.prefix(32)
        let ivPart = combinedKey.suffix(kCCBlockSizeAES128)
        if let decryptedData = decryptAESCBC(encryptedData: encryptedData, key: keyPart, iv: ivPart) {
            return String(data: decryptedData, encoding: .utf8)
        } else {
            return nil
        }
    }
}

func encryptAESCBC(plaintext: Data, key: Data, iv: Data) -> Data? {
    var numBytesEncrypted: size_t = 0
    let dataOutSize = plaintext.count + kCCBlockSizeAES128
    let dataOut = UnsafeMutablePointer<UInt8>.allocate(capacity: dataOutSize)
    defer { dataOut.deallocate() }
    
    let cryptStatus = CCCrypt(
        CCOperation(kCCEncrypt),
        CCAlgorithm(kCCAlgorithmAES),
        CCOptions(kCCOptionPKCS7Padding),
        (key as NSData).bytes, key.count,
        (iv as NSData).bytes,
        (plaintext as NSData).bytes, plaintext.count,
        dataOut, dataOutSize,
        &numBytesEncrypted)
    
    if cryptStatus == kCCSuccess {
        return Data(bytes: dataOut, count: numBytesEncrypted)
    } else {
        print("AES-CBC encryption error: \(cryptStatus)")
        return nil
    }
}

func decryptAESCBC(encryptedData: Data, key: Data, iv: Data) -> Data? {
    var numBytesDecrypted: size_t = 0
    let dataOutSize = encryptedData.count
    let dataOut = UnsafeMutablePointer<UInt8>.allocate(capacity: dataOutSize)
    defer { dataOut.deallocate() }
    
    let cryptStatus = CCCrypt(
        CCOperation(kCCDecrypt),
        CCAlgorithm(kCCAlgorithmAES),
        CCOptions(kCCOptionPKCS7Padding),
        (key as NSData).bytes, key.count,
        (iv as NSData).bytes,
        (encryptedData as NSData).bytes, encryptedData.count,
        dataOut, dataOutSize,
        &numBytesDecrypted)
    
    if cryptStatus == kCCSuccess {
        return Data(bytes: dataOut, count: numBytesDecrypted)
    } else {
        print("AES-CBC decryption error: \(cryptStatus)")
        return nil
    }
}

struct AsymmetricEncryptionResult {
    let ciphertext: Data
    let privateKey: String
}

func encryptAsymmetric(plaintext: String, rsaKeySize: Int, algorithm: AsymmetricAlgorithm) -> AsymmetricEncryptionResult? {
    let privateKeyAttrs: [String: Any] = [
        kSecAttrIsPermanent as String: false,
        kSecAttrIsExtractable as String: true
    ]
    let parameters: [String: Any] = [
        kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
        kSecAttrKeySizeInBits as String: rsaKeySize,
        kSecPrivateKeyAttrs as String: privateKeyAttrs
    ]
    var pubKey, privKey: SecKey?
    let status = SecKeyGeneratePair(parameters as CFDictionary, &pubKey, &privKey)
    guard status == errSecSuccess,
          let publicKey = pubKey,
          let privateKey = privKey,
          let data = plaintext.data(using: .utf8) else {
        print("Error generating key pair or converting plaintext.")
        return nil
    }
    var error: Unmanaged<CFError>?
    let secKeyAlgorithm: SecKeyAlgorithm = {
        switch algorithm {
        case .rsaPKCS1: return .rsaEncryptionPKCS1
        case .rsaOAEP: return .rsaEncryptionOAEPSHA256
        }
    }()
    guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, secKeyAlgorithm) else {
        print("Algorithm not supported")
        return nil
    }
    guard let cipherData = SecKeyCreateEncryptedData(publicKey, secKeyAlgorithm, data as CFData, &error) as Data? else {
        print("Asymmetric encryption error: \(error!.takeRetainedValue() as Error)")
        return nil
    }
    var errorPrivate: Unmanaged<CFError>?
    guard let privateKeyData = SecKeyCopyExternalRepresentation(privateKey, &errorPrivate) as Data? else {
        print("Private key extraction error: \(errorPrivate!.takeRetainedValue() as Error)")
        return nil
    }
    return AsymmetricEncryptionResult(ciphertext: cipherData,
                                      privateKey: privateKeyData.base64EncodedString())
}

func decryptAsymmetric(encryptedData: Data, privateKeyString: String, algorithm: AsymmetricAlgorithm) -> String? {
    guard let privateKeyData = Data(base64Encoded: privateKeyString) else { return nil }
    let keyDict: [String: Any] = [
        kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
        kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
        kSecAttrKeySizeInBits as String: 2048,
        kSecReturnPersistentRef as String: false
    ]
    var error: Unmanaged<CFError>?
    guard let privateKey = SecKeyCreateWithData(privateKeyData as CFData, keyDict as CFDictionary, &error) else {
        print("Error creating private key: \(error!.takeRetainedValue() as Error)")
        return nil
    }
    var decryptError: Unmanaged<CFError>?
    let secKeyAlgorithm: SecKeyAlgorithm = {
        switch algorithm {
        case .rsaPKCS1: return .rsaEncryptionPKCS1
        case .rsaOAEP: return .rsaEncryptionOAEPSHA256
        }
    }()
    guard let decryptedData = SecKeyCreateDecryptedData(privateKey, secKeyAlgorithm, encryptedData as CFData, &decryptError) as Data? else {
        print("Asymmetric decryption error: \(decryptError!.takeRetainedValue() as Error)")
        return nil
    }
    return String(data: decryptedData, encoding: .utf8)
}
