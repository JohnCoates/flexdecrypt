//
//  DecryptFile.swift
//  Created on 6/30/20
//

import Foundation
import ArgumentParser

struct DecryptFile: ParsableCommand {
    static var configuration = CommandConfiguration(commandName: "file", abstract: "Decrypt file.")

    @Argument(help: "The file to decrypt.")
    var file: String

    @Option(name: .customLong("output"), help: "The path to the output file.")
    var output: String?
    var outputUrl: URL {
        if let output = output {
            return URL(fileURLWithPath: output)
        } else {
            let lastPathComponent = file.components(separatedBy: "/").last ?? "decrypted"
            return URL(fileURLWithPath: "/tmp/" + lastPathComponent)
        }
    }

    func run() throws {
        FLXLog.printInternalMessages = options.verboseOutput

        let file = try MachOFile(url: URL(fileURLWithPath: self.file))
        let data = try file.sliceDataForHostArchitecture()
        try data.write(to: outputUrl)
        print("Wrote decrypted image to \(outputUrl.path)")
    }

    @OptionGroup()
    var options: Options
}
