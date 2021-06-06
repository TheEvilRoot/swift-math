import Foundation

enum MathOperator : CustomStringConvertible, Equatable {
    
    case plus
    case minus
    case mul
    case div
    case power
    
    var description: String {
        switch self {
        case .plus: return "+"
        case .minus: return "-"
        case .mul: return "*"
        case .div: return "/"
        case .power: return "^"
        }
    }
    
    var precedence: Int {
        switch self {
        case .plus, .minus: return 1
        case .mul, .div: return 2;
        case .power: return 3
        }
    }
    
    func eval(on: (Double, Double)) -> Double {
        switch self {
        case .plus: return on.0 + on.1
        case .minus: return on.0 - on.1
        case .mul: return on.0 * on.1
        case .div: return on.0 / on.1
        case .power: return pow(on.0, on.1)
        }
    }
}

indirect enum MathToken : CustomStringConvertible, Equatable {
    
    case number(Double)
    case op(MathOperator)
    case reference(String)
    case openParan
    case closeParan
    case expr(MathToken, MathOperator, MathToken)
    
    var description: String {
        switch self {
        case .number(let d): return String(d)
        case .op(let o): return o.description
        case .reference(let name): return "#\(name)"
        case .openParan: return "("
        case .closeParan: return ")"
        case .expr(let a, let op, let b):
            return "{\(a.description) \(op.description) \(b.description)}"
        }
    }
    
}

enum MathError : Error {
    case numberFormat(String)
    case unknownToken(String)
    case parseError
    case unexpectedToken(MathToken, String)
    case evalError(MathToken, [Variable], String)
    case unknownReference(String)
}

struct Variable : CustomStringConvertible {
    
    let name: String
    let value: MathToken
    
    var description: String {
        return "Variable \(name) = \(value.description)"
    }
    
}

struct Math {
    
    private static func isCharOperator(_ c: Character) -> Bool {
        return "!~+-/*^()".contains(c)
    }
    
    private static func isWhitespace(c: Character) -> Bool {
        return " \t\n".contains(c)
    }
    
    private static func isOperator(_ s: String) -> Bool {
        return [
            "+", "-", "*", "/", "^",
            "plus", "minus", "times", "div",
            "pow"
        ].contains(s)
    }
    
    private static func isNumber(_ s: String) -> Bool {
        if !s.allSatisfy({
            ".0123456789".contains($0)
        }) { return false }
        
        // more than 1 dot
        if s.firstIndex(of: ".") != s.lastIndex(of: ".") {
            return false
        }
        
        return true
    }
    
    private static func asNumber(_ s: String) -> Double? {
        if !Math.isNumber(s) { return nil }
        return Double(s)
    }
    
    private static func asOperator(_ s: String) -> MathOperator? {
        if !isOperator(s) { return nil }
        switch s {
        case "+", "plus": return .plus
        case "-", "minus": return .minus
        case "*", "times": return .mul
        case "/", "div": return .div
        case "^", "pow": return .power
        default: return nil
        }
    }
    
    private static func isParan(_ s: String) -> Bool {
        return ["(", ")"].contains(s)
    }
    
    private static func asParan(_ s: String) -> MathToken? {
        if !Math.isParan(s) { return nil }
        if "(" == s { return .openParan }
        if ")" == s { return .closeParan }
        return nil
    }
    
    private static func isWhitespace(s: String) -> Bool {
        return s.allSatisfy { isWhitespace(c: $0) }
    }
    
    private func isBackParse(_ token: MathToken?) -> Bool {
        if case .openParan = token {
            return false
        }
        return true
    }

