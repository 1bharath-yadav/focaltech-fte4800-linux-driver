            ; CALL XREFS from fcn.180019340 @ +0x8b5(x), +0xa39(x)
┌ 326: fcn.18002179c (int64_t arg1, int64_t arg2);
│ `- args(rcx, rdx) vars(4:sp[0x10..0x40])
│           0x18002179c      48895c2408     mov qword [var_8h], rbx
│           0x1800217a1      48896c2410     mov qword [var_10h], rbp
│           0x1800217a6      4889742418     mov qword [var_18h], rsi
│           0x1800217ab      57             push rdi
│           0x1800217ac      4883ec30       sub rsp, 0x30
│           0x1800217b0      488b05493d..   mov rax, qword [0x180175500] ; [0x180175500:8]=0
│           0x1800217b7      8bda           mov ebx, edx               ; arg2
│           0x1800217b9      4c8b055838..   mov r8, qword [0x180065018] ; [0x180065018:8]=0x180065000 section..data
│           0x1800217c0      488be9         mov rbp, rcx               ; arg1
│           0x1800217c3      488bd1         mov rdx, rcx               ; arg1
│           0x1800217c6      33ff           xor edi, edi
│           0x1800217c8      488b0d393d..   mov rcx, qword [0x180175508] ; [0x180175508:8]=0
│           0x1800217cf      488b80d803..   mov rax, qword [rax + 0x3d8]
│           0x1800217d6      ff15740b0100   call qword [0x180032350]   ; [0x180032350:8]=0x180031050
│           0x1800217dc      488bf0         mov rsi, rax
│           0x1800217df      85db           test ebx, ebx
│       ┌─< 0x1800217e1      7410           je 0x1800217f3
│       │   0x1800217e3      488bc8         mov rcx, rax               ; int64_t arg1
│       │   0x1800217e6      e819020000     call fcn.180021a04
│       │   0x1800217eb      85c0           test eax, eax
│      ┌──< 0x1800217ed      0f89b6000000   jns 0x1800218a9
│      ││   ; CODE XREF from fcn.18002179c @ 0x1800217e1(x)
│      │└─> 0x1800217f3      8bdf           mov ebx, edi
│      │    ; CODE XREF from fcn.18002179c @ 0x18002189e(x)
│      │┌─> 0x1800217f5      488b4e20       mov rcx, qword [rsi + 0x20]
│      │╎   0x1800217f9      0fb75130       movzx edx, word [rcx + 0x30]
│      │╎   0x1800217fd      488b4928       mov rcx, qword [rcx + 0x28]
│      │╎   0x180021801      e89292ffff     call fcn.18001aa98
│      │╎   0x180021806      84c0           test al, al
│     ┌───< 0x180021808      756d           jne 0x180021877
│     ││╎   0x18002180a      488b4620       mov rax, qword [rsi + 0x20]
│     ││╎   0x18002180e      4c8d05cb67..   lea r8, str.ft_feature_FT9368_loadfirmware_LoadFW ; 0x180037fe0 ; "ft_feature_FT9368_loadfirmware_LoadFW"
│     ││╎   0x180021815      41b908010000   mov r9d, 0x108             ; 264
│     ││╎   0x18002181b      488d15e667..   lea rdx, str._Driver__I__s__d_:_start_load_app_len___d ; 0x180038008 ; "[Driver] I %s[%d]: start load app len = %d"
│     ││╎   0x180021822      0fb74820       movzx ecx, word [rax + 0x20]
│     ││╎   0x180021826      894c2420       mov dword [var_20h], ecx
│     ││╎   0x18002182a      b902000000     mov ecx, 2
│     ││╎   0x18002182f      e83c71ffff     call fcn.180018970
│     ││╎   0x180021834      488b4e20       mov rcx, qword [rsi + 0x20]
│     ││╎   0x180021838      0fb75120       movzx edx, word [rcx + 0x20] ; int64_t arg2
│     ││╎   0x18002183c      488b4918       mov rcx, qword [rcx + 0x18] ; int64_t arg1
│     ││╎   0x180021840      e8d7a5ffff     call fcn.18001be1c
│     ││╎   0x180021845      84c0           test al, al
│    ┌────< 0x180021847      752e           jne 0x180021877
│    │││╎   0x180021849      488b4e18       mov rcx, qword [rsi + 0x18]
│    │││╎   0x18002184d      488b01         mov rax, qword [rcx]
│    │││╎   0x180021850      488b4068       mov rax, qword [rax + 0x68]
│    │││╎   0x180021854      ff15f60a0100   call qword [0x180032350]   ; [0x180032350:8]=0x180031050
│    │││╎   0x18002185a      b990010000     mov ecx, 0x190             ; 400 ; DWORD dwMilliseconds
│    │││╎   0x18002185f      ff15db070100   call qword [sym.imp.KERNEL32.dll_Sleep] ; [0x180032040:8]=0x638ca reloc.KERNEL32.dll_Sleep ; VOID Sleep(DWORD dwMilliseconds)
│    │││╎   0x180021865      488bcd         mov rcx, rbp
│    │││╎   0x180021868      e89facffff     call fcn.18001c50c
│    │││╎   0x18002186d      b968930000     mov ecx, 0x9368
│    │││╎   0x180021872      663bc1         cmp ax, cx
│   ┌─────< 0x180021875      7449           je 0x1800218c0
│   ││││╎   ; CODE XREFS from fcn.18002179c @ 0x180021808(x), 0x180021847(x)
│   │└└───> 0x180021877      41b915010000   mov r9d, 0x115             ; 277
│   │  │╎   0x18002187d      895c2420       mov dword [var_20h], ebx
│   │  │╎   0x180021881      4c8d055867..   lea r8, str.ft_feature_FT9368_loadfirmware_LoadFW ; 0x180037fe0 ; "ft_feature_FT9368_loadfirmware_LoadFW"
│   │  │╎   0x180021888      b902000000     mov ecx, 2
│   │  │╎   0x18002188d      488d15d467..   lea rdx, str._Driver__I__s__d_:_Down_fail__try_again__d_5_ ; 0x180038068 ; "[Driver] I %s[%d]: Down fail, try again(%d/5)"
│   │  │╎   0x180021894      e8d770ffff     call fcn.180018970
│   │  │╎   0x180021899      ffc3           inc ebx
│   │  │╎   0x18002189b      83fb05         cmp ebx, 5                 ; 5
│   │  │└─< 0x18002189e      0f8c51ffffff   jl 0x1800217f5
│   │  │    0x1800218a4      bf010000c0     mov edi, 0xc0000001
│   │  │    ; CODE XREF from fcn.18002179c @ 0x1800217ed(x)
│   │  └──> 0x1800218a9      8bc7           mov eax, edi
│   │       ; CODE XREF from fcn.18002179c @ 0x1800218e0(x)
│   │   ┌─> 0x1800218ab      488b5c2440     mov rbx, qword [var_8h]
│   │   ╎   0x1800218b0      488b6c2448     mov rbp, qword [var_10h]
│   │   ╎   0x1800218b5      488b742450     mov rsi, qword [var_18h]
│   │   ╎   0x1800218ba      4883c430       add rsp, 0x30
│   │   ╎   0x1800218be      5f             pop rdi
│   │   ╎   0x1800218bf      c3             ret
│   │   ╎   ; CODE XREF from fcn.18002179c @ 0x180021875(x)
│   └─────> 0x1800218c0      41b910010000   mov r9d, pe_nt_image_headers64 ; 0x110
│       ╎   0x1800218c6      4c8d051367..   lea r8, str.ft_feature_FT9368_loadfirmware_LoadFW ; 0x180037fe0 ; "ft_feature_FT9368_loadfirmware_LoadFW"
│       ╎   0x1800218cd      488d156467..   lea rdx, str._Driver__I__s__d_:_FT9368_update_fw_success ; 0x180038038 ; "[Driver] I %s[%d]: FT9368 update fw success"
│       ╎   0x1800218d4      b902000000     mov ecx, 2
│       ╎   0x1800218d9      e89270ffff     call fcn.180018970
│       ╎   0x1800218de      33c0           xor eax, eax
└       └─< 0x1800218e0      ebc9           jmp 0x1800218ab
            ; CALL XREF from fcn.18002179c @ 0x1800217e6(x)
┌ 356: fcn.180021a04 (int64_t arg1);
│ `- args(rcx) vars(12:sp[0x10..0x80])
│           0x180021a04      48895c2410     mov qword [var_10h], rbx
│           0x180021a09      4889742418     mov qword [var_18h], rsi
│           0x180021a0e      57             push rdi
│           0x180021a0f      4883ec70       sub rsp, 0x70
│           0x180021a13      488b059e6f..   mov rax, qword [0x1800789b8] ; [0x1800789b8:8]=0x2b992ddfa232
│           0x180021a1a      4833c4         xor rax, rsp
│           0x180021a1d      4889442460     mov qword [var_60h], rax
│           0x180021a22      0f57c0         xorps xmm0, xmm0
│           0x180021a25      33ff           xor edi, edi
│           0x180021a27      488bf1         mov rsi, rcx               ; arg1
│           0x180021a2a      0f11442440     movups xmmword [var_40h], xmm0
│           0x180021a2f      0f11442450     movups xmmword [var_50h], xmm0
│           0x180021a34      4885c9         test rcx, rcx              ; arg1
│       ┌─< 0x180021a37      756b           jne 0x180021aa4
│       │   0x180021a39      0faee8         lfence
│       │   0x180021a3c      be5c5c0000     mov esi, 0x5c5c            ; '\\\\'
│       │   0x180021a41      488d1d4863..   lea rbx, str.D:workSensorFT9368_ftWbioUmdfDriverV2_feature_src_ft_loadfirmware.cpp ; 0x180037d90 ; "D:\\work\\Sensor\\FT9368\\ftWbioUmdfDriverV2\\feature\\src\\ft_loadfirmware.cpp"
│       │   0x180021a48      8bd6           mov edx, esi
│       │   0x180021a4a      488bcb         mov rcx, rbx
│       │   0x180021a4d      e83ee30000     call fcn.18002fd90
│       │   0x180021a52      4885c0         test rax, rax
│      ┌──< 0x180021a55      740e           je 0x180021a65
│      ││   0x180021a57      8bd6           mov edx, esi
│      ││   0x180021a59      488bcb         mov rcx, rbx
│      ││   0x180021a5c      e82fe30000     call fcn.18002fd90
│      ││   0x180021a61      488d5801       lea rbx, [rax + 1]
│      ││   ; CODE XREF from fcn.180021a04 @ 0x180021a55(x)
│      └──> 0x180021a65      488d0d7c0d..   lea rcx, str.A_required_pointer_is_null ; 0x1800327e8 ; "A required pointer is null"
│       │   0x180021a6c      bf1c0022c0     mov edi, 0xc022001c        ; '\x1c'
│       │   0x180021a71      897c2430       mov dword [var_30h], edi
│       │   0x180021a75      4c8d058464..   lea r8, str.ft_feature_loadfirmware_FT9368isUpdateVersion ; 0x180037f00 ; "ft_feature_loadfirmware_FT9368isUpdateVersion"
│       │   0x180021a7c      48894c2428     mov qword [var_28h], rcx
│       │   0x180021a81      488d15e00d..   lea rdx, str._Driver__E_error_at__s__s:_d_:__s_0x_x ; 0x180032868 ; "[Driver] E error at %s[%s:%d]: %s 0x%x"
│       │   0x180021a88      b905000000     mov ecx, 5
│       │   0x180021a8d      c74424203d..   mov dword [var_20h], 0x3d  ; '='
│       │                                                              ; [0x3d:4]=-1 ; 61
│       │   0x180021a95      4c8bcb         mov r9, rbx
│       │   0x180021a98      e8d36effff     call fcn.180018970
│       │   ; CODE XREFS from fcn.180021a04 @ 0x180021b11(x), 0x180021b41(x)
│     ┌┌──> 0x180021a9d      8bc7           mov eax, edi
│    ┌────< 0x180021a9f      e9a5000000     jmp 0x180021b49
│    │╎╎│   ; CODE XREF from fcn.180021a04 @ 0x180021a37(x)
│    │╎╎└─> 0x180021aa4      8bdf           mov ebx, edi
│    │╎╎    ; CODE XREF from fcn.180021a04 @ 0x180021afa(x)
│    │╎╎┌─> 0x180021aa6      488b4e20       mov rcx, qword [rsi + 0x20]
│    │╎╎╎   0x180021aaa      488b01         mov rax, qword [rcx]
│    │╎╎╎   0x180021aad      488b4058       mov rax, qword [rax + 0x58]
│    │╎╎╎   0x180021ab1      ff1599080100   call qword [0x180032350]   ; [0x180032350:8]=0x180031050
│    │╎╎╎   0x180021ab7      488b4e18       mov rcx, qword [rsi + 0x18]
│    │╎╎╎   0x180021abb      4c8d442440     lea r8, [var_40h]
│    │╎╎╎   0x180021ac0      ba80910000     mov edx, 0x9180
│    │╎╎╎   0x180021ac5      41b920000000   mov r9d, 0x20              ; 32
│    │╎╎╎   0x180021acb      488b01         mov rax, qword [rcx]
│    │╎╎╎   0x180021ace      488b4058       mov rax, qword [rax + 0x58]
│    │╎╎╎   0x180021ad2      ff1578080100   call qword [0x180032350]   ; [0x180032350:8]=0x180031050
│    │╎╎╎   0x180021ad8      85c0           test eax, eax
│   ┌─────< 0x180021ada      786a           js 0x180021b46
│   ││╎╎╎   0x180021adc      807c245393     cmp byte [var_53h], 0x93
│  ┌──────< 0x180021ae1      7507           jne 0x180021aea
│  │││╎╎╎   0x180021ae3      807c245468     cmp byte [var_54h], 0x68   ; 'h'
│ ┌───────< 0x180021ae8      7416           je 0x180021b00
│ ││││╎╎╎   ; CODE XREF from fcn.180021a04 @ 0x180021ae1(x)
│ │└──────> 0x180021aea      b914000000     mov ecx, 0x14              ; 20 ; DWORD dwMilliseconds
│ │ ││╎╎╎   0x180021aef      ff154b050100   call qword [sym.imp.KERNEL32.dll_Sleep] ; [0x180032040:8]=0x638ca reloc.KERNEL32.dll_Sleep ; VOID Sleep(DWORD dwMilliseconds)
│ │ ││╎╎╎   0x180021af5      ffc3           inc ebx
│ │ ││╎╎╎   0x180021af7      83fb03         cmp ebx, 3                 ; 3
│ │ ││╎╎└─< 0x180021afa      7caa           jl 0x180021aa6
│ │ ││╎╎    ; CODE XREF from fcn.180021a04 @ 0x180021b03(x)
│ │ ││╎╎┌─> 0x180021afc      33c0           xor eax, eax
│ │┌──────< 0x180021afe      eb49           jmp 0x180021b49
│ ││││╎╎╎   ; CODE XREF from fcn.180021a04 @ 0x180021ae8(x)
│ └───────> 0x180021b00      83fb03         cmp ebx, 3                 ; 3
│  │││╎╎└─< 0x180021b03      7df7           jge 0x180021afc
│  │││╎╎    0x180021b05      488b4620       mov rax, qword [rsi + 0x20]
│  │││╎╎    0x180021b09      0fb64c2455     movzx ecx, byte [var_55h]
│  │││╎╎    0x180021b0e      3a480a         cmp cl, byte [rax + 0xa]
│  │││└───< 0x180021b11      748a           je 0x180021a9d
│  │││ ╎    0x180021b13      0fb6400a       movzx eax, byte [rax + 0xa]
│  │││ ╎    0x180021b17      4c8d05e263..   lea r8, str.ft_feature_loadfirmware_FT9368isUpdateVersion ; 0x180037f00 ; "ft_feature_loadfirmware_FT9368isUpdateVersion"
│  │││ ╎    0x180021b1e      41b955000000   mov r9d, 0x55              ; 'U' ; 85
│  │││ ╎    0x180021b24      89442428       mov dword [var_28h], eax
│  │││ ╎    0x180021b28      894c2420       mov dword [var_20h], ecx
│  │││ ╎    0x180021b2c      488d15fd63..   lea rdx, str._Driver__I__s__d_:_There_is_a_newer_FT9368_FW_to_update_0x_x___0x_x ; 0x180037f30 ; "[Driver] I %s[%d]: There is a newer FT9368 FW to update 0x%x => 0x%x"
│  │││ ╎    0x180021b33      418d49ad       lea ecx, [r9 - 0x53]
│  │││ ╎    0x180021b37      e8346effff     call fcn.180018970
│  │││ ╎    0x180021b3c      bf0d0000c0     mov edi, 0xc000000d        ; '\r'
│  │││ └──< 0x180021b41      e957ffffff     jmp 0x180021a9d
│  │││      ; CODE XREF from fcn.180021a04 @ 0x180021ada(x)
│  │└─────> 0x180021b46      0faee8         lfence
│  │ │      ; CODE XREFS from fcn.180021a04 @ 0x180021a9f(x), 0x180021afe(x)
│  └─└────> 0x180021b49      488b4c2460     mov rcx, qword [var_60h]
│           0x180021b4e      4833cc         xor rcx, rsp
│           0x180021b51      e8ead30000     call fcn.18002ef40
│           0x180021b56      4c8d5c2470     lea r11, [var_70h]
│           0x180021b5b      498b5b18       mov rbx, qword [r11 + 0x18]
│           0x180021b5f      498b7320       mov rsi, qword [r11 + 0x20]
│           0x180021b63      498be3         mov rsp, r11
│           0x180021b66      5f             pop rdi
└           0x180021b67      c3             ret
            ; CALL XREF from fcn.18002179c @ 0x180021801(x)
