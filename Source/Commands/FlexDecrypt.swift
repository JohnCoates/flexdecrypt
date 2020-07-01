//
//  FlexDecrypt.swift
//  Created on 6/30/20
//

import Foundation
import ArgumentParser

struct FlexDecrypt: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "A tool for decrypting apps and Mach-O binaries. Based " +
        "on the Flex 3 jailbreak app's source code.", version: "1.0.0",
        subcommands: [DecryptFile.self],
        defaultSubcommand: DecryptFile.self
    )
}

struct Options: ParsableArguments {
    @Flag(name: [.customLong("verbose"), .customShort("v")],
          help: "Use verbose output.")
    var verboseOutput = false
}
