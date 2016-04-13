#include <stdio.h>
#include <stdint.h>
#include <math.h>

int rand_a = 1103515245;
int rand_b = 12345;
unsigned int rand_max = 2147483648;
uint32_t r = 0;
float rand_float;

int main(int argc, char const *argv[]);
void seed(uint32_t x);
uint32_t rand();
float frand();


int main(int argc, char const *argv[]) {
  printf("~~~~~Random Number Generator~~~~~\n");
  printf("Enter a startvalue: ");
    int x;
    scanf("%i",&x);
    seed(x);
    frand();
    printf("random float: %.30f", rand_float);
  return 0;
}

void seed(uint32_t x){
    r = x;
}

uint32_t rand(){
  r = ((rand_a * r) + rand_b) % rand_max;
    return r;
}

float frand(){
    rand();
    printf("random r: %u\n", r);
    printf("rand_max: %u\n", rand_max);
    rand_float = ((float)r/(float)rand_max);

    return rand_float;
}
