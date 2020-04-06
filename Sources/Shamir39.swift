//
//  Shamir39.swift
//  Shamir39iOS
//
//  Created by MinSoo Kang on 2020/04/01.
//  Copyright © 2020 MinSoo Kang. All rights reserved.
//

import UIKit



public struct Shamir39 {
    
    public init() {}
    
    struct Config {
        
        let bits: Int
        let size: Int
        let max: Int;
        
        let radix: Int = 16;
        
        let unsafePRNG = false;
        let alert = false;
        var logs: [Int?] = []
        var exps: [Int?] = [];
        
        init(bits: Int) {
        
            
            self.bits = bits
            self.size = Int(pow(2.0, Double(bits)))
            self.max = self.size - 1;
            
            let primitivePolynomials:[Int?] = [nil,nil,1,3,3,5,3,3,29,17,9,5,83,27,43,3,45,9,39,39,9,5,3,33,27,9,71,39,9,5,83];
            
            self.logs = Array(repeating: nil, count: 2048)
            self.exps = Array(repeating: nil, count: 2048)
            
            var x: Int = 1;
            let primitive: Int? = primitivePolynomials[self.bits];
            
            for i in 0..<self.size {
                
                self.exps[i] = x;
                self.logs[x] = i;
                x <<= 1;
                if(x >= self.size){
                    x ^= primitive!;
                    x &= self.max;
                }
            }
        }
        
        func getRNG(_ bits: Int) -> String{
            
            let bitsPerNum = 32;
            let bytes = ceil( Double(bits) / 32.0);
            
            var b: [UInt8] = Array(repeating: 0, count: Int(bytes))
            
            for i in 0..<b.count {
                b[i] = UInt8(arc4random_uniform(255))
            }
            
            var str = "NULL";
            while str == "NULL" {
                str = construct(bits: bits, arr: b, radix: 10, size: bitsPerNum)
            }
            
            return str
        }
        
        
        private func construct(bits: Int,
                               arr: [UInt8],
                               radix: Int,
                               size: Int) -> String{

            var str = "";
            var i = 0;
            let len = arr.count - 1;

            while(i<len || (str.count < bits)){
            
                if let pad = Int(String(arr[i]), radix: radix){
                    str = str + Shamir39Utils.shared.padLeft(String(pad, radix: 2, uppercase: false), size);
                }

                i = i + 1;
                
            }
            
            let start = str.index(str.startIndex, offsetBy: str.count - 11)
            let end = str.index(str.endIndex, offsetBy: 0)
            
            str = String(str[start..<end]);
            
            var isNull = true;
            for s in str.components(separatedBy: ""){
                if s != "0"{
                    isNull = false;
                    break;
                }
            }
            return isNull ? "NULL" : str
        }
        
    }
    

    let VERSION = "shamir39-p1";
    let config: Config = Config(bits: 11)
    
    func splits(bip39MnemonicWords:[String], m: Int, n:Int) throws -> [String]{
        
        let wordlist = Wordlist.list;
        
        if (m < 2) {
            throw Shamir39Error("Must require at least 2 shares")
        }
        if (m > 4095) {
            throw Shamir39Error("Must require at most 4095 shares")
        }
        if (n < 2) {
            throw Shamir39Error("Must split to at least 2 shares")
        }
        if (n > 4095) {
            throw Shamir39Error("Must split to at most 4095 shares")
        }
        
        if (wordlist.count != 2048){
            throw Shamir39Error("Wordlist must have 2048 words")
        }
        
        if (bip39MnemonicWords.count == 0){
            throw Shamir39Error("No bip39 mnemonic words provided")
        }
        
        
        // convert bip39 mnemonic into bits
        var binStr = "";
        for i in 0..<bip39MnemonicWords.count {
            
            let w = bip39MnemonicWords[i]
            if let index = wordlist.firstIndex(of: w){

                var bits = String(index, radix: 2, uppercase: true)
                bits = Shamir39Utils.shared.lpad(bits, 11);
                binStr = binStr + bits;
                
            }else{
                throw Shamir39Error("Invalid word found in list: \(w)")
            }
        }
        
        
        // pad mnemonic for use as hex
        let lenForHex = ceil(Double(binStr.count) / 4.0) * 4
        binStr = Shamir39Utils.shared.lpad(binStr, Int(lenForHex))
        
        let totalHexChars = binStr.count / 4;
        var hexStr = "";
        
        
        for i in 0..<totalHexChars {
            
            let start = binStr.index(binStr.startIndex, offsetBy: (i*4))
            let end = binStr.index(binStr.startIndex, offsetBy: ((i+1)*4))
            let range = start..<end
            
            let nibbleStr = binStr[range]
            
            if let hexValue = Int(nibbleStr, radix: 2){

                let hexChar = String(hexValue, radix: 16, uppercase: false)
                hexStr = hexStr + hexChar;
            }else{
                throw Shamir39Error("Parse Integer Fail")
            }
        }
        
        
        var mnemonics: [String] = [];
        // create shamir parts
        
        let partsHex = try share(hexStr, n, m, 0, true)
        
        for o in 0..<partsHex.count{
            
            var mnemonic: [String] = []
            mnemonic.append(VERSION)
            
            let parametersBin = Shamir39Utils.shared.paramsToBinaryStr(m,o);
            let paramWords = Shamir39Utils.shared.binToMnemoic(parametersBin, wordlist)
            
            mnemonic.append(contentsOf: paramWords)
            
            let partHex = partsHex[o];
            let partBin = try Shamir39Utils.shared.hex2bin(partHex);
            let partWords = Shamir39Utils.shared.binToMnemoic(partBin, wordlist);
            
            mnemonic.append(contentsOf: partWords)
            
            var result = ""
            for m in mnemonic {
                if result == "" {
                    result = m
                }else{
                    result = result + " " + m
                }
            }
            mnemonics.append(result)
        }
        
        return mnemonics
    }

    
    
