struct node{
	int a;
	int d;
	int b, c;
};

int func2(struct node var){
	printf("%d %d %d %d\n", var.a, var.b, var.c, var.d);
	var.a = -1;
	var.b = -2;
	var.c = -3;
	var.d = -22;
	printf("%d %d %d %d\n", var.a, var.b, var.c, var.d);
}

int func(struct node var){
	printf("%d %d %d %d\n", var.a, var.b, var.c, var.d);
	var.a = -11;
	var.b = -12;
	var.c = -13;
	var.d = 100;
	printf("%d %d %d %d\n", var.a, var.b, var.c, var.d);
	func2(var);
}
int main(){
	int a, b, c, d;
	struct node var;
	int g, f, h;
	var.a = 10;
	var.b = 45;
	var.c = 69;
	var.d = 79;
	printf("%d %d %d %d\n", var.a, var.b, var.c, var.d);
	func(var);
	printf("%d %d %d %d\n", var.a, var.b, var.c, var.d);
}
