#include "io.h"

static void reverse(char *s, int len) {
  int i, j;
  char c;
  for (i = 0, j = len - 1; i < j; i++, j--) {
    c = s[i];
    s[i] = s[j];
    s[j] = c;
  }
}

void _itoa(int val, char *str, int redix) {
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

void printstr(const char* str){
  while(*str){
    store1(UART_TX, *str);
    str++;
  }
}

void putch(char ch) {
  store1(UART_TX, ch);
}

typedef void (*push)(char* pout, char src, char* end); 

// for printf, pout and end must be null
static void push_stdout(char* pout, char src, char* end) {
  // assert(pout == NULL && end == NULL);
  putch(src);
}

// for sprintf and snprintf, if sprintf, end must be NULL
static void push_str(char* pout, char src, char* end) {
  // assert(pout != NULL && end != NULL);
  if(!end || pout < end){
    *pout = src;
  }
}

static int _print(char* pout, char* end, const char *fmt, va_list ap, push f) {
  char fmt_buffer[32]; // buffer to temporarily store the formatted string
  int return_value = 0; 
  int num; uint64_t llu_num;
  char *ptr_fmt_buffer;
  for(const char* p = fmt; *p != '\0'; p++) {
    if(*p == '%') {
      p++;
      switch(*p){
        case 'd':
          num = va_arg(ap, int);
          _itoa(num, fmt_buffer, -10);
          ptr_fmt_buffer = fmt_buffer;
          while(*ptr_fmt_buffer != '\0') {
            f(pout, *ptr_fmt_buffer, end);
            return_value++;
            pout++;
            ptr_fmt_buffer++;
          }
          break;
        case 'x':
          num = va_arg(ap, int);
          _itoa(num, fmt_buffer, 16);
          ptr_fmt_buffer = fmt_buffer;
          while(*ptr_fmt_buffer != '\0') {
            f(pout, *ptr_fmt_buffer, end);
            return_value++;
            pout++;
            ptr_fmt_buffer++;
          }
          break;
        case 'c':
          f(pout, va_arg(ap, int), end);
          return_value++;
          pout++;
          break;
        case 's':
          char* str = va_arg(ap, char*);
          char* ptr_str = str;
          while(*ptr_str != '\0') {
            f(pout, *ptr_str, end);
            pout++;
            ptr_str++;
            return_value++;
          }
          break;

        case 'l':
          p++;
          if(*p == 'l') {
            p++;
            if(*p == 'u') {
              llu_num = va_arg(ap, uint64_t);
              ptr_fmt_buffer = fmt_buffer;
              while(llu_num != 0) {
                *ptr_fmt_buffer = llu_num % 10 + '0';
                llu_num /= 10;
                ptr_fmt_buffer++;
              }
              while(ptr_fmt_buffer > fmt_buffer) {
                ptr_fmt_buffer--;
                f(pout, *ptr_fmt_buffer, end);
                return_value++;
                pout++;
              }
            }
          }
          break; 
        default:
          f(pout, '%', end);
          pout++;
          return_value++;
          f(pout, *p, end);
          pout++;
          return_value++;
          break;
      }
    }
    else {
      f(pout, *p, end);
      pout++;
      return_value++;
    }
  }
  if(end)*end = '\0';
  f(pout, '\0', end);
  va_end(ap);
  return return_value;
}

int printf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);

  int ret = _print(NULL, NULL, fmt, ap, push_stdout);
  return ret;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  char *pout = out;
  
  return _print(pout, NULL, fmt, ap, push_str);
}

int sprintf(char *out, const char *fmt, ...) {
  char *pout = out;
  va_list ap;
  va_start(ap, fmt);

  return vsprintf(pout, fmt, ap);
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  char *pout = out;
  va_list ap;
  va_start(ap, fmt);

  return vsnprintf(pout, n, fmt, ap);
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  char *pout = out; // pointer to the current position in the output buffer
  char *end = out + n - 1; // pointer to the end of the output buffer
  
  return _print(pout, end, fmt, ap, push_str);
}

size_t strlen(const char *s) {
  size_t size = 0;
  while(*s){
    size++;
    s++;
  }
  return size;
}

char *strcpy(char *dst, const char *src) {
  size_t i;
  for (i = 0; src[i] != '\0'; i++) {
    dst[i] = src[i];
  }
  dst[i] = '\0';
  return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  size_t i;
  for (i = 0; i < n && src[i] != '\0'; i++) {
    dst[i] = src[i];
  }
  for (; i < n; i++) {
    dst[i] = '\0';
  }
  return dst;
}

char *strcat(char *dst, const char *src) {
  size_t dst_len = strlen(dst);
  size_t i;
  for (i = 0; src[i] != '\0'; i++) {
    dst[dst_len + i] = src[i];
  }
  dst[dst_len + i] = '\0';
  return dst;
}

char *_strncat(char *dst, const char *src, size_t n) {
  size_t dst_len = strlen(dst);
  size_t i;
  for (i = 0; i < n && src[i] != '\0'; i++) {
    dst[dst_len + i] = src[i];
  }
  dst[dst_len + i] = '\0';
  return dst;
}

int strcmp(const char *s1, const char *s2) {
  int cmp = 0;
  while (*s1 != '\0' && *s2 != '\0') {
    cmp = *s1 - *s2;
    if (cmp != 0) {
      break;
    }
    s1++;
    s2++;
  }
  return *s1 - *s2;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  int cmp = 0;
  while (*s1 != '\0' && *s2 != '\0' && n > 0) {
    cmp = *s1 - *s2;
    if (cmp != 0) {
      break;
    }
    s1++;
    s2++;
    n--;
  }
  return cmp || (*s1 - *s2);
}

void *memset(void *s, int c, size_t n) {
  char *p = s;
  while(n > 0){
    *p = (char)c;
    p++;
    n--;
  }
  return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  char *pdst = dst;
  const char *psrc = src;
  if (pdst <= psrc || pdst >= psrc + n) {
    // Forward copy
    while (n-- > 0) {
      *pdst = *psrc;
      pdst++;
      psrc++;
    }
  } else {
    // Backward copy
    pdst += n;
    psrc += n;
    while (n-- > 0) {
      *--pdst = *--psrc;
    }
  }
  return dst;
}

void *memcpy(void *out, const void *in, size_t n) {
  char *dst = out;
  const char *src = in;
  while (n-- > 0) {
    *dst = *src;
    dst++;
    src++;
  }
  return out;
}

int memcmp(const void *s1, const void *s2, size_t n) {
  int cmp = 0;
  const char *p1 = s1;
  const char *p2 = s2;
  while (n > 0) {
    cmp = *p1 - *p2;
    if (cmp != 0) {
      break;
    }
    p1++;
    p2++;
    n--;
  }
  return cmp;
}