    func combine(parts:[[String]]) throws -> String{
        
        let wordlist = Wordlist.list
        
        var hexParts: [Int: String?] = [:]
        
        var requiredParts = -1;
        
        for i in 0..<parts.count {
            
            let words = parts[i];
            if words[0] != VERSION {
                throw Shamir39Error("Version doesn't match")
            }
            
            // get params
            var mBinStr = "";
            var oBinStr = "";
            var endParamsIndex = 1;
            
            for j in 1..<words.count {
                
                let word = words[j];
                if let wordIndex = wordlist.firstIndex(of: word){
                    
                    let wordBin = Shamir39Utils.shared.lpad(String(wordIndex, radix: 2), 11)
                    
                    let mStart = wordBin.index(wordBin.startIndex, offsetBy: 1)
                    let mEnd = wordBin.index(wordBin.startIndex, offsetBy: 6)
                    mBinStr = mBinStr + wordBin[mStart..<mEnd]
                    
                    let oStart = wordBin.index(wordBin.startIndex, offsetBy: 6)
                    let oEnd = wordBin.index(wordBin.startIndex, offsetBy: 11)
                    oBinStr = oBinStr + wordBin[oStart..<oEnd]
                    
                    
                    let isEndOfParams = wordBin.hasPrefix("0")
                    if isEndOfParams {
                        endParamsIndex = j;
                        break;
                    }
                }else{
                    throw Shamir39Error("Word not in wordlist: : \(word)")
                }
            }
            
            
            // parse parameters
            if let m = Int(mBinStr, radix: 2),
                let o = Int(oBinStr, radix: 2){

                if requiredParts == -1 {
                    requiredParts = m;
                }
                
                if (m != requiredParts){
                    throw Shamir39Error("Inconsisent M parameters")
                }
                
                var partBin = "";
                
                var j = endParamsIndex + 1;
                while j<words.count {
                    
                    let word = words[j];
                    if let wordIndex = wordlist.firstIndex(of: word){
                     
                        let wordBin = Shamir39Utils.shared.lpad(String(wordIndex, radix: 2), 11)
                        partBin = partBin + wordBin;
                        
                    }else{
                        throw Shamir39Error("Word not in wordlist: \(word)")
                    }
                    j = j+1;
                }
                
                let hexChars = Int(floor((Double(partBin.count) / 4.0))) * 4
                let diff = partBin.count - hexChars
               
                partBin = String(partBin[partBin.index(partBin.startIndex, offsetBy: diff)..<partBin.index(partBin.endIndex, offsetBy: 0)])
                let partHex = Shamir39Utils.shared.bin2hex(partBin)
                
                hexParts[o] = partHex;
                
            }else{
                throw Shamir39Error("Parse Integer Fail")
            }
        }
        
        
        // validate the parameters to ensure the secret can be created
        if (hexParts.count < requiredParts) {
            throw Shamir39Error("Not enough parts, requires \(requiredParts)")
        }
        
        
        var list: [Share2] = [];

        var index = 0
        for key in hexParts.keys{
            if let part = hexParts[key],
                let p = part{
                list.append(Share2(id: key + 1, part: p))
            }
            index = index + 1
        }
        
        list.sort(by: {
            s0, s1 in
            if s0.id > s1.id {
                return false;
            }else{
                return true;
            }
        })
        
        // combine parts into secret
        let secretHex = try combine(0, list);
        var secretBin = try Shamir39Utils.shared.hex2bin(secretHex);
        
        let totalWords = Int(floor(Double(secretBin.count) / 11.0))
        let totalBits = totalWords * 11
        
        let diff = secretBin.count - totalBits
        
        let start = secretBin.index(secretBin.startIndex, offsetBy: diff)
        let end = secretBin.index(secretBin.endIndex, offsetBy: 0)
        secretBin = String(secretBin[start..<end])
        
        
        var mnemonic: [String] = [];
        
        for i in 0..<totalWords {
            
            let start = secretBin.index(secretBin.startIndex, offsetBy: i*11)
            let end = secretBin.index(secretBin.startIndex, offsetBy: (i+1)*11)
            let wordIndexBin = String(secretBin[start..<end])
            if let wordIndex = Int(wordIndexBin, radix: 2){

                let word = wordlist[wordIndex]
                mnemonic.append(word)
            }else{
                throw Shamir39Error("Parse Integer Fail")
            }
        }
        
        var result = ""
        for m in mnemonic{
            if result == ""{
                result = m
            }else{
                result = result + " " + m
            }
        }
        return result;
    }
    
    
    private func combine(_ at: Int,
                         _ shares: [Share2] ) throws -> String{
        
        
        var setBits = -1;
        var idx = -1;
        var result = ""
        
        var x: [Int] = []
        var y: [[Int:Int]] = []
        
        
        
        for i in 0..<shares.count{
            
            let share = try processShare(shares[i])

            if setBits == -1 {
                setBits = share.bits
            }else if share.bits != setBits{
                throw Shamir39Error("Mismatched shares: Different bit settings.")
            }
            
            if Shamir39Utils.shared.inArray(x, share.id){
                continue;
            }
            
            x.append(share.id)
            idx = x.count - 1;
            
            let s: [Int] = try split(Shamir39Utils.shared.hex2bin(share.value), 0)
            
            let len2 = s.count;
            
            for j in 0..<len2{
                if i == 0 {
                    y.append([Int:Int]())
                }
                y[j][idx] = s[j];
                
            }
            
        }
        
        
        let len = y.count;
        for i in 0..<len {
            
            let lag = String( lagrange(at, x, y[i]), radix: 2)
            let pl = Shamir39Utils.shared.padLeft(lag, config.bits)
            
            result = pl + result
            
        }
        
        if at == 0 {
            
            if let temp = result.firstIndex(of: "1"){
                
                let start = result.index(temp, offsetBy: 1)
                let end = result.index(result.endIndex, offsetBy: 0)
                let test = String(result[start..<end])
                
                return Shamir39Utils.shared.bin2hex(test)
                
            }else{
                throw Shamir39Error("Combine error")
            }
        }else{
            return Shamir39Utils.shared.bin2hex(result)
        }
    }
    
    
    
    
    private func processShare(_ share: Share2) throws -> Share3 {

        let bits = config.bits
        
        let max = Int(pow(2, Double(bits))) - 1
        let idLength = String(max, radix: config.radix).count
        
        let id = share.id
        if id % 1 != 0
            || id < 1
            || id > max {
            throw Shamir39Error("Share id must be an integer between 1 and \(config.max), inclusive.")
        }
        
        let part = share.part
        if part.count == 0 {
            throw Shamir39Error("Invalid share: zero-length share.")
        }
        
        return Share3(
            bits: bits,
            id: id,
            value: part)
        
    }
    