┌ 699: fcn.18001aa98 ();
│ afv: vars(5:sp[0x10..0x40])
│           0x18001aa98      48895c2418     mov qword [var_18h], rbx
│           0x18001aa9d      55             push rbp
│           0x18001aa9e      56             push rsi
│           0x18001aa9f      57             push rdi
│           0x18001aaa0      4154           push r12
│           0x18001aaa2      4155           push r13
│           0x18001aaa4      4156           push r14
│           0x18001aaa6      4157           push r15
│           0x18001aaa8      b8704e0000     mov eax, 0x4e70            ; 'pN'
│           0x18001aaad      e8be440100     call fcn.18002ef70
│           0x18001aab2      482be0         sub rsp, rax
│           0x18001aab5      488b05fcde..   mov rax, qword [0x1800789b8] ; [0x1800789b8:8]=0x2b992ddfa232
│           0x18001aabc      4833c4         xor rax, rsp
│           0x18001aabf      4889842460..   mov qword [rsp + 0x4e60], rax ; [0x4e60:8]=-1
│           0x18001aac7      488b050a93..   mov rax, qword [0x180163dd8] ; [0x180163dd8:8]=0
│           0x18001aace      41bd01000000   mov r13d, 1
│           0x18001aad4      33db           xor ebx, ebx
│           0x18001aad6      48894c2430     mov qword [var_30h], rcx
│           0x18001aadb      448bf2         mov r14d, edx
│           0x18001aade      4c8be1         mov r12, rcx
│           0x18001aae1      458d7d04       lea r15d, [r13 + 4]
│           0x18001aae5      4885c0         test rax, rax
│       ┌─< 0x18001aae8      7505           jne 0x18001aaef
│       │   0x18001aaea      8d7802         lea edi, [rax + 2]
│      ┌──< 0x18001aaed      eb4c           jmp 0x18001ab3b
│      ││   ; CODE XREF from fcn.18001aa98 @ 0x18001aae8(x)
│      │└─> 0x18001aaef      48391dea92..   cmp qword [0x180163de0], rbx ; [0x180163de0:8]=0
│      │┌─< 0x18001aaf6      7507           jne 0x18001aaff
│      ││   0x18001aaf8      bf04000000     mov edi, 4
│     ┌───< 0x18001aafd      eb3c           jmp 0x18001ab3b
│     │││   ; CODE XREF from fcn.18001aa98 @ 0x18001aaf6(x)
│     ││└─> 0x18001aaff      48391de292..   cmp qword [0x180163de8], rbx ; [0x180163de8:8]=0
│     ││┌─< 0x18001ab06      7505           jne 0x18001ab0d
│     │││   0x18001ab08      418bff         mov edi, r15d
│    ┌────< 0x18001ab0b      eb2e           jmp 0x18001ab3b
│    ││││   ; CODE XREF from fcn.18001aa98 @ 0x18001ab06(x)
│    │││└─> 0x18001ab0d      48391ddc92..   cmp qword [0x180163df0], rbx ; [0x180163df0:8]=0
│    │││┌─< 0x18001ab14      7507           jne 0x18001ab1d
│    ││││   0x18001ab16      bf06000000     mov edi, 6
│   ┌─────< 0x18001ab1b      eb1e           jmp 0x18001ab3b
│   │││││   ; CODE XREF from fcn.18001aa98 @ 0x18001ab14(x)
│   ││││└─> 0x18001ab1d      48391dd492..   cmp qword [0x180163df8], rbx ; [0x180163df8:8]=0
│   ││││┌─< 0x18001ab24      7507           jne 0x18001ab2d
│   │││││   0x18001ab26      bf07000000     mov edi, 7
│  ┌──────< 0x18001ab2b      eb0e           jmp 0x18001ab3b
│  ││││││   ; CODE XREF from fcn.18001aa98 @ 0x18001ab24(x)
│  │││││└─> 0x18001ab2d      48391dcc92..   cmp qword [0x180163e00], rbx ; [0x180163e00:8]=0
│  │││││┌─< 0x18001ab34      755a           jne 0x18001ab90
│  ││││││   0x18001ab36      bf08000000     mov edi, 8
│  ││││││   ; CODE XREFS from fcn.18001aa98 @ 0x18001aaed(x), 0x18001aafd(x), 0x18001ab0b(x), 0x18001ab1b(x), 0x18001ab2b(x)
│  └└└└└──> 0x18001ab3b      bd5c5c0000     mov ebp, 0x5c5c            ; '\\\\'
│       │   0x18001ab40      488d3559ae..   lea rsi, str.D:workSensorFT9368_ftWbioUmdfDriverV2_feature_srcFT9368_Updata.cpp ; 0x1800359a0 ; "D:\\work\\Sensor\\FT9368\\ftWbioUmdfDriverV2\\feature\\src\\FT9368_Updata.cpp"
│       │   0x18001ab47      8bd5           mov edx, ebp
│       │   0x18001ab49      488bce         mov rcx, rsi
│       │   0x18001ab4c      e83f520100     call fcn.18002fd90
│       │   0x18001ab51      4885c0         test rax, rax
│      ┌──< 0x18001ab54      740e           je 0x18001ab64
│      ││   0x18001ab56      8bd5           mov edx, ebp
│      ││   0x18001ab58      488bce         mov rcx, rsi
│      ││   0x18001ab5b      e830520100     call fcn.18002fd90
│      ││   0x18001ab60      4a8d3428       lea rsi, [rax + r13]
│      ││   ; CODE XREF from fcn.18001aa98 @ 0x18001ab54(x)
│      └──> 0x18001ab64      897c2428       mov dword [var_28h], edi
│       │   0x18001ab68      4c8d0501b0..   lea r8, str.Check_CallBack_Fun ; 0x180035b70 ; "Check_CallBack_Fun"
│       │   0x18001ab6f      4c8bce         mov r9, rsi
│       │   0x18001ab72      c74424202a..   mov dword [var_20h], 0x42a ; [0x42a:4]=-1 ; 1066
│       │   0x18001ab7a      488d1577ae..   lea rdx, str._Driver__E_error_at__s__s:_d_:_ERROR_ret_d ; 0x1800359f8 ; "[Driver] E error at %s[%s:%d]: ERROR ret=%d"
│       │   0x18001ab81      418bcf         mov ecx, r15d
│       │   0x18001ab84      e8e7ddffff     call fcn.180018970
│       │   0x18001ab89      488b054892..   mov rax, qword [0x180163dd8] ; [0x180163dd8:8]=0
│       │   ; CODE XREF from fcn.18001aa98 @ 0x18001ab34(x)
│       └─> 0x18001ab90      b902000000     mov ecx, 2
│           0x18001ab95      ff15b5770100   call qword [0x180032350]   ; [0x180032350:8]=0x180031050
│           0x18001ab9b      8b157f921400   mov edx, dword [0x180163e20] ; [0x180163e20:4]=0
│           0x18001aba1      8bc2           mov eax, edx
│           0x18001aba3      2501000080     and eax, 0x80000001
│       ┌─< 0x18001aba8      7d09           jge 0x18001abb3
│       │   0x18001abaa      412bc5         sub eax, r13d
│       │   0x18001abad      83c8fe         or eax, 0xfffffffe         ; 4294967294
│       │   0x18001abb0      4103c5         add eax, r13d
│       │   ; CODE XREF from fcn.18001aa98 @ 0x18001aba8(x)
│       └─> 0x18001abb3      85c0           test eax, eax
│       ┌─< 0x18001abb5      7516           jne 0x18001abcd
│       │   0x18001abb7      488b054292..   mov rax, qword [0x180163e00] ; [0x180163e00:8]=0
│       │   0x18001abbe      418bcd         mov ecx, r13d
│       │   0x18001abc1      ff1589770100   call qword [0x180032350]   ; [0x180032350:8]=0x180031050
│       │   0x18001abc7      8b1553921400   mov edx, dword [0x180163e20] ; [0x180163e20:4]=0
│       │   ; CODE XREF from fcn.18001aa98 @ 0x18001abb5(x)
│       └─> 0x18001abcd      89542420       mov dword [var_20h], edx
│           0x18001abd1      4c8d0588ad..   lea r8, str.BootLoad_Down  ; 0x180035960 ; "BootLoad_Down"
│           0x18001abd8      488d1591ad..   lea rdx, str._Driver__I__s__d_:_downcount___d ; 0x180035970 ; "[Driver] I %s[%d]: downcount = %d"
│           0x18001abdf      41b9a6000000   mov r9d, 0xa6              ; 166
│           0x18001abe5      b902000000     mov ecx, 2
│           0x18001abea      e881ddffff     call fcn.180018970
│           0x18001abef      44012d2a92..   add dword [0x180163e20], r13d ; [0x180163e20:4]=0
│           0x18001abf6      b155           mov cl, 0x55               ; 'U' ; 85
│           0x18001abf8      e853080000     call fcn.18001b450
│           0x18001abfd      ba55aa0000     mov edx, 0xaa55
│           0x18001ac02      b904000000     mov ecx, 4
│           0x18001ac07      e8d8080000     call fcn.18001b4e4
│           0x18001ac0c      ba10010000     mov edx, pe_nt_image_headers64 ; 0x110
│           0x18001ac11      b948000000     mov ecx, 0x48              ; 'H' ; 72
│           0x18001ac16      e8c9080000     call fcn.18001b4e4
│           0x18001ac1b      418bf6         mov esi, r14d
│           0x18001ac1e      8bfb           mov edi, ebx
│           0x18001ac20      c1ee02         shr esi, 2
│           0x18001ac23      85f6           test esi, esi
│       ┌─< 0x18001ac25      0f84a9000000   je 0x18001acd4
│       │   0x18001ac2b      bb00200000     mov ebx, 0x2000
│       │   ; CODE XREF from fcn.18001aa98 @ 0x18001ac77(x)
│      ┌──> 0x18001ac30      8d2cbd0000..   lea ebp, [rdi*4]
│      ╎│   0x18001ac37      ba1f000000     mov edx, 0x1f              ; 31
│      ╎│   0x18001ac3c      4903ec         add rbp, r12
│      ╎│   0x18001ac3f      448d3c3b       lea r15d, [rbx + rdi]
│      ╎│   0x18001ac43      4c8bc5         mov r8, rbp
│      ╎│   0x18001ac46      410fb7cf       movzx ecx, r15w
│      ╎│   0x18001ac4a      e8d5060000     call fcn.18001b324
│      ╎│   0x18001ac4f      8d4720         lea eax, [rdi + 0x20]
│      ╎│   0x18001ac52      3bc6           cmp eax, esi
│     ┌───< 0x18001ac54      721c           jb 0x18001ac72
│     │╎│   0x18001ac56      0faee8         lfence
│     │╎│   0x18001ac59      0fb7d6         movzx edx, si
│     │╎│   0x18001ac5c      4c8bc5         mov r8, rbp
│     │╎│   0x18001ac5f      662bd7         sub dx, di
│     │╎│   0x18001ac62      410fb7cf       movzx ecx, r15w
│     │╎│   0x18001ac66      66412bd5       sub dx, r13w
│     │╎│   0x18001ac6a      e8b5060000     call fcn.18001b324
│     │╎│   0x18001ac6f      418bfe         mov edi, r14d
│     │╎│   ; CODE XREF from fcn.18001aa98 @ 0x18001ac54(x)
│     └───> 0x18001ac72      83c720         add edi, 0x20              ; 32
│      ╎│   0x18001ac75      3bfe           cmp edi, esi
│      └──< 0x18001ac77      72b7           jb 0x18001ac30
│       │   0x18001ac79      33db           xor ebx, ebx
│       │   0x18001ac7b      41bc00200000   mov r12d, 0x2000
│       │   0x18001ac81      8bfb           mov edi, ebx
│       │   ; CODE XREF from fcn.18001aa98 @ 0x18001accd(x)
│      ┌──> 0x18001ac83      8d0cbd0000..   lea ecx, [rdi*4]
│      ╎│   0x18001ac8a      ba3f000000     mov edx, 0x3f              ; '?' ; 63
│      ╎│   0x18001ac8f      4c8d7c2440     lea r15, [var_40h]
│      ╎│   0x18001ac94      4c03f9         add r15, rcx
│      ╎│   0x18001ac97      418d2c3c       lea ebp, [r12 + rdi]
│      ╎│   0x18001ac9b      4d8bc7         mov r8, r15
│      ╎│   0x18001ac9e      0fb7cd         movzx ecx, bp
│      ╎│   0x18001aca1      e8ce020000     call fcn.18001af74
│      ╎│   0x18001aca6      8d4740         lea eax, [rdi + 0x40]
│      ╎│   0x18001aca9      3bc6           cmp eax, esi
│     ┌───< 0x18001acab      721b           jb 0x18001acc8
│     │╎│   0x18001acad      0faee8         lfence
│     │╎│   0x18001acb0      0fb7d6         movzx edx, si
│     │╎│   0x18001acb3      4d8bc7         mov r8, r15
│     │╎│   0x18001acb6      662bd7         sub dx, di
│     │╎│   0x18001acb9      0fb7cd         movzx ecx, bp
│     │╎│   0x18001acbc      66412bd5       sub dx, r13w
│     │╎│   0x18001acc0      e8af020000     call fcn.18001af74
│     │╎│   0x18001acc5      418bfe         mov edi, r14d
│     │╎│   ; CODE XREF from fcn.18001aa98 @ 0x18001acab(x)
│     └───> 0x18001acc8      83c740         add edi, 0x40              ; 64
│      ╎│   0x18001accb      3bfe           cmp edi, esi
│      └──< 0x18001accd      72b4           jb 0x18001ac83
│       │   0x18001accf      4c8b642430     mov r12, qword [var_30h]
│       │   ; CODE XREF from fcn.18001aa98 @ 0x18001ac25(x)
│       └─> 0x18001acd4      4585f6         test r14d, r14d
│       ┌─< 0x18001acd7      7420           je 0x18001acf9
│       │   0x18001acd9      488d442440     lea rax, [var_40h]
│       │   0x18001acde      4c2be0         sub r12, rax
│       │   0x18001ace1      488d4c2440     lea rcx, [var_40h]
│       │   ; CODE XREF from fcn.18001aa98 @ 0x18001acf7(x)
│      ┌──> 0x18001ace6      418a040c       mov al, byte [r12 + rcx]
│      ╎│   0x18001acea      3801           cmp byte [rcx], al
│     ┌───< 0x18001acec      7560           jne 0x18001ad4e
│     │╎│   0x18001acee      4103dd         add ebx, r13d
│     │╎│   0x18001acf1      4903cd         add rcx, r13
│     │╎│   0x18001acf4      413bde         cmp ebx, r14d
│     │└──< 0x18001acf7      72ed           jb 0x18001ace6
│     │ │   ; CODE XREF from fcn.18001aa98 @ 0x18001acd7(x)
│     │ └─> 0x18001acf9      ba5a5a0000     mov edx, 0x5a5a            ; 'ZZ'
│     │     0x18001acfe      b907000000     mov ecx, 7
│     │     0x18001ad03      e8dc070000     call fcn.18001b4e4
│     │     0x18001ad08      b10a           mov cl, 0xa
│     │     0x18001ad0a      e841070000     call fcn.18001b450
│     │     0x18001ad0f      488b05ea90..   mov rax, qword [0x180163e00] ; [0x180163e00:8]=0
│     │     0x18001ad16      b90a000000     mov ecx, 0xa
│     │     0x18001ad1b      ff152f760100   call qword [0x180032350]   ; [0x180032350:8]=0x180031050
│     │     0x18001ad21      32c0           xor al, al
│     │     ; CODE XREF from fcn.18001aa98 @ 0x18001ad51(x)
│     │ ┌─> 0x18001ad23      488b8c2460..   mov rcx, qword [rsp + 0x4e60]
│     │ ╎   0x18001ad2b      4833cc         xor rcx, rsp
│     │ ╎   0x18001ad2e      e80d420100     call fcn.18002ef40
│     │ ╎   0x18001ad33      488b9c24c0..   mov rbx, qword [rsp + 0x4ec0]
│     │ ╎   0x18001ad3b      4881c4704e..   add rsp, 0x4e70
│     │ ╎   0x18001ad42      415f           pop r15
│     │ ╎   0x18001ad44      415e           pop r14
│     │ ╎   0x18001ad46      415d           pop r13
│     │ ╎   0x18001ad48      415c           pop r12
│     │ ╎   0x18001ad4a      5f             pop rdi
│     │ ╎   0x18001ad4b      5e             pop rsi
│     │ ╎   0x18001ad4c      5d             pop rbp
│     │ ╎   0x18001ad4d      c3             ret
│     │ ╎   ; CODE XREF from fcn.18001aa98 @ 0x18001acec(x)
│     └───> 0x18001ad4e      418ac5         mov al, r13b
└       └─< 0x18001ad51      ebd0           jmp 0x18001ad23
            ; CALL XREFS from fcn.180019340 @ +0x889(x), +0x991(x), +0xa13(x), +0xbfe(x)
┌ 46: fcn.180019340 (int64_t arg1);
│ `- args(rcx)
│           0x180019340      4053           push rbx
│           0x180019342      4883ec20       sub rsp, 0x20
│           0x180019346      488bd9         mov rbx, rcx               ; arg1
│           0x180019349      488b4920       mov rcx, qword [rcx + 0x20] ; arg1
│           0x18001934d      4885c9         test rcx, rcx              ; arg1
│       ┌─< 0x180019350      7411           je 0x180019363
│       │   0x180019352      488b01         mov rax, qword [rcx]       ; arg1
│       │   0x180019355      ba01000000     mov edx, 1
│       │   0x18001935a      488b00         mov rax, qword [rax]
│       │   0x18001935d      ff15ed8f0100   call qword [0x180032350]   ; [0x180032350:8]=0x180031050
│       │   ; CODE XREF from fcn.180019340 @ 0x180019350(x)
│       └─> 0x180019363      4883632000     and qword [rbx + 0x20], 0
│           0x180019368      4883c420       add rsp, 0x20
│           0x18001936c      5b             pop rbx
└           0x18001936d      c3             ret
