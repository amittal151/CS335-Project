int func(int n) {
   if(n == 0){
      return 0;

   } 
   else if(n == 1) {

      return 1;
   } 
   else {
      return func(n-1) + func(n-2);
   }
}

int main() {
   int n = 5;
   int i;
    int ans =func(n) + func(n-1) * func(n);
    return 0;
}