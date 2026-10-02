/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20251212 (64-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of ./SSDT1.dat
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x0000736B (29547)
 *     Revision         0x02
 *     Checksum         0x0A
 *     OEM ID           "DptfTb"
 *     OEM Table ID     "DptfTabl"
 *     OEM Revision     0x00001000 (4096)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20200717 (538969879)
 */
DefinitionBlock ("", "SSDT", 2, "DptfTb", "DptfTabl", 0x00001000)
{
    External (_SB_.AAC0, FieldUnitObj)
    External (_SB_.ACRT, FieldUnitObj)
    External (_SB_.APSV, FieldUnitObj)
    External (_SB_.CBMI, FieldUnitObj)
    External (_SB_.CFGD, FieldUnitObj)
    External (_SB_.CLVL, FieldUnitObj)
    External (_SB_.CPID, UnknownObj)
    External (_SB_.CPPC, FieldUnitObj)
    External (_SB_.CTC0, FieldUnitObj)
    External (_SB_.CTC1, FieldUnitObj)
    External (_SB_.CTC2, FieldUnitObj)
    External (_SB_.OSCP, IntObj)
    External (_SB_.PAGD, DeviceObj)
    External (_SB_.PAGD._PUR, PkgObj)
    External (_SB_.PAGD._STA, MethodObj)    // 0 Arguments
    External (_SB_.PC00, DeviceObj)
    External (_SB_.PC00.LPCB.H_EC, DeviceObj)
    External (_SB_.PC00.LPCB.H_EC.ACUR, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.AP01, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.AP02, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.AP10, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.ARTG, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.AVOL, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.B1FC, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.B1RC, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.BICC, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.BMAX, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.CFAN, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.CFSP, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.CHGR, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.CHRG, DeviceObj)
    External (_SB_.PC00.LPCB.H_EC.CMDR, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.CMPP, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.CPUP, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.CTYP, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.DFSP, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.DGPU, DeviceObj)
    External (_SB_.PC00.LPCB.H_EC.ECAV, IntObj)
    External (_SB_.PC00.LPCB.H_EC.ECF2, OpRegionObj)
    External (_SB_.PC00.LPCB.H_EC.ECMD, MethodObj)    // 1 Arguments
    External (_SB_.PC00.LPCB.H_EC.ECRD, MethodObj)    // 1 Arguments
    External (_SB_.PC00.LPCB.H_EC.ECWT, MethodObj)    // 2 Arguments
    External (_SB_.PC00.LPCB.H_EC.FCHG, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.GFSP, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.HYST, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.PBOK, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.PBSS, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.PECH, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.PENV, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.PINV, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.PLMX, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.PMAX, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.PPSH, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.PPSL, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.PPWR, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.PROP, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.PSOC, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.PSTP, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.PWRT, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.RBHF, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.SEN2, DeviceObj)
    External (_SB_.PC00.LPCB.H_EC.SEN3, DeviceObj)
    External (_SB_.PC00.LPCB.H_EC.SEN4, DeviceObj)
    External (_SB_.PC00.LPCB.H_EC.SEN5, DeviceObj)
    External (_SB_.PC00.LPCB.H_EC.TFN1, DeviceObj)
    External (_SB_.PC00.LPCB.H_EC.TFN2, DeviceObj)
    External (_SB_.PC00.LPCB.H_EC.TFN3, DeviceObj)
    External (_SB_.PC00.LPCB.H_EC.TSHT, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.TSI_, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.TSLT, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.TSR1, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.TSR2, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.TSR3, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.TSR4, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.TSR5, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.TSSR, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.UVTH, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.VBNL, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.VMIN, FieldUnitObj)
    External (_SB_.PC00.MC__.MHBR, FieldUnitObj)
    External (_SB_.PC00.TCPU, DeviceObj)
    External (_SB_.PL10, FieldUnitObj)
    External (_SB_.PL11, FieldUnitObj)
    External (_SB_.PL12, FieldUnitObj)
    External (_SB_.PL20, FieldUnitObj)
    External (_SB_.PL21, FieldUnitObj)
    External (_SB_.PL22, FieldUnitObj)
    External (_SB_.PLW0, FieldUnitObj)
    External (_SB_.PLW1, FieldUnitObj)
    External (_SB_.PLW2, FieldUnitObj)
    External (_SB_.PR00, ProcessorObj)
    External (_SB_.PR00._PSS, MethodObj)    // 0 Arguments
    External (_SB_.PR00._TPC, IntObj)
    External (_SB_.PR00._TSD, MethodObj)    // 0 Arguments
    External (_SB_.PR00._TSS, MethodObj)    // 0 Arguments
    External (_SB_.PR00.LPSS, PkgObj)
    External (_SB_.PR00.TPSS, PkgObj)
    External (_SB_.PR00.TSMC, PkgObj)
    External (_SB_.PR00.TSMF, PkgObj)
    External (_SB_.PR01, ProcessorObj)
    External (_SB_.PR02, ProcessorObj)
    External (_SB_.PR03, ProcessorObj)
    External (_SB_.PR04, ProcessorObj)
    External (_SB_.PR05, ProcessorObj)
    External (_SB_.PR06, ProcessorObj)
    External (_SB_.PR07, ProcessorObj)
    External (_SB_.PR08, ProcessorObj)
    External (_SB_.PR09, ProcessorObj)
    External (_SB_.PR10, ProcessorObj)
    External (_SB_.PR11, ProcessorObj)
    External (_SB_.PR12, ProcessorObj)
    External (_SB_.PR13, ProcessorObj)
    External (_SB_.PR14, ProcessorObj)
    External (_SB_.PR15, ProcessorObj)
    External (_SB_.PR16, ProcessorObj)
    External (_SB_.PR17, ProcessorObj)
    External (_SB_.PR18, ProcessorObj)
    External (_SB_.PR19, ProcessorObj)
    External (_SB_.PR20, ProcessorObj)
    External (_SB_.PR21, ProcessorObj)
    External (_SB_.PR22, ProcessorObj)
    External (_SB_.PR23, ProcessorObj)
    External (_SB_.PR24, ProcessorObj)
    External (_SB_.PR25, ProcessorObj)
    External (_SB_.PR26, ProcessorObj)
    External (_SB_.PR27, ProcessorObj)
    External (_SB_.PR28, ProcessorObj)
    External (_SB_.PR29, ProcessorObj)
    External (_SB_.PR30, ProcessorObj)
    External (_SB_.PR31, ProcessorObj)
    External (_SB_.SLPB, DeviceObj)
    External (_SB_.TAR0, FieldUnitObj)
    External (_SB_.TAR1, FieldUnitObj)
    External (_SB_.TAR2, FieldUnitObj)
    External (_SB_.TPWR, DeviceObj)
    External (_TZ_.ETMD, IntObj)
    External (_TZ_.TZ00, ThermalZoneObj)
    External (ACTT, IntObj)
    External (ATPC, IntObj)
    External (BATR, IntObj)
    External (CHGE, IntObj)
    External (CRTT, IntObj)
    External (DCFE, IntObj)
    External (DPTF, IntObj)
    External (ECON, IntObj)
    External (FND1, IntObj)
    External (FND2, IntObj)
    External (FND3, IntObj)
    External (HIDW, MethodObj)    // 4 Arguments
    External (HIWC, MethodObj)    // 1 Arguments
    External (IN34, IntObj)
    External (IPCS, MethodObj)    // 7 Arguments
    External (ODV0, IntObj)
    External (ODV1, IntObj)
    External (ODV2, IntObj)
    External (ODV3, IntObj)
    External (ODV4, IntObj)
    External (ODV5, IntObj)
    External (PCHE, FieldUnitObj)
    External (PF00, IntObj)
    External (PLID, IntObj)
    External (PNHM, IntObj)
    External (PPPR, IntObj)
    External (PPSZ, IntObj)
    External (PSVT, IntObj)
    External (PTPC, IntObj)
    External (PWRE, IntObj)
    External (PWRS, IntObj)
    External (S1DE, IntObj)
    External (S2DE, IntObj)
    External (S3DE, IntObj)
    External (S4DE, IntObj)
    External (S5DE, IntObj)
    External (S6DE, IntObj)
    External (S6P2, IntObj)
    External (SADE, IntObj)
    External (SSP1, IntObj)
    External (SSP2, IntObj)
    External (SSP3, IntObj)
    External (SSP4, IntObj)
    External (SSP5, IntObj)
    External (TCNT, IntObj)
    External (TSOD, IntObj)

    Scope (\_SB)
    {
        Device (IETM)
        {
            Method (GCID, 0, Serialized)
            {
                Switch ((\_SB.CPID & 0x0FFF0FF0))
                {
                    Case (0x000B0670)
                    {
                        Return (Zero)
                    }
                    Case (0x000B06A0)
                    {
                        Return (Zero)
                    }
                    Case (0x000B06F0)
                    {
                        Return (Zero)
                    }
                    Default
                    {
                        Return (One)
                    }

                }
            }

            Method (GHID, 1, Serialized)
            {
                Local0 = \_SB.IETM.GCID ()
                If ((Zero == Local0))
                {
                    If ((Arg0 == "IETM"))
                    {
                        Return ("INTC10A0")
                    }

                    If ((Arg0 == "SEN1"))
                    {
                        Return ("INTC10A1")
                    }

                    If ((Arg0 == "SEN2"))
                    {
                        Return ("INTC10A1")
                    }

                    If ((Arg0 == "SEN3"))
                    {
                        Return ("INTC10A1")
                    }

                    If ((Arg0 == "SEN4"))
                    {
                        Return ("INTC10A1")
                    }

                    If ((Arg0 == "SEN5"))
                    {
                        Return ("INTC10A1")
                    }

                    If ((Arg0 == "TPCH"))
                    {
                        Return ("INTC10A3")
                    }

                    If ((Arg0 == "TFN1"))
                    {
                        Return ("INTC10A2")
                    }

                    If ((Arg0 == "TFN2"))
                    {
                        Return ("INTC10A2")
                    }

                    If ((Arg0 == "TFN3"))
                    {
                        Return ("INTC10A2")
                    }

                    If ((Arg0 == "TPWR"))
                    {
                        Return ("INTC10A4")
                    }

                    If ((Arg0 == "1"))
                    {
                        Return ("INTC10A5")
                    }

                    If ((Arg0 == "CHRG"))
                    {
                        Return ("INTC10A1")
                    }

                    Return ("XXXX9999")
                }
                Else
                {
                    If ((Arg0 == "IETM"))
                    {
                        Return ("INTC1041")
                    }

                    If ((Arg0 == "SEN1"))
                    {
                        Return ("INTC1046")
                    }

                    If ((Arg0 == "SEN2"))
                    {
                        Return ("INTC1046")
                    }

                    If ((Arg0 == "SEN3"))
                    {
                        Return ("INTC1046")
                    }

                    If ((Arg0 == "SEN4"))
                    {
                        Return ("INTC1046")
                    }

                    If ((Arg0 == "SEN5"))
                    {
                        Return ("INTC1046")
                    }

                    If ((Arg0 == "TPCH"))
                    {
                        Return ("INTC1049")
                    }

                    If ((Arg0 == "TFN1"))
                    {
                        Return ("INTC1048")
                    }

                    If ((Arg0 == "TFN2"))
                    {
                        Return ("INTC1048")
                    }

                    If ((Arg0 == "TFN3"))
                    {
                        Return ("INTC1048")
                    }

                    If ((Arg0 == "TPWR"))
                    {
                        Return ("INTC1060")
                    }

                    If ((Arg0 == "1"))
                    {
                        Return ("INTC1061")
                    }

                    If ((Arg0 == "CHRG"))
                    {
                        Return ("INTC1046")
                    }

                    Return ("XXXX9999")
                }
            }

            Name (_UID, "IETM")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Method (_DSM, 4, Serialized)  // _DSM: Device-Specific Method
            {
                If (CondRefOf (HIWC))
                {
                    If (HIWC (Arg0))
                    {
                        If (CondRefOf (HIDW))
                        {
                            Return (HIDW (Arg0, Arg1, Arg2, Arg3))
                        }
                    }
                }

                Return (Buffer (One)
                {
                     0x00                                             // .
                })
            }

            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If (((\DPTF == One) && (\IN34 == One)))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (PTRP, Zero)
            Name (PSEM, Zero)
            Name (ATRP, Zero)
            Name (ASEM, Zero)
            Name (YTRP, Zero)
            Name (YSEM, Zero)
            Method (_OSC, 4, Serialized)  // _OSC: Operating System Capabilities
            {
                CreateDWordField (Arg3, Zero, STS1)
                CreateDWordField (Arg3, 0x04, CAP1)
                If ((Arg1 != One))
                {
                    STS1 &= 0xFFFFFF00
                    STS1 |= 0x0A
                    Return (Arg3)
                }

                If ((Arg2 != 0x02))
                {
                    STS1 &= 0xFFFFFF00
                    STS1 |= 0x02
                    Return (Arg3)
                }

                If (CondRefOf (\_SB.APSV))
                {
                    If ((PSEM == Zero))
                    {
                        PSEM = One
                        PTRP = \_SB.APSV /* External reference */
                    }
                }

                If (CondRefOf (\_SB.AAC0))
                {
                    If ((ASEM == Zero))
                    {
                        ASEM = One
                        ATRP = \_SB.AAC0 /* External reference */
                    }
                }

                If (CondRefOf (\_SB.ACRT))
                {
                    If ((YSEM == Zero))
                    {
                        YSEM = One
                        YTRP = \_SB.ACRT /* External reference */
                    }
                }

                If ((Arg0 == ToUUID ("b23ba85d-c8b7-3542-88de-8de2ffcfd698") /* Unknown UUID */))
                {
                    If (~(STS1 & One))
                    {
                        If ((CAP1 & One))
                        {
                            If ((CAP1 & 0x02))
                            {
                                \_SB.AAC0 = 0x6E
                                \_TZ.ETMD = Zero
                            }
                            Else
                            {
                                \_SB.AAC0 = ATRP /* \_SB_.IETM.ATRP */
                                \_TZ.ETMD = One
                            }

                            If ((CAP1 & 0x04))
                            {
                                \_SB.APSV = 0x6E
                            }
                            Else
                            {
                                \_SB.APSV = PTRP /* \_SB_.IETM.PTRP */
                            }

                            If ((CAP1 & 0x08))
                            {
                                \_SB.ACRT = 0xD2
                            }
                            Else
                            {
                                \_SB.ACRT = YTRP /* \_SB_.IETM.YTRP */
                            }

                            If (CondRefOf (\_TZ.TZ00))
                            {
                                Notify (\_TZ.TZ00, 0x81) // Information Change
                            }
                        }
                        Else
                        {
                            \_SB.ACRT = YTRP /* \_SB_.IETM.YTRP */
                            \_SB.APSV = PTRP /* \_SB_.IETM.PTRP */
                            \_SB.AAC0 = ATRP /* \_SB_.IETM.ATRP */
                            \_TZ.ETMD = One
                        }

                        If (CondRefOf (\_TZ.TZ00))
                        {
                            Notify (\_TZ.TZ00, 0x81) // Information Change
                        }
                    }

                    Return (Arg3)
                }

                Return (Arg3)
            }

            Method (DCFG, 0, NotSerialized)
            {
                Return (\DCFE) /* External reference */
            }

            Name (ODVX, Package (0x06)
            {
                Zero, 
                Zero, 
                Zero, 
                Zero, 
                Zero, 
                Zero
            })
            Method (ODVP, 0, Serialized)
            {
                ODVX [Zero] = \ODV0 /* External reference */
                ODVX [One] = \ODV1 /* External reference */
                ODVX [0x02] = \ODV2 /* External reference */
                ODVX [0x03] = \ODV3 /* External reference */
                ODVX [0x04] = \ODV4 /* External reference */
                ODVX [0x05] = \ODV5 /* External reference */
                Return (ODVX) /* \_SB_.IETM.ODVX */
            }
        }
    }

    Scope (\_SB.PC00.LPCB.H_EC)
    {
        Mutex (PATM, 0x00)
        Method (_QF1, 0, NotSerialized)  // _Qxx: EC Query, xx=0x00-0xFF
        {
            Local0 = \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.TSSR))
            While (Local0)
            {
                \_SB.PC00.LPCB.H_EC.ECWT (Zero, RefOf (\_SB.PC00.LPCB.H_EC.TSSR))
                If ((Local0 & 0x10))
                {
                    Notify (\_SB.PC00.LPCB.H_EC.SEN5, 0x90) // Device-Specific
                }

                If ((Local0 & 0x08))
                {
                    Notify (\_SB.PC00.LPCB.H_EC.SEN4, 0x90) // Device-Specific
                }

                If ((Local0 & One))
                {
                    Notify (\_SB.PC00.LPCB.H_EC.SEN3, 0x90) // Device-Specific
                }

                If ((Local0 & 0x04))
                {
                    Notify (\_SB.PC00.LPCB.H_EC.SEN2, 0x90) // Device-Specific
                }

                If ((Local0 & One))
                {
                    Notify (\_SB.PC00.LPCB.H_EC.DGPU, 0x90) // Device-Specific
                }

                Local0 = \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.TSSR))
            }
        }
    }

    Scope (\_SB.IETM)
    {
        Method (KTOC, 1, Serialized)
        {
            If ((Arg0 > 0x0AAC))
            {
                Return (((Arg0 - 0x0AAC) / 0x0A))
            }
            Else
            {
                Return (Zero)
            }
        }

        Method (CTOK, 1, Serialized)
        {
            Return (((Arg0 * 0x0A) + 0x0AAC))
        }

        Method (C10K, 1, Serialized)
        {
            Name (TMP1, Buffer (0x10)
            {
                 0x00                                             // .
            })
            CreateByteField (TMP1, Zero, TMPL)
            CreateByteField (TMP1, One, TMPH)
            Local0 = (Arg0 + 0x0AAC)
            TMPL = (Local0 & 0xFF)
            TMPH = ((Local0 & 0xFF00) >> 0x08)
            ToInteger (TMP1, Local1)
            Return (Local1)
        }

        Method (K10C, 1, Serialized)
        {
            If ((Arg0 > 0x0AAC))
            {
                Return ((Arg0 - 0x0AAC))
            }
            Else
            {
                Return (Zero)
            }
        }
    }

    Scope (\_SB.PC00.TCPU)
    {
        Name (PFLG, Zero)
        Method (_STA, 0, NotSerialized)  // _STA: Status
        {
            If ((\SADE == One))
            {
                Return (0x0F)
            }
            Else
            {
                Return (Zero)
            }
        }

        OperationRegion (CPWR, SystemMemory, ((\_SB.PC00.MC.MHBR << 0x0F) + 0x5000), 0x1000)
        Field (CPWR, ByteAcc, NoLock, Preserve)
        {
            Offset (0x930), 
            PTDP,   15, 
            Offset (0x932), 
            PMIN,   15, 
            Offset (0x934), 
            PMAX,   15, 
            Offset (0x936), 
            TMAX,   7, 
            Offset (0x938), 
            PWRU,   4, 
            Offset (0x939), 
            EGYU,   5, 
            Offset (0x93A), 
            TIMU,   4, 
            Offset (0x958), 
            Offset (0x95C), 
            LPMS,   1, 
            CTNL,   2, 
            Offset (0x978), 
            PCTP,   8, 
            Offset (0x998), 
            RP0C,   8, 
            RP1C,   8, 
            RPNC,   8, 
            Offset (0xF3C), 
            TRAT,   8, 
            Offset (0xF40), 
            PTD1,   15, 
            Offset (0xF42), 
            TRA1,   8, 
            Offset (0xF44), 
            PMX1,   15, 
            Offset (0xF46), 
            PMN1,   15, 
            Offset (0xF48), 
            PTD2,   15, 
            Offset (0xF4A), 
            TRA2,   8, 
            Offset (0xF4C), 
            PMX2,   15, 
            Offset (0xF4E), 
            PMN2,   15, 
            Offset (0xF50), 
            CTCL,   2, 
                ,   29, 
            CLCK,   1, 
            MNTR,   8
        }

        Name (XPCC, Zero)
        Method (PPCC, 0, Serialized)
        {
            If (((XPCC == Zero) && CondRefOf (\_SB.CBMI)))
            {
                Switch (ToInteger (\_SB.CBMI))
                {
                    Case (Zero)
                    {
                        If (((\_SB.CLVL >= One) && (\_SB.CLVL <= 0x03)))
                        {
                            CPL0 ()
                            XPCC = One
                        }
                    }
                    Case (One)
                    {
                        If (((\_SB.CLVL == 0x02) || (\_SB.CLVL == 0x03)))
                        {
                            CPL1 ()
                            XPCC = One
                        }
                    }
                    Case (0x02)
                    {
                        If ((\_SB.CLVL == 0x03))
                        {
                            CPL2 ()
                            XPCC = One
                        }
                    }

                }
            }

            Return (NPCC) /* \_SB_.PC00.TCPU.NPCC */
        }

        Name (NPCC, Package (0x03)
        {
            0x02, 
            Package (0x06)
            {
                Zero, 
                0x88B8, 
                0xAFC8, 
                0x6D60, 
                0x7D00, 
                0x03E8
            }, 

            Package (0x06)
            {
                One, 
                0xDBBA, 
                0xDBBA, 
                Zero, 
                Zero, 
                0x03E8
            }
        })
        Method (CPNU, 2, Serialized)
        {
            Name (CNVT, Zero)
            Name (PPUU, Zero)
            Name (RMDR, Zero)
            If ((PWRU == Zero))
            {
                PPUU = One
            }
            Else
            {
                PPUU = (PWRU-- << 0x02)
            }

            Divide (Arg0, PPUU, RMDR, CNVT) /* \_SB_.PC00.TCPU.CPNU.CNVT */
            If ((Arg1 == Zero))
            {
                Return (CNVT) /* \_SB_.PC00.TCPU.CPNU.CNVT */
            }
            Else
            {
                CNVT *= 0x03E8
                RMDR *= 0x03E8
                RMDR /= PPUU
                CNVT += RMDR /* \_SB_.PC00.TCPU.CPNU.RMDR */
                Return (CNVT) /* \_SB_.PC00.TCPU.CPNU.CNVT */
            }
        }

        Method (CPL0, 0, NotSerialized)
        {
            \_SB.PC00.TCPU.NPCC [Zero] = 0x02
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [Zero] = Zero
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [One] = 0x7D
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x02] = CPNU (\_SB.PL10, One)
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x03] = (\_SB.PLW0 * 0x03E8)
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x04] = ((\_SB.PLW0 * 0x03E8
                ) + 0x0FA0)
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x05] = PPSZ /* External reference */
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [Zero] = One
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [One] = CPNU (\_SB.PL20, One)
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x02] = CPNU (\_SB.PL20, One)
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x03] = Zero
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x04] = Zero
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x05] = PPSZ /* External reference */
        }

        Method (CPL1, 0, NotSerialized)
        {
            \_SB.PC00.TCPU.NPCC [Zero] = 0x02
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [Zero] = Zero
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [One] = 0x7D
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x02] = CPNU (\_SB.PL11, One)
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x03] = (\_SB.PLW1 * 0x03E8)
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x04] = ((\_SB.PLW1 * 0x03E8
                ) + 0x0FA0)
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x05] = PPSZ /* External reference */
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [Zero] = One
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [One] = CPNU (\_SB.PL21, One)
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x02] = CPNU (\_SB.PL21, One)
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x03] = Zero
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x04] = Zero
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x05] = PPSZ /* External reference */
        }

        Method (CPL2, 0, NotSerialized)
        {
            \_SB.PC00.TCPU.NPCC [Zero] = 0x02
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [Zero] = Zero
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [One] = 0x7D
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x02] = CPNU (\_SB.PL12, One)
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x03] = (\_SB.PLW2 * 0x03E8)
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x04] = ((\_SB.PLW2 * 0x03E8
                ) + 0x0FA0)
            DerefOf (\_SB.PC00.TCPU.NPCC [One]) [0x05] = PPSZ /* External reference */
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [Zero] = One
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [One] = CPNU (\_SB.PL22, One)
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x02] = CPNU (\_SB.PL22, One)
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x03] = Zero
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x04] = Zero
            DerefOf (\_SB.PC00.TCPU.NPCC [0x02]) [0x05] = PPSZ /* External reference */
        }

        Name (LSTM, Zero)
        Name (_PPC, Zero)  // _PPC: Performance Present Capabilities
        Method (SPPC, 1, Serialized)
        {
            If (CondRefOf (\_SB.CPPC))
            {
                \_SB.CPPC = Arg0
            }

            If ((ToInteger (\TCNT) > Zero))
            {
                Notify (\_SB.PR00, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > One))
            {
                Notify (\_SB.PR01, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x02))
            {
                Notify (\_SB.PR02, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x03))
            {
                Notify (\_SB.PR03, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x04))
            {
                Notify (\_SB.PR04, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x05))
            {
                Notify (\_SB.PR05, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x06))
            {
                Notify (\_SB.PR06, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x07))
            {
                Notify (\_SB.PR07, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x08))
            {
                Notify (\_SB.PR08, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x09))
            {
                Notify (\_SB.PR09, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x0A))
            {
                Notify (\_SB.PR10, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x0B))
            {
                Notify (\_SB.PR11, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x0C))
            {
                Notify (\_SB.PR12, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x0D))
            {
                Notify (\_SB.PR13, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x0E))
            {
                Notify (\_SB.PR14, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x0F))
            {
                Notify (\_SB.PR15, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x10))
            {
                Notify (\_SB.PR16, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x11))
            {
                Notify (\_SB.PR17, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x12))
            {
                Notify (\_SB.PR18, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x13))
            {
                Notify (\_SB.PR19, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x14))
            {
                Notify (\_SB.PR20, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x15))
            {
                Notify (\_SB.PR21, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x16))
            {
                Notify (\_SB.PR22, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x17))
            {
                Notify (\_SB.PR23, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x18))
            {
                Notify (\_SB.PR24, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x19))
            {
                Notify (\_SB.PR25, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x1A))
            {
                Notify (\_SB.PR26, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x1B))
            {
                Notify (\_SB.PR27, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x1C))
            {
                Notify (\_SB.PR28, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x1D))
            {
                Notify (\_SB.PR29, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x1E))
            {
                Notify (\_SB.PR30, 0x80) // Status Change
            }

            If ((ToInteger (\TCNT) > 0x1F))
            {
                Notify (\_SB.PR31, 0x80) // Status Change
            }
        }

        Method (SPUR, 1, NotSerialized)
        {
            If ((Arg0 <= \TCNT))
            {
                If ((\_SB.PAGD._STA () == 0x0F))
                {
                    \_SB.PAGD._PUR [One] = Arg0
                    Notify (\_SB.PAGD, 0x80) // Status Change
                }
            }
        }

        Method (PCCC, 0, Serialized)
        {
            PCCX [Zero] = One
            Switch (ToInteger (CPNU (PTDP, Zero)))
            {
                Case (0x39)
                {
                    DerefOf (PCCX [One]) [Zero] = 0xA7F8
                    DerefOf (PCCX [One]) [One] = 0x00017318
                }
                Case (0x2F)
                {
                    DerefOf (PCCX [One]) [Zero] = 0x9858
                    DerefOf (PCCX [One]) [One] = 0x00014C08
                }
                Case (0x25)
                {
                    DerefOf (PCCX [One]) [Zero] = 0x7148
                    DerefOf (PCCX [One]) [One] = 0xD6D8
                }
                Case (0x19)
                {
                    DerefOf (PCCX [One]) [Zero] = 0x3E80
                    DerefOf (PCCX [One]) [One] = 0x7D00
                }
                Case (0x0F)
                {
                    DerefOf (PCCX [One]) [Zero] = 0x36B0
                    DerefOf (PCCX [One]) [One] = 0x7D00
                }
                Case (0x0B)
                {
                    DerefOf (PCCX [One]) [Zero] = 0x36B0
                    DerefOf (PCCX [One]) [One] = 0x61A8
                }
                Default
                {
                    DerefOf (PCCX [One]) [Zero] = 0xFF
                    DerefOf (PCCX [One]) [One] = 0xFF
                }

            }

            Return (PCCX) /* \_SB_.PC00.TCPU.PCCX */
        }

        Name (PCCX, Package (0x02)
        {
            0x80000000, 
            Package (0x02)
            {
                0x80000000, 
                0x80000000
            }
        })
        Name (KEFF, Package (0x1E)
        {
            Package (0x02)
            {
                0x01BC, 
                Zero
            }, 

            Package (0x02)
            {
                0x01CF, 
                0x27
            }, 

            Package (0x02)
            {
                0x01E1, 
                0x4B
            }, 

            Package (0x02)
            {
                0x01F3, 
                0x6C
            }, 

            Package (0x02)
            {
                0x0206, 
                0x8B
            }, 

            Package (0x02)
            {
                0x0218, 
                0xA8
            }, 

            Package (0x02)
            {
                0x022A, 
                0xC3
            }, 

            Package (0x02)
            {
                0x023D, 
                0xDD
            }, 

            Package (0x02)
            {
                0x024F, 
                0xF4
            }, 

            Package (0x02)
            {
                0x0261, 
                0x010B
            }, 

            Package (0x02)
            {
                0x0274, 
                0x011F
            }, 

            Package (0x02)
            {
                0x032C, 
                0x01BD
            }, 

            Package (0x02)
            {
                0x03D7, 
                0x0227
            }, 

            Package (0x02)
            {
                0x048B, 
                0x026D
            }, 

            Package (0x02)
            {
                0x053E, 
                0x02A1
            }, 

            Package (0x02)
            {
                0x05F7, 
                0x02C6
            }, 

            Package (0x02)
            {
                0x06A8, 
                0x02E6
            }, 

            Package (0x02)
            {
                0x075D, 
                0x02FF
            }, 

            Package (0x02)
            {
                0x0818, 
                0x0311
            }, 

            Package (0x02)
            {
                0x08CF, 
                0x0322
            }, 

            Package (0x02)
            {
                0x179C, 
                0x0381
            }, 

            Package (0x02)
            {
                0x2DDC, 
                0x039C
            }, 

            Package (0x02)
            {
                0x44A8, 
                0x039E
            }, 

            Package (0x02)
            {
                0x5C35, 
                0x0397
            }, 

            Package (0x02)
            {
                0x747D, 
                0x038D
            }, 

            Package (0x02)
            {
                0x8D7F, 
                0x0382
            }, 

            Package (0x02)
            {
                0xA768, 
                0x0376
            }, 

            Package (0x02)
            {
                0xC23B, 
                0x0369
            }, 

            Package (0x02)
            {
                0xDE26, 
                0x035A
            }, 

            Package (0x02)
            {
                0xFB7C, 
                0x034A
            }
        })
        Name (CEUP, Package (0x06)
        {
            0x80000000, 
            0x80000000, 
            0x80000000, 
            0x80000000, 
            0x80000000, 
            0x80000000
        })
        Method (TMPX, 0, Serialized)
        {
            Return (\_SB.IETM.CTOK (PCTP))
        }

        Method (_DTI, 1, NotSerialized)  // _DTI: Device Temperature Indication
        {
            LSTM = Arg0
            Notify (\_SB.PC00.TCPU, 0x91) // Device-Specific
        }

        Method (_NTT, 0, NotSerialized)  // _NTT: Notification Temperature Threshold
        {
            Return (0x0ADE)
        }

        Name (PTYP, Zero)
        Method (_PSS, 0, NotSerialized)  // _PSS: Performance Supported States
        {
            If (CondRefOf (\_SB.PR00._PSS))
            {
                Return (\_SB.PR00._PSS ())
            }
            Else
            {
                Return (Package (0x02)
                {
                    Package (0x06)
                    {
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero
                    }, 

                    Package (0x06)
                    {
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero
                    }
                })
            }
        }

        Method (_TSS, 0, NotSerialized)  // _TSS: Throttling Supported States
        {
            If (CondRefOf (\_SB.PR00._TSS))
            {
                Return (\_SB.PR00._TSS ())
            }
            Else
            {
                Return (Package (0x01)
                {
                    Package (0x05)
                    {
                        One, 
                        Zero, 
                        Zero, 
                        Zero, 
                        Zero
                    }
                })
            }
        }

        Method (_TPC, 0, NotSerialized)  // _TPC: Throttling Present Capabilities
        {
            If (CondRefOf (\_SB.PR00._TPC))
            {
                Return (\_SB.PR00._TPC) /* External reference */
            }
            Else
            {
                Return (Zero)
            }
        }

        Method (_PTC, 0, NotSerialized)  // _PTC: Processor Throttling Control
        {
            If ((CondRefOf (\PF00) && (\PF00 != 0x80000000)))
            {
                If ((\PF00 & 0x04))
                {
                    Return (Package (0x02)
                    {
                        ResourceTemplate ()
                        {
                            Register (FFixedHW, 
                                0x00,               // Bit Width
                                0x00,               // Bit Offset
                                0x0000000000000000, // Address
                                ,)
                        }, 

                        ResourceTemplate ()
                        {
                            Register (FFixedHW, 
                                0x00,               // Bit Width
                                0x00,               // Bit Offset
                                0x0000000000000000, // Address
                                ,)
                        }
                    })
                }
                Else
                {
                    Return (Package (0x02)
                    {
                        ResourceTemplate ()
                        {
                            Register (SystemIO, 
                                0x05,               // Bit Width
                                0x00,               // Bit Offset
                                0x0000000000001810, // Address
                                ,)
                        }, 

                        ResourceTemplate ()
                        {
                            Register (SystemIO, 
                                0x05,               // Bit Width
                                0x00,               // Bit Offset
                                0x0000000000001810, // Address
                                ,)
                        }
                    })
                }
            }
            Else
            {
                Return (Package (0x02)
                {
                    ResourceTemplate ()
                    {
                        Register (FFixedHW, 
                            0x00,               // Bit Width
                            0x00,               // Bit Offset
                            0x0000000000000000, // Address
                            ,)
                    }, 

                    ResourceTemplate ()
                    {
                        Register (FFixedHW, 
                            0x00,               // Bit Width
                            0x00,               // Bit Offset
                            0x0000000000000000, // Address
                            ,)
                    }
                })
            }
        }

        Method (_TSD, 0, NotSerialized)  // _TSD: Throttling State Dependencies
        {
            If (CondRefOf (\_SB.PR00._TSD))
            {
                Return (\_SB.PR00._TSD ())
            }
            Else
            {
                Return (Package (0x01)
                {
                    Package (0x05)
                    {
                        0x05, 
                        Zero, 
                        Zero, 
                        0xFC, 
                        Zero
                    }
                })
            }
        }

        Method (_TDL, 0, NotSerialized)  // _TDL: T-State Depth Limit
        {
            If ((CondRefOf (\_SB.PR00._TSS) && CondRefOf (\_SB.CFGD)))
            {
                If ((\_SB.CFGD & 0x2000))
                {
                    Return ((SizeOf (\_SB.PR00.TSMF) - One))
                }
                Else
                {
                    Return ((SizeOf (\_SB.PR00.TSMC) - One))
                }
            }
            Else
            {
                Return (Zero)
            }
        }

        Method (_PDL, 0, NotSerialized)  // _PDL: P-state Depth Limit
        {
            If (CondRefOf (\_SB.PR00._PSS))
            {
                If ((\_SB.OSCP & 0x0400))
                {
                    Return ((SizeOf (\_SB.PR00.TPSS) - One))
                }
                Else
                {
                    Return ((SizeOf (\_SB.PR00.LPSS) - One))
                }
            }
            Else
            {
                Return (Zero)
            }
        }

        Name (TJMX, 0x6E)
        Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
        {
            Return (Zero)
        }

        Method (_AC0, 0, Serialized)  // _ACx: Active Cooling, x=0-9
        {
            Local1 = \_SB.IETM.CTOK (TJMX)
            Local1 -= 0x0A
            If ((LSTM >= Local1))
            {
                Return ((Local1 - 0x14))
            }
            Else
            {
                Return (Local1)
            }
        }

        Method (_AC1, 0, Serialized)  // _ACx: Active Cooling, x=0-9
        {
            Local1 = \_SB.IETM.CTOK (TJMX)
            Local1 -= 0x1E
            If ((LSTM >= Local1))
            {
                Return ((Local1 - 0x14))
            }
            Else
            {
                Return (Local1)
            }
        }

        Method (_AC2, 0, Serialized)  // _ACx: Active Cooling, x=0-9
        {
            Local1 = \_SB.IETM.CTOK (TJMX)
            Local1 -= 0x28
            If ((LSTM >= Local1))
            {
                Return ((Local1 - 0x14))
            }
            Else
            {
                Return (Local1)
            }
        }

        Method (_AC3, 0, Serialized)  // _ACx: Active Cooling, x=0-9
        {
            Local1 = \_SB.IETM.CTOK (TJMX)
            Local1 -= 0x37
            If ((LSTM >= Local1))
            {
                Return ((Local1 - 0x14))
            }
            Else
            {
                Return (Local1)
            }
        }

        Method (_AC4, 0, Serialized)  // _ACx: Active Cooling, x=0-9
        {
            Local1 = \_SB.IETM.CTOK (TJMX)
            Local1 -= 0x46
            If ((LSTM >= Local1))
            {
                Return ((Local1 - 0x14))
            }
            Else
            {
                Return (Local1)
            }
        }

        Method (_PSV, 0, Serialized)  // _PSV: Passive Temperature
        {
            Return (\_SB.IETM.CTOK (TJMX))
        }

        Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
        {
            Return (\_SB.IETM.CTOK (TJMX))
        }

        Method (_CR3, 0, Serialized)  // _CR3: Warm/Standby Temperature
        {
            Return (\_SB.IETM.CTOK (TJMX))
        }

        Method (_HOT, 0, Serialized)  // _HOT: Hot Temperature
        {
            Return (\_SB.IETM.CTOK (TJMX))
        }

        Method (UVTH, 1, Serialized)
        {
            If (((\ECON == One) && (\_SB.PC00.LPCB.H_EC.ECAV == One)))
            {
                \_SB.PC00.LPCB.H_EC.ECWT (Arg0, RefOf (\_SB.PC00.LPCB.H_EC.UVTH))
                \_SB.PC00.LPCB.H_EC.ECMD (0x17)
            }
        }
    }

    Scope (\_SB.IETM)
    {
        Name (CTSP, Package (0x01)
        {
            ToUUID ("e145970a-e4c1-4d73-900e-c9c5a69dd067") /* Unknown UUID */
        })
    }

    Scope (\_SB.PC00.TCPU)
    {
        Method (TDPL, 0, Serialized)
        {
            Name (AAAA, Zero)
            Name (BBBB, Zero)
            Name (CCCC, Zero)
            Local0 = CTNL /* \_SB_.PC00.TCPU.CTNL */
            If (((Local0 == One) || (Local0 == 0x02)))
            {
                Local0 = \_SB.CLVL /* External reference */
            }
            Else
            {
                Return (Package (0x01)
                {
                    Zero
                })
            }

            If ((CLCK == One))
            {
                Local0 = One
            }

            AAAA = CPNU (\_SB.PL10, One)
            BBBB = CPNU (\_SB.PL11, One)
            CCCC = CPNU (\_SB.PL12, One)
            Name (TMP1, Package (0x01)
            {
                Package (0x05)
                {
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000
                }
            })
            Name (TMP2, Package (0x02)
            {
                Package (0x05)
                {
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000
                }, 

                Package (0x05)
                {
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000
                }
            })
            Name (TMP3, Package (0x03)
            {
                Package (0x05)
                {
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000
                }, 

                Package (0x05)
                {
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000
                }, 

                Package (0x05)
                {
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000, 
                    0x80000000
                }
            })
            If ((Local0 == 0x03))
            {
                If ((AAAA > BBBB))
                {
                    If ((AAAA > CCCC))
                    {
                        If ((BBBB > CCCC))
                        {
                            Local3 = Zero
                            LEV0 = Zero
                            Local4 = One
                            LEV1 = One
                            Local5 = 0x02
                            LEV2 = 0x02
                        }
                        Else
                        {
                            Local3 = Zero
                            LEV0 = Zero
                            Local5 = One
                            LEV1 = 0x02
                            Local4 = 0x02
                            LEV2 = One
                        }
                    }
                    Else
                    {
                        Local5 = Zero
                        LEV0 = 0x02
                        Local3 = One
                        LEV1 = Zero
                        Local4 = 0x02
                        LEV2 = One
                    }
                }
                ElseIf ((BBBB > CCCC))
                {
                    If ((AAAA > CCCC))
                    {
                        Local4 = Zero
                        LEV0 = One
                        Local3 = One
                        LEV1 = Zero
                        Local5 = 0x02
                        LEV2 = 0x02
                    }
                    Else
                    {
                        Local4 = Zero
                        LEV0 = One
                        Local5 = One
                        LEV1 = 0x02
                        Local3 = 0x02
                        LEV2 = Zero
                    }
                }
                Else
                {
                    Local5 = Zero
                    LEV0 = 0x02
                    Local4 = One
                    LEV1 = One
                    Local3 = 0x02
                    LEV2 = Zero
                }

                Local1 = (\_SB.TAR0 + One)
                Local2 = (Local1 * 0x64)
                DerefOf (TMP3 [Local3]) [Zero] = AAAA /* \_SB_.PC00.TCPU.TDPL.AAAA */
                DerefOf (TMP3 [Local3]) [One] = Local2
                DerefOf (TMP3 [Local3]) [0x02] = \_SB.CTC0 /* External reference */
                DerefOf (TMP3 [Local3]) [0x03] = Local1
                DerefOf (TMP3 [Local3]) [0x04] = Zero
                Local1 = (\_SB.TAR1 + One)
                Local2 = (Local1 * 0x64)
                DerefOf (TMP3 [Local4]) [Zero] = BBBB /* \_SB_.PC00.TCPU.TDPL.BBBB */
                DerefOf (TMP3 [Local4]) [One] = Local2
                DerefOf (TMP3 [Local4]) [0x02] = \_SB.CTC1 /* External reference */
                DerefOf (TMP3 [Local4]) [0x03] = Local1
                DerefOf (TMP3 [Local4]) [0x04] = Zero
                Local1 = (\_SB.TAR2 + One)
                Local2 = (Local1 * 0x64)
                DerefOf (TMP3 [Local5]) [Zero] = CCCC /* \_SB_.PC00.TCPU.TDPL.CCCC */
                DerefOf (TMP3 [Local5]) [One] = Local2
                DerefOf (TMP3 [Local5]) [0x02] = \_SB.CTC2 /* External reference */
                DerefOf (TMP3 [Local5]) [0x03] = Local1
                DerefOf (TMP3 [Local5]) [0x04] = Zero
                Return (TMP3) /* \_SB_.PC00.TCPU.TDPL.TMP3 */
            }

            If ((Local0 == 0x02))
            {
                If ((AAAA > BBBB))
                {
                    Local3 = Zero
                    Local4 = One
                    LEV0 = Zero
                    LEV1 = One
                    LEV2 = Zero
                }
                Else
                {
                    Local4 = Zero
                    Local3 = One
                    LEV0 = One
                    LEV1 = Zero
                    LEV2 = Zero
                }

                Local1 = (\_SB.TAR0 + One)
                Local2 = (Local1 * 0x64)
                DerefOf (TMP2 [Local3]) [Zero] = AAAA /* \_SB_.PC00.TCPU.TDPL.AAAA */
                DerefOf (TMP2 [Local3]) [One] = Local2
                DerefOf (TMP2 [Local3]) [0x02] = \_SB.CTC0 /* External reference */
                DerefOf (TMP2 [Local3]) [0x03] = Local1
                DerefOf (TMP2 [Local3]) [0x04] = Zero
                Local1 = (\_SB.TAR1 + One)
                Local2 = (Local1 * 0x64)
                DerefOf (TMP2 [Local4]) [Zero] = BBBB /* \_SB_.PC00.TCPU.TDPL.BBBB */
                DerefOf (TMP2 [Local4]) [One] = Local2
                DerefOf (TMP2 [Local4]) [0x02] = \_SB.CTC1 /* External reference */
                DerefOf (TMP2 [Local4]) [0x03] = Local1
                DerefOf (TMP2 [Local4]) [0x04] = Zero
                Return (TMP2) /* \_SB_.PC00.TCPU.TDPL.TMP2 */
            }

            If ((Local0 == One))
            {
                Switch (ToInteger (\_SB.CBMI))
                {
                    Case (Zero)
                    {
                        Local1 = (\_SB.TAR0 + One)
                        Local2 = (Local1 * 0x64)
                        DerefOf (TMP1 [Zero]) [Zero] = AAAA /* \_SB_.PC00.TCPU.TDPL.AAAA */
                        DerefOf (TMP1 [Zero]) [One] = Local2
                        DerefOf (TMP1 [Zero]) [0x02] = \_SB.CTC0 /* External reference */
                        DerefOf (TMP1 [Zero]) [0x03] = Local1
                        DerefOf (TMP1 [Zero]) [0x04] = Zero
                        LEV0 = Zero
                        LEV1 = Zero
                        LEV2 = Zero
                    }
                    Case (One)
                    {
                        Local1 = (\_SB.TAR1 + One)
                        Local2 = (Local1 * 0x64)
                        DerefOf (TMP1 [Zero]) [Zero] = BBBB /* \_SB_.PC00.TCPU.TDPL.BBBB */
                        DerefOf (TMP1 [Zero]) [One] = Local2
                        DerefOf (TMP1 [Zero]) [0x02] = \_SB.CTC1 /* External reference */
                        DerefOf (TMP1 [Zero]) [0x03] = Local1
                        DerefOf (TMP1 [Zero]) [0x04] = Zero
                        LEV0 = One
                        LEV1 = One
                        LEV2 = One
                    }
                    Case (0x02)
                    {
                        Local1 = (\_SB.TAR2 + One)
                        Local2 = (Local1 * 0x64)
                        DerefOf (TMP1 [Zero]) [Zero] = CCCC /* \_SB_.PC00.TCPU.TDPL.CCCC */
                        DerefOf (TMP1 [Zero]) [One] = Local2
                        DerefOf (TMP1 [Zero]) [0x02] = \_SB.CTC2 /* External reference */
                        DerefOf (TMP1 [Zero]) [0x03] = Local1
                        DerefOf (TMP1 [Zero]) [0x04] = Zero
                        LEV0 = 0x02
                        LEV1 = 0x02
                        LEV2 = 0x02
                    }

                }

                Return (TMP1) /* \_SB_.PC00.TCPU.TDPL.TMP1 */
            }

            Return (Zero)
        }

        Name (MAXT, Zero)
        Method (TDPC, 0, NotSerialized)
        {
            Return (MAXT) /* \_SB_.PC00.TCPU.MAXT */
        }

        Name (LEV0, Zero)
        Name (LEV1, Zero)
        Name (LEV2, Zero)
        Method (STDP, 1, Serialized)
        {
            If ((Arg0 >= \_SB.CLVL))
            {
                Return (Zero)
            }

            Switch (ToInteger (Arg0))
            {
                Case (Zero)
                {
                    Local0 = LEV0 /* \_SB_.PC00.TCPU.LEV0 */
                }
                Case (One)
                {
                    Local0 = LEV1 /* \_SB_.PC00.TCPU.LEV1 */
                }
                Case (0x02)
                {
                    Local0 = LEV2 /* \_SB_.PC00.TCPU.LEV2 */
                }

            }

            Switch (ToInteger (Local0))
            {
                Case (Zero)
                {
                    CPL0 ()
                }
                Case (One)
                {
                    CPL1 ()
                }
                Case (0x02)
                {
                    CPL2 ()
                }

            }

            Notify (\_SB.PC00.TCPU, 0x83) // Device-Specific Change
        }
    }

    Scope (\_SB.PC00.LPCB.H_EC)
    {
        Device (TFN1)
        {
            Name (_UID, "TFN1")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Name (_STR, Unicode ("Fan 1"))  // _STR: Description String
            Name (PTYP, 0x04)
            Name (FON, One)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((FND1 == One))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_FIF, 0, NotSerialized)  // _FIF: Fan Information
            {
                Return (Package (0x04)
                {
                    Zero, 
                    One, 
                    0x02, 
                    Zero
                })
            }

            Method (_FPS, 0, NotSerialized)  // _FPS: Fan Performance States
            {
                Return (Package (0x0D)
                {
                    Zero, 
                    Package (0x05)
                    {
                        0x64, 
                        0xFFFFFFFF, 
                        0x2EE0, 
                        0x01F4, 
                        0x1388
                    }, 

                    Package (0x05)
                    {
                        0x5F, 
                        0xFFFFFFFF, 
                        0x2D50, 
                        0x01DB, 
                        0x128E
                    }, 

                    Package (0x05)
                    {
                        0x5A, 
                        0xFFFFFFFF, 
                        0x2BC0, 
                        0x01C2, 
                        0x1194
                    }, 

                    Package (0x05)
                    {
                        0x55, 
                        0xFFFFFFFF, 
                        0x2904, 
                        0x01A9, 
                        0x109A
                    }, 

                    Package (0x05)
                    {
                        0x50, 
                        0xFFFFFFFF, 
                        0x2648, 
                        0x0190, 
                        0x0FA0
                    }, 

                    Package (0x05)
                    {
                        0x46, 
                        0xFFFFFFFF, 
                        0x2454, 
                        0x015E, 
                        0x0DAC
                    }, 

                    Package (0x05)
                    {
                        0x3C, 
                        0xFFFFFFFF, 
                        0x1CE8, 
                        0x012C, 
                        0x0BB8
                    }, 

                    Package (0x05)
                    {
                        0x32, 
                        0xFFFFFFFF, 
                        0x189C, 
                        0xFA, 
                        0x09C4
                    }, 

                    Package (0x05)
                    {
                        0x28, 
                        0xFFFFFFFF, 
                        0x13EC, 
                        0xC8, 
                        0x07D0
                    }, 

                    Package (0x05)
                    {
                        0x1E, 
                        0xFFFFFFFF, 
                        0x0ED8, 
                        0x96, 
                        0x05DC
                    }, 

                    Package (0x05)
                    {
                        0x19, 
                        0xFFFFFFFF, 
                        0x0C80, 
                        0x7D, 
                        0x04E2
                    }, 

                    Package (0x05)
                    {
                        Zero, 
                        0xFFFFFFFF, 
                        Zero, 
                        Zero, 
                        Zero
                    }
                })
            }

            Name (FSLV, Zero)
            Method (_FSL, 1, Serialized)  // _FSL: Fan Set Level
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    If ((Arg0 != \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.PENV))))
                    {
                        \_SB.PC00.LPCB.H_EC.ECWT (Zero, RefOf (\_SB.PC00.LPCB.H_EC.PPSL))
                        \_SB.PC00.LPCB.H_EC.ECWT (Zero, RefOf (\_SB.PC00.LPCB.H_EC.PPSH))
                        \_SB.PC00.LPCB.H_EC.ECWT (\_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.PENV)), RefOf (\_SB.PC00.LPCB.H_EC.PINV))
                        \_SB.PC00.LPCB.H_EC.ECWT (Arg0, RefOf (\_SB.PC00.LPCB.H_EC.PENV))
                        FSLV = Arg0
                        \_SB.PC00.LPCB.H_EC.ECWT (0x64, RefOf (\_SB.PC00.LPCB.H_EC.PSTP))
                        \_SB.PC00.LPCB.H_EC.ECMD (0x1A)
                    }
                }
            }

            Name (TFST, Package (0x03)
            {
                Zero, 
                0xFFFFFFFF, 
                0xFFFFFFFF
            })
            Method (_FST, 0, Serialized)  // _FST: Fan Status
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    TFST [One] = FSLV /* \_SB_.PC00.LPCB.H_EC.TFN1.FSLV */
                    TFST [0x02] = \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.CFSP))
                }

                Return (TFST) /* \_SB_.PC00.LPCB.H_EC.TFN1.TFST */
            }
        }
    }

    Scope (\_SB.PC00.LPCB.H_EC)
    {
        Device (TFN2)
        {
            Name (_HID, "INTC1048")  // _HID: Hardware ID
            Name (_UID, "TFN2")  // _UID: Unique ID
            Name (_STR, Unicode ("DDR Fan"))  // _STR: Description String
            Name (PTYP, 0x04)
            Name (FON, One)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((FND2 == One))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_FIF, 0, NotSerialized)  // _FIF: Fan Information
            {
                Return (Package (0x04)
                {
                    Zero, 
                    One, 
                    0x02, 
                    Zero
                })
            }

            Method (_FPS, 0, NotSerialized)  // _FPS: Fan Performance States
            {
                Return (Package (0x0D)
                {
                    Zero, 
                    Package (0x05)
                    {
                        0x64, 
                        0xFFFFFFFF, 
                        0x2EE0, 
                        0x01F4, 
                        0x1388
                    }, 

                    Package (0x05)
                    {
                        0x5F, 
                        0xFFFFFFFF, 
                        0x2D50, 
                        0x01DB, 
                        0x128E
                    }, 

                    Package (0x05)
                    {
                        0x5A, 
                        0xFFFFFFFF, 
                        0x2BC0, 
                        0x01C2, 
                        0x1194
                    }, 

                    Package (0x05)
                    {
                        0x55, 
                        0xFFFFFFFF, 
                        0x2904, 
                        0x01A9, 
                        0x109A
                    }, 

                    Package (0x05)
                    {
                        0x50, 
                        0xFFFFFFFF, 
                        0x2648, 
                        0x0190, 
                        0x0FA0
                    }, 

                    Package (0x05)
                    {
                        0x46, 
                        0xFFFFFFFF, 
                        0x2454, 
                        0x015E, 
                        0x0DAC
                    }, 

                    Package (0x05)
                    {
                        0x3C, 
                        0xFFFFFFFF, 
                        0x1CE8, 
                        0x012C, 
                        0x0BB8
                    }, 

                    Package (0x05)
                    {
                        0x32, 
                        0xFFFFFFFF, 
                        0x189C, 
                        0xFA, 
                        0x09C4
                    }, 

                    Package (0x05)
                    {
                        0x28, 
                        0xFFFFFFFF, 
                        0x13EC, 
                        0xC8, 
                        0x07D0
                    }, 

                    Package (0x05)
                    {
                        0x1E, 
                        0xFFFFFFFF, 
                        0x0ED8, 
                        0x96, 
                        0x05DC
                    }, 

                    Package (0x05)
                    {
                        0x19, 
                        0xFFFFFFFF, 
                        0x0C80, 
                        0x7D, 
                        0x04E2
                    }, 

                    Package (0x05)
                    {
                        Zero, 
                        0xFFFFFFFF, 
                        Zero, 
                        Zero, 
                        Zero
                    }
                })
            }

            Name (FSLV, Zero)
            Method (_FSL, 1, Serialized)  // _FSL: Fan Set Level
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    If ((Arg0 != \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.PENV))))
                    {
                        \_SB.PC00.LPCB.H_EC.ECWT (One, RefOf (\_SB.PC00.LPCB.H_EC.PPSL))
                        \_SB.PC00.LPCB.H_EC.ECWT (Zero, RefOf (\_SB.PC00.LPCB.H_EC.PPSH))
                        \_SB.PC00.LPCB.H_EC.ECWT (\_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.PENV)), RefOf (\_SB.PC00.LPCB.H_EC.PINV))
                        \_SB.PC00.LPCB.H_EC.ECWT (Arg0, RefOf (\_SB.PC00.LPCB.H_EC.PENV))
                        FSLV = Arg0
                        \_SB.PC00.LPCB.H_EC.ECWT (0x64, RefOf (\_SB.PC00.LPCB.H_EC.PSTP))
                        \_SB.PC00.LPCB.H_EC.ECMD (0x1A)
                    }
                }
            }

            Name (TFST, Package (0x03)
            {
                Zero, 
                0xFFFFFFFF, 
                0xFFFFFFFF
            })
            Method (_FST, 0, Serialized)  // _FST: Fan Status
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    TFST [One] = FSLV /* \_SB_.PC00.LPCB.H_EC.TFN2.FSLV */
                    TFST [0x02] = \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.DFSP))
                }

                Return (TFST) /* \_SB_.PC00.LPCB.H_EC.TFN2.TFST */
            }
        }
    }

    Scope (\_SB.PC00.LPCB.H_EC)
    {
        Device (TFN3)
        {
            Name (_HID, "INTC1048")  // _HID: Hardware ID
            Name (_UID, "TFN3")  // _UID: Unique ID
            Name (_STR, Unicode ("GFX Fan"))  // _STR: Description String
            Name (PTYP, 0x04)
            Name (FON, One)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((FND3 == One))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_FIF, 0, NotSerialized)  // _FIF: Fan Information
            {
                Return (Package (0x04)
                {
                    Zero, 
                    One, 
                    0x02, 
                    Zero
                })
            }

            Method (_FPS, 0, NotSerialized)  // _FPS: Fan Performance States
            {
                Return (Package (0x0D)
                {
                    Zero, 
                    Package (0x05)
                    {
                        0x64, 
                        0xFFFFFFFF, 
                        0x2EE0, 
                        0x01F4, 
                        0x1388
                    }, 

                    Package (0x05)
                    {
                        0x5F, 
                        0xFFFFFFFF, 
                        0x2D50, 
                        0x01DB, 
                        0x128E
                    }, 

                    Package (0x05)
                    {
                        0x5A, 
                        0xFFFFFFFF, 
                        0x2BC0, 
                        0x01C2, 
                        0x1194
                    }, 

                    Package (0x05)
                    {
                        0x55, 
                        0xFFFFFFFF, 
                        0x2904, 
                        0x01A9, 
                        0x109A
                    }, 

                    Package (0x05)
                    {
                        0x50, 
                        0xFFFFFFFF, 
                        0x2648, 
                        0x0190, 
                        0x0FA0
                    }, 

                    Package (0x05)
                    {
                        0x46, 
                        0xFFFFFFFF, 
                        0x2454, 
                        0x015E, 
                        0x0DAC
                    }, 

                    Package (0x05)
                    {
                        0x3C, 
                        0xFFFFFFFF, 
                        0x1CE8, 
                        0x012C, 
                        0x0BB8
                    }, 

                    Package (0x05)
                    {
                        0x32, 
                        0xFFFFFFFF, 
                        0x189C, 
                        0xFA, 
                        0x09C4
                    }, 

                    Package (0x05)
                    {
                        0x28, 
                        0xFFFFFFFF, 
                        0x13EC, 
                        0xC8, 
                        0x07D0
                    }, 

                    Package (0x05)
                    {
                        0x1E, 
                        0xFFFFFFFF, 
                        0x0ED8, 
                        0x96, 
                        0x05DC
                    }, 

                    Package (0x05)
                    {
                        0x19, 
                        0xFFFFFFFF, 
                        0x0C80, 
                        0x7D, 
                        0x04E2
                    }, 

                    Package (0x05)
                    {
                        Zero, 
                        0xFFFFFFFF, 
                        Zero, 
                        Zero, 
                        Zero
                    }
                })
            }

            Name (FSLV, Zero)
            Method (_FSL, 1, Serialized)  // _FSL: Fan Set Level
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    If ((Arg0 != \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.PENV))))
                    {
                        \_SB.PC00.LPCB.H_EC.ECWT (0x02, RefOf (\_SB.PC00.LPCB.H_EC.PPSL))
                        \_SB.PC00.LPCB.H_EC.ECWT (Zero, RefOf (\_SB.PC00.LPCB.H_EC.PPSH))
                        \_SB.PC00.LPCB.H_EC.ECWT (\_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.PENV)), RefOf (\_SB.PC00.LPCB.H_EC.PINV))
                        \_SB.PC00.LPCB.H_EC.ECWT (Arg0, RefOf (\_SB.PC00.LPCB.H_EC.PENV))
                        FSLV = Arg0
                        \_SB.PC00.LPCB.H_EC.ECWT (0x64, RefOf (\_SB.PC00.LPCB.H_EC.PSTP))
                        \_SB.PC00.LPCB.H_EC.ECMD (0x1A)
                    }
                }
            }

            Name (TFST, Package (0x03)
            {
                Zero, 
                0xFFFFFFFF, 
                0xFFFFFFFF
            })
            Method (_FST, 0, Serialized)  // _FST: Fan Status
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    TFST [One] = FSLV /* \_SB_.PC00.LPCB.H_EC.TFN3.FSLV */
                    TFST [0x02] = \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.GFSP))
                }

                Return (TFST) /* \_SB_.PC00.LPCB.H_EC.TFN3.TFST */
            }
        }
    }

    Scope (\_SB.PC00.LPCB.H_EC)
    {
        Device (CHRG)
        {
            Name (_UID, "CHRG")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Name (_STR, Unicode ("Charger"))  // _STR: Description String
            Name (PTYP, 0x0B)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((\CHGE == One))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Name (PSSS, Zero)
            Name (PPPS, Zero)
            Name (PPS1, Package (0x08)
            {
                Package (0x08)
                {
                    0x64, 
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x0DAC, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x55, 
                    Zero, 
                    Zero, 
                    Zero, 
                    One, 
                    0x0BB8, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x47, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x02, 
                    0x09C4, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x39, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x03, 
                    0x07D0, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x2A, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x04, 
                    0x05DC, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x1C, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x05, 
                    0x03E8, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x0E, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x06, 
                    0x01F4, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x07, 
                    Zero, 
                    "MilliAmps", 
                    Zero
                }
            })
            Name (PPS2, Package (0x0A)
            {
                Package (0x08)
                {
                    0x64, 
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x1194, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x58, 
                    Zero, 
                    Zero, 
                    Zero, 
                    One, 
                    0x0FA0, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x4D, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x02, 
                    0x0DAC, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x42, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x03, 
                    0x0BB8, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x37, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x04, 
                    0x09C4, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x2C, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x05, 
                    0x07D0, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x21, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x06, 
                    0x05DC, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x16, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x07, 
                    0x03E8, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    0x0B, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x08, 
                    0x01F4, 
                    "MilliAmps", 
                    Zero
                }, 

                Package (0x08)
                {
                    Zero, 
                    Zero, 
                    Zero, 
                    Zero, 
                    0x09, 
                    Zero, 
                    "MilliAmps", 
                    Zero
                }
            })
            Method (PPSS, 0, Serialized)
            {
                If ((ECRD (RefOf (FCHG)) == One))
                {
                    Return (PPS2) /* \_SB_.PC00.LPCB.H_EC.CHRG.PPS2 */
                }
                Else
                {
                    Return (PPS1) /* \_SB_.PC00.LPCB.H_EC.CHRG.PPS1 */
                }
            }

            Method (PCAL, 0, Serialized)
            {
                If ((ECRD (RefOf (FCHG)) == One))
                {
                    PSSS = SizeOf (PPS2)
                }
                Else
                {
                    PSSS = SizeOf (PPS1)
                }
            }

            Method (PPPC, 0, NotSerialized)
            {
                Return (PPPS) /* \_SB_.PC00.LPCB.H_EC.CHRG.PPPS */
            }

            Method (SPPC, 1, Serialized)
            {
                PCAL ()
                If ((ToInteger (Arg0) <= (PSSS - One)))
                {
                    If ((ECRD (RefOf (FCHG)) == One))
                    {
                        Local1 = DerefOf (DerefOf (PPS2 [Arg0]) [0x05])
                        PPPS = DerefOf (DerefOf (PPS2 [Arg0]) [0x04])
                    }
                    Else
                    {
                        Local1 = DerefOf (DerefOf (PPS1 [Arg0]) [0x05])
                        PPPS = DerefOf (DerefOf (PPS1 [Arg0]) [0x04])
                    }

                    \_SB.PC00.LPCB.H_EC.ECWT (Local1, RefOf (\_SB.PC00.LPCB.H_EC.CHGR))
                    \_SB.PC00.LPCB.H_EC.ECMD (0x37)
                }
            }

            Method (PPDL, 0, NotSerialized)
            {
                PCAL ()
                Return ((PSSS - One))
            }
        }
    }

    Scope (\_SB)
    {
        Device (TPWR)
        {
            Name (_UID, "TPWR")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Name (_STR, Unicode ("Platform Power"))  // _STR: Description String
            Name (PTYP, 0x11)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((\PWRE == One))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (PSOC, 0, NotSerialized)
            {
                If ((\_SB.PC00.LPCB.H_EC.ECAV == Zero))
                {
                    Return (Zero)
                }

                If ((\_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.B1FC)) == Zero))
                {
                    Return (Zero)
                }

                If ((\_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.B1RC)) > \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.B1FC))))
                {
                    Return (Zero)
                }

                If ((\_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.B1RC)) == \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.B1FC))))
                {
                    Return (0x64)
                }

                If ((\_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.B1RC)) < \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.B1FC))))
                {
                    Local0 = (\_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.B1RC)) * 0x64)
                    Divide (Local0, \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.B1FC)), Local2, Local1)
                    Local2 /= 0x64
                    Local3 = (\_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.B1FC)) / 0xC8)
                    If ((Local2 >= Local3))
                    {
                        Local1 += One
                    }

                    Return (Local1)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (PSRC, 0, Serialized)
            {
                If ((\_SB.PC00.LPCB.H_EC.ECAV == Zero))
                {
                    Return (Zero)
                }
                Else
                {
                    Local0 = \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.PWRT))
                    Local1 = (Local0 & 0xF0)
                }

                Switch (ToInteger ((ToInteger (Local0) & 0x07)))
                {
                    Case (Zero)
                    {
                        Local1 |= Zero
                    }
                    Case (One)
                    {
                        Local1 |= One
                    }
                    Case (0x02)
                    {
                        Local1 |= 0x02
                    }
                    Default
                    {
                        Local1 |= Zero
                    }

                }

                Return (Local1)
            }

            Method (ARTG, 0, NotSerialized)
            {
                If (((PSRC () & 0x07) == One))
                {
                    If ((\_SB.PC00.LPCB.H_EC.ECAV == One))
                    {
                        Local0 = (\_SB.PC00.LPCB.H_EC.ARTG * 0x0A)
                        Return (Local0)
                    }
                    Else
                    {
                        Return (0x00015F90)
                    }
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (PROP, 0, NotSerialized)
            {
                If ((\_SB.PC00.LPCB.H_EC.ECAV == One))
                {
                    Local0 = (\_SB.PC00.LPCB.H_EC.PROP * 0x03E8)
                    Return (Local0)
                }
                Else
                {
                    Return (0x61A8)
                }
            }

            Method (PBOK, 1, Serialized)
            {
                If ((\_SB.PC00.LPCB.H_EC.ECAV == One))
                {
                    Local0 = (Arg0 & 0x0F)
                    \_SB.PC00.LPCB.H_EC.ECWT (Local0, RefOf (\_SB.PC00.LPCB.H_EC.PBOK))
                    \_SB.PC00.LPCB.H_EC.ECMD (0x15)
                }
            }
        }
    }

    Scope (\_SB)
    {
        Device (TPCH)
        {
            Name (_UID, "TPCH")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Name (_STR, Unicode ("Intel PCH FIVR Participant"))  // _STR: Description String
            Name (PTYP, 0x05)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((\PCHE == One))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (RFC0, 1, Serialized)
            {
                IPCS (0xA3, One, 0x08, Zero, Arg0, Zero, Zero)
                Return (Package (0x01)
                {
                    Zero
                })
            }

            Method (RFC1, 1, Serialized)
            {
                IPCS (0xA3, One, 0x08, One, Arg0, Zero, Zero)
                Return (Package (0x01)
                {
                    Zero
                })
            }

            Method (SEMI, 1, Serialized)
            {
                IPCS (0xA3, One, 0x08, 0x02, Arg0, Zero, Zero)
                Return (Package (0x01)
                {
                    Zero
                })
            }

            Method (PKGC, 1, Serialized)
            {
                Name (PPKG, Package (0x02)
                {
                    Zero, 
                    Zero
                })
                PPKG [Zero] = DerefOf (Arg0 [Zero])
                PPKG [One] = DerefOf (Arg0 [One])
                Return (PPKG) /* \_SB_.TPCH.PKGC.PPKG */
            }

            Method (GFC0, 0, Serialized)
            {
                Local0 = IPCS (0xA3, Zero, 0x08, Zero, Zero, Zero, Zero)
                Local1 = \_SB.TPCH.PKGC (Local0)
                Return (Local1)
            }

            Method (GFC1, 0, Serialized)
            {
                Local0 = IPCS (0xA3, Zero, 0x08, One, Zero, Zero, Zero)
                Local1 = \_SB.TPCH.PKGC (Local0)
                Return (Local1)
            }

            Method (GEMI, 0, Serialized)
            {
                Local0 = IPCS (0xA3, Zero, 0x08, 0x02, Zero, Zero, Zero)
                Local1 = \_SB.TPCH.PKGC (Local0)
                Return (Local1)
            }

            Method (GFFS, 0, Serialized)
            {
                Local0 = IPCS (0xA3, Zero, 0x08, 0x03, Zero, Zero, Zero)
                Local1 = \_SB.TPCH.PKGC (Local0)
                Return (Local1)
            }

            Method (GFCS, 0, Serialized)
            {
                Local0 = IPCS (0xA3, Zero, 0x08, 0x04, Zero, Zero, Zero)
                Local1 = \_SB.TPCH.PKGC (Local0)
                Return (Local1)
            }
        }
    }

    Scope (\_SB)
    {
        Device (BAT1)
        {
            Name (_UID, "1")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Name (_STR, Unicode ("Battery 1 Participant"))  // _STR: Description String
            Name (PTYP, 0x0C)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((\BATR == One))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (PMAX, 0, Serialized)
            {
                If ((\_SB.PC00.LPCB.H_EC.ECAV == One))
                {
                    Local0 = \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.BMAX))
                    If (Local0)
                    {
                        Local0 = ~Local0 |= 0xFFFF0000
                        Local0 = (Local0 += One * 0x0A)
                    }

                    Return (Local0)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (CTYP, 0, NotSerialized)
            {
                If ((\_SB.PC00.LPCB.H_EC.ECAV == One))
                {
                    Return (\_SB.PC00.LPCB.H_EC.CTYP) /* External reference */
                }
                Else
                {
                    Return (0x03)
                }
            }

            Method (PBSS, 0, NotSerialized)
            {
                If ((\_SB.PC00.LPCB.H_EC.ECAV == One))
                {
                    Local0 = \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.PBSS))
                    Return (Local0)
                }

                Return (0x64)
            }

            Method (DPSP, 0, Serialized)
            {
                Return (\PPPR) /* External reference */
            }

            Method (RBHF, 0, NotSerialized)
            {
                If ((\_SB.PC00.LPCB.H_EC.ECAV == One))
                {
                    Local0 = \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.RBHF))
                    Return (Local0)
                }

                Return (0xFFFFFFFF)
            }

            Method (VBNL, 0, NotSerialized)
            {
                If ((\_SB.PC00.LPCB.H_EC.ECAV == One))
                {
                    Local0 = \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.VBNL))
                    Return (Local0)
                }

                Return (0xFFFFFFFF)
            }

            Method (CMPP, 0, NotSerialized)
            {
                If ((\_SB.PC00.LPCB.H_EC.ECAV == One))
                {
                    Local0 = \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.CMPP))
                    Return (Local0)
                }

                Return (0xFFFFFFFF)
            }
        }
    }

    Scope (\_SB.PC00.LPCB.H_EC)
    {
        Device (SEN1)
        {
            Name (_UID, "SEN1")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Name (_STR, Unicode ("Thermistor PCH VR"))  // _STR: Description String
            Name (PTYP, 0x03)
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((\S1DE == One))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Return (\_SB.IETM.C10K (\_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.TSR1))))
                }
                Else
                {
                    Return (0x0BB8)
                }
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Local0 = Acquire (\_SB.PC00.LPCB.H_EC.PATM, 0x0064)
                    If ((Local0 == Zero))
                    {
                        Local1 = \_SB.IETM.K10C (Arg0)
                        \_SB.PC00.LPCB.H_EC.ECWT (Zero, RefOf (\_SB.PC00.LPCB.H_EC.TSI))
                        \_SB.PC00.LPCB.H_EC.ECWT (0x02, RefOf (\_SB.PC00.LPCB.H_EC.HYST))
                        \_SB.PC00.LPCB.H_EC.ECWT (Local1, RefOf (\_SB.PC00.LPCB.H_EC.TSLT))
                        \_SB.PC00.LPCB.H_EC.ECMD (0x4A)
                        Release (\_SB.PC00.LPCB.H_EC.PATM)
                    }
                }
            }

            Method (PAT1, 1, Serialized)
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Local0 = Acquire (\_SB.PC00.LPCB.H_EC.PATM, 0x0064)
                    If ((Local0 == Zero))
                    {
                        Local1 = \_SB.IETM.K10C (Arg0)
                        \_SB.PC00.LPCB.H_EC.ECWT (Zero, RefOf (\_SB.PC00.LPCB.H_EC.TSI))
                        \_SB.PC00.LPCB.H_EC.ECWT (0x02, RefOf (\_SB.PC00.LPCB.H_EC.HYST))
                        \_SB.PC00.LPCB.H_EC.ECWT (Local1, RefOf (\_SB.PC00.LPCB.H_EC.TSHT))
                        \_SB.PC00.LPCB.H_EC.ECMD (0x4A)
                        Release (\_SB.PC00.LPCB.H_EC.PATM)
                    }
                }
            }

            Name (GTSH, 0x14)
            Name (LSTM, Zero)
            Method (_DTI, 1, NotSerialized)  // _DTI: Device Temperature Indication
            {
                LSTM = Arg0
                Notify (\_SB.PC00.LPCB.H_EC.SEN1, 0x91) // Device-Specific
            }

            Method (_NTT, 0, NotSerialized)  // _NTT: Notification Temperature Threshold
            {
                Return (0x0ADE)
            }

            Name (S1AC, 0x3C)
            Name (S1A1, 0x32)
            Name (S1A2, 0x28)
            Name (S1PV, 0x41)
            Name (S1CC, 0x50)
            Name (S1C3, 0x46)
            Name (S1HP, 0x4B)
            Name (SSP1, Zero)
            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (SSP1) /* \_SB_.PC00.LPCB.H_EC.SEN1.SSP1 */
            }

            Method (_AC0, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Local1 = \_SB.IETM.CTOK (S1AC)
                If ((LSTM >= Local1))
                {
                    Return ((Local1 - 0x14))
                }
                Else
                {
                    Return (Local1)
                }
            }

            Method (_AC1, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S1A1))
            }

            Method (_AC2, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S1A2))
            }

            Method (_PSV, 0, Serialized)  // _PSV: Passive Temperature
            {
                Return (\_SB.IETM.CTOK (S1PV))
            }

            Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
            {
                Return (\_SB.IETM.CTOK (S1CC))
            }

            Method (_CR3, 0, Serialized)  // _CR3: Warm/Standby Temperature
            {
                Return (\_SB.IETM.CTOK (S1C3))
            }

            Method (_HOT, 0, Serialized)  // _HOT: Hot Temperature
            {
                Return (\_SB.IETM.CTOK (S1HP))
            }
        }
    }

    Scope (\_SB.PC00.LPCB.H_EC)
    {
        Device (SEN2)
        {
            Name (_UID, "SEN2")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Name (_STR, Unicode ("Thermistor GT VR"))  // _STR: Description String
            Name (PTYP, 0x03)
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((\S2DE == One))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Return (\_SB.IETM.CTOK (\_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.TSR2))))
                }
                Else
                {
                    Return (0x0BB8)
                }
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Local0 = Acquire (\_SB.PC00.LPCB.H_EC.PATM, 0x0064)
                    If ((Local0 == Zero))
                    {
                        Local1 = \_SB.IETM.KTOC (Arg0)
                        \_SB.PC00.LPCB.H_EC.ECWT (0x02, RefOf (\_SB.PC00.LPCB.H_EC.TSI))
                        \_SB.PC00.LPCB.H_EC.ECWT (0x02, RefOf (\_SB.PC00.LPCB.H_EC.HYST))
                        \_SB.PC00.LPCB.H_EC.ECWT (Local1, RefOf (\_SB.PC00.LPCB.H_EC.TSLT))
                        \_SB.PC00.LPCB.H_EC.ECMD (0x4A)
                        Release (\_SB.PC00.LPCB.H_EC.PATM)
                    }
                }
            }

            Method (PAT1, 1, Serialized)
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Local0 = Acquire (\_SB.PC00.LPCB.H_EC.PATM, 0x0064)
                    If ((Local0 == Zero))
                    {
                        Local1 = \_SB.IETM.KTOC (Arg0)
                        \_SB.PC00.LPCB.H_EC.ECWT (0x02, RefOf (\_SB.PC00.LPCB.H_EC.TSI))
                        \_SB.PC00.LPCB.H_EC.ECWT (0x02, RefOf (\_SB.PC00.LPCB.H_EC.HYST))
                        \_SB.PC00.LPCB.H_EC.ECWT (Local1, RefOf (\_SB.PC00.LPCB.H_EC.TSHT))
                        \_SB.PC00.LPCB.H_EC.ECMD (0x4A)
                        Release (\_SB.PC00.LPCB.H_EC.PATM)
                    }
                }
            }

            Name (GTSH, 0x14)
            Name (LSTM, Zero)
            Method (_DTI, 1, NotSerialized)  // _DTI: Device Temperature Indication
            {
                LSTM = Arg0
                Notify (\_SB.PC00.LPCB.H_EC.SEN2, 0x91) // Device-Specific
            }

            Method (_NTT, 0, NotSerialized)  // _NTT: Notification Temperature Threshold
            {
                Return (0x0ADE)
            }

            Name (S2AC, 0x3C)
            Name (S2A1, 0x32)
            Name (S2A2, 0x28)
            Name (S2PV, 0x41)
            Name (S2CC, 0x50)
            Name (S2C3, 0x46)
            Name (S2HP, 0x4B)
            Name (SSP2, Zero)
            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (SSP2) /* \_SB_.PC00.LPCB.H_EC.SEN2.SSP2 */
            }

            Method (_AC0, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Local1 = \_SB.IETM.CTOK (S2AC)
                If ((LSTM >= Local1))
                {
                    Return ((Local1 - 0x14))
                }
                Else
                {
                    Return (Local1)
                }
            }

            Method (_AC1, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S2A1))
            }

            Method (_AC2, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S2A2))
            }

            Method (_PSV, 0, Serialized)  // _PSV: Passive Temperature
            {
                Return (\_SB.IETM.CTOK (S2PV))
            }

            Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
            {
                Return (\_SB.IETM.CTOK (S2CC))
            }

            Method (_CR3, 0, Serialized)  // _CR3: Warm/Standby Temperature
            {
                Return (\_SB.IETM.CTOK (S2C3))
            }

            Method (_HOT, 0, Serialized)  // _HOT: Hot Temperature
            {
                Return (\_SB.IETM.CTOK (S2HP))
            }
        }
    }

    Scope (\_SB.PC00.LPCB.H_EC)
    {
        Device (SEN3)
        {
            Name (_UID, "SEN3")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Name (_STR, Unicode ("Thermistor Ambient"))  // _STR: Description String
            Name (PTYP, 0x03)
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((\S3DE == One))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Return (\_SB.IETM.CTOK (\_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.TSR3))))
                }
                Else
                {
                    Return (0x0BB8)
                }
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Local0 = Acquire (\_SB.PC00.LPCB.H_EC.PATM, 0x0064)
                    If ((Local0 == Zero))
                    {
                        Local1 = \_SB.IETM.K10C (Arg0)
                        \_SB.PC00.LPCB.H_EC.ECWT (0x02, RefOf (\_SB.PC00.LPCB.H_EC.TSI))
                        \_SB.PC00.LPCB.H_EC.ECWT (0x02, RefOf (\_SB.PC00.LPCB.H_EC.HYST))
                        \_SB.PC00.LPCB.H_EC.ECWT (Local1, RefOf (\_SB.PC00.LPCB.H_EC.TSLT))
                        \_SB.PC00.LPCB.H_EC.ECMD (0x4A)
                        Release (\_SB.PC00.LPCB.H_EC.PATM)
                    }
                }
            }

            Method (PAT1, 1, Serialized)
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Local0 = Acquire (\_SB.PC00.LPCB.H_EC.PATM, 0x0064)
                    If ((Local0 == Zero))
                    {
                        Local1 = \_SB.IETM.K10C (Arg0)
                        \_SB.PC00.LPCB.H_EC.ECWT (0x02, RefOf (\_SB.PC00.LPCB.H_EC.TSI))
                        \_SB.PC00.LPCB.H_EC.ECWT (0x02, RefOf (\_SB.PC00.LPCB.H_EC.HYST))
                        \_SB.PC00.LPCB.H_EC.ECWT (Local1, RefOf (\_SB.PC00.LPCB.H_EC.TSHT))
                        \_SB.PC00.LPCB.H_EC.ECMD (0x4A)
                        Release (\_SB.PC00.LPCB.H_EC.PATM)
                    }
                }
            }

            Name (GTSH, 0x14)
            Name (LSTM, Zero)
            Method (_DTI, 1, NotSerialized)  // _DTI: Device Temperature Indication
            {
                LSTM = Arg0
                Notify (\_SB.PC00.LPCB.H_EC.SEN3, 0x91) // Device-Specific
            }

            Method (_NTT, 0, NotSerialized)  // _NTT: Notification Temperature Threshold
            {
                Return (0x0ADE)
            }

            Name (S3AC, 0x3C)
            Name (S3A1, 0x32)
            Name (S3A2, 0x28)
            Name (S3PV, 0x41)
            Name (S3CC, 0x50)
            Name (S3C3, 0x46)
            Name (S3HP, 0x4B)
            Name (SSP3, Zero)
            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (SSP3) /* \_SB_.PC00.LPCB.H_EC.SEN3.SSP3 */
            }

            Method (_AC3, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Local1 = \_SB.IETM.CTOK (S3AC)
                If ((LSTM >= Local1))
                {
                    Return ((Local1 - 0x14))
                }
                Else
                {
                    Return (Local1)
                }
            }

            Method (_AC4, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S3A1))
            }

            Method (_AC5, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S3A2))
            }

            Method (_PSV, 0, Serialized)  // _PSV: Passive Temperature
            {
                Return (\_SB.IETM.CTOK (S3PV))
            }

            Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
            {
                Return (\_SB.IETM.CTOK (S3CC))
            }

            Method (_CR3, 0, Serialized)  // _CR3: Warm/Standby Temperature
            {
                Return (\_SB.IETM.CTOK (S3C3))
            }

            Method (_HOT, 0, Serialized)  // _HOT: Hot Temperature
            {
                Return (\_SB.IETM.CTOK (S3HP))
            }
        }
    }

    Scope (\_SB.PC00.LPCB.H_EC)
    {
        Device (SEN4)
        {
            Name (_UID, "SEN4")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Name (_STR, Unicode ("Thermistor Battery Charger"))  // _STR: Description String
            Name (PTYP, 0x03)
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((\S4DE == One))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Return (\_SB.IETM.CTOK (\_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.TSR4))))
                }
                Else
                {
                    Return (0x0BB8)
                }
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Local0 = Acquire (\_SB.PC00.LPCB.H_EC.PATM, 0x0064)
                    If ((Local0 == Zero))
                    {
                        Local1 = \_SB.IETM.K10C (Arg0)
                        \_SB.PC00.LPCB.H_EC.ECWT (0x03, RefOf (\_SB.PC00.LPCB.H_EC.TSI))
                        \_SB.PC00.LPCB.H_EC.ECWT (0x02, RefOf (\_SB.PC00.LPCB.H_EC.HYST))
                        \_SB.PC00.LPCB.H_EC.ECWT (Local1, RefOf (\_SB.PC00.LPCB.H_EC.TSLT))
                        \_SB.PC00.LPCB.H_EC.ECMD (0x4A)
                        Release (\_SB.PC00.LPCB.H_EC.PATM)
                    }
                }
            }

            Method (PAT1, 1, Serialized)
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Local0 = Acquire (\_SB.PC00.LPCB.H_EC.PATM, 0x0064)
                    If ((Local0 == Zero))
                    {
                        Local1 = \_SB.IETM.K10C (Arg0)
                        \_SB.PC00.LPCB.H_EC.ECWT (0x03, RefOf (\_SB.PC00.LPCB.H_EC.TSI))
                        \_SB.PC00.LPCB.H_EC.ECWT (0x02, RefOf (\_SB.PC00.LPCB.H_EC.HYST))
                        \_SB.PC00.LPCB.H_EC.ECWT (Local1, RefOf (\_SB.PC00.LPCB.H_EC.TSHT))
                        \_SB.PC00.LPCB.H_EC.ECMD (0x4A)
                        Release (\_SB.PC00.LPCB.H_EC.PATM)
                    }
                }
            }

            Name (GTSH, 0x14)
            Name (LSTM, Zero)
            Method (_DTI, 1, NotSerialized)  // _DTI: Device Temperature Indication
            {
                LSTM = Arg0
                Notify (\_SB.PC00.LPCB.H_EC.SEN4, 0x91) // Device-Specific
            }

            Method (_NTT, 0, NotSerialized)  // _NTT: Notification Temperature Threshold
            {
                Return (0x0ADE)
            }

            Name (S4AC, 0x3C)
            Name (S4A1, 0x32)
            Name (S4A2, 0x28)
            Name (S4PV, 0x41)
            Name (S4CC, 0x50)
            Name (S4C3, 0x46)
            Name (S4HP, 0x4B)
            Name (SSP4, Zero)
            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (SSP4) /* \_SB_.PC00.LPCB.H_EC.SEN4.SSP4 */
            }

            Method (_AC0, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Local1 = \_SB.IETM.CTOK (S4AC)
                If ((LSTM >= Local1))
                {
                    Return ((Local1 - 0x14))
                }
                Else
                {
                    Return (Local1)
                }
            }

            Method (_AC1, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S4A1))
            }

            Method (_AC2, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S4A2))
            }

            Method (_PSV, 0, Serialized)  // _PSV: Passive Temperature
            {
                Return (\_SB.IETM.CTOK (S4PV))
            }

            Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
            {
                Return (\_SB.IETM.CTOK (S4CC))
            }

            Method (_CR3, 0, Serialized)  // _CR3: Warm/Standby Temperature
            {
                Return (\_SB.IETM.CTOK (S4C3))
            }

            Method (_HOT, 0, Serialized)  // _HOT: Hot Temperature
            {
                Return (\_SB.IETM.CTOK (S4HP))
            }
        }
    }

    Scope (\_SB.PC00.LPCB.H_EC)
    {
        Device (SEN5)
        {
            Name (_UID, "SEN5")  // _UID: Unique ID
            Method (_HID, 0, NotSerialized)  // _HID: Hardware ID
            {
                Return (\_SB.IETM.GHID (_UID))
            }

            Name (_STR, Unicode ("Thermistor Memory"))  // _STR: Description String
            Name (PTYP, 0x03)
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((\S5DE == One))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Return (\_SB.IETM.C10K (\_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.TSR5))))
                }
                Else
                {
                    Return (0x0BB8)
                }
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Local0 = Acquire (\_SB.PC00.LPCB.H_EC.PATM, 0x0064)
                    If ((Local0 == Zero))
                    {
                        Local1 = \_SB.IETM.K10C (Arg0)
                        \_SB.PC00.LPCB.H_EC.ECWT (0x04, RefOf (\_SB.PC00.LPCB.H_EC.TSI))
                        \_SB.PC00.LPCB.H_EC.ECWT (0x02, RefOf (\_SB.PC00.LPCB.H_EC.HYST))
                        \_SB.PC00.LPCB.H_EC.ECWT (Local1, RefOf (\_SB.PC00.LPCB.H_EC.TSLT))
                        \_SB.PC00.LPCB.H_EC.ECMD (0x4A)
                        Release (\_SB.PC00.LPCB.H_EC.PATM)
                    }
                }
            }

            Method (PAT1, 1, Serialized)
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Local0 = Acquire (\_SB.PC00.LPCB.H_EC.PATM, 0x0064)
                    If ((Local0 == Zero))
                    {
                        Local1 = \_SB.IETM.K10C (Arg0)
                        \_SB.PC00.LPCB.H_EC.ECWT (0x04, RefOf (\_SB.PC00.LPCB.H_EC.TSI))
                        \_SB.PC00.LPCB.H_EC.ECWT (0x02, RefOf (\_SB.PC00.LPCB.H_EC.HYST))
                        \_SB.PC00.LPCB.H_EC.ECWT (Local1, RefOf (\_SB.PC00.LPCB.H_EC.TSHT))
                        \_SB.PC00.LPCB.H_EC.ECMD (0x4A)
                        Release (\_SB.PC00.LPCB.H_EC.PATM)
                    }
                }
            }

            Name (GTSH, 0x14)
            Name (LSTM, Zero)
            Method (_DTI, 1, NotSerialized)  // _DTI: Device Temperature Indication
            {
                LSTM = Arg0
                Notify (\_SB.PC00.LPCB.H_EC.SEN5, 0x91) // Device-Specific
            }

            Method (_NTT, 0, NotSerialized)  // _NTT: Notification Temperature Threshold
            {
                Return (0x0ADE)
            }

            Name (S5AC, 0x3C)
            Name (S5A1, 0x32)
            Name (S5A2, 0x28)
            Name (S5PV, 0x41)
            Name (S5CC, 0x50)
            Name (S5C3, 0x46)
            Name (S5HP, 0x4B)
            Name (SSP5, Zero)
            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (SSP5) /* \_SB_.PC00.LPCB.H_EC.SEN5.SSP5 */
            }

            Method (_AC0, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Local1 = \_SB.IETM.CTOK (S5AC)
                If ((LSTM >= Local1))
                {
                    Return ((Local1 - 0x14))
                }
                Else
                {
                    Return (Local1)
                }
            }

            Method (_AC1, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S5A1))
            }

            Method (_AC2, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S5A2))
            }

            Method (_PSV, 0, Serialized)  // _PSV: Passive Temperature
            {
                Return (\_SB.IETM.CTOK (S5PV))
            }

            Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
            {
                Return (\_SB.IETM.CTOK (S5CC))
            }

            Method (_CR3, 0, Serialized)  // _CR3: Warm/Standby Temperature
            {
                Return (\_SB.IETM.CTOK (S5C3))
            }

            Method (_HOT, 0, Serialized)  // _HOT: Hot Temperature
            {
                Return (\_SB.IETM.CTOK (S5HP))
            }
        }
    }

    Scope (\_SB.PC00.LPCB.H_EC)
    {
        Device (DGPU)
        {
            Name (_HID, "INTC1046")  // _HID: Hardware ID
            Name (_UID, "DGPU")  // _UID: Unique ID
            Name (_STR, Unicode ("Discrete Gpu Sensor"))  // _STR: Description String
            Name (PTYP, 0x03)
            Name (CTYP, Zero)
            Name (PFLG, Zero)
            Method (_STA, 0, NotSerialized)  // _STA: Status
            {
                If ((\S6DE == One))
                {
                    Return (0x0F)
                }
                Else
                {
                    Return (Zero)
                }
            }

            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Return (\_SB.IETM.C10K (\_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.TSR1))))
                }
                Else
                {
                    Return (0x0BB8)
                }
            }

            Name (PATC, 0x02)
            Method (PAT0, 1, Serialized)
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Local0 = Acquire (\_SB.PC00.LPCB.H_EC.PATM, 0x0064)
                    If ((Local0 == Zero))
                    {
                        Local1 = \_SB.IETM.K10C (Arg0)
                        \_SB.PC00.LPCB.H_EC.ECWT (Zero, RefOf (\_SB.PC00.LPCB.H_EC.TSI))
                        \_SB.PC00.LPCB.H_EC.ECWT (0x02, RefOf (\_SB.PC00.LPCB.H_EC.HYST))
                        \_SB.PC00.LPCB.H_EC.ECWT (Local1, RefOf (\_SB.PC00.LPCB.H_EC.TSLT))
                        \_SB.PC00.LPCB.H_EC.ECMD (0x4A)
                        Release (\_SB.PC00.LPCB.H_EC.PATM)
                    }
                }
            }

            Method (PAT1, 1, Serialized)
            {
                If (\_SB.PC00.LPCB.H_EC.ECAV)
                {
                    Local0 = Acquire (\_SB.PC00.LPCB.H_EC.PATM, 0x0064)
                    If ((Local0 == Zero))
                    {
                        Local1 = \_SB.IETM.K10C (Arg0)
                        \_SB.PC00.LPCB.H_EC.ECWT (Zero, RefOf (\_SB.PC00.LPCB.H_EC.TSI))
                        \_SB.PC00.LPCB.H_EC.ECWT (0x02, RefOf (\_SB.PC00.LPCB.H_EC.HYST))
                        \_SB.PC00.LPCB.H_EC.ECWT (Local1, RefOf (\_SB.PC00.LPCB.H_EC.TSHT))
                        \_SB.PC00.LPCB.H_EC.ECMD (0x4A)
                        Release (\_SB.PC00.LPCB.H_EC.PATM)
                    }
                }
            }

            Name (GTSH, 0x14)
            Name (LSTM, Zero)
            Method (_DTI, 1, NotSerialized)  // _DTI: Device Temperature Indication
            {
                LSTM = Arg0
                Notify (\_SB.PC00.LPCB.H_EC.DGPU, 0x91) // Device-Specific
            }

            Method (_NTT, 0, NotSerialized)  // _NTT: Notification Temperature Threshold
            {
                Return (0x0ADE)
            }

            Name (S6AC, 0x3C)
            Name (S6A1, 0x32)
            Name (S6A2, 0x28)
            Name (S6PV, 0x41)
            Name (S6CC, 0x50)
            Name (S6C3, 0x46)
            Name (S6HP, 0x4B)
            Name (S6P2, Zero)
            Method (_TSP, 0, Serialized)  // _TSP: Thermal Sampling Period
            {
                Return (S6P2) /* \_SB_.PC00.LPCB.H_EC.DGPU.S6P2 */
            }

            Method (_AC0, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Local1 = \_SB.IETM.CTOK (S6AC)
                If ((LSTM >= Local1))
                {
                    Return ((Local1 - 0x14))
                }
                Else
                {
                    Return (Local1)
                }
            }

            Method (_AC1, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S6A1))
            }

            Method (_AC2, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (\_SB.IETM.CTOK (S6A2))
            }

            Method (_PSV, 0, Serialized)  // _PSV: Passive Temperature
            {
                Return (\_SB.IETM.CTOK (S6PV))
            }

            Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
            {
                Return (\_SB.IETM.CTOK (S6CC))
            }

            Method (_CR3, 0, Serialized)  // _CR3: Warm/Standby Temperature
            {
                Return (\_SB.IETM.CTOK (S6C3))
            }

            Method (_HOT, 0, Serialized)  // _HOT: Hot Temperature
            {
                Return (\_SB.IETM.CTOK (S6HP))
            }
        }
    }

    Scope (\_SB.IETM)
    {
        Name (TRT0, Package (0x02)
        {
            Package (0x08)
            {
                \_SB.PC00.TCPU, 
                \_SB.PC00.LPCB.H_EC.SEN2, 
                0x28, 
                0x64, 
                Zero, 
                Zero, 
                Zero, 
                Zero
            }, 

            Package (0x08)
            {
                \_SB.PC00.LPCB.H_EC.CHRG, 
                \_SB.PC00.LPCB.H_EC.SEN4, 
                0x14, 
                0xC8, 
                Zero, 
                Zero, 
                Zero, 
                Zero
            }
        })
        Method (_TRT, 0, NotSerialized)  // _TRT: Thermal Relationship Table
        {
            Return (TRT0) /* \_SB_.IETM.TRT0 */
        }
    }

    Scope (\_SB.IETM)
    {
        Name (PTTL, 0x14)
        Name (PSVT, Package (0x05)
        {
            0x02, 
            Package (0x0C)
            {
                \_SB.PC00.LPCB.H_EC.CHRG, 
                \_SB.PC00.LPCB.H_EC.SEN3, 
                One, 
                0xC8, 
                0x0C6E, 
                0x0E, 
                0x000A0000, 
                "MAX", 
                One, 
                0x0A, 
                0x0A, 
                Zero
            }, 

            Package (0x0C)
            {
                \_SB.PC00.LPCB.H_EC.CHRG, 
                \_SB.PC00.LPCB.H_EC.SEN3, 
                One, 
                0xC8, 
                0x0CA0, 
                0x0E, 
                0x000A0000, 
                One, 
                One, 
                0x0A, 
                0x0A, 
                Zero
            }, 

            Package (0x0C)
            {
                \_SB.PC00.LPCB.H_EC.CHRG, 
                \_SB.PC00.LPCB.H_EC.SEN3, 
                One, 
                0xC8, 
                0x0CD2, 
                0x0E, 
                0x000A0000, 
                0x02, 
                One, 
                0x0A, 
                0x0A, 
                Zero
            }, 

            Package (0x0C)
            {
                \_SB.PC00.LPCB.H_EC.CHRG, 
                \_SB.PC00.LPCB.H_EC.SEN3, 
                One, 
                0xC8, 
                0x0D36, 
                0x0E, 
                0x000A0000, 
                "MIN", 
                One, 
                0x0A, 
                0x0A, 
                Zero
            }
        })
    }

    Scope (\_SB.IETM)
    {
        Name (ART1, Package (0x06)
        {
            Zero, 
            Package (0x0D)
            {
                \_SB.PC00.LPCB.H_EC.TFN1, 
                \_SB.PC00.TCPU, 
                0x64, 
                0x50, 
                0x3C, 
                0x28, 
                0x1E, 
                0x14, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF
            }, 

            Package (0x0D)
            {
                \_SB.PC00.LPCB.H_EC.TFN1, 
                \_SB.PC00.LPCB.H_EC.SEN2, 
                0x64, 
                0x50, 
                0x3C, 
                0x1E, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF
            }, 

            Package (0x0D)
            {
                \_SB.PC00.LPCB.H_EC.TFN1, 
                \_SB.PC00.LPCB.H_EC.SEN3, 
                0x64, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0x50, 
                0x3C, 
                0x1E, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF
            }, 

            Package (0x0D)
            {
                \_SB.PC00.LPCB.H_EC.TFN1, 
                \_SB.PC00.LPCB.H_EC.SEN4, 
                0x64, 
                0x50, 
                0x3C, 
                0x1E, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF
            }, 

            Package (0x0D)
            {
                \_SB.PC00.LPCB.H_EC.TFN1, 
                \_SB.PC00.LPCB.H_EC.SEN5, 
                0x64, 
                0x50, 
                0x3C, 
                0x1E, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF
            }
        })
        Name (ART0, Package (0x06)
        {
            Zero, 
            Package (0x0D)
            {
                \_SB.PC00.LPCB.H_EC.TFN1, 
                \_SB.PC00.TCPU, 
                0x64, 
                0x64, 
                0x50, 
                0x32, 
                0x28, 
                0x1E, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF
            }, 

            Package (0x0D)
            {
                \_SB.PC00.LPCB.H_EC.TFN1, 
                \_SB.PC00.LPCB.H_EC.SEN2, 
                0x64, 
                0x50, 
                0x32, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF
            }, 

            Package (0x0D)
            {
                \_SB.PC00.LPCB.H_EC.TFN1, 
                \_SB.PC00.LPCB.H_EC.SEN3, 
                0x64, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0x64, 
                0x50, 
                0x32, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF
            }, 

            Package (0x0D)
            {
                \_SB.PC00.LPCB.H_EC.TFN1, 
                \_SB.PC00.LPCB.H_EC.SEN4, 
                0x64, 
                0x64, 
                0x50, 
                0x32, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF
            }, 

            Package (0x0D)
            {
                \_SB.PC00.LPCB.H_EC.TFN1, 
                \_SB.PC00.LPCB.H_EC.SEN5, 
                0x64, 
                0x64, 
                0x50, 
                0x32, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF, 
                0xFFFFFFFF
            }
        })
        Method (_ART, 0, NotSerialized)  // _ART: Active Cooling Relationship Table
        {
            If (\_SB.PC00.LPCB.H_EC.SEN3.CTYP)
            {
                Return (ART1) /* \_SB_.IETM.ART1 */
            }
            Else
            {
                Return (ART0) /* \_SB_.IETM.ART0 */
            }
        }
    }

    Scope (\_SB.IETM)
    {
        Name (DP2P, Package (0x01)
        {
            ToUUID ("9e04115a-ae87-4d1c-9500-0f3e340bfe75") /* Unknown UUID */
        })
        Name (DPSP, Package (0x01)
        {
            ToUUID ("42a441d6-ae6a-462b-a84b-4a8ce79027d3") /* Unknown UUID */
        })
        Name (DASP, Package (0x01)
        {
            ToUUID ("3a95c389-e4b8-4629-a526-c52c88626bae") /* Unknown UUID */
        })
        Name (DA2P, Package (0x01)
        {
            ToUUID ("0e56fab6-bdfc-4e8c-8246-40ecfd4d74ea") /* Unknown UUID */
        })
        Name (DCSP, Package (0x01)
        {
            ToUUID ("97c68ae7-15fa-499c-b8c9-5da81d606e0a") /* Unknown UUID */
        })
        Name (RFIP, Package (0x01)
        {
            ToUUID ("c4ce1849-243a-49f3-b8d5-f97002f38e6a") /* Unknown UUID */
        })
        Name (POBP, Package (0x01)
        {
            ToUUID ("f5a35014-c209-46a4-993a-eb56de7530a1") /* Unknown UUID */
        })
        Name (DAPP, Package (0x01)
        {
            ToUUID ("63be270f-1c11-48fd-a6f7-3af253ff3e2d") /* Unknown UUID */
        })
        Name (DVSP, Package (0x01)
        {
            ToUUID ("6ed722a7-9240-48a5-b479-31eef723d7cf") /* Unknown UUID */
        })
        Name (DPID, Package (0x01)
        {
            ToUUID ("42496e14-bc1b-46e8-a798-ca915464426f") /* Unknown UUID */
        })
    }

    Scope (\_SB.IETM)
    {
        Method (TEVT, 2, Serialized)
        {
            Switch (ToInteger (Arg0))
            {
                Case ("IETM")
                {
                    Notify (\_SB.IETM, Arg1)
                }
                Case ("TCPU")
                {
                    Notify (\_SB.PC00.TCPU, Arg1)
                }
                Case ("TPCH")
                {
                    Notify (\_SB.TPCH, Arg1)
                }

            }

            If (\ECON)
            {
                Switch (ToInteger (Arg0))
                {
                    Case ("CHRG")
                    {
                        Notify (\_SB.PC00.LPCB.H_EC.CHRG, Arg1)
                    }
                    Case ("DGPU")
                    {
                        Notify (\_SB.PC00.LPCB.H_EC.DGPU, Arg1)
                    }
                    Case ("SEN2")
                    {
                        Notify (\_SB.PC00.LPCB.H_EC.SEN2, Arg1)
                    }
                    Case ("SEN3")
                    {
                        Notify (\_SB.PC00.LPCB.H_EC.SEN3, Arg1)
                    }
                    Case ("SEN4")
                    {
                        Notify (\_SB.PC00.LPCB.H_EC.SEN4, Arg1)
                    }
                    Case ("SEN5")
                    {
                        Notify (\_SB.PC00.LPCB.H_EC.SEN5, Arg1)
                    }
                    Case ("TFN1")
                    {
                        Notify (\_SB.PC00.LPCB.H_EC.TFN1, Arg1)
                    }
                    Case ("TFN2")
                    {
                        Notify (\_SB.PC00.LPCB.H_EC.TFN2, Arg1)
                    }
                    Case ("TFN3")
                    {
                        Notify (\_SB.PC00.LPCB.H_EC.TFN3, Arg1)
                    }
                    Case ("TPWR")
                    {
                        Notify (\_SB.TPWR, Arg1)
                    }

                }
            }
        }
    }

    Scope (\_SB.IETM)
    {
        Method (GDDV, 0, Serialized)
        {
            Switch (ToInteger (PLID))
            {
                Case (Package (0x01)
                    {
                        0x1B
                    }

)
                {
                    Return (Package (0x01)
                    {
                        Buffer (0x044B)
                        {
                            /* 0000 */  0xE5, 0x1F, 0x94, 0x00, 0x00, 0x00, 0x00, 0x02,  // ........
                            /* 0008 */  0x00, 0x00, 0x00, 0x40, 0x67, 0x64, 0x64, 0x76,  // ...@gddv
                            /* 0010 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0018 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0020 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0028 */  0x00, 0x00, 0x00, 0x00, 0x4F, 0x45, 0x4D, 0x20,  // ....OEM 
                            /* 0030 */  0x45, 0x78, 0x70, 0x6F, 0x72, 0x74, 0x65, 0x64,  // Exported
                            /* 0038 */  0x20, 0x44, 0x61, 0x74, 0x61, 0x56, 0x61, 0x75,  //  DataVau
                            /* 0040 */  0x6C, 0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // lt......
                            /* 0048 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0050 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0058 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0060 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0068 */  0x00, 0x00, 0x00, 0x00, 0x80, 0x4B, 0xF8, 0xA1,  // .....K..
                            /* 0070 */  0xDB, 0x42, 0xBD, 0x7D, 0xCF, 0x35, 0x88, 0x3A,  // .B.}.5.:
                            /* 0078 */  0xB5, 0x36, 0x0E, 0x52, 0xE1, 0x1D, 0x9C, 0x57,  // .6.R...W
                            /* 0080 */  0x8C, 0xD6, 0x5D, 0xFE, 0xBD, 0x33, 0x77, 0x1D,  // ..]..3w.
                            /* 0088 */  0x06, 0x96, 0x98, 0xE8, 0xB7, 0x03, 0x00, 0x00,  // ........
                            /* 0090 */  0x52, 0x45, 0x50, 0x4F, 0x5D, 0x00, 0x00, 0x00,  // REPO]...
                            /* 0098 */  0x01, 0x55, 0x4D, 0x00, 0x00, 0x00, 0x00, 0x00,  // .UM.....
                            /* 00A0 */  0x00, 0x00, 0x72, 0x87, 0xCD, 0xFF, 0x6D, 0x24,  // ..r...m$
                            /* 00A8 */  0x47, 0xDB, 0x3D, 0x24, 0x92, 0xB4, 0x16, 0x6F,  // G.=$...o
                            /* 00B0 */  0x45, 0xD8, 0xC3, 0xF5, 0x66, 0x14, 0x9F, 0x22,  // E...f.."
                            /* 00B8 */  0xD7, 0xF7, 0xDE, 0x67, 0x90, 0x9A, 0xA2, 0x0D,  // ...g....
                            /* 00C0 */  0x39, 0x25, 0xAD, 0xC3, 0x1A, 0xAD, 0x52, 0x0B,  // 9%....R.
                            /* 00C8 */  0x75, 0x38, 0xE1, 0xA4, 0x14, 0x44, 0x0F, 0xD3,  // u8...D..
                            /* 00D0 */  0x8E, 0xF2, 0xC3, 0x2A, 0xAE, 0xE5, 0x63, 0x97,  // ...*..c.
                            /* 00D8 */  0x9F, 0x3E, 0x8A, 0x8F, 0x8F, 0x5D, 0xFD, 0x8E,  // .>...]..
                            /* 00E0 */  0x1F, 0x7A, 0x9A, 0xE6, 0x99, 0x3C, 0xD4, 0xDE,  // .z...<..
                            /* 00E8 */  0x94, 0xC9, 0x7C, 0xAF, 0x73, 0xD4, 0x50, 0xA9,  // ..|.s.P.
                            /* 00F0 */  0x57, 0x95, 0x12, 0xD5, 0x5E, 0x96, 0x0D, 0x5A,  // W...^..Z
                            /* 00F8 */  0xD5, 0x6B, 0xAE, 0x06, 0x48, 0x5D, 0x6D, 0x66,  // .k..H]mf
                            /* 0100 */  0x89, 0x37, 0x9D, 0x50, 0xA4, 0x2C, 0xD0, 0x17,  // .7.P.,..
                            /* 0108 */  0x20, 0x5D, 0x3B, 0x32, 0x85, 0xF2, 0x56, 0xD4,  //  ];2..V.
                            /* 0110 */  0x7D, 0xDE, 0x14, 0x62, 0x32, 0xED, 0xB7, 0x4E,  // }..b2..N
                            /* 0118 */  0x8D, 0x3A, 0xC5, 0x46, 0x57, 0xAC, 0xDF, 0x56,  // .:.FW..V
                            /* 0120 */  0xE7, 0xDF, 0x79, 0xA9, 0x28, 0x8B, 0x60, 0x7B,  // ..y.(.`{
                            /* 0128 */  0x4B, 0xD6, 0x10, 0x98, 0x82, 0x99, 0x7C, 0xDA,  // K.....|.
                            /* 0130 */  0x79, 0x9D, 0xCC, 0x02, 0xEB, 0xF9, 0x9E, 0x60,  // y......`
                            /* 0138 */  0x25, 0x9D, 0x76, 0x60, 0xD8, 0xFC, 0x35, 0x6D,  // %.v`..5m
                            /* 0140 */  0x06, 0x99, 0x04, 0x80, 0xD5, 0x80, 0xAD, 0x42,  // .......B
                            /* 0148 */  0xDB, 0x95, 0x47, 0xD4, 0x0B, 0xE9, 0x47, 0x21,  // ..G...G!
                            /* 0150 */  0x17, 0xFE, 0xD5, 0x3D, 0x80, 0x12, 0x29, 0x3A,  // ...=..):
                            /* 0158 */  0x19, 0xFF, 0x8D, 0xE0, 0x11, 0x15, 0x20, 0xE7,  // ...... .
                            /* 0160 */  0x72, 0x01, 0x4F, 0xC3, 0xE7, 0x82, 0xF5, 0xEA,  // r.O.....
                            /* 0168 */  0x9A, 0xCB, 0xC6, 0x82, 0x64, 0x24, 0x46, 0x78,  // ....d$Fx
                            /* 0170 */  0xA1, 0xBC, 0xDB, 0x69, 0xCA, 0x72, 0xC8, 0x70,  // ...i.r.p
                            /* 0178 */  0x07, 0x44, 0x5A, 0x38, 0x20, 0xF6, 0x46, 0x68,  // .DZ8 .Fh
                            /* 0180 */  0x1B, 0x41, 0x95, 0x8D, 0x77, 0x35, 0x24, 0x28,  // .A..w5$(
                            /* 0188 */  0x0F, 0xF8, 0xA9, 0x92, 0xBF, 0x4C, 0x83, 0xED,  // .....L..
                            /* 0190 */  0xAB, 0x07, 0xF0, 0x72, 0xCC, 0x03, 0x8B, 0xE3,  // ...r....
                            /* 0198 */  0xAE, 0x22, 0xE8, 0x53, 0x25, 0x5D, 0xF7, 0x4C,  // .".S%].L
                            /* 01A0 */  0xFF, 0xAF, 0x9C, 0x79, 0x94, 0xE3, 0x48, 0xC2,  // ...y..H.
                            /* 01A8 */  0xFB, 0x46, 0x03, 0x67, 0xCA, 0xAA, 0xB2, 0x86,  // .F.g....
                            /* 01B0 */  0xF0, 0x1D, 0x7B, 0x51, 0x90, 0xE8, 0x89, 0x4D,  // ..{Q...M
                            /* 01B8 */  0xB7, 0x73, 0x63, 0xA9, 0x9A, 0x46, 0xE0, 0x9F,  // .sc..F..
                            /* 01C0 */  0xB7, 0x1A, 0x86, 0xD0, 0x17, 0x4F, 0x83, 0x9A,  // .....O..
                            /* 01C8 */  0x72, 0x18, 0x1D, 0x0E, 0xFC, 0x05, 0xE9, 0x81,  // r.......
                            /* 01D0 */  0x57, 0xA8, 0xB2, 0xE7, 0xF7, 0x0E, 0x81, 0x13,  // W.......
                            /* 01D8 */  0xE8, 0xC1, 0x02, 0x1A, 0xD8, 0x4B, 0x67, 0x9D,  // .....Kg.
                            /* 01E0 */  0x46, 0x2D, 0xFC, 0xF5, 0xDC, 0x42, 0x31, 0xE1,  // F-...B1.
                            /* 01E8 */  0x79, 0xDB, 0x3F, 0x8A, 0x38, 0x9D, 0xB7, 0x0C,  // y.?.8...
                            /* 01F0 */  0xC8, 0x5C, 0x7C, 0x0D, 0xED, 0xA9, 0xB0, 0x7D,  // .\|....}
                            /* 01F8 */  0x28, 0xF7, 0xB7, 0x7A, 0x96, 0x41, 0xEA, 0x9D,  // (..z.A..
                            /* 0200 */  0x20, 0x6E, 0x6E, 0xA2, 0xBB, 0x32, 0x98, 0xCD,  //  nn..2..
                            /* 0208 */  0x3F, 0x79, 0x6F, 0x5C, 0x12, 0xAD, 0x67, 0xA7,  // ?yo\..g.
                            /* 0210 */  0xE9, 0xC6, 0x50, 0x57, 0x09, 0x16, 0x05, 0x65,  // ..PW...e
                            /* 0218 */  0x02, 0x2A, 0xDE, 0x84, 0xE6, 0xCC, 0x90, 0xD8,  // .*......
                            /* 0220 */  0x61, 0x84, 0x14, 0xB0, 0x07, 0xC8, 0xE3, 0x45,  // a......E
                            /* 0228 */  0x04, 0xA8, 0xE0, 0x47, 0x0D, 0xFC, 0x5D, 0xE7,  // ...G..].
                            /* 0230 */  0x44, 0x38, 0xB9, 0x34, 0xF8, 0x67, 0xC0, 0x70,  // D8.4.g.p
                            /* 0238 */  0xE8, 0xD3, 0x37, 0xAD, 0x01, 0x9A, 0x2D, 0xEF,  // ..7...-.
                            /* 0240 */  0xD4, 0x61, 0x67, 0x7A, 0x89, 0x60, 0xE9, 0x6A,  // .agz.`.j
                            /* 0248 */  0x18, 0x56, 0x6F, 0x0B, 0x47, 0xB8, 0xA5, 0x1A,  // .Vo.G...
                            /* 0250 */  0xA5, 0xC6, 0x6C, 0x44, 0xF7, 0xC2, 0x75, 0x77,  // ..lD..uw
                            /* 0258 */  0x69, 0x8B, 0xC5, 0xD1, 0x4E, 0xEF, 0x08, 0x1F,  // i...N...
                            /* 0260 */  0x2C, 0xE6, 0xF0, 0x46, 0x65, 0x81, 0xD0, 0xB7,  // ,..Fe...
                            /* 0268 */  0x69, 0x60, 0x9A, 0xF7, 0xE4, 0xCE, 0xCC, 0x04,  // i`......
                            /* 0270 */  0x4F, 0x4B, 0xA3, 0x1C, 0xF3, 0x1F, 0x82, 0x03,  // OK......
                            /* 0278 */  0x5F, 0x47, 0xCF, 0x58, 0xD5, 0xA9, 0x00, 0x27,  // _G.X...'
                            /* 0280 */  0xAD, 0x38, 0x7F, 0xB9, 0x0A, 0xEC, 0xD6, 0xFA,  // .8......
                            /* 0288 */  0xF1, 0xAB, 0x36, 0x1F, 0xF7, 0x90, 0x48, 0xDB,  // ..6...H.
                            /* 0290 */  0x07, 0x3A, 0x50, 0xAB, 0x1D, 0x83, 0x28, 0x51,  // .:P...(Q
                            /* 0298 */  0xC7, 0x8E, 0x97, 0x77, 0x66, 0x52, 0x68, 0x56,  // ...wfRhV
                            /* 02A0 */  0x2F, 0x04, 0xEA, 0xB1, 0xDF, 0x49, 0xDF, 0x9F,  // /....I..
                            /* 02A8 */  0xC2, 0x2D, 0x05, 0x9B, 0x1C, 0xC3, 0x11, 0x16,  // .-......
                            /* 02B0 */  0xD3, 0xB0, 0xA2, 0x6B, 0x6B, 0xCC, 0xEF, 0x3A,  // ...kk..:
                            /* 02B8 */  0x5F, 0xEA, 0x97, 0x3A, 0xB1, 0x0A, 0x10, 0xC7,  // _..:....
                            /* 02C0 */  0x86, 0x83, 0xA9, 0x85, 0x31, 0x2F, 0xBA, 0x71,  // ....1/.q
                            /* 02C8 */  0xD6, 0x85, 0xC2, 0xC3, 0x07, 0x94, 0xF0, 0x6C,  // .......l
                            /* 02D0 */  0x2C, 0xE5, 0xAF, 0x3E, 0x74, 0x0E, 0x60, 0xEB,  // ,..>t.`.
                            /* 02D8 */  0xCB, 0x50, 0x94, 0x75, 0x72, 0x85, 0xDA, 0x8C,  // .P.ur...
                            /* 02E0 */  0x25, 0x29, 0x58, 0xE4, 0x51, 0x3C, 0x80, 0x36,  // %)X.Q<.6
                            /* 02E8 */  0x37, 0x45, 0x1C, 0xBF, 0x8D, 0x13, 0x03, 0xB8,  // 7E......
                            /* 02F0 */  0x2B, 0xF0, 0xD6, 0x92, 0x97, 0xDC, 0xFA, 0x5F,  // +......_
                            /* 02F8 */  0x85, 0x98, 0xD5, 0xBB, 0x86, 0x02, 0x47, 0xDC,  // ......G.
                            /* 0300 */  0xFE, 0xC5, 0x19, 0xE5, 0x1C, 0x7C, 0x56, 0x91,  // .....|V.
                            /* 0308 */  0x7F, 0x11, 0xFC, 0xFF, 0x32, 0x9F, 0x50, 0x83,  // ....2.P.
                            /* 0310 */  0x28, 0x77, 0xAA, 0x31, 0xAA, 0x6A, 0x25, 0xA8,  // (w.1.j%.
                            /* 0318 */  0xCB, 0x16, 0x84, 0x33, 0x9E, 0x55, 0x70, 0x83,  // ...3.Up.
                            /* 0320 */  0x98, 0x50, 0x6E, 0xAD, 0xEA, 0xB8, 0x4B, 0x2A,  // .Pn...K*
                            /* 0328 */  0xF2, 0x27, 0xD7, 0x17, 0xC4, 0xD7, 0x45, 0xBF,  // .'....E.
                            /* 0330 */  0x5D, 0xDE, 0x81, 0x5E, 0xD3, 0x59, 0x60, 0x90,  // ]..^.Y`.
                            /* 0338 */  0x00, 0xE3, 0xA4, 0xB0, 0xF0, 0x0A, 0x6D, 0x20,  // ......m 
                            /* 0340 */  0xD7, 0xFF, 0x60, 0xD0, 0xCE, 0x78, 0x18, 0x61,  // ..`..x.a
                            /* 0348 */  0x38, 0x17, 0x2A, 0x7A, 0x57, 0x4A, 0x4A, 0x42,  // 8.*zWJJB
                            /* 0350 */  0xF6, 0x14, 0x16, 0x63, 0xD2, 0x35, 0x4A, 0xCE,  // ...c.5J.
                            /* 0358 */  0x52, 0x3D, 0xF4, 0x74, 0xDE, 0x6B, 0x44, 0xAB,  // R=.t.kD.
                            /* 0360 */  0x28, 0x75, 0x31, 0x0B, 0x25, 0xC5, 0xC5, 0x86,  // (u1.%...
                            /* 0368 */  0xFA, 0x74, 0xC8, 0xE0, 0xB0, 0x79, 0xD8, 0x6C,  // .t...y.l
                            /* 0370 */  0x58, 0xDB, 0x91, 0x55, 0x81, 0xDB, 0xB4, 0x71,  // X..U...q
                            /* 0378 */  0x84, 0x30, 0x2A, 0x4F, 0x67, 0x8A, 0xE3, 0x68,  // .0*Og..h
                            /* 0380 */  0x7F, 0x5D, 0xF8, 0x38, 0x99, 0x67, 0xBF, 0x8C,  // .].8.g..
                            /* 0388 */  0x5D, 0x3E, 0x7B, 0x2E, 0x72, 0x49, 0x71, 0xB9,  // ]>{.rIq.
                            /* 0390 */  0xD5, 0xA3, 0x3A, 0x4B, 0x8C, 0x5F, 0x81, 0xAA,  // ..:K._..
                            /* 0398 */  0xE3, 0x88, 0x12, 0x97, 0x1B, 0x1F, 0x81, 0x4C,  // .......L
                            /* 03A0 */  0x3D, 0x62, 0xB8, 0x1D, 0x87, 0x75, 0x55, 0x05,  // =b...uU.
                            /* 03A8 */  0xAD, 0x99, 0xA5, 0x87, 0x36, 0x42, 0xE4, 0xD3,  // ....6B..
                            /* 03B0 */  0x55, 0xD6, 0x17, 0x2C, 0x03, 0xA0, 0xB2, 0xB3,  // U..,....
                            /* 03B8 */  0x26, 0x63, 0xEA, 0x77, 0xAF, 0x25, 0xF3, 0xA9,  // &c.w.%..
                            /* 03C0 */  0xA5, 0x84, 0x06, 0xD1, 0xB1, 0xD9, 0xDD, 0xCB,  // ........
                            /* 03C8 */  0x41, 0xE2, 0xE4, 0x06, 0xE1, 0xE3, 0x58, 0xD5,  // A.....X.
                            /* 03D0 */  0xCE, 0xE4, 0x1B, 0x51, 0xED, 0xF3, 0x38, 0x5B,  // ...Q..8[
                            /* 03D8 */  0xCA, 0x8C, 0x8F, 0x6B, 0x5D, 0x04, 0xE4, 0x9D,  // ...k]...
                            /* 03E0 */  0xA5, 0x3E, 0xA9, 0x9F, 0x3B, 0xF7, 0xDA, 0xBA,  // .>..;...
                            /* 03E8 */  0xC0, 0x4A, 0xC5, 0xEC, 0x39, 0xFF, 0x43, 0xBC,  // .J..9.C.
                            /* 03F0 */  0x97, 0x80, 0x11, 0xE0, 0x52, 0xC6, 0x1F, 0xFA,  // ....R...
                            /* 03F8 */  0x57, 0xFB, 0x2F, 0xC9, 0x9B, 0x87, 0xB2, 0xDD,  // W./.....
                            /* 0400 */  0x38, 0xA9, 0xE5, 0xDB, 0x37, 0x44, 0xF6, 0x24,  // 8...7D.$
                            /* 0408 */  0x73, 0x39, 0xB1, 0xDB, 0x52, 0xA6, 0x08, 0x3F,  // s9..R..?
                            /* 0410 */  0x99, 0x9E, 0x02, 0x25, 0x3F, 0x5F, 0x6E, 0xE2,  // ...%?_n.
                            /* 0418 */  0xAC, 0x14, 0x48, 0x0F, 0xED, 0x9A, 0xC3, 0xCF,  // ..H.....
                            /* 0420 */  0xB9, 0x48, 0xEB, 0xD0, 0x55, 0xAC, 0x65, 0xF2,  // .H..U.e.
                            /* 0428 */  0x55, 0xDF, 0x6B, 0x73, 0x01, 0x37, 0x4D, 0x1E,  // U.ks.7M.
                            /* 0430 */  0x00, 0x06, 0xE4, 0xD1, 0xC6, 0xE5, 0xB8, 0x8E,  // ........
                            /* 0438 */  0xDF, 0x1E, 0xFB, 0x4E, 0x4D, 0xFC, 0x60, 0x59,  // ...NM.`Y
                            /* 0440 */  0x01, 0x5A, 0xD2, 0xCB, 0xD7, 0x26, 0x76, 0xE3,  // .Z...&v.
                            /* 0448 */  0xA6, 0x5B, 0x5E                                 // .[^
                        }
                    })
                }
                Default
                {
                    Return (Package (0x01)
                    {
                        Buffer (0x055D)
                        {
                            /* 0000 */  0xE5, 0x1F, 0x94, 0x00, 0x00, 0x00, 0x00, 0x02,  // ........
                            /* 0008 */  0x00, 0x00, 0x00, 0x40, 0x67, 0x64, 0x64, 0x76,  // ...@gddv
                            /* 0010 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0018 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0020 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0028 */  0x00, 0x00, 0x00, 0x00, 0x4F, 0x45, 0x4D, 0x20,  // ....OEM 
                            /* 0030 */  0x45, 0x78, 0x70, 0x6F, 0x72, 0x74, 0x65, 0x64,  // Exported
                            /* 0038 */  0x20, 0x44, 0x61, 0x74, 0x61, 0x56, 0x61, 0x75,  //  DataVau
                            /* 0040 */  0x6C, 0x74, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // lt......
                            /* 0048 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0050 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0058 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0060 */  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,  // ........
                            /* 0068 */  0x00, 0x00, 0x00, 0x00, 0x37, 0xB9, 0x9B, 0xB6,  // ....7...
                            /* 0070 */  0xA2, 0xD0, 0x90, 0xA1, 0x75, 0xB9, 0x39, 0x77,  // ....u.9w
                            /* 0078 */  0xFE, 0x14, 0x39, 0x25, 0x4A, 0x37, 0xC0, 0xD9,  // ..9%J7..
                            /* 0080 */  0x94, 0x0B, 0x6B, 0x19, 0x37, 0x34, 0xC4, 0xEE,  // ..k.74..
                            /* 0088 */  0xE4, 0x74, 0x38, 0xDA, 0xC9, 0x04, 0x00, 0x00,  // .t8.....
                            /* 0090 */  0x52, 0x45, 0x50, 0x4F, 0x5D, 0x00, 0x00, 0x00,  // REPO]...
                            /* 0098 */  0x01, 0xB4, 0x52, 0x00, 0x00, 0x00, 0x00, 0x00,  // ..R.....
                            /* 00A0 */  0x00, 0x00, 0x72, 0x87, 0xCD, 0xFF, 0x6D, 0x24,  // ..r...m$
                            /* 00A8 */  0x47, 0xDB, 0x3D, 0x24, 0x92, 0xB4, 0x16, 0x6F,  // G.=$...o
                            /* 00B0 */  0x45, 0xD8, 0xC3, 0xF5, 0x66, 0x14, 0x9F, 0x22,  // E...f.."
                            /* 00B8 */  0xD7, 0xF7, 0xDE, 0x67, 0x90, 0x9A, 0xA2, 0x0D,  // ...g....
                            /* 00C0 */  0x39, 0x25, 0xAD, 0xC3, 0x1A, 0xAD, 0x52, 0x0B,  // 9%....R.
                            /* 00C8 */  0x75, 0x38, 0xE1, 0xA4, 0x14, 0x43, 0x99, 0x61,  // u8...C.a
                            /* 00D0 */  0xE6, 0xBC, 0x27, 0x7F, 0xEE, 0xBD, 0xB3, 0x64,  // ..'....d
                            /* 00D8 */  0x15, 0x9C, 0x0C, 0x50, 0x7E, 0x6D, 0x5F, 0x74,  // ...P~m_t
                            /* 00E0 */  0xF3, 0xBD, 0x52, 0x70, 0x91, 0x6D, 0x81, 0x5D,  // ..Rp.m.]
                            /* 00E8 */  0x50, 0xD7, 0x09, 0x4D, 0x48, 0x84, 0xF5, 0x60,  // P..MH..`
                            /* 00F0 */  0x93, 0x5C, 0x34, 0xE7, 0x5E, 0x34, 0x5E, 0x05,  // .\4.^4^.
                            /* 00F8 */  0x25, 0xFC, 0xD9, 0xF9, 0x9B, 0x26, 0x4B, 0x61,  // %....&Ka
                            /* 0100 */  0x61, 0xED, 0x02, 0x46, 0xB9, 0xFA, 0x75, 0xF6,  // a..F..u.
                            /* 0108 */  0xC7, 0x8E, 0x75, 0x39, 0x28, 0x4A, 0x9C, 0x77,  // ..u9(J.w
                            /* 0110 */  0xB1, 0x0D, 0x0C, 0x5C, 0xC5, 0x91, 0x85, 0x4A,  // ...\...J
                            /* 0118 */  0x1C, 0x8D, 0xE4, 0x7E, 0xB0, 0x56, 0x05, 0xD6,  // ...~.V..
                            /* 0120 */  0x59, 0x28, 0xB2, 0x51, 0xFE, 0x0C, 0xFA, 0xE5,  // Y(.Q....
                            /* 0128 */  0x01, 0xA3, 0x91, 0x86, 0x68, 0x4A, 0xA4, 0xF2,  // ....hJ..
                            /* 0130 */  0x89, 0xBA, 0x8E, 0xCC, 0x87, 0x9D, 0xAD, 0x3B,  // .......;
                            /* 0138 */  0x01, 0x23, 0x92, 0xE8, 0x1A, 0xCA, 0x4E, 0x2B,  // .#....N+
                            /* 0140 */  0x9A, 0x45, 0x9D, 0x75, 0x80, 0x45, 0x6A, 0x0D,  // .E.u.Ej.
                            /* 0148 */  0x8F, 0x62, 0xD1, 0x80, 0x56, 0xD0, 0xB0, 0xCA,  // .b..V...
                            /* 0150 */  0x1A, 0xB8, 0x06, 0x25, 0xEF, 0xA6, 0xC8, 0xDB,  // ...%....
                            /* 0158 */  0xDA, 0xB4, 0xCA, 0x75, 0x47, 0x17, 0xCA, 0x32,  // ...uG..2
                            /* 0160 */  0x74, 0xAD, 0xA8, 0x97, 0x2E, 0xED, 0x82, 0x2C,  // t......,
                            /* 0168 */  0x76, 0xEE, 0x32, 0x2F, 0x8F, 0x32, 0x27, 0x23,  // v.2/.2'#
                            /* 0170 */  0xB8, 0x8A, 0xD8, 0x47, 0x49, 0x40, 0x0F, 0xA8,  // ...GI@..
                            /* 0178 */  0x30, 0x14, 0xD9, 0xD5, 0xA7, 0x88, 0x6E, 0x3C,  // 0.....n<
                            /* 0180 */  0xDC, 0x4B, 0xB5, 0x3E, 0x15, 0x98, 0x62, 0xDB,  // .K.>..b.
                            /* 0188 */  0xD5, 0x56, 0x25, 0x4E, 0x22, 0x47, 0x7F, 0x80,  // .V%N"G..
                            /* 0190 */  0x65, 0x43, 0x2E, 0xA0, 0xD9, 0xBF, 0x33, 0x50,  // eC....3P
                            /* 0198 */  0xE7, 0x67, 0x8F, 0x8E, 0xC7, 0x56, 0x57, 0x83,  // .g...VW.
                            /* 01A0 */  0xB6, 0x4C, 0x10, 0xC0, 0x99, 0xDB, 0x56, 0xD5,  // .L....V.
                            /* 01A8 */  0x3A, 0xA0, 0x50, 0xC8, 0x27, 0xA2, 0xBE, 0xAF,  // :.P.'...
                            /* 01B0 */  0xCC, 0xD9, 0x23, 0x82, 0x4B, 0x2E, 0xDA, 0xF0,  // ..#.K...
                            /* 01B8 */  0x9C, 0xE9, 0xC1, 0x97, 0x8F, 0x4A, 0x47, 0x3F,  // .....JG?
                            /* 01C0 */  0x91, 0x10, 0xD2, 0xD6, 0x4C, 0xDE, 0x12, 0xC2,  // ....L...
                            /* 01C8 */  0xAD, 0xFF, 0x33, 0xBF, 0xC9, 0x43, 0x99, 0x45,  // ..3..C.E
                            /* 01D0 */  0x7C, 0xE7, 0x93, 0x1D, 0x2E, 0x7F, 0xB2, 0x1A,  // |.......
                            /* 01D8 */  0x8A, 0xAF, 0x38, 0xE5, 0x5F, 0x0C, 0xA5, 0xAE,  // ..8._...
                            /* 01E0 */  0xCB, 0xE9, 0xFD, 0x97, 0xA0, 0x27, 0xE2, 0x20,  // .....'. 
                            /* 01E8 */  0x8E, 0x87, 0xCD, 0x72, 0xE5, 0xBF, 0xB0, 0x9E,  // ...r....
                            /* 01F0 */  0xC4, 0xAC, 0xE5, 0x69, 0x84, 0xE7, 0xA1, 0xF3,  // ...i....
                            /* 01F8 */  0x36, 0x61, 0x46, 0xAC, 0xEB, 0x65, 0x44, 0x6C,  // 6aF..eDl
                            /* 0200 */  0xE3, 0xF8, 0x68, 0x9A, 0xEB, 0x15, 0xB1, 0x40,  // ..h....@
                            /* 0208 */  0xAE, 0x46, 0x44, 0x5C, 0xD1, 0xA0, 0xFE, 0x79,  // .FD\...y
                            /* 0210 */  0x32, 0x5D, 0x35, 0x3B, 0x6C, 0x11, 0x76, 0x28,  // 2]5;l.v(
                            /* 0218 */  0xFD, 0x07, 0xE6, 0xF9, 0x27, 0x2B, 0x73, 0x75,  // ....'+su
                            /* 0220 */  0xF0, 0x34, 0x92, 0xD5, 0xF7, 0x5E, 0x1E, 0xB0,  // .4...^..
                            /* 0228 */  0x7D, 0xEC, 0x90, 0x90, 0x41, 0x5E, 0x51, 0xF9,  // }...A^Q.
                            /* 0230 */  0x41, 0x14, 0x31, 0x1A, 0x07, 0xCD, 0xFB, 0xF8,  // A.1.....
                            /* 0238 */  0xD0, 0x93, 0x3B, 0xD7, 0x54, 0xB1, 0xC7, 0x03,  // ..;.T...
                            /* 0240 */  0xF2, 0x53, 0x49, 0x88, 0xD2, 0xFC, 0xCC, 0x11,  // .SI.....
                            /* 0248 */  0x25, 0x0E, 0x14, 0x35, 0x11, 0xBD, 0xFC, 0x30,  // %..5...0
                            /* 0250 */  0xD7, 0xC5, 0x34, 0x09, 0x50, 0x0C, 0x03, 0xAA,  // ..4.P...
                            /* 0258 */  0x7F, 0xA3, 0x56, 0x0B, 0x70, 0x47, 0x17, 0xF3,  // ..V.pG..
                            /* 0260 */  0xC9, 0xA6, 0x04, 0xFA, 0x91, 0x86, 0x4D, 0x3D,  // ......M=
                            /* 0268 */  0xEF, 0x4E, 0x15, 0x33, 0xA4, 0x54, 0x2B, 0xEA,  // .N.3.T+.
                            /* 0270 */  0xD8, 0x9C, 0xE6, 0xEC, 0x47, 0xF7, 0xFA, 0x40,  // ....G..@
                            /* 0278 */  0x14, 0x1C, 0xCB, 0xF0, 0xB8, 0xAD, 0x66, 0xBE,  // ......f.
                            /* 0280 */  0x91, 0xAF, 0x96, 0xD6, 0x6C, 0x95, 0x3F, 0x97,  // ....l.?.
                            /* 0288 */  0x69, 0x21, 0x23, 0x8F, 0xDF, 0xD4, 0xC3, 0xC6,  // i!#.....
                            /* 0290 */  0x6A, 0xE3, 0xE8, 0x4E, 0x3E, 0x5C, 0xFD, 0x29,  // j..N>\.)
                            /* 0298 */  0xE1, 0xD3, 0xB9, 0x74, 0x83, 0xF5, 0x1D, 0x14,  // ...t....
                            /* 02A0 */  0xD3, 0xC7, 0x6F, 0x66, 0x4D, 0x61, 0xA3, 0x20,  // ..ofMa. 
                            /* 02A8 */  0xE7, 0x57, 0x5E, 0xBB, 0xA5, 0x04, 0x7C, 0x10,  // .W^...|.
                            /* 02B0 */  0x94, 0xFD, 0xC1, 0xA1, 0xC0, 0x9A, 0xA8, 0x5E,  // .......^
                            /* 02B8 */  0x69, 0xE9, 0xBB, 0x3F, 0xA1, 0x00, 0x69, 0xEE,  // i..?..i.
                            /* 02C0 */  0xA6, 0x78, 0x95, 0x35, 0x91, 0x6F, 0x91, 0x35,  // .x.5.o.5
                            /* 02C8 */  0x65, 0x51, 0x29, 0x8F, 0x41, 0xB3, 0x6F, 0x18,  // eQ).A.o.
                            /* 02D0 */  0x0C, 0xF7, 0x5B, 0xE9, 0xB0, 0x69, 0x8E, 0xAB,  // ..[..i..
                            /* 02D8 */  0x7A, 0xD6, 0xFB, 0x17, 0x3B, 0x89, 0x84, 0x09,  // z...;...
                            /* 02E0 */  0xA5, 0x5C, 0x6D, 0x56, 0x6A, 0xF5, 0x34, 0x25,  // .\mVj.4%
                            /* 02E8 */  0xA7, 0x48, 0x72, 0xFE, 0xC0, 0x89, 0x8B, 0xDC,  // .Hr.....
                            /* 02F0 */  0xAA, 0x1A, 0xB8, 0x76, 0xC0, 0x55, 0x1E, 0xF4,  // ...v.U..
                            /* 02F8 */  0x31, 0xB0, 0x3E, 0x9B, 0x62, 0x2E, 0xA0, 0x4E,  // 1.>.b..N
                            /* 0300 */  0xDF, 0xBA, 0xA1, 0x5D, 0x5D, 0x15, 0x9A, 0x5A,  // ...]]..Z
                            /* 0308 */  0x5E, 0xC1, 0x74, 0xB9, 0x69, 0x09, 0xB5, 0x9E,  // ^.t.i...
                            /* 0310 */  0x5A, 0xF0, 0x79, 0x9B, 0x37, 0xAE, 0x37, 0xF5,  // Z.y.7.7.
                            /* 0318 */  0xC2, 0x6F, 0xF8, 0x8F, 0x47, 0x3D, 0x8E, 0xE2,  // .o..G=..
                            /* 0320 */  0xA8, 0xDA, 0x13, 0xD3, 0x46, 0xA0, 0x18, 0xA8,  // ....F...
                            /* 0328 */  0xEA, 0xA1, 0xAE, 0x05, 0x89, 0xBF, 0x5E, 0x22,  // ......^"
                            /* 0330 */  0xA0, 0x9F, 0x4D, 0x07, 0x44, 0x25, 0x40, 0xE1,  // ..M.D%@.
                            /* 0338 */  0xA4, 0x92, 0xDF, 0xBD, 0x5D, 0x97, 0x5C, 0x3C,  // ....].\<
                            /* 0340 */  0x4B, 0x76, 0x78, 0x8A, 0xE1, 0xED, 0xE6, 0x05,  // Kvx.....
                            /* 0348 */  0xBB, 0x3E, 0xE7, 0xD4, 0x4E, 0x2E, 0x2D, 0xCB,  // .>..N.-.
                            /* 0350 */  0xF6, 0x69, 0x27, 0xE4, 0x52, 0x86, 0xC4, 0x98,  // .i'.R...
                            /* 0358 */  0x24, 0x72, 0xDD, 0xAA, 0xD8, 0xD0, 0x2B, 0x57,  // $r....+W
                            /* 0360 */  0xB2, 0xB1, 0xAB, 0x40, 0x96, 0xBD, 0x7A, 0x15,  // ...@..z.
                            /* 0368 */  0x5F, 0xB9, 0x8F, 0x09, 0x70, 0x0B, 0xA1, 0xD7,  // _...p...
                            /* 0370 */  0x5E, 0xDB, 0x7C, 0xF2, 0xE6, 0x77, 0xAA, 0xAF,  // ^.|..w..
                            /* 0378 */  0x02, 0xE9, 0x26, 0xF9, 0x2B, 0x3D, 0xEF, 0x9E,  // ..&.+=..
                            /* 0380 */  0x40, 0xC0, 0x0F, 0xC4, 0x7A, 0xF8, 0x19, 0x50,  // @...z..P
                            /* 0388 */  0xF3, 0x30, 0x30, 0x10, 0x62, 0xEC, 0x9B, 0xDE,  // .00.b...
                            /* 0390 */  0x38, 0x13, 0x2D, 0x95, 0x8D, 0xEF, 0x20, 0x9B,  // 8.-... .
                            /* 0398 */  0x21, 0x55, 0x97, 0xFF, 0x70, 0x53, 0x1F, 0xE6,  // !U..pS..
                            /* 03A0 */  0x79, 0xA5, 0xD5, 0x37, 0x99, 0xE1, 0xEF, 0x75,  // y..7...u
                            /* 03A8 */  0xD4, 0xBD, 0x29, 0x28, 0xF0, 0x4D, 0x55, 0x47,  // ..)(.MUG
                            /* 03B0 */  0xFE, 0x2E, 0x3D, 0x65, 0xA1, 0xEF, 0xFB, 0x7E,  // ..=e...~
                            /* 03B8 */  0x7F, 0x46, 0x4E, 0xB6, 0xDF, 0x4D, 0x30, 0x3C,  // .FN..M0<
                            /* 03C0 */  0x75, 0x0C, 0xDC, 0x29, 0x33, 0x1F, 0x09, 0xF6,  // u..)3...
                            /* 03C8 */  0x7B, 0xB3, 0xA6, 0xF7, 0xFB, 0xD8, 0xE8, 0x31,  // {......1
                            /* 03D0 */  0xE4, 0xAA, 0xBB, 0xF4, 0x45, 0x07, 0x7B, 0x53,  // ....E.{S
                            /* 03D8 */  0x5D, 0xE6, 0x65, 0xD1, 0x5B, 0x9A, 0xAE, 0xA4,  // ].e.[...
                            /* 03E0 */  0x4D, 0x3C, 0x3D, 0xFA, 0x11, 0x4F, 0x6E, 0x6B,  // M<=..Onk
                            /* 03E8 */  0xDA, 0x04, 0x28, 0x7F, 0x39, 0x0B, 0x9E, 0xCD,  // ..(.9...
                            /* 03F0 */  0x9E, 0x3C, 0xE5, 0x98, 0xAE, 0x35, 0xB9, 0xA3,  // .<...5..
                            /* 03F8 */  0x23, 0x32, 0xD0, 0x40, 0xE6, 0xD3, 0x55, 0x36,  // #2.@..U6
                            /* 0400 */  0xB0, 0xAB, 0xC7, 0xF1, 0x0A, 0x9C, 0x37, 0x84,  // ......7.
                            /* 0408 */  0xC4, 0x3B, 0xD4, 0x43, 0x44, 0x9F, 0x79, 0xF6,  // .;.CD.y.
                            /* 0410 */  0xD0, 0xDA, 0xAA, 0x68, 0x95, 0x75, 0x78, 0xE6,  // ...h.ux.
                            /* 0418 */  0xC9, 0x22, 0xB1, 0x42, 0xA0, 0x79, 0xC8, 0x83,  // .".B.y..
                            /* 0420 */  0xF5, 0x69, 0x1D, 0x05, 0x7D, 0x84, 0x88, 0xDC,  // .i..}...
                            /* 0428 */  0x8E, 0x95, 0x97, 0xED, 0x0A, 0xEA, 0x3A, 0x56,  // ......:V
                            /* 0430 */  0x5E, 0x55, 0x41, 0xE6, 0xF9, 0x71, 0xF0, 0x3A,  // ^UA..q.:
                            /* 0438 */  0x0A, 0x83, 0xB0, 0xC3, 0x7D, 0xA3, 0xB3, 0xF3,  // ....}...
                            /* 0440 */  0xDB, 0xC0, 0x8E, 0xF6, 0x51, 0xA1, 0x10, 0xCA,  // ....Q...
                            /* 0448 */  0x72, 0x43, 0xFD, 0x4B, 0xFF, 0x86, 0x01, 0x29,  // rC.K...)
                            /* 0450 */  0x2C, 0xDC, 0x56, 0x5B, 0xA8, 0x05, 0x2C, 0x7C,  // ,.V[..,|
                            /* 0458 */  0x92, 0x41, 0x44, 0x90, 0xBA, 0xDC, 0x91, 0xBD,  // .AD.....
                            /* 0460 */  0xFF, 0xE5, 0x11, 0x1A, 0x89, 0x35, 0xF2, 0x52,  // .....5.R
                            /* 0468 */  0xAF, 0xD2, 0x6E, 0xFF, 0xE0, 0xCE, 0xA7, 0xB3,  // ..n.....
                            /* 0470 */  0xC4, 0x89, 0x69, 0xC8, 0x63, 0x04, 0x12, 0x69,  // ..i.c..i
                            /* 0478 */  0x20, 0xD8, 0x77, 0x8A, 0xCD, 0x66, 0x54, 0xE6,  //  .w..fT.
                            /* 0480 */  0x31, 0xD9, 0x33, 0xA3, 0xCC, 0xB1, 0x70, 0x5C,  // 1.3...p\
                            /* 0488 */  0x19, 0xB1, 0x04, 0x7B, 0x51, 0x0F, 0x02, 0xAD,  // ...{Q...
                            /* 0490 */  0xF4, 0xB3, 0x4E, 0x7D, 0xA8, 0x8D, 0xAF, 0xC7,  // ..N}....
                            /* 0498 */  0xEC, 0xFF, 0x1C, 0x8C, 0x5A, 0x87, 0x78, 0x49,  // ....Z.xI
                            /* 04A0 */  0x6E, 0x63, 0x78, 0x36, 0xEB, 0xF7, 0x98, 0x5B,  // ncx6...[
                            /* 04A8 */  0xFA, 0xE9, 0x69, 0xEA, 0x3E, 0x96, 0x35, 0xA8,  // ..i.>.5.
                            /* 04B0 */  0x25, 0x48, 0x50, 0x5F, 0xAE, 0x9F, 0x6D, 0xA6,  // %HP_..m.
                            /* 04B8 */  0x23, 0x97, 0x40, 0xC9, 0xF2, 0x09, 0x04, 0x3A,  // #.@....:
                            /* 04C0 */  0xEF, 0x05, 0x4E, 0x61, 0x70, 0xBB, 0x02, 0x94,  // ..Nap...
                            /* 04C8 */  0x6B, 0x28, 0xBA, 0xF3, 0x32, 0xAC, 0x48, 0x38,  // k(..2.H8
                            /* 04D0 */  0xF8, 0x09, 0x7F, 0x2E, 0xB7, 0x25, 0xD3, 0x7E,  // .....%.~
                            /* 04D8 */  0x36, 0x38, 0x43, 0xAB, 0x10, 0x12, 0xA3, 0xB1,  // 68C.....
                            /* 04E0 */  0xC9, 0xD2, 0xA9, 0x95, 0xDA, 0xCA, 0x43, 0xF8,  // ......C.
                            /* 04E8 */  0xDB, 0x5C, 0xC7, 0x10, 0xED, 0xAF, 0xEA, 0xB5,  // .\......
                            /* 04F0 */  0xD7, 0xD6, 0x83, 0xC8, 0x62, 0xEA, 0xB1, 0xBE,  // ....b...
                            /* 04F8 */  0xC6, 0xB6, 0x62, 0xD6, 0xB0, 0xAB, 0x11, 0x72,  // ..b....r
                            /* 0500 */  0xE6, 0x87, 0x56, 0x49, 0xA0, 0x87, 0x4D, 0x6B,  // ..VI..Mk
                            /* 0508 */  0xEB, 0x38, 0x90, 0xA8, 0x3D, 0x55, 0xB0, 0x6F,  // .8..=U.o
                            /* 0510 */  0x8A, 0x6C, 0x75, 0x0E, 0x2A, 0xF4, 0xCE, 0xA7,  // .lu.*...
                            /* 0518 */  0xBD, 0x7F, 0x75, 0xF7, 0xB9, 0x4F, 0xFB, 0xBB,  // ..u..O..
                            /* 0520 */  0x54, 0xB9, 0xC8, 0xD2, 0x26, 0x75, 0x57, 0x72,  // T...&uWr
                            /* 0528 */  0x71, 0xE9, 0x00, 0x6D, 0x46, 0x68, 0x93, 0x07,  // q..mFh..
                            /* 0530 */  0xFD, 0xCA, 0x4A, 0xB8, 0x70, 0x99, 0x92, 0x3F,  // ..J.p..?
                            /* 0538 */  0xB7, 0x51, 0xC6, 0xE5, 0x02, 0x57, 0x1A, 0xEF,  // .Q...W..
                            /* 0540 */  0x38, 0x8C, 0x59, 0x38, 0xAA, 0x38, 0xF5, 0x41,  // 8.Y8.8.A
                            /* 0548 */  0xCC, 0xE3, 0x3B, 0x16, 0xCF, 0xFB, 0x2E, 0xA5,  // ..;.....
                            /* 0550 */  0x6A, 0x05, 0xB8, 0xD1, 0x0E, 0x1F, 0xEB, 0x6B,  // j......k
                            /* 0558 */  0x49, 0x33, 0x4E, 0x85, 0x00                     // I3N..
                        }
                    })
                }

            }
        }

        Method (IMOK, 1, NotSerialized)
        {
            Return (Arg0)
        }
    }
}

