//
//  Shamir39Utils.swift
//  Shamir39iOS
//
//  Created by MinSoo Kang on 2020/04/01.
//  Copyright © 2020 MinSoo Kang. All rights reserved.
//

import UIKit


struct Shamir39Error : Error {
    
    let msg: String
    init(_ msg : String) {
        self.msg = msg
    }
    
}



class Shamir39Utils {
    static let shared = Shamir39Utils()
    private init() {}
    
    
    func padLeft(_ str: String,
                 _ bits: Int) -> String{
    
        let missing = str.count % bits;
        if missing == 0 {
            return str
        }else{
            
            var temp = ""
            for _ in 0..<(bits - missing ){
                temp = temp + "0"
            }
            return temp + str
        }
    }
    
    
    
    func inArray(_ arr: [Int],
                         _ val: Int) -> Bool{
        
        let len = arr.count
        for i in 0..<len {
            if arr[i] == val {
                return true;
            }
        }
       
        return false;
    }
    
    
    func paramsToBinaryStr(_ m: Int, _ o: Int) -> String{
        
        var mBin = String(m, radix: 2, uppercase: false)
        var oBin = String(o, radix: 2, uppercase: false)
        
        let mBinFinalLength = ceil(Double(mBin.count) / 5.0) * 5;
        let oBinFinalLength = ceil(Double(oBin.count) / 5.0) * 5;
        
        let binFinalLength = max(mBinFinalLength , oBinFinalLength)
        
        mBin = lpad(mBin, Int(binFinalLength))
        oBin = lpad(oBin, Int(binFinalLength))
        
        let totalWords = Double(oBin.count) / 5.0
        
        var binStr = "";
        
        
        for i in 0..<Int(totalWords) {
            
            let isLastWord: Bool = (i == (Int(totalWords) - 1));
            var leadingBit = "1";
            if isLastWord {
                leadingBit = "0";
            }
            
            let mStart = mBin.index(mBin.startIndex, offsetBy: i*5)
            let mEnd = mBin.index(mBin.startIndex, offsetBy: (i+1)*5)
            let mBits = String(mBin[mStart..<mEnd])
            
            let oStart = oBin.index(oBin.startIndex, offsetBy: i*5)
            let oEnd = oBin.index(oBin.startIndex, offsetBy: (i+1)*5)
            let oBits = String(oBin[oStart..<oEnd])
            
            binStr = binStr + leadingBit + mBits + oBits;
            
        }
        return binStr;
    }
    
    func binToMnemoic(_ binStr: String, _ wordlist: [String]) -> [String] {
        
        var mnemonic:[String] = [];
        
        let totalWords = ceil(Double(binStr.count) / 11)
        let totalBits = Int(totalWords) * 11
        
        let b = lpad(binStr, totalBits)
        
        for i in 0..<Int(totalWords) {
            
            let start = b.index(b.startIndex, offsetBy: i*11)
            let end = b.index(b.startIndex, offsetBy: (i+1)*11)
            let bits = String(b[start..<end])
            if let wordIndex = Int(bits, radix:2) {
                mnemonic.append(wordlist[wordIndex])
            }
            
        }
        
        return mnemonic
    }
    
    func lpad(_ s: String, _ n: Int) -> String {
        var temp = s
        while (temp.count < n) {
            temp = "0" + temp;
        }
        return temp;
    }
    
    func hex2bin(_ str: String) throws -> String{
        
        var bin = ""
        var num = 0;
        
        let list = str.slice()
        var i = list.count - 1;
        
        while i>=0 {
            
            if let n = Int(list[i], radix: 16){
                
                num = n;
                
                let temp = Shamir39Utils.shared.padLeft(String(num, radix: 2, uppercase: false), 4)
                bin = temp + bin
                
                i = i - 1;
                
            }else{
                throw Shamir39Error("Invalid hex character.")
                break;
            }
        }
        return bin;
    }
    
    
    func bin2hex(_ str: String) -> String{
     
        var hex = "";
        var num = 0;
        
        let s = Shamir39Utils.shared.padLeft(str, 4);
        var i = s.count;
        while i>=4 {
            
            let start = i-4;
            let end = i;
            
            if let n = Int(String(s[(s.index(s.startIndex, offsetBy: start))..<(s.index(s.startIndex, offsetBy: end))]), radix: 2){
                num = n;
                hex = String(num, radix: 16) + hex
            }
            
            i = i - 4;
        }
        
        return hex;
    }
}

extension String{
    
    func slice(_ start: Int,
               _ end: Int) -> String{
        
        let s = self.index(self.startIndex, offsetBy: start)
        let e = self.index(self.startIndex, offsetBy: start + end)
           
        let result = self[s..<e]
        return String(result)
    }
    
    func slice() -> [String]{
        
        var result: [String] = []
        for i in 0..<self.count{
            let start = self.index(self.startIndex, offsetBy: i)
            let end = self.index(self.startIndex, offsetBy: i + 1)
            result.append(String(self[start..<end]))
        }
        
        return result
    }

}
