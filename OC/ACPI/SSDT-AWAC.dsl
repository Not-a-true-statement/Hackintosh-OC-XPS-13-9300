DefinitionBlock ("", "SSDT", 2, "DRTNIA", "AWAC", 0x00000000)
{
    External (STAS, IntObj)

    Scope (_SB)
    {
        If (_OSI ("Darwin"))
        {
            STAS = One
        }
    }
}

