//
//  ProvisioningPduType.swift
//  nRFMeshProvision
//
//  Created by Aleksander Nowakowski on 07/05/2019.
//

import Foundation

internal typealias ProvisioningPdu = Data

internal enum ProvisioningPduType: UInt8 {
    case invite        = 0
    case capabilities  = 1
    case start         = 2
    case publicKey     = 3
    case inputComplete = 4
    case confirmation  = 5
    case random        = 6
    case data          = 7
    case complete      = 8
    case failed        = 9
    
    var type: UInt8 {
        return rawValue
    }
}

internal enum ProvisioningRequest {
    case invite(attentionTimer: UInt8)
    case start(algorithm: Algorithm, publicKey: PublicKey, authenticationMethod: AuthenticationMethod)
    case publicKey(_ key: Data)
    
    var pdu: ProvisioningPdu {
        switch self {
        case let .invite(attentionTimer: timer):
            var data = ProvisioningPdu(pdu: .invite)
            return data.with(timer)
        case let .start(algorithm: algorithm, publicKey: publicKey, authenticationMethod: method):
            var data = ProvisioningPdu(pdu: .start)
            data += algorithm.value
            data += publicKey.value
            data += method.value
            return data
        case let .publicKey(key):
            var data = ProvisioningPdu(pdu: .publicKey)
            data += key
            return data
        }
    }
    
}

internal struct ProvisioningResponse {
    let type: ProvisioningPduType
    let capabilities: ProvisioningCapabilities?
    let publicKey: Data?
    
    init?(_ data: Data) {
        guard data.count > 0, let pduType = ProvisioningPduType(rawValue: data[0]) else {
            return nil
        }
        
        self.type = pduType
        
        switch pduType {
        case .capabilities:
            capabilities = ProvisioningCapabilities(data)
            publicKey = nil
        case .publicKey:
            publicKey = data.subdata(in: 1..<data.count)
            capabilities = nil
        case .inputComplete:
            publicKey = nil
            capabilities = nil
        default:
            return nil
        }
    }
    
    var isValid: Bool {
        switch type {
        case .capabilities:
            return capabilities != nil
        case .publicKey:
            return publicKey != nil
        case .inputComplete:
            return true
        default:
            return false
        }
    }
}

extension ProvisioningRequest: CustomDebugStringConvertible {
    
    var debugDescription: String {
        switch self {
        case let .invite(attentionTimer: timer):
            return "Provisioning Invite (attention timer: \(timer) sec)"
        case let .start(algorithm: algorithm, publicKey: publicKey, authenticationMethod: authenticationMethod):
            return "Provisioning Start (algorithm: \(algorithm), public Key: \(publicKey), authentication Method: \(authenticationMethod))"
        case let .publicKey(key):
            return "Provisioner Public Key (0x\(key.hex))"
        }
    }

}

private extension Data {
    
    init(pdu: ProvisioningPduType) {
        self = Data([pdu.type])
    }
    
    mutating func with(_ parameter: UInt8) -> Data {
        self.append(parameter)
        return self
    }
    
    mutating func with(_ parameter: UInt16) -> Data {
        self.append(parameter.data)
        return self
    }
    
}
