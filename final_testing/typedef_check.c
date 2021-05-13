typedef struct node{
	int a;
	int b;
} mystruct;

int main(){

	mystruct var;
	struct node temp;
	var.a = 1;
	var.b = var.a + 1;
	temp = var;
	
	printf("%d %d, %d %d\n", var.a, var.b, temp.a, temp.b);
}

