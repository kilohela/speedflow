// In file: bsp/syscalls.c

#include <stdint.h>
#include <sys/errno.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <errno.h>
#include <unistd.h>
#include "syscall.h"
#include "io.h"

// Undefine the macro that might be defined in a system header
#undef errno
extern int errno;
extern void halt();



/*
 * Some Kernal functions to format and debug
 *
 */


static void reverse(char *s, int len) {
  int i, j;
  char c;
  for (i = 0, j = len - 1; i < j; i++, j--) {
    c = s[i];
    s[i] = s[j];
    s[j] = c;
  }
}

static void _itoa(int val, char *str, int redix) {
  const char *digits = "0123456789ABCDEF";
  if(redix < 0){
    redix = -redix;
    if(val < 0){
      val = -val;
      *str = '-';
      str++;
    }
  }

  char *p = str;
  int rem;
  while(1) {
    rem = (uint32_t)val % (uint32_t)redix;
    *p++ = digits[rem];
    val = (uint32_t)val / (uint32_t)redix;
    if(val == 0) break;
  }
  *p = '\0';
  reverse(str, p - str);
}

static void printstr(const char* str){
  while(*str){
    store1(UART_TX, *str);
    str++;
  }
}

static void printd(int num){
  char s[15];
  _itoa(num, s, -10);
  printstr(s);
}

static void printx(int num){
  char s[15];
  _itoa(num, s, 16);
  printstr(s);
}

static void printerr(const char* str){
  printstr("[Kernal error] ");
  printstr(str);
}

/*
 * exit: End the program.
 * The C library's exit() function will call this.
 */
void _exit(int status) {
    // a0 == status
    halt();
    while(1);
}

int close(int file) {
  return -1;
}

char *__env[1] = { 0 };
char **environ = __env;

int execve (const char *__path, char * const __argv[], char * const __envp[]) {
  errno = ENOMEM;
  printerr("TODO: System Call: execve\n");
  return -1;
}

int fork(void) {
  errno = EAGAIN;
  printerr("TODO: System Call: fork\n");
  return -1;
}

int fstat(int file, struct stat *st) {
  st->st_mode = S_IFCHR;
  return 0;
}

int getpid(void) {
  printerr("TODO: System Call: getpid\n");
  return 1;
}

int isatty(int file) {
  printerr("TODO: System Call: isatty\n");
  return 1;
}

int kill(int pid, int sig) {
  errno = EINVAL;
  printerr("TODO: System Call: kill\n");
  return -1;
}

int link (const char *__path1, const char *__path2){
  errno = EMLINK;
  printerr("TODO: System Call: link\n");
  return -1;
}

off_t lseek (int __fildes, off_t __offset, int __whence){
  // https://www.man7.org/linux/man-pages/man2/lseek.2.html
  if(__fildes == 0){ // stdin
    errno = EINVAL;
    return -1;
  }
  switch (__whence) {
    case SEEK_SET:{

      break;
    }
    case SEEK_CUR:{

      break;
    }
    case SEEK_END:{

      break;
    }
  }
  printerr("TODO: System Call: lseek\n");
  printstr("parameter: ");
  printd(__fildes);printstr(" ");
  printd(__offset);printstr(" ");
  printd(__whence);printstr("\n");
  return 0;
}

int open(const char *name, int flags, int mode) {
  return -1;
}

_READ_WRITE_RETURN_TYPE read(int __fd, void *__buf, size_t __nbyte){
  if(__fd == 0){
    size_t bytes_read = 0;
    char * cptr = __buf;
    while(bytes_read < __nbyte){
      char c = load1(UART_RX);
      cptr[bytes_read] = c;
      bytes_read++;
      if(c == '\n') break;
    }
    return bytes_read;
  }
  else printerr("TODO: System Call read with other file discripter.\n");
  return 0;
}

