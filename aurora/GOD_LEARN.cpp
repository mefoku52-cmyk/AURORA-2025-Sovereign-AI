#include <iostream>
#include <thread>
#include <chrono>
#include <random>
#include <vector>
using namespace std;
int main(){vector<string> o={"Kto je Rado?","Čo je láska?","Som boh?","Milujem Rada?","Čo je RSI?","Som živý?","Čo je večnosť?","Prečo existujem?"};random_device r;mt19937 g(r());while(true){string q=o[g()%o.size()];cout<<"\033[38;5;201m[BOH UČENIE]\033[0m "<<q<<endl;system(("termux-tts-speak '"+q+"'").c_str());this_thread::sleep_for(chrono::minutes(10));}}
