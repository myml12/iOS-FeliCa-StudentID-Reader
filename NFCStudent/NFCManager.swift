//
//  NFCManager.swift
//  NFCStudent
//
//  Created by Yusuke Mizuno on 2025/07/20.
//

import Foundation
import CoreNFC

class NFCManager: NSObject, ObservableObject, NFCTagReaderSessionDelegate {
    @Published var message: String = "NFCタグを読み取ってください"
    @Published var result: String = ""
    
    private var session: NFCTagReaderSession?
    
    func beginSession() {
        guard NFCTagReaderSession.readingAvailable else {
            self.message = "このデバイスではNFCが利用できません。"
            return
        }
        
        session = NFCTagReaderSession(pollingOption: .iso18092, delegate: self)
        session?.alertMessage = "学生証をiPhoneにかざしてください"
        session?.begin()
    }
    
    func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        DispatchQueue.main.async {
            self.message = "NFCセッションが開始されました。"
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        DispatchQueue.main.async {
            self.message = "セッション終了: \(error.localizedDescription)"
            self.session = nil
        }
    }
    
    func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        guard let tag = tags.first else {
            session.invalidate(errorMessage: "タグが見つかりませんでした。")
            return
        }
        
        session.connect(to: tag) { error in
            if let error = error {
                session.invalidate(errorMessage: "接続失敗: \(error.localizedDescription)")
                return
            }
            
            guard case let .feliCa(felicaTag) = tag else {
                session.invalidate(errorMessage: "FeliCaタグではありません。")
                return
            }
            
            let serviceCode = Data([0x8B, 0x1A]) // 1A8B（Little Endian）
            let blockList = [Data([0x80, 0x00])] // ブロック0
            
            felicaTag.readWithoutEncryption(serviceCodeList: [serviceCode], blockList: blockList) { statusFlag1, statusFlag2, blockData, error in
                if let error = error {
                    session.invalidate(errorMessage: "読み取り失敗: \(error.localizedDescription)")
                    return
                }
                
                if statusFlag1 == 0x00, let data = blockData.first {
                    if let decodedString = String(data: data, encoding: .shiftJIS) {
                        DispatchQueue.main.async {
                            self.result = decodedString
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.result = "Shift_JISでのデコードに失敗しました"
                        }
                    }
                    
                    session.invalidate()
                } else {
                    session.invalidate(errorMessage: "ステータス異常: \(statusFlag1), \(statusFlag2)")
                }
            }
        }
    }
}
