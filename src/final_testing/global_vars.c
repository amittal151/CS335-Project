int a;
int b = 1;
int arr[10] = {1,2,3,4,5,6,7,8,9,10};
void print(){
	for(a = 0; a < sizeof(arr)/sizeof(arr[0]); a++) printf("%d ", arr[a]);
}
int main(){
	print();
	printf("\na = %d\n", a);
}
