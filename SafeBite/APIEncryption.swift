import Foundation
import CommonCrypto

func decryptAPIKey(encryptedText: String, secretKey: String, iv: String) -> String? {
    // Ensure key and IV are 16 bytes (128 bits)
    let keyLength = kCCKeySizeAES128
    guard let dataToDecrypt = Data(base64Encoded: encryptedText),
          let ivData = iv.data(using: .utf8),
          var keyData = secretKey.data(using: .utf8) else {
        print("Invalid input data.")
        return nil
    }
    
    print("Key Length: \(secretKey.count) bytes")
    print("IV Length: \(iv.count) bytes")
    
    if keyData.count < keyLength {
        // Pad the key to 16 bytes if it's shorter
        keyData.append(contentsOf: [UInt8](repeating: 0, count: keyLength - keyData.count))
    } else if keyData.count > keyLength {
        // Truncate the key if it's longer
        keyData = keyData.subdata(in: 0..<keyLength)
    }
    
    let bufferSize = dataToDecrypt.count + kCCBlockSizeAES128
    var buffer = Data(count: bufferSize)
    var numBytesDecrypted: size_t = 0
    
    let cryptStatus = buffer.withUnsafeMutableBytes { bufferBytes in
        dataToDecrypt.withUnsafeBytes { encryptedBytes in
            keyData.withUnsafeBytes { keyBytes in
                ivData.withUnsafeBytes { ivBytes in
                    CCCrypt(
                        CCOperation(kCCDecrypt),                 // Operation: Decrypt
                        CCAlgorithm(kCCAlgorithmAES),            // Algorithm: AES
                        CCOptions(kCCOptionPKCS7Padding),        // Padding: PKCS7
                        keyBytes.baseAddress,                    // Key pointer
                        keyLength,                               // Key length
                        ivBytes.baseAddress,                     // IV pointer
                        encryptedBytes.baseAddress,              // Encrypted data pointer
                        dataToDecrypt.count,                     // Encrypted data length
                        bufferBytes.baseAddress,                 // Output buffer pointer
                        bufferSize,                              // Output buffer size
                        &numBytesDecrypted                       // Output bytes processed
                    )
                }
            }
        }
    }
    
    guard cryptStatus == kCCSuccess else {
        print("Decryption failed with status: \(cryptStatus)")
        return nil
    }
    print("cryptStatus: \(cryptStatus)")
    
    // Trim the buffer to the actual decrypted data size
    buffer.removeSubrange(numBytesDecrypted..<buffer.count)
    
    let decryptedKey = String(data: buffer, encoding: .utf8)
    print("Decrypted API Key: \(decryptedKey ?? "Failed to decrypt; returned nil")")
    return decryptedKey // Convert to String
}