    private func share(_ secret: String,
                       _ numShares: Int,
                       _ threshold: Int,
                       _ padLength: Int,
                       _ withoutPrefix: Bool) throws ->  [String]{
        

        
        if(numShares % 1 != 0 || numShares < 2){
            throw Shamir39Error("Number of shares must be an integer between 2 and 2^bits-1 (\(config.max)), inclusive.")
        }
        if(numShares > config.max){
            throw Shamir39Error("Number of shares must be an integer between 2 and 2^bits-1 (\(config.max), inclusive. To create")
        }
        if(threshold % 1 != 0 || threshold < 2){
            throw Shamir39Error("Threshold number of shares must be an integer between 2 and 2^bits-1 (\(config.max), inclusive.")
        }
        if(threshold > config.max){
            
            let neededBits = ceil(log(Double(threshold) + 1) / M_LN2)
            throw Shamir39Error("Threshold number of shares must be an integer between 2 and 2^bits-1 (\(config.max)), inclusive.  To use a threshold of \(threshold), use at least \(neededBits) bits.")
        }
        if(padLength%1 != 0 ){
            throw Shamir39Error("Zero-pad length must be an integer greater than 1.")
        }

            
            let s0 = try "1" + Shamir39Utils.shared.hex2bin(secret);
            let s1 = try split(s0, padLength)
            
            var x: [String] = []
            var y: [String] = []
            
            for i in 0..<s1.count {

                let subShares = self.getShares(s1[i], numShares, threshold)
                
                for j in 0 ..< numShares{
                    
                    if i == 0 {
                        x.append( String(subShares[j].x, radix: config.radix, uppercase: false))
                        y.append( Shamir39Utils.shared.padLeft(String(subShares[j].y, radix: 2, uppercase: false), config.bits))
                    }else{
                        y[j] = Shamir39Utils.shared.padLeft( String(subShares[j].y, radix: 2, uppercase: false), config.bits) + y[j];
                    }
                }
            }
            
            let padding = String(config.max, radix: config.radix).count;
            
            if withoutPrefix {
             
                for a in 0..<numShares {
                    
                    x[a] = Shamir39Utils.shared.bin2hex(y[a]);
                }
                
            }else{
               
                for a in 0..<numShares {
                    x[a] = String(config.bits, radix: 36, uppercase: true) + Shamir39Utils.shared.padLeft(x[a], padding) + Shamir39Utils.shared.bin2hex(y[a]);
                }
            }
            
            return x;
        
    };
   
    
    private func split(_ str: String,
                       _ padLength: Int) throws -> [Int]{
        
        var s = str
        if(padLength != 0){
            s = Shamir39Utils.shared.padLeft(s, padLength)
        }
        var parts: [Int] = [];
        
        var i = s.count;
        
        while i>config.bits{
            
            if let num = Int(s.slice((i-config.bits), config.bits), radix: 2) {
                
                parts.append(num)
                i = i - config.bits
                
            }else{
                throw Shamir39Error("Parse Integer Fail")
            }
        }
        
        if let num = Int(s.slice(0,i), radix: 2) {
            parts.append(num);
        }else{
            throw Shamir39Error("Parse Integer Fail")
        }
        
        return parts;
        
    }
 
