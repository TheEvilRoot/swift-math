import XCTest
@testable import Math

final class MathTests: XCTestCase {
    
    func testTokenizer() {
        let math = Math()

        func testCase(input: String, output: [String]) {
            do {
                let tokens = try math.tokenizer(from: input)
                XCTAssert(tokens.elementsEqual(output),
                               "input: \(input) expected: \(output) got:\(tokens)")
            } catch let e {
                XCTFail(e.localizedDescription)
            }
        }
        
        testCase(input: "A + B", output: ["A", "+", "B"])
        testCase(input: "A+B", output: ["A", "+", "B"])
        testCase(input: "A +B", output: ["A", "+", "B"])
        testCase(input: "A + B * C", output: ["A", "+", "B", "*", "C"])
        testCase(input: "1.23431283 + B * C", output: ["1.23431283", "+", "B", "*", "C"])
        testCase(input: "A", output: ["A"])
        testCase(input: "", output: [])
        testCase(input: "(A + B)*2+A - 6.213*(A+B )", output: [
            "(", "A", "+", "B", ")", "*", "2", "+", "A",
            "-", "6.213", "*", "(", "A", "+", "B", ")"
        ])
    }
    
    func testLexer() {
        let math = Math()
        
        func testCase(input: String, output: [MathToken]) {
            do {
                let tokens = try math.lexer(from: try math.tokenizer(from: input))
                XCTAssert(tokens.elementsEqual(output),
                          "input: \(input) expected: \(output) got: \(tokens)")
            } catch let e {
                XCTFail(e.localizedDescription)
            }
        }
        
        testCase(input: "A + B", output: [
            .reference("A"),
            .op(.plus),
            .reference("B")
        ])
        testCase(input: "A + B * C", output: [
            .reference("A"),
            .op(.plus),
            .reference("B"),
            .op(.mul),
            .reference("C")
        ])
        testCase(input: "1.23431283 + B * C", output: [
            .number(1.23431283),
            .op(.plus),
            .reference("B"),
            .op(.mul),
            .reference("C")
        ])
        testCase(input: "A", output: [
            .reference("A")
        ])
        testCase(input: "", output: [])
        testCase(input: "(((A + B)*2)+A - 6.213)*(A+B )", output: [
            .openParan, .openParan, .openParan,
            .reference("A"), .op(.plus), .reference("B"),
            .closeParan, .op(.mul), .number(2), .closeParan,
            .op(.plus), .reference("A"), .op(.minus),
            .number(6.213), .closeParan, .op(.mul),
            .openParan, .reference("A"), .op(.plus), .reference("B"),
            .closeParan
        ])
        testCase(input: "(((A plus B)*2)+A minus 6.213)*(A+B)", output: [
            .openParan, .openParan, .openParan,
            .reference("A"), .op(.plus), .reference("B"),
            .closeParan, .op(.mul), .number(2), .closeParan,
            .op(.plus), .reference("A"), .op(.minus),
            .number(6.213), .closeParan, .op(.mul),
            .openParan, .reference("A"), .op(.plus), .reference("B"),
            .closeParan
        ])
        
    }
    
    func testParser() {
        let math = Math()
        
        func testCase(input: String, output: MathToken) {
            do {
                let token = try math.parser(from: math.lexer(from: try math.tokenizer(from: input)))
                XCTAssertEqual(token, output,
                          "input: \(input) expected: \(output) got: \(token)")
            } catch let e {
                XCTFail(e.localizedDescription)
            }
        }
        
        testCase(input: "A + B", output: .expr(
            .reference("A"), .plus, .reference("B")
        ))
        testCase(input: "A + B * C", output: .expr(
            .reference("A"), .plus, .expr(
                .reference("B"), .mul, .reference("C")
            )
        ))
        testCase(input: "1.23431283 + B * C", output: .expr(
            .number(1.23431283), .plus, .expr(
                .reference("B"), .mul, .reference("C")
            )
        ))
        testCase(input: "A", output: .reference("A"))
        testCase(input: "(((A plus B) * 2) + A minus 6.213) * (A + B)", output: .expr(
            .expr(
                .expr(
                    .expr(
                        .expr(
                            .reference("A"),
                            .plus,
                            .reference("B")
                        ),
                        .mul,
                        .number(2)
                    ),
                    .plus,
                    .reference("A")
                ),
                .minus,
                .number(6.213)
            ),
            .mul,
            .expr(.reference("A"), .plus, .reference("B"))
        ))
        testCase(input: "(((A plus B) * 2) + A minus 6.213) * (A + B) pow 2", output: .expr(
            .expr(
                .expr(
                    .expr(
                        .expr(
                            .reference("A"),
                            .plus,
                            .reference("B")
                        ),
                        .mul,
                        .number(2)
                    ),
                    .plus,
                    .reference("A")
                ),
                .minus,
                .number(6.213)
            ),
            .mul,
            .expr(
                .expr(.reference("A"), .plus, .reference("B")),
                .power,
                .number(2)
            )
        ))
    }
    
