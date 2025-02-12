  bits 64
  section .text
  global _start:

  struc address
  .sin_family resw 1
  .in_port_t resw 1
  .in_addr resd 1
  endstruc


  socket equ 41
  bind equ 49
  listen equ 50
  accept equ 43
  read equ 0
  write equ 1
  open equ 2
  close equ 3
  sock_stream equ 1
  af_inet equ 2
  exit equ 60
  o_rdonly equ 0

  BUF_SIZE equ 1500

zero_buf:
  loop:

    mov [output_buf+rcx-1], dil
    dec rcx

    cmp rcx, 0
    jne loop

    ret

_start:
  mov rdi, af_inet
  mov rsi, sock_stream
  xor rdx, rdx ; eq mov rdx, 0
  mov rax, socket ; acquire sock fd
  syscall

  cmp rax, -1
  je err_exit

  mov r15, rax ; r15 is sockfd

  mov rdi, r15
  mov rsi, addr
  mov rdx, 16
  mov rax, bind
  syscall

  cmp rax, 0
  jne err_exit

  mov rdi, r15
  mov rsi, 10
  mov rax, listen
  syscall

  cmp rax, 0
  jne err_exit

  xor r12, r12
accept_loop:
  mov rdi, r15
  xor rsi, rsi
  xor rdx, rdx
  mov rax, accept
  syscall

  cmp rax, -1
  je err_exit

  mov r14, rax ; move client fd into r14

  mov rdi, r14
  mov rsi, input_buf
  mov rdx, BUF_SIZE
  mov rax, read ; reading client input into input buf
  syscall

  push r12
  push rax
  push rdx
  xor r12, r12
strcmp:
  mov al, [input_buf+r12]
  mov dl, [route+r12]

  inc r12

  cmp al, dl
  je strcmp
  cmp rax, rdx
  jne NF

OK: ; 200
  pop rdx
  pop rax
  pop r12

  mov rdi, 1
  mov rsi, input_buf
  mov rdx, BUF_SIZE
  mov rax, 1 ; write input_buf to stdout
  syscall

  ; no touch r14, r15
  mov rdi, path
  mov rsi, o_rdonly
  mov rax, open ; open 200.html
  syscall

  cmp rax, -1
  je err_exit

  mov r13, rax ; r13 is the fd for 200.html

  mov rdi, r13
  mov rsi, output_buf
  mov rdx, BUF_SIZE
  mov rax, read ; read 1500 bytes from 200.html into output buf
  syscall

  cmp rax, -1
  je err_exit

  mov rdi, r13
  mov rax, close
  syscall ; close 200.html

  cmp rax, -1
  je err_exit

  mov rdi, r14
  mov rsi, output_buf
  mov rdx, BUF_SIZE
  mov rax, write ; write output_buf (200.html) to client fd (r14)
  syscall

  cmp rax, -1
  je err_exit

  mov rdi, r14 ; close client fd
  mov rax, close
  syscall

  push rdx
  push rcx

  xor dil, dil ; arg 1
  mov rcx, 1500 ; arg 2
  call zero_buf

  pop rcx
  pop rdx

  jmp exit_cond

NF: ; 404
  cmp r12, 7
  je OK

  pop rdx
  pop rax
  pop r12

  mov rdi, 1
  mov rsi, input_buf
  mov rdx, BUF_SIZE
  mov rax, 1 ; write input_buf to stdout
  syscall

  ; no touch r14, r15
  mov rdi, badpath
  mov rsi, o_rdonly
  mov rax, open ; open 400.html
  syscall

  cmp rax, -1
  je err_exit

  mov r13, rax ; r13 is the fd for 400.html

  mov rdi, r13
  mov rsi, output_buf
  mov rdx, BUF_SIZE
  mov rax, read ; read 1500 bytes from 400.html into output buf
  syscall

  cmp rax, -1
  je err_exit

  mov rdi, r13
  mov rax, close
  syscall ; close 400.html

  cmp rax, -1
  je err_exit

  mov rdi, r14
  mov rsi, output_buf
  mov rdx, BUF_SIZE
  mov rax, write ; write output_buf (400.html) to client fd (r14)
  syscall

  cmp rax, -1
  je err_exit

  mov rdi, r14 ; close client fd
  mov rax, close
  syscall

  push rdx
  push rcx

  xor dil, dil ; arg 1
  mov rcx, 1500 ; arg 2
  call zero_buf

  pop rcx
  pop rdx

exit_cond:
  inc r12
  cmp r12, 100 ; loop 100 times
  jne accept_loop

suc_exit:
  mov rdi, r15 ; close sock fd
  mov rax, close
  syscall

  mov rax, exit
  xor rdi, rdi
  syscall

err_exit:
  mov rdi, 1
  mov rsi, err_msg
  mov rdx, 18
  mov rax, 1
  syscall

  mov rax, exit
  mov rdi, 1
  syscall

  section .data

  err_msg db "Error. Exiting...", 0
  input_buf times BUF_SIZE db 0, 
  output_buf times BUF_SIZE db 0,
  route db "GET / "
  badpath db "404.html", 0
  path db "200.html", 0

addr:
  dw af_inet
  dw 0x901f
  dd 0
  dq 0
  section .bss
  str_buf resb 25
  str_len resb 1
