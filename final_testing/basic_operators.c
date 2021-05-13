
int main() {
  int n=-6;
  n = -1;     // -1
  n *= -1;    //  1
  n = n + 5;  //  6
  n = -n;     // -6
  n = n%2; //  3
  n = n + -1; //  2
  printf("n = ");
  printf("%d\n", n);
  if (n == 2) {
    printf("Test successful\n");
  } else {
    printf("Test failed\n");
  }
  return 0;
}