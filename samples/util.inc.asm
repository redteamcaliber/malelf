
%macro  prologue 0
        push    ebp
        mov     ebp,esp
%endmacro

%macro  prologue 1
        push    ebp
        mov     ebp,esp
        sub     esp,%1
%endmacro

%macro epilogue 0
        mov esp, ebp
        pop ebp
%endmacro

%macro readdir 0
        prologue
        mov edx, esp
        call %%list_dir

        %%list_dir:
        prologue
        push DWORD edx
        call print
        pop edx                     ;; IDIOT INSTRUCTION TO NOT FORGET THAT `dir` is already
        push edx                    ;; ON THE STACK  :-)
        call %%get_dir

        epilogue
        ret
; int opendir(char* path)
        %%opendir:
        prologue

        mov ebx, [ebp+8]
        xor  eax, eax
        mov   al, sys_open
        xor  ecx, ecx           ;O_RDONLY
        xor  edx, edx           ;
        int  0x80

        epilogue
        ret

; int getdents(int fd)
        %%getdents:
        prologue

        sub esp, 0x10000

        mov ebx, [ebp+8]
        xor  eax, eax
        mov   al, sys_getdents
        mov  ecx, esp
        mov  edx, 0x10000
        int  0x80

        mov ebx, esp
        epilogue
        ret

        %%getdents_error:
        push dword 0x00726f72       ; string error
        push word 0x7265

        push esp

        call print
        call exit


        %%get_dir:
        prologue
; reserva espaço para duas variáveis locais
; [esp] = total de bytes lidos por getdents
; [esp+4] = offset da estrutura dirent
        sub esp, 0x08

        mov edx, [ebp+8]

; Abre o diretório atual
        push dword edx
        call %%opendir
        add esp, 4

        push eax    ; eax = fd
        call %%getdents

        mov ecx, ebx
        xor ebx, ebx
        mov ebx, -1
        cmp ah, bh
        jz %%getdents_error

        mov [esp], eax          ; armazena o total de bytes de getdents
        mov DWORD [esp+4], 0x00 ; contador para o loop dos diretorios

        xor eax, eax
        mov ebx, ecx
%endmacro

;; Will iterate over files on stack and set the current file in ebx
%macro next_file_start_loop 0
loop_next_file:
        add ebx, eax
        mov edx, ebx
        add ebx, 0x0A           ; posição de d_name[]

; salva edx e eax na stack
; pois print vai sobrescre-los
        push edx
        push eax
%endmacro

%macro next_file_end_loop 0
; restaura eax e edx
        pop eax
        pop edx

        mov ebx, edx
        xor eax, eax
        xor ecx, ecx
        mov ax, [edx+8]
        mov cx, [esp+4]
        add ecx, eax
        mov edx, [esp]
        mov [esp+4], ecx
        cmp ecx, edx
        jl loop_next_file
%endmacro
