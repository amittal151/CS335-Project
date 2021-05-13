int main(){
    int a = 2, b = -3, c = 5;
    // +, -, *, /
    c = a + (b*c)/(b*a) - (-a)/b + (a-b)/c;
    printf("%d\n", c);

    // unary operators : -, ~
    c = -c;
    printf("%d\n", c);
    c = ~c;
    printf("%d\n", c);

    // bitwise operators : &, |, ^, <<, >>
    c = c^b;
    printf("%d\n", c);
    c = c&a | (c|b);
    printf("%d\n", c);
    c = c<<a;
    printf("%d\n", c);
    printf("%d\n", a);
    c = c>>a;
    printf("%d\n", c);

    // comparison operators, >, <, <=, >=
    c = (b >= a);
    printf("%d\n", c);
    c = (b <= a);
    printf("%d\n", c);
    c = (a < b);
    printf("%d\n", c);
    c = (a > b);
    printf("%d\n", c);
    c = !c;
    printf("%d\n", c);
    c += 10*(-1);
    printf("%d\n", c);
    c *= 15;
    printf("%d\n", c);
    c /= 3;
    printf("%d\n", c);
    c <<= 1;
    printf("%d\n", c);
    c >>= 2;
    printf("%d\n", c);
    c ^= 1000;
    printf("%d\n", c);
    c &= 10;
    printf("%d\n", c);
    c |= 15;
    printf("%d\n", c);
}