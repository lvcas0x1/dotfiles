#include <_inttypes.h>
#include <stdio.h>

int add(int a, int b) {
  int result = +b;
  return result;
}
int main(void) {
  int x = 10;
  int y = 20;
  int sum = add(x, y);

  printf("sum = %d\n", sum);

  return 0;
}
