struct node{
	int a, b, c;
};

struct node func1(struct node var){
	var.a = 1;
	var.b = 2;
	var.c = 3;
	return var;
}

struct node func(){
	struct node var;
	var.a = 100;
	var.b = 200;
	var.c = 300;
	printf("%d %d %d\n", var.a, var.b, var.c);
	var = func1(var);
	return var;
}

int main(){
	struct node temp = func();
	printf("%d %d %d\n", temp.a, temp.b, temp.c);
}
	
