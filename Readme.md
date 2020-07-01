## iOS App & Mach-O binary decryption
This is a decryption tool for research purposes. It uses mremap_encrypted to decrypt a file from disk.  

### Installation  
1. Download the .deb package from the [the latest release.](https://github.com/JohnCoates/flexdecrypt/releases/latest)
2. Transfer it to your device.
3. Use Filza to install it via UI, or use the command line: `dpkg -i flexdecrypt.deb`

Latest release also includes the flexdecrypt binary in case you want to install it yourself.

### Build from source
Open the project file with Xcode.  
Use the Debug scheme to run directly on your device from Xcode, with debugger support.  
Configure the run arguments with Xcode's scheme editor.  
Make sure you have [AppSync](https://cydia.akemi.ai/) installed so the app installs despite the custom entitlements.


### Information

Further reading at https://www.linkedin.com/pulse/decrypting-apps-ios-john-coates/

Contact: john@johncoates.dev
