#include "io.h"

void check(bool cond){
    if(!cond) {
        printf(ANSI_FG_RED);
        printf("[Fail]");
        printf(ANSI_NONE);
        printf("\n");
        halt();
    }
}

void pass(){
    printf(ANSI_FG_GREEN);
    printf("[Pass]");
    printf(ANSI_NONE);
    printf("\n");
}