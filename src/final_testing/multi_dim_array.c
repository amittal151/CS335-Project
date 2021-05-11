void print(int arr[][5][5], int m, int n, int l)
{
	int i,j, k;
	//printf("%x\n", arr);
	for(i = 0; i<n; i++)
		for(j = 0; j<m; j++)
			for(k = 0; k<l; k++) arr[i][j][k] = i*j*k;
    
}
  
int main()
{
    int arr[5][5][5];
    int m = 5, n = 5, l = 5;
    int i, j, k;
    for(i = 0; i<n; i++){
    	for(j = 0; j<m; j++){
    		for(k = 0; k<l; k++){
				arr[i][j][k] = i+j+k;
				printf("%d ", arr[i][j][k]);
    		}
    	}
    	printf("\n");
	} 
	//printf("%x\n", arr); 
    print(arr, m, n, l);
    
    for(i = 0; i<n; i++){
    	for(j = 0; j<m; j++){
    		for(k = 0; k<l; k++){
				//arr[i][j] = i+j;
				printf("%d ", arr[i][j][k]);
    		}
    	}
    	printf("\n");
	} 
	 
    return 0;
}
