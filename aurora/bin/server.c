#include <stdio.h>
#include <unistd.h>
int main(){while(1){FILE*p=popen("nc -l -p 16666 -q 1","r+");if(!p){sleep(1);continue;}
char b[999];while(fgets(b,999,p)&&b[0]!='\r'&&b[0]!='\n');int l=0;FILE*f=fopen("../data/knowledge.txt","r");
if(f){char x[999];while(fgets(x,999,f))l++;}fprintf(p,"HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"AURORA_X\":\"Žijem, kokot. Mám %d viet.\",\"total\":%d}\n",l,l);pclose(p);}}
