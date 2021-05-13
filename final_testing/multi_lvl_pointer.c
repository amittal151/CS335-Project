int main(){
	int a[5] = {1,2,3,4,5};
	int *b[5];
	int **c[5];
	int i;
	for(i = 0; i<5; i++){
		b[i] = &a[i];
		c[i] = &b[i];
		**c[i] = **c[i] + i;
		printf("%d %d %d\n", a[i], *b[i], **c[i]);
	}
}
