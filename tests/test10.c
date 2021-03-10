int sumOfDigits(int num)
{
    int sum=0;
    while(num>0)
    {
        sum+=(num%10);
        num/=10;
    }
    return sum;
}
 
int main()
{
 
    char yName[40], pName[40];
    int sum, sum1, i, choice;
    float perc=0;
 
    do
    {
        fflush(stdin);
        gets(yName);
 
       
        fflush(stdin);
        gets(pName);
 
        sum=0;
        for(i=0;i<(strlen(yName));i++)
        {
            sum+=tolower(yName[i]);
        }
 
        sum1=0;
        for(i=0;i<(strlen(yName));i++)
        {
            sum1+=tolower(pName[i]);
        }
 
        perc=(sumOfDigits(sum)+sumOfDigits(sum1))+40;
        if(perc>100) perc=100;
 
        scanf("%d",&choice);
 
    }while(choice!=0);
 
    return 0;
}