//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors.
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Support

@main
public struct Application {
  public static func main() {
    // MARK: Clock configuration
    rcc.ahb1enr.modify { rw in
      // Enable AHB clock to port G (for debug LEDs)
      rw.raw.gpiogen = 1
      // Enable AHB clock to port A
      rw.raw.gpiocen = 1
      // // Enable AHB clock to port B
      rw.raw.gpioden = 1
    }

    rcc.apb1enr.modify { rw in
      // Enable APB clock to uart 5
      rw.raw.uart5en = 1 
    }

    // MARK: Peripheral Configuration
    // Configure C12 as UART5 TX
    // Put Pin C12 into alternate function mode
    gpioc.moder.modify { $0.raw.moder12 = 0b10 }
    // Put Pin C12 into push pull
    gpioc.otyper.modify { $0.raw.ot12 = 0b0 }
    // Put Pin C12 into low speed
    gpioc.ospeedr.modify { $0.raw.ospeedr12 = 0b00 }
    // Disable pull up/down on Pin C12
    gpioc.pupdr.modify { $0.raw.pupdr12 = 0b00 }
    // Set alternate function uart5 on Pin C12
    gpioc.afrh.modify { $0.raw.afrh12 = 0b1000 }

    // Configure D2 as UART5 RX
    // Put Pin D2 into alternate function mode
    gpiod.moder.modify { $0.raw.moder2 = 0b10 }
    // Put Pin B7 into push pull
    gpiod.otyper.modify { $0.raw.ot2 = 0b0 }
    // Put Pin B7 into low speed
    gpiod.ospeedr.modify { $0.raw.ospeedr2 = 0b00 }
    // Disable pull up/down on Pin B7
    gpiod.pupdr.modify { $0.raw.pupdr2 = 0b00 }
    // Set alternate function uart5 on Pin D2
    gpiod.afrl.modify { $0.raw.afrl2 = 0b1000 }

    // Configure G13 as Output
    gpiog.moder.modify { $0.raw.moder13 = 0b01 }
    gpiog.moder.modify { $0.raw.moder14 = 0b01 }

    // Configure UART1
    // Set the baud rate to 16Mhz
    uart5.brr.modify { $0.raw.storage = 16000000/9600 }

    uart5.cr1.modify { rw in
      // Enable USART 1
      rw.raw.ue = 1
      // Enable RX
      rw.raw.re = 1
      // Enable TX
      rw.raw.te = 1
    }

    // MARK: Main Loop
    print("Hello Swift!")

    while true { 
      waitRxBufferFull()
      let byte = rx()
      tx(value: byte)
      waitTxBufferEmpty()
      // My serial console does not cook newlines so pressing "enter" sends a
      // carriage return ('\r') to the device. If we naively echo this byte back
      // to the user, we will move the cursor back to the start of the line and
      // overwrite previous characters. Instead, if we receive a carriage
      // return, send it back followed by a newline ('\n').
      if byte == UInt8(ascii: "\r") {
        tx(value: UInt8(ascii: "\n"))
        waitTxBufferEmpty()
      }  
    }
  }
}

func waitTxBufferEmpty() {
  // Spin while tx buffer not empty
  while uart5.sr.read().raw.txe == 0 { 
    redLed(on: false)
  }
  redLed(on: true)
}

func tx(value: UInt8) {
  uart5.dr.write { $0.raw.dr_field = UInt32(value) }
}

func waitRxBufferFull() {
  // Spin while rx buffer empty
  while uart5.sr.read().raw.rxne == 0 { 
    greenLed(on: true)
  }
  greenLed(on: false)
}

func rx() -> UInt8 {
  UInt8(uart5.dr.read().raw.dr_field)
}

func redLed(on: Bool) {
  if on {
    gpiog.bsrr.modify { r, w in w.raw.bs14 = 0b01 }
  } else {
    gpiog.bsrr.modify { r, w in w.raw.br14 = 0b01 }
  }
}

func greenLed(on: Bool) {
  if on {
    gpiog.bsrr.modify { r, w in w.raw.bs13 = 0b01 }
  } else {
    gpiog.bsrr.modify { r, w in w.raw.br13 = 0b01 }
  }
}

func shortDelay() {
for _ in 0..<300_000 {
        nop()
  } 
}

func longDelay() {
  for _ in 0..<1_000_000 {
        nop()
  } 
}

@_cdecl("Default_Handler")
public func defaultHandler() {
  while true { }
}

@_cdecl("putchar")
public func putchar(_ value: CInt) -> CInt {
  waitTxBufferEmpty()
  tx(value: UInt8(value))
  waitTxBufferEmpty()
  return 0
}