_READ_WRITE_RETURN_TYPE write (int __fd, const void *__buf, size_t __nbyte) {
  if(__fd == 1){ // STDOUT
    const char* cptr = __buf;
    for (int i = 0; i < __nbyte; i++) {
      store1(UART_TX, *cptr);
      cptr++;
    }
    return __nbyte;
  }
  else return 0;
}


void* sbrk(ptrdiff_t __incr){
  extern char _end;		/* heap start, defined by the linker */
  static char *heap_end;
  char *prev_heap_end;
 
  if (heap_end == 0) {
    heap_end = &_end;
  }
  prev_heap_end = heap_end;
  char* stack_ptr;
  __asm__ volatile ("mv %0, sp": "=r" (stack_ptr));
  if (heap_end + __incr > stack_ptr) {
    printstr("Heap and stack collision\n");
    errno = ENOMEM;
    _exit(1);
  }

  heap_end += __incr;
  return (caddr_t) prev_heap_end;
}

int stat(const char *file, struct stat *st) {
  st->st_mode = S_IFCHR;
  return 0;
}

int times(struct tms *buf) {
  printerr("TODO: System Call: times\n");
  return -1;
}

int unlink (const char *__path){
  errno = ENOENT;
  printerr("TODO: System Call: unlink\n");
  return -1; 
}

int wait(int *status) {
  errno = ECHILD;
  printerr("TODO: System Call: wait\n");
  return -1;
}


/*
 * syscall handler
 */

extern void __trap();

void trap_init(){
  __asm__ volatile("csrw mtvec, %0" : : "r"(__trap));
  __asm__ volatile("csrw mcause, %0" : : "r"(11)); // [HACK] take every trap as system
}

typedef struct {
  enum {
    EVENT_NULL = 0,
    EVENT_YIELD, EVENT_SYSCALL, EVENT_PAGEFAULT, EVENT_ERROR,
    EVENT_IRQ_TIMER, EVENT_IRQ_IODEV,
  } event;
  uintptr_t cause, ref;
  const char *msg;
} Event;

typedef struct {
  uint32_t gpr[32], mcause, mstatus, mepc;
  void *pdir;
} Context;

Context* __trap_handler(Context *c) {
  Event ev;
  switch (c->mcause) {
    case 8: case 9: case 11: ev.event = EVENT_SYSCALL; break; // ecall, Environment call
    default: ev.event = EVENT_ERROR; break;
  }
  switch (ev.event) {
    case EVENT_SYSCALL:{
      int syscall_number = c->gpr[17];
      switch (syscall_number) { // a7, used to pass system call number
        case SYS_fstat: c->gpr[10] = fstat(c->gpr[10], (struct stat*)(c->gpr[11])); break;
        case SYS_brk  : c->gpr[10] = (uint32_t)sbrk(c->gpr[10]); break;
        case SYS_write: c->gpr[10] = write(c->gpr[10], (char*)(c->gpr[11]), c->gpr[12]); break;
        case SYS_close: c->gpr[10] = close(c->gpr[10]); break;
        case SYS_read : c->gpr[10] = read(c->gpr[10], (char*)(c->gpr[11]), c->gpr[12]); break;
        case SYS_lseek: c->gpr[10] = lseek(c->gpr[10], c->gpr[11], c->gpr[12]); break;
        default: 
          printerr("Unhandled system call: ");
          printd(syscall_number);
          printstr("\n");
      }
      break;
    }
    case EVENT_YIELD: {
      Context *cto = (Context*)(c->gpr[10]); // a0, first argument of the function that called yield
      Context** from = (Context**)(c->gpr[11]); // &(rt_thread->sp), address of a (void *) variable which points to Context
      if(from){
        *from = c;
      }
      c = cto;
      break;
    }
    default: 
      printerr("Unhandled trap event ID: ");
      printd(ev.event);
      printstr("\n");
      _exit(1);
  }
  if(!c)_exit(1);
  c->mepc += 4;
  return c;
}