    func testEval() {
        let math = Math()
        
        func testCase(input: String, output: Double, vars: [Variable] = []) {
            do {
                let value = try math.evaluator(expr: try math.parser(from: math.lexer(from: try math.tokenizer(from: input))), vars: vars)
                XCTAssertEqual(value, output,
                          "input: \(input) expected: \(output) got: \(value)")
            } catch let e {
                XCTFail(e.localizedDescription)
            }
        }
        
        testCase(input: "1 + 2", output: 3)
        testCase(input: "2 - 2", output: 0)
        testCase(input: "2 * 2", output: 4)
        testCase(input: "2 * 2", output: 4)
        testCase(input: "16 / 2", output: 8)
        testCase(input: "15 / 2", output: 7.5)
        testCase(input: "15.2 / 2", output: 7.6)
        testCase(input: "1.5 + 1.5", output: 3)
        testCase(input: "1 - 2.5", output: -1.5)
        testCase(input: "2 pow 2", output: 4)
        testCase(input: "2 pow 10", output: 1024)
        testCase(input: "(2 + 2) ^ 5", output: 1024)
        testCase(input: "2 + 2 ^ 10", output: 1026)
        
        testCase(input: "2 * 2 pow 10", output: 2048)
        testCase(input: "2 + 2 * 2", output: 6)
        testCase(input: "(2 + 2) * 2", output: 8)
        
        testCase(input: "(A + 2) * 2", output: 8, vars: [
            "A".variable(2)
        ])
        
        testCase(input: "(((A plus B) * 2) + A minus 6.213) * (A + B) pow 2", output: 169.675, vars: [
            "A".expr(.reference("B"), .plus, .number(1)),
            "B".reference("C"),
            "C".variable(2) // (((3 + 2) * 2) + 3 - 6.213) * (3 + 2) ^ 2 =
                            // ((5 * 2) + 3 - 6.213) * 5 ^ 2 =
                            // (10 + 3 - 6.213) * 24 =
                            // (13 - 6.213) * 25 =
                            // 169,675
        ])
    }
    
    func testResolver() {
        let math = Math()
        
        func testCase(input: String, output: Double, vars: [Variable], shouldFail: Bool = false) throws {
            do {
                let value = try math.resolver(input, vars: vars)
                
                if shouldFail {
                    XCTFail("\(input) should fail")
                } else {
                    XCTAssertEqual(value, output,
                                   "input: \(input) expected: \(output) got: \(value) with: \(vars)")
                }
            } catch let e {
                if !shouldFail {
                    XCTFail(e.localizedDescription)
                }
            }
        }
        
        try? testCase(input: "variable", output: 1, vars: [
            "variable".variable(1)
        ])
        try? testCase(input: "A", output: 12, vars: [
            "A".expr(.reference("B"), .plus, .reference("C")),
            "B".variable(4),
            "C".expr(.reference("B"), .mul, .number(2))
        ])
        try? testCase(input: "A'", output: 3, vars: [
            "A'".expr(.reference("A"), .div, .number(4)),
            "A".expr(.reference("B"), .plus, .reference("C")),
            "B".variable(4),
            "C".expr(.reference("B"), .mul, .number(2))
        ])
        
        try? testCase(input: "A'", output: 0, vars: [
            "A".variable(1),
            "B".expr(.reference("A"), .plus, .number(1))
        ], shouldFail: true)
    }
    

    static var allTests = [
        ("testTokenizer", testTokenizer),
        ("testLexer", testLexer),
        ("testParser", testParser),
        ("testEval", testEval),
        ("testResolver", testResolver),
    ]
}

