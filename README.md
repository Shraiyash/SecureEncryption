# SecureEncryption

SecureEncryption is an iOS application built with SwiftUI that allows you to encrypt and decrypt text using various encryption algorithms. It provides a simple, user-friendly interface with the following key features:

- **Encryption & Decryption:**  
  Encrypt plain text using either symmetric (AES-GCM, ChaChaPoly, AES-CBC) or asymmetric (RSA PKCS1, RSA OAEP) algorithms. Then, decrypt the text using the provided decryption key.

- **History Archive:**  
  All encryption events are saved to a history list. You can view, copy, and delete history records.

- **Security:**  
  The app uses biometric (Face ID/Touch ID) or device passcode authentication to secure access to sensitive data.

- **Splash Screen:**  
  A simple splash screen displays the title ("Secure Encryption") and developer info ("Developer: Yash") when the app launches.

- **Copy & Share:**  
  Easily copy or share your encrypted text and decryption key using separate buttons.

- **Settings:**  
  Choose your preferred encryption algorithm options in the settings screen.

# Screenshots

Splash Screen: 

![Simulator Screenshot - iPhone 16 Pro - 2025-02-02 at 14 06 28](https://github.com/user-attachments/assets/eb32627e-ed18-473b-baa8-5c9978c36e14)


Biometrics/Passcode Protected:

![Simulator Screenshot - iPhone 16 Pro - 2025-02-02 at 14 06 33](https://github.com/user-attachments/assets/6d28277a-da58-473f-bba0-636ff5096188)


Nav Bar:

![Simulator Screenshot - iPhone 16 Pro - 2025-02-02 at 14 06 51](https://github.com/user-attachments/assets/f871a5a3-f3d4-47be-9413-b65976b0751c)

Encryption Activity:

![Simulator Screenshot - iPhone 16 Pro - 2025-02-02 at 14 06 43](https://github.com/user-attachments/assets/60aba8c7-99a6-44bb-b13d-1b2fa953b1ee)


Decryption Activity:

![Simulator Screenshot - iPhone 16 Pro - 2025-02-02 at 14 06 49](https://github.com/user-attachments/assets/9f9c86dc-e8b7-4816-91b3-3f73e713545d)


History Activity:

![Simulator Screenshot - iPhone 16 Pro - 2025-02-02 at 14 07 42](https://github.com/user-attachments/assets/61cf5498-f69d-4dfb-8792-571d10930541)

## Requirements

- Xcode 14 or later
- iOS 16 or later
- SwiftUI
- Frameworks: CryptoKit, Security, LocalAuthentication, MessageUI, CommonCrypto

## How to Run

1. **Clone the Repository:**  
   Clone this project to your local machine.

2. **Open in Xcode:**  
   Open the project file (`SecureEncryption.xcodeproj`) in Xcode.

3. **Build and Run:**  
   Build and run the app on an iOS simulator or (preferably) a real device.  
   *Note:* Some features (like biometric authentication and iMessage sharing) may only work on a real device.

## How It Works

1. **Launch & Authentication:**  
   When you launch the app, a splash screen displays for a few seconds. After that, the app immediately asks for biometric or passcode authentication.

2. **Encryption:**  
   - Enter your plain text.  
   - Choose whether to use symmetric or asymmetric encryption (with various algorithm options available in Settings).  
   - Tap "Encrypt Text" to encrypt the text.  
   - The app displays the encrypted text and a decryption key that you can copy or share.

3. **Decryption:**  
   - Paste the encrypted text and the decryption key.  
   - Tap "Decrypt Text" to retrieve the original plain text.

4. **History:**  
   - All encryption events are saved in the history.  
   - You can view the details of each entry, copy the sensitive data (after revealing it), and even delete unwanted records.

## License

This project is provided as-is for educational purposes.
