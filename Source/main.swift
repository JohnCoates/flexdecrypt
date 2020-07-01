//
//  main.swift
//  Created on 6/30/20
//

import Foundation

func disablePrintBuffering() {
    setbuf(__stdoutp, nil)
}

disablePrintBuffering()
FlexDecrypt.main()