    private func getShares(_ secret: Int,
                           _ numShares: Int,
                           _ threshold: Int) -> [Share]{

        var share: [Share] = [];
        var coeffs: [Int] = [secret];

        for _ in 1..<threshold{
            let rng = self.config.getRNG(config.bits)
            if let c = Int(rng, radix: 2) {
                coeffs.append(c)
            }
        }

        var i = 1;
        let len = numShares + 1;
        while i < len {
            share.append(Share(x: i, y: horner(i, coeffs)))
            i = i + 1;
        }

        return share
    }
    
    private func lagrange(_ at: Int,
                          _ x: [Int],
                          _ y: [Int:Int])->Int{
    
        var sum = 0;
        var product = -1;
        
        for i in 0..<x.count{
            
            if(y[i]!<1){
                continue;
            }
            product = config.logs[y[i]!]!;
            
            for j in 0..<x.count {
                
                if i == j {
                    continue;
                }
                
                if at == x[j]{
                    product = -1;
                    break;
                }
                product = ( product + config.logs[at ^ x[j]]! - config.logs[x[i] ^ x[j]]! + config.max) % config.max;
            }
            sum = (product == -1) ? sum : sum ^ config.exps[product]!
        }
        return sum
    }
    
    private func horner(_ x: Int,
                _ coeffs: [Int]) -> Int{
        
        
        var fx = 0;
        if let logx = config.logs[x]{
            var i = coeffs.count - 1;

            while i >= 0 {

                if fx == 0 {
                    
                    fx = coeffs[i]
                }else{
                    
                    let log0 = logx
                    if let log1 = config.logs[fx] {
                        fx = config.exps[ (log0 + log1) % config.max ]! ^ coeffs[i];
                    }
                }
                i = i - 1;
            }
        }

        

        return fx;
    };
    
    struct Share {
        let x: Int
        let y: Int
        init(x: Int,
             y: Int){
            self.x = x;
            self.y = y;
        }
    }
    
    struct Share2 {
        let id: Int
        let part: String
        init(id: Int,
             part: String) {
            self.id = id;
            self.part = part
        }
    }
    
    struct Share3 {
        
        let bits: Int
        let id: Int
        let value: String
        
        init(bits: Int,
             id: Int,
             value: String){
         
            self.bits = bits;
            self.id = id;
            self.value = value;
           
        }
    }
    
}


