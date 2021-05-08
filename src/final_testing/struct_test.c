typedef struct node{
	int a;
	int b;
	struct node* next;
}this; 

int main(){
  	this var1, var2, var3;
  	this* head, *ptr, *ptr1;
  	int i;
  	ptr = &var2;
  	ptr1 = &var3;
  	head = &var1;
  	ptr->next = ptr1;
  	ptr1->a = 69;
  	ptr1->b = 100;
  	head->next = ptr;
  	i = head->next->next->a + head->next->next->b;
  	printf("%d %d\n", i, var3.a); 
}
