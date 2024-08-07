//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

enum STM32F746Board {
    static func initialize() {
        // Configure pin I1 as an LED

        // (1) AHB1ENR[i] = 1 ... enable clock
        setRegisterBit(baseAddress: RCC.BaseAddress, offset: RCC.Offsets.AHB1ENR, bit: 8, value: 1)
        // (2) MODER[1] = 1 ... set mode to output
        setRegisterTwoBitField(baseAddress: GPIO.GPIOi_BaseAddress, offset: GPIO.Offsets.MODER, bitsStartingAt: 2, value: 1)
        // (3) OTYPER[1] = 0 ... output type is push-pull
        setRegisterBit(baseAddress: GPIO.GPIOi_BaseAddress, offset: GPIO.Offsets.OTYPER, bit: 1, value: 0)
        // (4) OSPEEDR[1] = 2 ... speed is high
        setRegisterTwoBitField(baseAddress: GPIO.GPIOi_BaseAddress, offset: GPIO.Offsets.OSPEEDR, bitsStartingAt: 2, value: 2)
        // (5) PUPDR[1] = 2 ... set pull to down
        setRegisterTwoBitField(baseAddress: GPIO.GPIOi_BaseAddress, offset: GPIO.Offsets.PUPDR, bitsStartingAt: 2, value: 2)

        ledOff()
    }
    
    static func ledOn() {
        // ODR[1] = 1
        setRegisterBit(baseAddress: GPIO.GPIOi_BaseAddress, offset: GPIO.Offsets.ODR, bit: 1, value: 1)
    }
    
    static func ledOff() {
        // ODR[1] = 0
        setRegisterBit(baseAddress: GPIO.GPIOi_BaseAddress, offset: GPIO.Offsets.ODR, bit: 1, value: 0)
    }
    
    static func delay(milliseconds: Int) {
        for _ in 0 ..< 10_000 * milliseconds {
            nop()
        }
    }
}

enum STM32F429Board {
    static func initialize() {
        // Configure pin PG13 as an LED

        // (1) AHB1ENR[i] = 1 ... enable clock
        setRegisterBit(baseAddress: RCC.BaseAddress, offset: RCC.Offsets.AHB1ENR, bit: 6, value: 1)
        // (2) MODER[1] = 1 ... set mode to output
        setRegisterBit(baseAddress: GPIO.GPIOg_BaseAddress, offset: GPIO.Offsets.MODER, bit: 26, value: 1);

        ledOff()
    }
    
    static func ledOn() {
        setRegisterBit(baseAddress: GPIO.GPIOg_BaseAddress, offset: GPIO.Offsets.BSRR, bit: 13, value: 1)
    }
    
    static func ledOff() {
        setRegisterBit(baseAddress: GPIO.GPIOg_BaseAddress, offset: GPIO.Offsets.BSRR, bit: 29, value: 1)
    }
    
    static func delay(milliseconds: Int) {
        for _ in 0 ..< 10_000 * milliseconds {
            nop()
        }
    }
}

@main
struct Main {
    typealias Board = STM32F429Board

    static func main() {
        Board.initialize()

        while true {
            Board.ledOn()
            Board.delay(milliseconds: 100)
            Board.ledOff()
            Board.delay(milliseconds: 300)
        }
    }
}
