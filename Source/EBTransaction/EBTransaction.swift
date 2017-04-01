//
//  EBTransaction.swift
//  CameraApp
//
//  Created by Anton Doudarev on 3/29/17.
//  Copyright © 2017 Anton Doudarev. All rights reserved.
//

import Foundation
import CoreBluetooth

public typealias EBTransactionCallback = ((_ data: Data?, _ error: Error?) -> Void)

public enum TransactionDirection : Int {
    case centralToPeripheral
    case peripheralToCentral
}

public enum TransactionType : Int {
    case read
    case readChunkable
    case write
    case writeChunkable
}

public class Transaction {
    
    var characteristic : CBCharacteristic?

    internal var direction      : TransactionDirection
    internal var type           : TransactionType
    internal var mtuSize        : Int16
    internal var totalPackets   : Int = 0
    internal var completion     : EBTransactionCallback?
    
    internal var activeResponseCount : Int = 0
    
    var dataPackets : [Data] = [Data]()
    
    var data : Data? {
        get {
            if type == .readChunkable || type == .writeChunkable {
                return  Data.reconstructedData(withArray: dataPackets)!
            } else {
                
                if let singlePacket = dataPackets.first {
                    return singlePacket
                }
                return nil
            }
        }
        set {
            if type == .readChunkable || type == .writeChunkable {
                dataPackets = newValue?.packetArray(withMTUSize: mtuSize) ?? [Data]()
                totalPackets = newValue?.packetArray(withMTUSize: mtuSize).count ?? 1
            } else {
                if let value = newValue {
                    dataPackets = [value]
                } else {
                    dataPackets = [Data]()
                }
            }
        }
    }
    
    public required init(_ type : TransactionType , _ direction : TransactionDirection, mtuSize : Int16 = 23) {
        self.direction = direction
        self.type = type
        self.mtuSize = mtuSize
    }

    func receivedReceipt() {
        activeResponseCount = activeResponseCount + 1
    }
    
    func nextPacket() -> Data? {
        return dataPackets[activeResponseCount - 1]
    }
    
    func sentReceipt() {
        activeResponseCount = activeResponseCount + 1
    }
    
    
    func appendPacket(_ dataPacket : Data?) {
        
        guard let dataPacket = dataPacket else {
            return
        }
        
        if type == .writeChunkable || type == .readChunkable {
            totalPackets = dataPacket.totalPackets
        }
        
        dataPackets.append(dataPacket)
    }
    
    var isComplete : Bool {
        get {
            print( activeResponseCount, "/ ",  totalPackets)
            if type == .readChunkable || type == .writeChunkable {
                return totalPackets == activeResponseCount
            }
            
            return (activeResponseCount == 1)
        }
    }
}

public class EBTransaction {
    
    var data : Data?
    var responseCount : Int = 0
    var chunks : [Data] = [Data]()
    var characteristic : CBCharacteristic?
    var completion : EBTransactionCallback?
    
    var isComplete : Bool {
        get {
            return chunks.count == responseCount && responseCount != 0
        }
    }
    
    var reconstructedValue : Data {
        get {  return  Data.reconstructedData(withArray: chunks)! }
    }
}
