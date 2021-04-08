struct node
{
   //defining a union
   char name[32];
   float sal;
   int wNo;
} u1;

struct struct1
{
   char name[32];
   float sal;
   int wNo;
} s1;


int main()
{
   int x1 = sizeof(u1);
   int x2 = sizeof(s1);
   struct struct1 *s;
   struct node *u;
   s = u; // we comparing struct with union
   return 0;
}