import Foundation

extension String {
    public var htmlEscaped: String {
        let charset = CharacterSet.letters.inverted
        var pos = startIndex
        var result = self
        while let range = result.rangeOfCharacter(from: charset, options: [], range: pos..<result.endIndex) {
            let escaped = result[range].unicodeScalars.flatMap { "&#x\(String($0.value, radix: 16, uppercase: true));" }
            result.replaceSubrange(range, with: escaped)
            pos = result.index(range.lowerBound, offsetBy: escaped.count)
        }
        return result
    }
}

extension Int {
    
    public var primeFactors: AnySequence<Int> {
        
        func factor(_ input: Int) -> (prime: Int, remainder: Int) {
            let end = Int(sqrt(Float(input)))
            if end > 2 {
                for prime in 2...end {
                    if input % prime == 0 {
                        return (prime, input / prime)
                    }
                }
            }
            return (input, 1)
        }
        
        return AnySequence<Int> { () -> AnyIterator<Int> in
            var current = self
            return AnyIterator<Int> {
                guard current != 1 else { return nil }
                
                let result = factor(current)
                current = result.remainder
                return result.prime
            }
        }
        
    }
}
