DefinitionBlock ("", "SSDT", 2, "ACDT", "RTC0", 0x00000000)
{
    External (_SB_.PCI0.LPCB, DeviceObj)    // (from opcode)

    Scope (_SB.PCI0.LPCB)
    {
        Device (RTC0)
        {
            // Name (_HID, EisaId ("PNP0B00"))  // _HID: Hardware ID
            // Name (_CRS, ResourceTemplate ()  // _CRS: Current Resource Settings
            // {
            //     IO (Decode16,
            //         0x0070,             // Range Minimum
            //         0x0070,             // Range Maximum
            //         0x01,               // Alignment
            //         0x08,               // Length
            //         )
            //     IRQNoFlags ()
            //         {8}
            // })
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (_OSI ("Darwin")) {
                    Return (0x0F)
                } Else {
                    Return (0);
                }
            }
        }
    }
}

// DefinitionBlock ("", "SSDT", 2, "ACDT", "RTC0", 0x00000000)
// {
//     External (_SB_.PCI0.LPCB.RTC_, DeviceObj)

//     Scope (_SB.PCI0.LPCB.RTC)
//     {
//         Method (_STA, 0, NotSerialized)  // _STA: Status
//         {
//             If (_OSI ("Darwin"))
//             {
//                 Return (0x0F)
//             }
//             Else
//             {
//                 Return (Zero)
//             }
//         }
//     }
// }

