long long  p[10007],sz[10007];
int find_par(int x){
    if(p[x]==x) return x;
    else return p[x]=find_par(p[x]);
}

void unite(int x, int y){
    int a = find_par(x);
    int b = find_par(y);

    if(a!=b){
        if(sz[a]<sz[b]) swap(a,b);
        p[b]=a;
        sz[a]+=sz[b];
    }
}

int main(){
    auto T=1;
    while(T--){
        long n;
        scanf("%d",&n);
        
        long c[n];
        for(int i=0;i<n;++i)  scanf("%d",&c[i]);
        for(int i=0;i<n;++i) sz[i] =0;
        for(int i=0;i<n;++i) p[i]=i;

        int m;
        scanf("%d",&m);
        int x,y;
        for(int i=0;i<m;++i){
             scanf("%d%d",&x,&y);
            --x, --y;
            unite(x,y);
        }

        int aa[n]={0}, sz[n]={0};
        int k=0;
        while(1){
            p[k]=find_par(k);
            aa[p[k]]+=c[k];
            sz[p[k]]++;
            k++;
            if(k==n) break;
        }

        int ans=-1, zz=0, yy;
        for(int i=0;i<n;++i){
            if(aa[i]>ans){
                ans=aa[i];
                zz=sz[i];
                yy=i;
            }
            else if(aa[i]==ans && zz>sz[i]){
                zz=sz[i];
                yy=i;
            }
        }
        int cnt=0;
        for(int i=0;i<n;++i){
            if(p[i]==yy){
                if(cnt) printf(" ");
                printf("%d", i+1)
                cnt|=1;
            }
        }
    }
    return 0;
}