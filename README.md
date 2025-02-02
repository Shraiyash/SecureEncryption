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

![Simulator Screenshot - iPhone 16 Pro - 2025-02-02 at 14 06 28](https://github.com/user-attachments/assets/635ad9ec-106a-4c84-9e17-cd5f63633288)


Biometrics/Passcode Protected:

![Simulator Screenshot - iPhone 16 Pro - 2025-02-02 at 14 06 33](https://github.com/user-attachments/assets/5e19aeb8-31a2-4e5b-8ca1-d5a1abbeb0b1)


Nav Bar:

![Simulator Screenshot - iPhone 16 Pro - 2025-02-02 at 14 06 51](https://github.com/user-attachments/assets/6727dada-6ac0-42a9-a8d0-22953c9cf986)


Encryption Activity:

![Simulator Screenshot - iPhone 16 Pro - 2025-02-02 at 14 06 39](https://github.com/user-attachments/assets/f5109c75-d3c8-4840-894a-5c6d733edcbd)


Encryption Settings:

![Simulator Screenshot - iPhone 16 Pro - 2025-02-02 at 14 06 43](https://github.com/user-attachments/assets/c20dbac7-290e-4edc-91d2-911508d9e458)


Decryption Activity:

![Simulator Screenshot - iPhone 16 Pro - 2025-02-02 at 14 06 49](https://github.com/user-attachments/assets/8e79ca9b-55a5-4432-8f9b-021c013b323b)


History Activity:

![Simulator Screenshot - iPhone 16 Pro - 2025-02-02 at 14 07 42](https://github.com/user-attachments/assets/fa0971d4-a2e0-4c79-a553-68d2ce6656af)


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