    fileprivate func isPreceding(_ a: MathToken?, _ b: MathToken) -> Bool {
        if let a = a {
            if case .op(let a_op) = a, case .op(let b_op) = b {
                return a_op.precedence >= b_op.precedence
            }
        }
        return false
    }

    
    func tokenizer(from input: String) throws -> [String] {
        var tokens: [String] = []
        var string = input
        var buffer = String()
        
        func triggerBuffer(_ initial: String) {
            if !buffer.isEmpty && !Math.isWhitespace(s: buffer) {
                tokens.append(buffer.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            buffer = initial
        }
        
        while !string.isEmpty {
            guard let first = string.first else { break }
            
            // for single character operators.
            // they are terminators for token and the next token
            if Math.isCharOperator(first) {
                triggerBuffer(String())
                tokens.append(String(string.removeFirst()))
                continue
            }
            
            if Math.isWhitespace(c: first) {
                triggerBuffer(String(string.removeFirst()))
                continue
            }
            
            buffer.append(string.removeFirst())
        }
        
        triggerBuffer(String())
        return tokens
    }
    
    func lexer(from strings: [String]) throws -> [MathToken] {
        return strings.map { tok -> MathToken in
            if let op = Math.asOperator(tok) {
                return .op(op)
            }
            
            if let number = Math.asNumber(tok) {
                return .number(number)
            }
            
            if let paran = Math.asParan(tok) {
                return paran
            }
            
            return .reference(tok)
        }
    }
    
    func parser(from input: [MathToken]) throws -> MathToken {
        var tokens = input
        var opStack: [MathToken] = []
        var valStack: [MathToken] = []
        
    
        while tokens.count > 0 {
            let token = tokens.removeFirst()
            
            switch token {
            case .openParan:
                opStack.append(token)
            case .number(_):
                valStack.append(token)
            case.reference(_):
                valStack.append(token)
            case .closeParan:
                while opStack.count > 0 && isBackParse(opStack.last) {
                    let operand1 = valStack.removeLast()
                    let operand2 = valStack.removeLast()
                    let op = opStack.removeLast()
                    
                    if case .op(let op_op) = op {
                        valStack.append(.expr(operand2, op_op, operand1))
                    }
                }
                if opStack.count > 0 {
                    opStack.removeLast() // open paran
                }
            case .op(_):
                while opStack.count > 0 && isPreceding(opStack.last, token) {
                    let operand1 = valStack.removeLast()
                    let operand2 = valStack.removeLast()
                    let op = opStack.removeLast()
                    
                    if case .op(let op_op) = op {
                        valStack.append(.expr(operand2, op_op, operand1))
                    }
                }
                opStack.append(token)
            default:
                throw MathError.unexpectedToken(token, "default")
            }
        }
        
        while opStack.count > 0 {
            let operand1 = valStack.removeLast()
            let operand2 = valStack.removeLast()
            let op = opStack.removeLast()
            
            if case .op(let op_op) = op {
                valStack.append(.expr(operand2, op_op, operand1))
            }
        }
        
        if let last = valStack.last {
            return last
        } else {
            throw MathError.parseError
        }
    }
    
    func evaluator(expr: MathToken, vars: [Variable]) throws -> Double {
        return try exprEvaluator(expr: expr, vars: vars)
    }
    
    private func exprEvaluator(expr: MathToken, vars: [Variable]) throws -> Double {
        switch expr {
        case .number(let value):
            print("eval \(expr) -> \(value)")
            return value
        case .reference(let name):
            let value = try resolver(name, vars: vars)
            print("eval \(expr) -> \(value)")
            return value
        case.expr(let a, let op, let b):
            let valueA = try exprEvaluator(expr: a, vars: vars)
            let valueB = try exprEvaluator(expr: b, vars: vars)
            let result = op.eval(on: (valueA, valueB))
            print("eval \(expr) = \(valueA) \(op) \(valueB) -> \(result)")
            return result
        default: throw MathError.evalError(expr, vars, "Invalid token to eval")
        }
    }
    
    func resolver(_ name: String, vars: [Variable]) throws -> Double {
        if let resolved = vars.first(where: { $0.name == name })?.value {
            let result = try exprEvaluator(expr: resolved, vars: vars)
            print("\(name) -> \(result)")
            return result
        } else { throw MathError.unknownReference(name)}
    }
    
}

extension String {
    func variable(_ value: Double) -> Variable {
        return Variable(name: self, value: .number(value))
    }
    func reference(_ ref: String) -> Variable {
        return Variable(name: self, value: .reference(ref))
    }
    func expr(_ a: MathToken, _ op: MathOperator, _ b: MathToken) -> Variable {
        return Variable(name: self, value: .expr(a, op, b))
    }
}
