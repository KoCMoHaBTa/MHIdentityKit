//
//  MockHS256.swift
//  MHIdentityKit
//
//  Created by Milen Halachev on 26.08.19.
//  Copyright © 2019 Milen Halachev. All rights reserved.
//

import Foundation

struct MockHS256 {
    
    let input = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJuaWNrbmFtZSI6ImthbGluLnZlbmtvdiIsIm5hbWUiOiJrYWxpbi52ZW5rb3ZAZWxkZXJzb3NzLmNvbSIsInBpY3R1cmUiOiJodHRwczovL3MuZ3JhdmF0YXIuY29tL2F2YXRhci9iZTI5OWMwODBlNzEwMDY0MWIwY2FhYmMzM2QyMThjND9zPTQ4MCZyPXBnJmQ9aHR0cHMlM0ElMkYlMkZjZG4uYXV0aDAuY29tJTJGYXZhdGFycyUyRmthLnBuZyIsInVwZGF0ZWRfYXQiOiIyMDE5LTA4LTI2VDEzOjA2OjQ3LjY4NFoiLCJlbWFpbCI6ImthbGluLnZlbmtvdkBlbGRlcnNvc3MuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImlzcyI6Imh0dHBzOi8vc3Ryb3dyLWRldmVsb3BtZW50LmV1LmF1dGgwLmNvbS8iLCJzdWIiOiJhdXRoMHw1YzU0NjI1ZDc1ZWIwMjA5NmZkYzM3MzciLCJhdWQiOiJrRkI0NjdLejg4N1lOSmNRT0dHc3pqY2tETTNHWURsOSIsImlhdCI6MTU2NjgyNDgwNywiZXhwIjoxNTY2ODYwODA3fQ".data(using: .ascii)!
    
    let signature = Data(base64UrlEncoded: "mA5KUKe2OY7m3PYpeE3NivweoPcv_8ErjcUtkMFV0GY")!
    
    let secret = "9kFI9WLMatSx6r0TsuKsJKp2P5tbddPEl9ohcERDjAOnBjYI6vnij2jbnRlJndog"
}
