/*
 * Intel ACPI Component Architecture
 * AML/ASL+ Disassembler version 20251212 (64-bit version)
 * Copyright (c) 2000 - 2025 Intel Corporation
 * 
 * Disassembling to symbolic ASL+ operators
 *
 * Disassembly of ./SSDT8.dat
 *
 * Original Table Header:
 *     Signature        "SSDT"
 *     Length           0x00001F1A (7962)
 *     Revision         0x02
 *     Checksum         0x15
 *     OEM ID           "ALASKA"
 *     OEM Table ID     "Ther_Rvp"
 *     OEM Revision     0x00001000 (4096)
 *     Compiler ID      "INTL"
 *     Compiler Version 0x20200717 (538969879)
 */
DefinitionBlock ("", "SSDT", 2, "ALASKA", "Ther_Rvp", 0x00001000)
{
    External (_SB_.AAC0, UnknownObj)
    External (_SB_.ACRT, UnknownObj)
    External (_SB_.APSV, UnknownObj)
    External (_SB_.CAGS, MethodObj)    // 1 Arguments
    External (_SB_.CPID, UnknownObj)
    External (_SB_.CSD0, MethodObj)    // 1 Arguments
    External (_SB_.CSD3, MethodObj)    // 1 Arguments
    External (_SB_.GGOV, MethodObj)    // 1 Arguments
    External (_SB_.ISME, MethodObj)    // 1 Arguments
    External (_SB_.OSCO, UnknownObj)
    External (_SB_.PC00, DeviceObj)
    External (_SB_.PC00.GLAN, DeviceObj)
    External (_SB_.PC00.HDAS, DeviceObj)
    External (_SB_.PC00.HDAS.VDID, UnknownObj)
    External (_SB_.PC00.I2C0, DeviceObj)
    External (_SB_.PC00.I2C0.TPD0, DeviceObj)
    External (_SB_.PC00.I2C0.TPD0._STA, MethodObj)    // 0 Arguments
    External (_SB_.PC00.I2C0.TPL1, DeviceObj)
    External (_SB_.PC00.I2C0.TPL1._STA, MethodObj)    // 0 Arguments
    External (_SB_.PC00.I2C1, DeviceObj)
    External (_SB_.PC00.I2C1.TPL1, DeviceObj)
    External (_SB_.PC00.LPCB.H_EC.ECAV, IntObj)
    External (_SB_.PC00.LPCB.H_EC.ECMD, MethodObj)    // 1 Arguments
    External (_SB_.PC00.LPCB.H_EC.ECRD, MethodObj)    // 1 Arguments
    External (_SB_.PC00.LPCB.H_EC.ECWT, MethodObj)    // 2 Arguments
    External (_SB_.PC00.LPCB.H_EC.PECH, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.PECL, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.PENV, FieldUnitObj)
    External (_SB_.PC00.LPCB.H_EC.PLMX, FieldUnitObj)
    External (_SB_.PC00.PEG0, DeviceObj)
    External (_SB_.PC00.PEG0.CEMP, MethodObj)    // 1 Arguments
    External (_SB_.PC00.PEG0.D3HT, FieldUnitObj)
    External (_SB_.PC00.PEG0.DHDW, MethodObj)    // 0 Arguments
    External (_SB_.PC00.PEG0.DL23, MethodObj)    // 0 Arguments
    External (_SB_.PC00.PEG0.DVES, MethodObj)    // 0 Arguments
    External (_SB_.PC00.PEG0.EHDW, MethodObj)    // 0 Arguments
    External (_SB_.PC00.PEG0.HBSL, FieldUnitObj)
    External (_SB_.PC00.PEG0.L23D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.PEG0.PCPB, IntObj)
    External (_SB_.PC00.PEG0.PEGP, DeviceObj)
    External (_SB_.PC00.PEG0.PEGP.PAHC, MethodObj)    // 0 Arguments
    External (_SB_.PC00.PEG0.PRMV, IntObj)
    External (_SB_.PC00.PEG0.PRTP, IntObj)
    External (_SB_.PC00.PEG0.RD3C, IntObj)
    External (_SB_.PC00.PEG0.SLOT, IntObj)
    External (_SB_.PC00.PEG0.TMCS, IntObj)
    External (_SB_.PC00.PEG0.VDID, UnknownObj)
    External (_SB_.PC00.PEG1, DeviceObj)
    External (_SB_.PC00.PEG1.CEMP, MethodObj)    // 1 Arguments
    External (_SB_.PC00.PEG1.D3HT, FieldUnitObj)
    External (_SB_.PC00.PEG1.DGDS, UnknownObj)
    External (_SB_.PC00.PEG1.DHDW, MethodObj)    // 0 Arguments
    External (_SB_.PC00.PEG1.DL23, MethodObj)    // 0 Arguments
    External (_SB_.PC00.PEG1.DVES, MethodObj)    // 0 Arguments
    External (_SB_.PC00.PEG1.EHDW, MethodObj)    // 0 Arguments
    External (_SB_.PC00.PEG1.HBSL, FieldUnitObj)
    External (_SB_.PC00.PEG1.L23D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.PEG1.PCPB, IntObj)
    External (_SB_.PC00.PEG1.PEGP, DeviceObj)
    External (_SB_.PC00.PEG1.PEGP.DBRL, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DGD1, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DGD2, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DGD3, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DGD4, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DGD5, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DGD6, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DGD7, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DGD8, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DGD9, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DGDA, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DGDB, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DGDC, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DGDD, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DGDE, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DGDF, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DGDS, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DGDX, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.DNID, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.EDMX, UnknownObj)
    External (_SB_.PC00.PEG1.PEGP.PEGB.PEGE.DEDP, DeviceObj)
    External (_SB_.PC00.PEG1.PRMV, IntObj)
    External (_SB_.PC00.PEG1.PRTP, IntObj)
    External (_SB_.PC00.PEG1.RD3C, IntObj)
    External (_SB_.PC00.PEG1.SLOT, IntObj)
    External (_SB_.PC00.PEG1.TMCS, IntObj)
    External (_SB_.PC00.PEG1.VDID, UnknownObj)
    External (_SB_.PC00.PEG2, DeviceObj)
    External (_SB_.PC00.PEG2.CEMP, MethodObj)    // 1 Arguments
    External (_SB_.PC00.PEG2.D3HT, FieldUnitObj)
    External (_SB_.PC00.PEG2.DHDW, MethodObj)    // 0 Arguments
    External (_SB_.PC00.PEG2.DL23, MethodObj)    // 0 Arguments
    External (_SB_.PC00.PEG2.DVES, MethodObj)    // 0 Arguments
    External (_SB_.PC00.PEG2.EHDW, MethodObj)    // 0 Arguments
    External (_SB_.PC00.PEG2.HBSL, FieldUnitObj)
    External (_SB_.PC00.PEG2.L23D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.PEG2.PCPB, IntObj)
    External (_SB_.PC00.PEG2.PEGP, DeviceObj)
    External (_SB_.PC00.PEG2.PEGP.PAHC, MethodObj)    // 0 Arguments
    External (_SB_.PC00.PEG2.PRMV, IntObj)
    External (_SB_.PC00.PEG2.PRTP, IntObj)
    External (_SB_.PC00.PEG2.RD3C, IntObj)
    External (_SB_.PC00.PEG2.SLOT, IntObj)
    External (_SB_.PC00.PEG2.TMCS, IntObj)
    External (_SB_.PC00.PEG2.VDID, UnknownObj)
    External (_SB_.PC00.RP01, DeviceObj)
    External (_SB_.PC00.RP01.PRMV, IntObj)
    External (_SB_.PC00.RP01.PRTP, IntObj)
    External (_SB_.PC00.RP01.RD3C, IntObj)
    External (_SB_.PC00.RP01.SLOT, IntObj)
    External (_SB_.PC00.RP01.VDID, UnknownObj)
    External (_SB_.PC00.RP02, DeviceObj)
    External (_SB_.PC00.RP02.PRMV, IntObj)
    External (_SB_.PC00.RP02.PRTP, IntObj)
    External (_SB_.PC00.RP02.RD3C, IntObj)
    External (_SB_.PC00.RP02.SLOT, IntObj)
    External (_SB_.PC00.RP02.VDID, UnknownObj)
    External (_SB_.PC00.RP03, DeviceObj)
    External (_SB_.PC00.RP03.PRMV, IntObj)
    External (_SB_.PC00.RP03.PRTP, IntObj)
    External (_SB_.PC00.RP03.RD3C, IntObj)
    External (_SB_.PC00.RP03.SLOT, IntObj)
    External (_SB_.PC00.RP03.VDID, UnknownObj)
    External (_SB_.PC00.RP04, DeviceObj)
    External (_SB_.PC00.RP04.PRMV, IntObj)
    External (_SB_.PC00.RP04.PRTP, IntObj)
    External (_SB_.PC00.RP04.RD3C, IntObj)
    External (_SB_.PC00.RP04.SLOT, IntObj)
    External (_SB_.PC00.RP04.VDID, UnknownObj)
    External (_SB_.PC00.RP05, DeviceObj)
    External (_SB_.PC00.RP05.PRMV, IntObj)
    External (_SB_.PC00.RP05.PRTP, IntObj)
    External (_SB_.PC00.RP05.RD3C, IntObj)
    External (_SB_.PC00.RP05.SLOT, IntObj)
    External (_SB_.PC00.RP05.VDID, UnknownObj)
    External (_SB_.PC00.RP06, DeviceObj)
    External (_SB_.PC00.RP06.DL23, MethodObj)    // 0 Arguments
    External (_SB_.PC00.RP06.L23D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.RP06.LASX, UnknownObj)
    External (_SB_.PC00.RP06.PRMV, IntObj)
    External (_SB_.PC00.RP06.PRTP, IntObj)
    External (_SB_.PC00.RP06.PWRG, UnknownObj)
    External (_SB_.PC00.RP06.PXSX, DeviceObj)
    External (_SB_.PC00.RP06.RD3C, IntObj)
    External (_SB_.PC00.RP06.SCLK, UnknownObj)
    External (_SB_.PC00.RP06.SLOT, IntObj)
    External (_SB_.PC00.RP06.TB2F, UnknownObj)
    External (_SB_.PC00.RP06.TB2R, UnknownObj)
    External (_SB_.PC00.RP06.TFDI, UnknownObj)
    External (_SB_.PC00.RP06.TN2B, UnknownObj)
    External (_SB_.PC00.RP06.TR2B, UnknownObj)
    External (_SB_.PC00.RP06.TR2P, UnknownObj)
    External (_SB_.PC00.RP06.VDID, UnknownObj)
    External (_SB_.PC00.RP06.WAKG, UnknownObj)
    External (_SB_.PC00.RP06.WAKP, UnknownObj)
    External (_SB_.PC00.RP06.WWEN, UnknownObj)
    External (_SB_.PC00.RP07, DeviceObj)
    External (_SB_.PC00.RP07.PRMV, IntObj)
    External (_SB_.PC00.RP07.PRTP, IntObj)
    External (_SB_.PC00.RP07.RD3C, IntObj)
    External (_SB_.PC00.RP07.SLOT, IntObj)
    External (_SB_.PC00.RP07.VDID, UnknownObj)
    External (_SB_.PC00.RP08, DeviceObj)
    External (_SB_.PC00.RP08.CEMP, MethodObj)    // 1 Arguments
    External (_SB_.PC00.RP08.D3HT, FieldUnitObj)
    External (_SB_.PC00.RP08.DHDW, MethodObj)    // 0 Arguments
    External (_SB_.PC00.RP08.DL23, MethodObj)    // 0 Arguments
    External (_SB_.PC00.RP08.DVES, MethodObj)    // 0 Arguments
    External (_SB_.PC00.RP08.EHDW, MethodObj)    // 0 Arguments
    External (_SB_.PC00.RP08.HBSL, FieldUnitObj)
    External (_SB_.PC00.RP08.L23D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.RP08.PCPB, IntObj)
    External (_SB_.PC00.RP08.PRMV, IntObj)
    External (_SB_.PC00.RP08.PRTP, IntObj)
    External (_SB_.PC00.RP08.RD3C, IntObj)
    External (_SB_.PC00.RP08.SLOT, IntObj)
    External (_SB_.PC00.RP08.TMCS, IntObj)
    External (_SB_.PC00.RP08.VDID, UnknownObj)
    External (_SB_.PC00.RP09, DeviceObj)
    External (_SB_.PC00.RP09.CEMP, MethodObj)    // 1 Arguments
    External (_SB_.PC00.RP09.D3HT, FieldUnitObj)
    External (_SB_.PC00.RP09.DHDW, MethodObj)    // 0 Arguments
    External (_SB_.PC00.RP09.DL23, MethodObj)    // 0 Arguments
    External (_SB_.PC00.RP09.DVES, MethodObj)    // 0 Arguments
    External (_SB_.PC00.RP09.EHDW, MethodObj)    // 0 Arguments
    External (_SB_.PC00.RP09.HBSL, FieldUnitObj)
    External (_SB_.PC00.RP09.L23D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.RP09.PCPB, IntObj)
    External (_SB_.PC00.RP09.PRMV, IntObj)
    External (_SB_.PC00.RP09.PRTP, IntObj)
    External (_SB_.PC00.RP09.PXSX, DeviceObj)
    External (_SB_.PC00.RP09.PXSX.PAHC, MethodObj)    // 0 Arguments
    External (_SB_.PC00.RP09.RD3C, IntObj)
    External (_SB_.PC00.RP09.SLOT, IntObj)
    External (_SB_.PC00.RP09.TMCS, IntObj)
    External (_SB_.PC00.RP09.VDID, UnknownObj)
    External (_SB_.PC00.RP10, DeviceObj)
    External (_SB_.PC00.RP10.PRMV, IntObj)
    External (_SB_.PC00.RP10.PRTP, IntObj)
    External (_SB_.PC00.RP10.RD3C, IntObj)
    External (_SB_.PC00.RP10.SLOT, IntObj)
    External (_SB_.PC00.RP10.VDID, UnknownObj)
    External (_SB_.PC00.RP11, DeviceObj)
    External (_SB_.PC00.RP11.PRMV, IntObj)
    External (_SB_.PC00.RP11.PRTP, IntObj)
    External (_SB_.PC00.RP11.RD3C, IntObj)
    External (_SB_.PC00.RP11.SLOT, IntObj)
    External (_SB_.PC00.RP11.VDID, UnknownObj)
    External (_SB_.PC00.RP12, DeviceObj)
    External (_SB_.PC00.RP12.PRMV, IntObj)
    External (_SB_.PC00.RP12.PRTP, IntObj)
    External (_SB_.PC00.RP12.RD3C, IntObj)
    External (_SB_.PC00.RP12.SLOT, IntObj)
    External (_SB_.PC00.RP12.VDID, UnknownObj)
    External (_SB_.PC00.RP13, DeviceObj)
    External (_SB_.PC00.RP13.PRMV, IntObj)
    External (_SB_.PC00.RP13.PRTP, IntObj)
    External (_SB_.PC00.RP13.RD3C, IntObj)
    External (_SB_.PC00.RP13.SLOT, IntObj)
    External (_SB_.PC00.RP13.VDID, UnknownObj)
    External (_SB_.PC00.RP14, DeviceObj)
    External (_SB_.PC00.RP14.PRMV, IntObj)
    External (_SB_.PC00.RP14.PRTP, IntObj)
    External (_SB_.PC00.RP14.RD3C, IntObj)
    External (_SB_.PC00.RP14.SLOT, IntObj)
    External (_SB_.PC00.RP14.VDID, UnknownObj)
    External (_SB_.PC00.RP15, DeviceObj)
    External (_SB_.PC00.RP15.PRMV, IntObj)
    External (_SB_.PC00.RP15.PRTP, IntObj)
    External (_SB_.PC00.RP15.RD3C, IntObj)
    External (_SB_.PC00.RP15.SLOT, IntObj)
    External (_SB_.PC00.RP15.VDID, UnknownObj)
    External (_SB_.PC00.RP16, DeviceObj)
    External (_SB_.PC00.RP16.PRMV, IntObj)
    External (_SB_.PC00.RP16.PRTP, IntObj)
    External (_SB_.PC00.RP16.RD3C, IntObj)
    External (_SB_.PC00.RP16.SLOT, IntObj)
    External (_SB_.PC00.RP16.VDID, UnknownObj)
    External (_SB_.PC00.RP17, DeviceObj)
    External (_SB_.PC00.RP17.PRMV, IntObj)
    External (_SB_.PC00.RP17.PRTP, IntObj)
    External (_SB_.PC00.RP17.RD3C, IntObj)
    External (_SB_.PC00.RP17.SLOT, IntObj)
    External (_SB_.PC00.RP17.VDID, UnknownObj)
    External (_SB_.PC00.RP18, DeviceObj)
    External (_SB_.PC00.RP18.PRMV, IntObj)
    External (_SB_.PC00.RP18.PRTP, IntObj)
    External (_SB_.PC00.RP18.RD3C, IntObj)
    External (_SB_.PC00.RP18.SLOT, IntObj)
    External (_SB_.PC00.RP18.VDID, UnknownObj)
    External (_SB_.PC00.RP19, DeviceObj)
    External (_SB_.PC00.RP19.PRMV, IntObj)
    External (_SB_.PC00.RP19.PRTP, IntObj)
    External (_SB_.PC00.RP19.RD3C, IntObj)
    External (_SB_.PC00.RP19.SLOT, IntObj)
    External (_SB_.PC00.RP19.VDID, UnknownObj)
    External (_SB_.PC00.RP20, DeviceObj)
    External (_SB_.PC00.RP20.PRMV, IntObj)
    External (_SB_.PC00.RP20.PRTP, IntObj)
    External (_SB_.PC00.RP20.RD3C, IntObj)
    External (_SB_.PC00.RP20.SLOT, IntObj)
    External (_SB_.PC00.RP20.VDID, UnknownObj)
    External (_SB_.PC00.RP21, DeviceObj)
    External (_SB_.PC00.RP21.PRMV, IntObj)
    External (_SB_.PC00.RP21.PRTP, IntObj)
    External (_SB_.PC00.RP21.RD3C, IntObj)
    External (_SB_.PC00.RP21.SLOT, IntObj)
    External (_SB_.PC00.RP21.VDID, UnknownObj)
    External (_SB_.PC00.RP22, DeviceObj)
    External (_SB_.PC00.RP22.PRMV, IntObj)
    External (_SB_.PC00.RP22.PRTP, IntObj)
    External (_SB_.PC00.RP22.RD3C, IntObj)
    External (_SB_.PC00.RP22.SLOT, IntObj)
    External (_SB_.PC00.RP22.VDID, UnknownObj)
    External (_SB_.PC00.RP23, DeviceObj)
    External (_SB_.PC00.RP23.PRMV, IntObj)
    External (_SB_.PC00.RP23.PRTP, IntObj)
    External (_SB_.PC00.RP23.RD3C, IntObj)
    External (_SB_.PC00.RP23.SLOT, IntObj)
    External (_SB_.PC00.RP23.VDID, UnknownObj)
    External (_SB_.PC00.RP24, DeviceObj)
    External (_SB_.PC00.RP24.PRMV, IntObj)
    External (_SB_.PC00.RP24.PRTP, IntObj)
    External (_SB_.PC00.RP24.RD3C, IntObj)
    External (_SB_.PC00.RP24.SLOT, IntObj)
    External (_SB_.PC00.RP24.VDID, UnknownObj)
    External (_SB_.PC00.RP25, DeviceObj)
    External (_SB_.PC00.RP25.PRMV, IntObj)
    External (_SB_.PC00.RP25.PRTP, IntObj)
    External (_SB_.PC00.RP25.RD3C, IntObj)
    External (_SB_.PC00.RP25.SLOT, IntObj)
    External (_SB_.PC00.RP25.VDID, UnknownObj)
    External (_SB_.PC00.RP26, DeviceObj)
    External (_SB_.PC00.RP26.PRMV, IntObj)
    External (_SB_.PC00.RP26.PRTP, IntObj)
    External (_SB_.PC00.RP26.RD3C, IntObj)
    External (_SB_.PC00.RP26.SLOT, IntObj)
    External (_SB_.PC00.RP26.VDID, UnknownObj)
    External (_SB_.PC00.RP27, DeviceObj)
    External (_SB_.PC00.RP27.PRMV, IntObj)
    External (_SB_.PC00.RP27.PRTP, IntObj)
    External (_SB_.PC00.RP27.RD3C, IntObj)
    External (_SB_.PC00.RP27.SLOT, IntObj)
    External (_SB_.PC00.RP27.VDID, UnknownObj)
    External (_SB_.PC00.RP28, DeviceObj)
    External (_SB_.PC00.RP28.PRMV, IntObj)
    External (_SB_.PC00.RP28.PRTP, IntObj)
    External (_SB_.PC00.RP28.RD3C, IntObj)
    External (_SB_.PC00.RP28.SLOT, IntObj)
    External (_SB_.PC00.RP28.VDID, UnknownObj)
    External (_SB_.PC00.SAT0, DeviceObj)
    External (_SB_.PC00.SAT0.PRT0, DeviceObj)
    External (_SB_.PC00.SAT0.PRT1, DeviceObj)
    External (_SB_.PC00.SAT0.PRT2, DeviceObj)
    External (_SB_.PC00.SAT0.PRT3, DeviceObj)
    External (_SB_.PC00.SAT0.PRT4, DeviceObj)
    External (_SB_.PC00.SAT0.PRT5, DeviceObj)
    External (_SB_.PC00.SAT0.PRT6, DeviceObj)
    External (_SB_.PC00.SAT0.PRT7, DeviceObj)
    External (_SB_.PC00.UA02.BTH0, DeviceObj)
    External (_SB_.PC00.VMD0, DeviceObj)
    External (_SB_.PC00.VMD0.HBSL, UnknownObj)
    External (_SB_.PC00.VMD0.PEG0, DeviceObj)
    External (_SB_.PC00.VMD0.PEG0.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PEG0.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PEG0.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PEG1, DeviceObj)
    External (_SB_.PC00.VMD0.PEG1.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PEG1.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PEG1.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PEG2, DeviceObj)
    External (_SB_.PC00.VMD0.PEG2.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PEG2.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PEG2.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PEG3, DeviceObj)
    External (_SB_.PC00.VMD0.PEG3.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PEG3.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PEG3.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT0, DeviceObj)
    External (_SB_.PC00.VMD0.PRT0.VS3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT0.VSOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT0.VSON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT1, DeviceObj)
    External (_SB_.PC00.VMD0.PRT1.VS3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT1.VSOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT1.VSON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT2, DeviceObj)
    External (_SB_.PC00.VMD0.PRT2.VS3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT2.VSOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT2.VSON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT3, DeviceObj)
    External (_SB_.PC00.VMD0.PRT3.VS3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT3.VSOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT3.VSON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT4, DeviceObj)
    External (_SB_.PC00.VMD0.PRT4.VS3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT4.VSOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT4.VSON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT5, DeviceObj)
    External (_SB_.PC00.VMD0.PRT5.VS3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT5.VSOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT5.VSON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT6, DeviceObj)
    External (_SB_.PC00.VMD0.PRT6.VS3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT6.VSOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT6.VSON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT7, DeviceObj)
    External (_SB_.PC00.VMD0.PRT7.VS3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT7.VSOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.PRT7.VSON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP01, DeviceObj)
    External (_SB_.PC00.VMD0.RP01.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP01.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP01.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP02, DeviceObj)
    External (_SB_.PC00.VMD0.RP02.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP02.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP02.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP03, DeviceObj)
    External (_SB_.PC00.VMD0.RP03.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP03.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP03.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP04, DeviceObj)
    External (_SB_.PC00.VMD0.RP04.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP04.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP04.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP05, DeviceObj)
    External (_SB_.PC00.VMD0.RP05.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP05.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP05.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP06, DeviceObj)
    External (_SB_.PC00.VMD0.RP06.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP06.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP06.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP07, DeviceObj)
    External (_SB_.PC00.VMD0.RP07.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP07.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP07.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP08, DeviceObj)
    External (_SB_.PC00.VMD0.RP08.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP08.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP08.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP09, DeviceObj)
    External (_SB_.PC00.VMD0.RP09.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP09.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP09.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP10, DeviceObj)
    External (_SB_.PC00.VMD0.RP10.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP10.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP10.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP11, DeviceObj)
    External (_SB_.PC00.VMD0.RP11.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP11.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP11.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP12, DeviceObj)
    External (_SB_.PC00.VMD0.RP12.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP12.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP12.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP13, DeviceObj)
    External (_SB_.PC00.VMD0.RP13.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP13.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP13.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP14, DeviceObj)
    External (_SB_.PC00.VMD0.RP14.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP14.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP14.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP15, DeviceObj)
    External (_SB_.PC00.VMD0.RP15.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP15.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP15.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP16, DeviceObj)
    External (_SB_.PC00.VMD0.RP16.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP16.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP16.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP17, DeviceObj)
    External (_SB_.PC00.VMD0.RP17.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP17.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP17.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP18, DeviceObj)
    External (_SB_.PC00.VMD0.RP18.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP18.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP18.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP19, DeviceObj)
    External (_SB_.PC00.VMD0.RP19.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP19.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP19.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP20, DeviceObj)
    External (_SB_.PC00.VMD0.RP20.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP20.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP20.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP21, DeviceObj)
    External (_SB_.PC00.VMD0.RP21.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP21.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP21.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP22, DeviceObj)
    External (_SB_.PC00.VMD0.RP22.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP22.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP22.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP23, DeviceObj)
    External (_SB_.PC00.VMD0.RP23.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP23.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP23.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP24, DeviceObj)
    External (_SB_.PC00.VMD0.RP24.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP24.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP24.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP25, DeviceObj)
    External (_SB_.PC00.VMD0.RP25.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP25.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP25.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP26, DeviceObj)
    External (_SB_.PC00.VMD0.RP26.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP26.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP26.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP27, DeviceObj)
    External (_SB_.PC00.VMD0.RP27.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP27.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP27.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP28, DeviceObj)
    External (_SB_.PC00.VMD0.RP28.VPOF, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP28.VPON, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.RP28.VR3D, MethodObj)    // 0 Arguments
    External (_SB_.PC00.VMD0.VMCP, UnknownObj)
    External (_SB_.PC00.VMD0.VMR1, UnknownObj)
    External (_SB_.PC00.VMD0.VMR2, UnknownObj)
    External (_SB_.PC00.VMD0.VMR3, UnknownObj)
    External (_SB_.PC00.VMD0.VMR4, UnknownObj)
    External (_SB_.PC00.VMD0.VMS0, UnknownObj)
    External (_SB_.PC00.XDCI, DeviceObj)
    External (_SB_.PC00.XDCI.D0I3, UnknownObj)
    External (_SB_.PC00.XDCI.XDCB, UnknownObj)
    External (_SB_.PC00.XHCI, DeviceObj)
    External (_SB_.PC00.XHCI.MEMB, UnknownObj)
    External (_SB_.PC00.XHCI.RHUB, DeviceObj)
    External (_SB_.PC00.XHCI.RHUB.HS01, DeviceObj)
    External (_SB_.PC00.XHCI.RHUB.HS02, DeviceObj)
    External (_SB_.PC00.XHCI.RHUB.HS10, DeviceObj)
    External (_SB_.PC00.XHCI.RHUB.SS01, DeviceObj)
    External (_SB_.PC00.XHCI.RHUB.SS02, DeviceObj)
    External (_SB_.PR00, UnknownObj)
    External (_SB_.PR01, UnknownObj)
    External (_SB_.PR02, UnknownObj)
    External (_SB_.PR03, UnknownObj)
    External (_SB_.PR04, UnknownObj)
    External (_SB_.PR05, UnknownObj)
    External (_SB_.PR06, UnknownObj)
    External (_SB_.PR07, UnknownObj)
    External (_SB_.PR08, UnknownObj)
    External (_SB_.PR09, UnknownObj)
    External (_SB_.PR10, UnknownObj)
    External (_SB_.PR11, UnknownObj)
    External (_SB_.PR12, UnknownObj)
    External (_SB_.PR13, UnknownObj)
    External (_SB_.PR14, UnknownObj)
    External (_SB_.PR15, UnknownObj)
    External (_SB_.PR16, UnknownObj)
    External (_SB_.PR17, UnknownObj)
    External (_SB_.PR18, UnknownObj)
    External (_SB_.PR19, UnknownObj)
    External (_SB_.PR20, UnknownObj)
    External (_SB_.PR21, UnknownObj)
    External (_SB_.PR22, UnknownObj)
    External (_SB_.PR23, UnknownObj)
    External (_SB_.PR24, UnknownObj)
    External (_SB_.PR25, UnknownObj)
    External (_SB_.PR26, UnknownObj)
    External (_SB_.PR27, UnknownObj)
    External (_SB_.PR28, UnknownObj)
    External (_SB_.PR29, UnknownObj)
    External (_SB_.PR30, UnknownObj)
    External (_SB_.PR31, UnknownObj)
    External (_SB_.PSD0, MethodObj)    // 1 Arguments
    External (_SB_.PSD3, MethodObj)    // 1 Arguments
    External (_SB_.SGOV, MethodObj)    // 2 Arguments
    External (_SB_.SGRA, MethodObj)    // 2 Arguments
    External (_SB_.SHPO, MethodObj)    // 2 Arguments
    External (AC0F, IntObj)
    External (AC1F, IntObj)
    External (ACT1, IntObj)
    External (ACTT, IntObj)
    External (AUDD, FieldUnitObj)
    External (CRTT, IntObj)
    External (CTYP, IntObj)
    External (DG2P, UnknownObj)
    External (DG2R, UnknownObj)
    External (DGBA, FieldUnitObj)
    External (DGOP, FieldUnitObj)
    External (DGP2, UnknownObj)
    External (DGR2, UnknownObj)
    External (DTFS, IntObj)
    External (DTOE, IntObj)
    External (DTRC, IntObj)
    External (DTRD, IntObj)
    External (DTRO, IntObj)
    External (DVID, UnknownObj)
    External (ECON, IntObj)
    External (EDMX, UnknownObj)
    External (GBED, UnknownObj)
    External (GBEP, UnknownObj)
    External (GBES, UnknownObj)
    External (GPDI, UnknownObj)
    External (GPLI, UnknownObj)
    External (GPLP, UnknownObj)
    External (GPLR, UnknownObj)
    External (HBCL, FieldUnitObj)
    External (HBPL, FieldUnitObj)
    External (IC0D, FieldUnitObj)
    External (IC1D, FieldUnitObj)
    External (IC1S, FieldUnitObj)
    External (P1WK, FieldUnitObj)
    External (P1WP, UnknownObj)
    External (PBRS, UnknownObj)
    External (PCHS, FieldUnitObj)
    External (PCHX, IntObj)
    External (PEP0, UnknownObj)
    External (PFCP, UnknownObj)
    External (PIN_.OFF_, MethodObj)    // 1 Arguments
    External (PIN_.ON__, MethodObj)    // 1 Arguments
    External (PIN_.STA_, MethodObj)    // 1 Arguments
    External (PPDI, UnknownObj)
    External (PPLI, UnknownObj)
    External (PPLP, UnknownObj)
    External (PPLR, UnknownObj)
    External (PPSP, UnknownObj)
    External (PPSR, UnknownObj)
    External (PRST, UnknownObj)
    External (PS2P, UnknownObj)
    External (PSP2, UnknownObj)
    External (PSPE, UnknownObj)
    External (PSPR, UnknownObj)
    External (PSR2, UnknownObj)
    External (PSVT, IntObj)
    External (PSW2, UnknownObj)
    External (PSWP, UnknownObj)
    External (R8DC, UnknownObj)
    External (R8WR, UnknownObj)
    External (RCG0, IntObj)
    External (RCG1, IntObj)
    External (RPS0, IntObj)
    External (RPT0, IntObj)
    External (S0ID, UnknownObj)
    External (SATP, UnknownObj)
    External (SD2P, UnknownObj)
    External (SD2R, UnknownObj)
    External (SD5P, UnknownObj)
    External (SD5R, UnknownObj)
    External (SDP1, UnknownObj)
    External (SDP5, UnknownObj)
    External (SDPP, UnknownObj)
    External (SDR1, UnknownObj)
    External (SDR2, UnknownObj)
    External (SDR5, UnknownObj)
    External (SDRP, UnknownObj)
    External (SDS0, FieldUnitObj)
    External (SDS1, FieldUnitObj)
    External (SHSB, FieldUnitObj)
    External (SPCO, MethodObj)    // 2 Arguments
    External (SPCX, MethodObj)    // 3 Arguments
    External (SR2P, UnknownObj)
    External (SSDP, UnknownObj)
    External (SSDR, UnknownObj)
    External (STD3, FieldUnitObj)
    External (STPP, UnknownObj)
    External (TBPE, IntObj)
    External (TC1V, IntObj)
    External (TC2V, IntObj)
    External (TCNT, IntObj)
    External (TEDC, IntObj)
    External (TOFF, IntObj)
    External (TPDT, UnknownObj)
    External (TPLS, UnknownObj)
    External (TPLT, UnknownObj)
    External (TSPV, IntObj)
    External (UAMS, UnknownObj)
    External (VFN0, IntObj)
    External (VFN1, IntObj)
    External (VFN2, IntObj)
    External (VFN3, IntObj)
    External (VFN4, IntObj)
    External (VMDE, UnknownObj)
    External (VRRD, FieldUnitObj)
    External (WBRS, UnknownObj)
    External (WFCP, UnknownObj)
    External (WLWK, UnknownObj)
    External (WPRP, UnknownObj)
    External (WRTO, UnknownObj)
    External (WWKP, UnknownObj)
    External (WWMT, UnknownObj)
    External (XDCE, UnknownObj)
    External (XDST, IntObj)
    External (XHPR, UnknownObj)
    External (ZPPB, UnknownObj)

    Scope (\_TZ)
    {
        Name (ETMD, One)
        Event (FCET)
        Name (FCRN, Zero)
        Mutex (FCMT, 0x00)
        Name (CVF0, Zero)
        Name (CVF1, Zero)
        Name (CVF2, Zero)
        Name (CVF3, Zero)
        Name (CVF4, Zero)
        Mutex (FMT0, 0x00)
        Mutex (FMT1, 0x00)
        Mutex (FMT2, 0x00)
        Mutex (FMT3, 0x00)
        Mutex (FMT4, 0x00)
        PowerResource (FN00, 0x00, 0x0000)
        {
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                Local1 = Zero
                Local0 = Acquire (FMT0, 0x03E8)
                If ((Local0 == Zero))
                {
                    Local1 = CVF0 /* \_TZ_.CVF0 */
                    Release (FMT0)
                }

                Return (Local1)
            }

            Method (_ON, 0, Serialized)  // _ON_: Power On
            {
                Local0 = Acquire (FMT0, 0x03E8)
                If ((Local0 == Zero))
                {
                    CVF0 = One
                    Release (FMT0)
                }

                FNCL ()
            }

            Method (_OFF, 0, Serialized)  // _OFF: Power Off
            {
                Local0 = Acquire (FMT0, 0x03E8)
                If ((Local0 == Zero))
                {
                    CVF0 = Zero
                    Release (FMT0)
                }

                FNCL ()
            }
        }

        Device (FAN0)
        {
            Name (_HID, EisaId ("PNP0C0B") /* Fan (Thermal Solution) */)  // _HID: Hardware ID
            Name (_UID, Zero)  // _UID: Unique ID
            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                FN00
            })
        }

        PowerResource (FN01, 0x00, 0x0000)
        {
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                Local1 = Zero
                Local0 = Acquire (FMT1, 0x03E8)
                If ((Local0 == Zero))
                {
                    Local1 = CVF1 /* \_TZ_.CVF1 */
                    Release (FMT1)
                }

                Return (Local1)
            }

            Method (_ON, 0, Serialized)  // _ON_: Power On
            {
                Local0 = Acquire (FMT1, 0x03E8)
                If ((Local0 == Zero))
                {
                    CVF1 = One
                    Release (FMT1)
                }

                FNCL ()
            }

            Method (_OFF, 0, Serialized)  // _OFF: Power Off
            {
                Local0 = Acquire (FMT1, 0x03E8)
                If ((Local0 == Zero))
                {
                    CVF1 = Zero
                    Release (FMT1)
                }

                FNCL ()
            }
        }

        Device (FAN1)
        {
            Name (_HID, EisaId ("PNP0C0B") /* Fan (Thermal Solution) */)  // _HID: Hardware ID
            Name (_UID, One)  // _UID: Unique ID
            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                FN01
            })
        }

        PowerResource (FN02, 0x00, 0x0000)
        {
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                Local1 = Zero
                Local0 = Acquire (FMT2, 0x03E8)
                If ((Local0 == Zero))
                {
                    Local1 = CVF2 /* \_TZ_.CVF2 */
                    Release (FMT2)
                }

                Return (Local1)
            }

            Method (_ON, 0, Serialized)  // _ON_: Power On
            {
                Local0 = Acquire (FMT2, 0x03E8)
                If ((Local0 == Zero))
                {
                    CVF2 = One
                    Release (FMT2)
                }

                FNCL ()
            }

            Method (_OFF, 0, Serialized)  // _OFF: Power Off
            {
                Local0 = Acquire (FMT2, 0x03E8)
                If ((Local0 == Zero))
                {
                    CVF2 = Zero
                    Release (FMT2)
                }

                FNCL ()
            }
        }

        Device (FAN2)
        {
            Name (_HID, EisaId ("PNP0C0B") /* Fan (Thermal Solution) */)  // _HID: Hardware ID
            Name (_UID, 0x02)  // _UID: Unique ID
            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                FN02
            })
        }

        PowerResource (FN03, 0x00, 0x0000)
        {
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                Local1 = Zero
                Local0 = Acquire (FMT3, 0x03E8)
                If ((Local0 == Zero))
                {
                    Local1 = CVF3 /* \_TZ_.CVF3 */
                    Release (FMT3)
                }

                Return (Local1)
            }

            Method (_ON, 0, Serialized)  // _ON_: Power On
            {
                Local0 = Acquire (FMT3, 0x03E8)
                If ((Local0 == Zero))
                {
                    CVF3 = One
                    Release (FMT3)
                }

                FNCL ()
            }

            Method (_OFF, 0, Serialized)  // _OFF: Power Off
            {
                Local0 = Acquire (FMT3, 0x03E8)
                If ((Local0 == Zero))
                {
                    CVF3 = Zero
                    Release (FMT3)
                }

                FNCL ()
            }
        }

        Device (FAN3)
        {
            Name (_HID, EisaId ("PNP0C0B") /* Fan (Thermal Solution) */)  // _HID: Hardware ID
            Name (_UID, 0x03)  // _UID: Unique ID
            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                FN03
            })
        }

        PowerResource (FN04, 0x00, 0x0000)
        {
            Method (_STA, 0, Serialized)  // _STA: Status
            {
                Local1 = Zero
                Local0 = Acquire (FMT4, 0x03E8)
                If ((Local0 == Zero))
                {
                    Local1 = CVF4 /* \_TZ_.CVF4 */
                    Release (FMT4)
                }

                Return (Local1)
            }

            Method (_ON, 0, Serialized)  // _ON_: Power On
            {
                Local0 = Acquire (FMT4, 0x03E8)
                If ((Local0 == Zero))
                {
                    CVF4 = One
                    Release (FMT4)
                }

                FNCL ()
            }

            Method (_OFF, 0, Serialized)  // _OFF: Power Off
            {
                Local0 = Acquire (FMT4, 0x03E8)
                If ((Local0 == Zero))
                {
                    CVF4 = Zero
                    Release (FMT4)
                }

                FNCL ()
            }
        }

        Device (FAN4)
        {
            Name (_HID, EisaId ("PNP0C0B") /* Fan (Thermal Solution) */)  // _HID: Hardware ID
            Name (_UID, 0x04)  // _UID: Unique ID
            Name (_PR0, Package (0x01)  // _PR0: Power Resources for D0
            {
                FN04
            })
        }

        Method (FNCL, 0, NotSerialized)
        {
            Local0 = Zero
            Local1 = Zero
            Local2 = Zero
            Local3 = Zero
            Local4 = Zero
            Local5 = Acquire (FMT0, 0x03E8)
            If ((Local5 == Zero))
            {
                Local0 = CVF0 /* \_TZ_.CVF0 */
                Release (FMT0)
            }

            Local5 = Acquire (FMT1, 0x03E8)
            If ((Local5 == Zero))
            {
                Local1 = CVF1 /* \_TZ_.CVF1 */
                Release (FMT1)
            }

            Local5 = Acquire (FMT2, 0x03E8)
            If ((Local5 == Zero))
            {
                Local2 = CVF2 /* \_TZ_.CVF2 */
                Release (FMT2)
            }

            Local5 = Acquire (FMT3, 0x03E8)
            If ((Local5 == Zero))
            {
                Local3 = CVF3 /* \_TZ_.CVF3 */
                Release (FMT3)
            }

            Local5 = Acquire (FMT4, 0x03E8)
            If ((Local5 == Zero))
            {
                Local4 = CVF4 /* \_TZ_.CVF4 */
                Release (FMT4)
            }

            \VFN0 = Local0
            \VFN1 = Local1
            \VFN2 = Local2
            \VFN3 = Local3
            \VFN4 = Local4
            If (\ECON)
            {
                If ((\_SB.PC00.LPCB.H_EC.ECAV && ETMD))
                {
                    If (((Local0 != Zero) && (Local1 != Zero)))
                    {
                        \_SB.PC00.LPCB.H_EC.ECWT (AC0F, RefOf (\_SB.PC00.LPCB.H_EC.PENV))
                    }
                    ElseIf (((Local0 == Zero) && (Local1 != Zero)))
                    {
                        \_SB.PC00.LPCB.H_EC.ECWT (AC1F, RefOf (\_SB.PC00.LPCB.H_EC.PENV))
                    }
                    Else
                    {
                        \_SB.PC00.LPCB.H_EC.ECWT (Zero, RefOf (\_SB.PC00.LPCB.H_EC.PENV))
                    }

                    \_SB.PC00.LPCB.H_EC.ECMD (0x1A)
                }
            }
        }

        ThermalZone (TZ00)
        {
            Name (PTMP, 0x0BB8)
            Method (_SCP, 1, Serialized)  // _SCP: Set Cooling Policy
            {
                \CTYP = Arg0
            }

            Method (_CRT, 0, Serialized)  // _CRT: Critical Temperature
            {
                If (CondRefOf (\_SB.ACRT))
                {
                    If ((\_SB.ACRT != Zero))
                    {
                        Return ((0x0AAC + (\_SB.ACRT * 0x0A)))
                    }
                }

                Return ((0x0AAC + (\CRTT * 0x0A)))
            }

            Method (_AC0, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                If (CondRefOf (\_SB.AAC0))
                {
                    If ((\_SB.AAC0 != Zero))
                    {
                        Return ((0x0AAC + (\_SB.AAC0 * 0x0A)))
                    }
                }

                Return ((0x0AAC + (\ACTT * 0x0A)))
            }

            Method (_AC1, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return ((0x0AAC + (\ACT1 * 0x0A)))
            }

            Method (_AC2, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (((0x0AAC + (\ACT1 * 0x0A)) - 0x32))
            }

            Method (_AC3, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (((0x0AAC + (\ACT1 * 0x0A)) - 0x64))
            }

            Method (_AC4, 0, Serialized)  // _ACx: Active Cooling, x=0-9
            {
                Return (((0x0AAC + (\ACT1 * 0x0A)) - 0x96))
            }

            Name (_AL0, Package (0x01)  // _ALx: Active List, x=0-9
            {
                FAN0
            })
            Name (_AL1, Package (0x01)  // _ALx: Active List, x=0-9
            {
                FAN1
            })
            Name (_AL2, Package (0x01)  // _ALx: Active List, x=0-9
            {
                FAN2
            })
            Name (_AL3, Package (0x01)  // _ALx: Active List, x=0-9
            {
                FAN3
            })
            Name (_AL4, Package (0x01)  // _ALx: Active List, x=0-9
            {
                FAN4
            })
            Method (_TMP, 0, Serialized)  // _TMP: Temperature
            {
                If (!ETMD)
                {
                    Return (0x0BB8)
                }

                If (\ECON)
                {
                    Local0 = \_SB.PC00.LPCB.H_EC.ECRD (RefOf (\_SB.PC00.LPCB.H_EC.PLMX))
                    Local0 = (0x0AAC + (Local0 * 0x0A))
                    PTMP = Local0
                    Return (Local0)
                }

                Return (0x0BC2)
            }

            Method (_PSL, 0, Serialized)  // _PSL: Passive List
            {
                If ((\TCNT == 0x20))
                {
                    Return (Package (0x20)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13, 
                        \_SB.PR14, 
                        \_SB.PR15, 
                        \_SB.PR16, 
                        \_SB.PR17, 
                        \_SB.PR18, 
                        \_SB.PR19, 
                        \_SB.PR20, 
                        \_SB.PR21, 
                        \_SB.PR22, 
                        \_SB.PR23, 
                        \_SB.PR24, 
                        \_SB.PR25, 
                        \_SB.PR26, 
                        \_SB.PR27, 
                        \_SB.PR28, 
                        \_SB.PR29, 
                        \_SB.PR30, 
                        \_SB.PR31
                    })
                }

                If ((\TCNT == 0x1F))
                {
                    Return (Package (0x1F)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13, 
                        \_SB.PR14, 
                        \_SB.PR15, 
                        \_SB.PR16, 
                        \_SB.PR17, 
                        \_SB.PR18, 
                        \_SB.PR19, 
                        \_SB.PR20, 
                        \_SB.PR21, 
                        \_SB.PR22, 
                        \_SB.PR23, 
                        \_SB.PR24, 
                        \_SB.PR25, 
                        \_SB.PR26, 
                        \_SB.PR27, 
                        \_SB.PR28, 
                        \_SB.PR29, 
                        \_SB.PR30
                    })
                }

                If ((\TCNT == 0x1E))
                {
                    Return (Package (0x1E)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13, 
                        \_SB.PR14, 
                        \_SB.PR15, 
                        \_SB.PR16, 
                        \_SB.PR17, 
                        \_SB.PR18, 
                        \_SB.PR19, 
                        \_SB.PR20, 
                        \_SB.PR21, 
                        \_SB.PR22, 
                        \_SB.PR23, 
                        \_SB.PR24, 
                        \_SB.PR25, 
                        \_SB.PR26, 
                        \_SB.PR27, 
                        \_SB.PR28, 
                        \_SB.PR29
                    })
                }

                If ((\TCNT == 0x1D))
                {
                    Return (Package (0x1D)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13, 
                        \_SB.PR14, 
                        \_SB.PR15, 
                        \_SB.PR16, 
                        \_SB.PR17, 
                        \_SB.PR18, 
                        \_SB.PR19, 
                        \_SB.PR20, 
                        \_SB.PR21, 
                        \_SB.PR22, 
                        \_SB.PR23, 
                        \_SB.PR24, 
                        \_SB.PR25, 
                        \_SB.PR26, 
                        \_SB.PR27, 
                        \_SB.PR28
                    })
                }

                If ((\TCNT == 0x1C))
                {
                    Return (Package (0x1C)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13, 
                        \_SB.PR14, 
                        \_SB.PR15, 
                        \_SB.PR16, 
                        \_SB.PR17, 
                        \_SB.PR18, 
                        \_SB.PR19, 
                        \_SB.PR20, 
                        \_SB.PR21, 
                        \_SB.PR22, 
                        \_SB.PR23, 
                        \_SB.PR24, 
                        \_SB.PR25, 
                        \_SB.PR26, 
                        \_SB.PR27
                    })
                }

                If ((\TCNT == 0x1B))
                {
                    Return (Package (0x1B)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13, 
                        \_SB.PR14, 
                        \_SB.PR15, 
                        \_SB.PR16, 
                        \_SB.PR17, 
                        \_SB.PR18, 
                        \_SB.PR19, 
                        \_SB.PR20, 
                        \_SB.PR21, 
                        \_SB.PR22, 
                        \_SB.PR23, 
                        \_SB.PR24, 
                        \_SB.PR25, 
                        \_SB.PR26
                    })
                }

                If ((\TCNT == 0x1A))
                {
                    Return (Package (0x1A)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13, 
                        \_SB.PR14, 
                        \_SB.PR15, 
                        \_SB.PR16, 
                        \_SB.PR17, 
                        \_SB.PR18, 
                        \_SB.PR19, 
                        \_SB.PR20, 
                        \_SB.PR21, 
                        \_SB.PR22, 
                        \_SB.PR23, 
                        \_SB.PR24, 
                        \_SB.PR25
                    })
                }

                If ((\TCNT == 0x19))
                {
                    Return (Package (0x19)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13, 
                        \_SB.PR14, 
                        \_SB.PR15, 
                        \_SB.PR16, 
                        \_SB.PR17, 
                        \_SB.PR18, 
                        \_SB.PR19, 
                        \_SB.PR20, 
                        \_SB.PR21, 
                        \_SB.PR22, 
                        \_SB.PR23, 
                        \_SB.PR24
                    })
                }

                If ((\TCNT == 0x18))
                {
                    Return (Package (0x18)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13, 
                        \_SB.PR14, 
                        \_SB.PR15, 
                        \_SB.PR16, 
                        \_SB.PR17, 
                        \_SB.PR18, 
                        \_SB.PR19, 
                        \_SB.PR20, 
                        \_SB.PR21, 
                        \_SB.PR22, 
                        \_SB.PR23
                    })
                }

                If ((\TCNT == 0x17))
                {
                    Return (Package (0x17)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13, 
                        \_SB.PR14, 
                        \_SB.PR15, 
                        \_SB.PR16, 
                        \_SB.PR17, 
                        \_SB.PR18, 
                        \_SB.PR19, 
                        \_SB.PR20, 
                        \_SB.PR21, 
                        \_SB.PR22
                    })
                }

                If ((\TCNT == 0x16))
                {
                    Return (Package (0x16)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13, 
                        \_SB.PR14, 
                        \_SB.PR15, 
                        \_SB.PR16, 
                        \_SB.PR17, 
                        \_SB.PR18, 
                        \_SB.PR19, 
                        \_SB.PR20, 
                        \_SB.PR21
                    })
                }

                If ((\TCNT == 0x15))
                {
                    Return (Package (0x15)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13, 
                        \_SB.PR14, 
                        \_SB.PR15, 
                        \_SB.PR16, 
                        \_SB.PR17, 
                        \_SB.PR18, 
                        \_SB.PR19, 
                        \_SB.PR20
                    })
                }

                If ((\TCNT == 0x14))
                {
                    Return (Package (0x14)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13, 
                        \_SB.PR14, 
                        \_SB.PR15, 
                        \_SB.PR16, 
                        \_SB.PR17, 
                        \_SB.PR18, 
                        \_SB.PR19
                    })
                }

                If ((\TCNT == 0x13))
                {
                    Return (Package (0x13)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13, 
                        \_SB.PR14, 
                        \_SB.PR15, 
                        \_SB.PR16, 
                        \_SB.PR17, 
                        \_SB.PR18
                    })
                }

                If ((\TCNT == 0x12))
                {
                    Return (Package (0x12)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13, 
                        \_SB.PR14, 
                        \_SB.PR15, 
                        \_SB.PR16, 
                        \_SB.PR17
                    })
                }

                If ((\TCNT == 0x11))
                {
                    Return (Package (0x11)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13, 
                        \_SB.PR14, 
                        \_SB.PR15, 
                        \_SB.PR16
                    })
                }

                If ((\TCNT == 0x10))
                {
                    Return (Package (0x10)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13, 
                        \_SB.PR14, 
                        \_SB.PR15
                    })
                }

                If ((\TCNT == 0x0E))
                {
                    Return (Package (0x0E)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11, 
                        \_SB.PR12, 
                        \_SB.PR13
                    })
                }

                If ((\TCNT == 0x0C))
                {
                    Return (Package (0x0C)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09, 
                        \_SB.PR10, 
                        \_SB.PR11
                    })
                }

                If ((\TCNT == 0x0A))
                {
                    Return (Package (0x0A)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07, 
                        \_SB.PR08, 
                        \_SB.PR09
                    })
                }

                If ((\TCNT == 0x08))
                {
                    Return (Package (0x08)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06, 
                        \_SB.PR07
                    })
                }

                If ((\TCNT == 0x07))
                {
                    Return (Package (0x07)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05, 
                        \_SB.PR06
                    })
                }

                If ((\TCNT == 0x06))
                {
                    Return (Package (0x06)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04, 
                        \_SB.PR05
                    })
                }

                If ((\TCNT == 0x05))
                {
                    Return (Package (0x05)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03, 
                        \_SB.PR04
                    })
                }

                If ((\TCNT == 0x04))
                {
                    Return (Package (0x04)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02, 
                        \_SB.PR03
                    })
                }

                If ((\TCNT == 0x03))
                {
                    Return (Package (0x03)
                    {
                        \_SB.PR00, 
                        \_SB.PR01, 
                        \_SB.PR02
                    })
                }

                If ((\TCNT == 0x02))
                {
                    Return (Package (0x02)
                    {
                        \_SB.PR00, 
                        \_SB.PR01
                    })
                }

                Return (Package (0x01)
                {
                    \_SB.PR00
                })
            }

            Method (XPSV, 0, Serialized)
            {
                If (CondRefOf (\_SB.APSV))
                {
                    If ((\_SB.APSV != Zero))
                    {
                        Return ((0x0AAC + (\_SB.APSV * 0x0A)))
                    }
                }

                Return ((0x0AAC + (\PSVT * 0x0A)))
            }

            Method (XTC1, 0, Serialized)
            {
                Return (\TC1V) /* External reference */
            }

            Method (XTC2, 0, Serialized)
            {
                Return (\TC2V) /* External reference */
            }

            Method (XTSP, 0, Serialized)
            {
                Return (\TSPV) /* External reference */
            }
        }
    }
}

