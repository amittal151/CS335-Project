
int main(){
	FILE* file1 = fopen("read_file.txt", "r");
	FILE* file2 = fopen("write_file.txt", "w");
	char c = fgetc(file1);
	while(c != -1){
		fputc(c, file2);
		c = fgetc(file1);
	}
	fclose(file1);
	fclose(file2);
}
