int main()
{
    int *arr[5][5];
	int i, j, k;
	
	for(i = 0; i<5; i++){
		for(j = 0; j<5; j++){
			arr[i][j] = malloc(sizeof(int)*5);
			//printf("%x ", arr[i][j]);
		}
		printf("\n");
	}
	
	
	for(i = 0; i<5; i++){
		for(j = 0; j<5; j++){
			for(k = 0; k<5; k++) arr[i][j][k] = i*j*k;
		}
		printf("\n");
	}
	
	for(i = 0; i<5; i++){
		for(j = 0; j<5; j++){
			for(k = 0; k<5; k++) printf("%d ", arr[i][j][k]);
		}
		printf("\n");
	}
    return 0;
}
