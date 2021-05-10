
int main(){
  int i=1,n,k,o=1,z;
  int t;
  scanf("%d", &t);
  for(;t>0 ;t--){
   scanf("%d%d",&n,&k);
    if(k+k+1>n)printf("-1");
    else{
      
      for(o=i=0;i++<n;){
       
        z = o<k?(i&1?(i<2?i:i-1):(i<n?i+1:n)):i;
        printf("%d ",z);
        o+=i-1&&i&1;
      }
    }
    printf("\n");
  }
  return 0;
}
