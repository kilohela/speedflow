#include <stdio.h>
#include <limits.h>
#include <stdbool.h>

// 宏定义，用于打印测试标题
#define PRINT_TEST_TITLE(title) \
    printf("\n========================================\n"); \
    printf("          %s\n", title); \
    printf("========================================\n");

int main() {

    PRINT_TEST_TITLE("输入测试");
    int a, b;
    scanf("%d%d", &a, &b);
    printf("get a = %d, b = %d, a * b = %d\n", a, b, a*b);

    return 0;
}