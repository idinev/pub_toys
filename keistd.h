//#define KEISTD_IMPL

#ifndef _KEISTD_H_
#define _KEISTD_H_
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <memory.h>

typedef unsigned int uint;
typedef unsigned long long ui64;
typedef signed long long si64;
typedef unsigned short ushort;
typedef unsigned char uchar;
typedef signed char schar;

#define null 0
#define loopi(count) for(int i=0;i<count;i++)
#define loopui(count) for(uint i=0;i<count;i++)
#define loop(var, count) for(int var=0;var<count; var++)
#define arraysize(array) ((int)(sizeof(array)/sizeof(array[0])))
#define foreach_pvec(var, pvector) for(auto EDXPTR = (pvector).items; auto var = *EDXPTR++; )

#define likely_if(cond)       if(__builtin_expect(!!(cond), 1))
#define unlikely_if(cond)     if(__builtin_expect(!!(cond), 0))
#define unlikely_while(cond)    while(__builtin_expect(!!(cond), 0))
#define noinline __attribute__((noinline))
#define restrict __restrict__
#define UnusedArg(arg) ((void)(arg))
#define UnusedArgs2(arg1,arg2) 				((void)(arg1));((void)(arg2))
#define UnusedArgs3(arg1,arg2,arg3)			((void)(arg1));((void)(arg2));((void)(arg3))
#define UnusedArgs4(arg1,arg2,arg3,arg4)	((void)(arg1));((void)(arg2));((void)(arg3));((void)(arg4))
#define not_implemented assert(0)

#define ArrSize(arr)	(int(sizeof(arr)/sizeof(arr[0])))
#define Bit32Siz(num)	(((num)+31)/32)
#define IsBit32Set(name, idx) 		(name[(idx)>>5] & (1 << ((idx)&31)))
#define Bit32SetTo1(name, idx)		name[(idx)>>5] |= (1 << ((idx) & 31))
#define Bit32ClearTo0(name, idx)	name[(idx)>>5] &= ~(1 << ((idx) & 31))
// provides a valid 'curBitIdx', with values [0;numDwords*32-1]
#define Bit32IterateValid(bitField, numDwords)	for(int _bitWordIdx=0;_bitWordIdx<(numDwords);_bitWordIdx++)\
														if(uint _bitWordVal = (uint) (bitField[_bitWordIdx]))\
															for(int curBitIdx = (_bitWordIdx<<5); _bitWordVal; _bitWordVal >>= 1, curBitIdx++)\
																if(_bitWordVal & 1)

#define print(x) DebugPrint(#x,x)
#define prints(x) DebugPrint(x)
#define printID(x) DebugPrintID(#x,x)
#define printh(x) DebugPrintHex(#x,(int)x)
#define printi(x) DebugPrint(#x,(int)x)
#define PrintLine DebugPrintLine()
#define printOnce(x) {static bool yep=false; if(!yep){yep=true;print(x);}}
#define printArray(x,asize) {DebugPrint(#x,"{"); for(int _iii=0;_iii<asize;_iii++){trace("	[%d]",_iii);DebugPrint("	",x[_iii]);}DebugPrint("}");}
void DebugPrint(const char* x);
void DebugPrint(const char* name, int x);
void DebugPrint(const char* name, double x);
void DebugPrint(const char* name, const char* x);
void DebugPrintHex(const char* name, int x);
void _onUAssertFail();
#define BreakpointInt3 asm("int3")
#define AUTOCALL_ON_START(func) static BootupCaller _autocall##func(func)
#ifdef assert
	#warning "Assert was already defined"
#else
  #ifndef NDEBUG
	#define assert(cond) if(!(cond)) _onUAssertFail()
  #else
	#define assert(cond)
  #endif
#endif


#define CAN_ERR __attribute__ ((warn_unused_result))

#define memzero(obj) memset(&(obj), 0, sizeof(obj))
void* memclone(const void* ptr,int size);


char* uffetch(const char* fname, int* len=null, int padEnd=1, int padStart=0);
bool  ufdump(const char* fname, const void* data, int len);
bool  ufopenRead(const char* fname);
void  ufcloseRead();
int   ufread4();
short ufread2();
char  ufread1();
float ufreadF();
bool  ufread(void* data, int len);
void  ufreadSkip(int offs);
char* ufreadStr();
void* ufreadAlloc(int len);

bool ufopenWrite(const char* fname);
void ufcloseWrite();
bool ufwrite4(int x);
bool ufwrite2(short x);
bool ufwrite1(char x);
bool ufwriteF(float x);
bool ufwrite(const void* data, int len);
bool ufwriteStr(const char* str);

char* strclone(const char* data);
void itoaComma(char* str, int x);
char* strfirst(char* str, char c);
char* strfirst(char* str, char c1, char c2);
char* strlast(char* str, char c);
char* strlast(char* str, char c1, char c2);
void  strSkipWhitespace(char** str);
int   strRemoveChars(char* data,char c); // returns resulting strlen()

#define BenchEnd(name) { static int bindex=0; _BenchEndFunc(name, bindex); }
void BenchStart();
uint _BenchEndFunc(const char* name, int& index);
void BenchPrint();

void SSE_DenormalsAreZero_FlushToZero();

//================= misc utils ======================================

// Return -1 if not found, otherwise [0;numDwords*32-1]
inline int Bit32FindFirstZero(const int* bitField, int numDwords){
	for(int idxDword=0; idxDword < numDwords; idxDword++){
		int curDword = bitField[idxDword];
		if(curDword == -1)continue;
		for(int i=0;;i++,curDword >>= 1){
			if(curDword & 1) continue;
			return (idxDword<<5) | i;
		}
	}
	return -1; // not found
}


//=================== math utils =================================
union UI6432{ // view ui64 as uints
	ui64 whole;
	uint halfes[2];
};
union F2I{ // view floats as ints
	int i;
	uint u;
	float f;
};
struct IPOINT{
	int x,y;
};
struct IRECT{
	int x,y,x2,y2;
};
struct FPOINT{
	float x,y;
};
inline IPOINT operator+(const IPOINT& a,const IPOINT& b){ IPOINT c; c.x=a.x+b.x; c.y=a.y+b.y; return c;}
inline IPOINT operator-(const IPOINT& a,const IPOINT& b){ IPOINT c; c.x=a.x-b.x; c.y=a.y-b.y; return c;}

inline int fast_abs(int x){
	int sign = (x>>31);
	return (x^sign) - sign;
}
inline int fast_min(int a, int b){
	int c = a-b;
	return b + (c & (c>>31));
}
inline int fast_max(int a, int b){
	int c = a-b;
	return a - (c & (c>>31));
}
inline int fast_negsign(int x){ // (x>=0 ?  0 : -1)
	return x>>31;
}
inline int fast_possign(int x){ // (x>=0 ?  +1 : 0)
	return x>>31;
}
inline int fast_signsign(int x){ // (x>=0 ?  +1 : -1)
	return (x>>31) | 1;
}
inline int fast_signdir(int x){ // x>0 ? +1 : (x<0 ? -1 : 0)
	return (x>>31) - (-x>>31);
}

inline int fast_clamp(int x, int xmin, int xmax){ // clamps to [xmin,xmax]
	int c = x;
	unlikely_if(x > xmax) c=xmax;
	else unlikely_if(x < xmin)c=xmin;
	return c;
}
inline int fast_clamp(int x, int xmax){ // clamps to [0; xmax]. Assumes xmax >= 0
	int c = x;
	unlikely_if(x > xmax) c=xmax;
	else unlikely_if(x < 0)c=0;
	return c;
}

inline float mix(float start, float end, float t){ // lerp. t=[0.0;1.0]
	return start + t*(end-start);
}
inline float saturate(float x){ // clamp x between [0.0;1.0]
	F2I d;	d.f = x;
	unlikely_if(d.i > 0x3F800000) d.i = 0x3F800000;
	else unlikely_if(d.i < 0 ) d.i = 0;
	return d.f;
}
inline float smoothstep(float t){ // t = [0;1]
	return t * t * (3.0f - 2.0f * t);
}


struct HStr{
	const char* str;
	int len;
	int hash;

	bool equ(const char* var) const{
		likely_if(strlen(var)!=(size_t)len) return false;
		if(strncmp(str,var,len)) return false;
		return true;
	}
	bool equ(const char* var, int vlen) const{
		likely_if(vlen!=len) return false;
		if(strncmp(str,var,len)) return false;
		return true;
	}
	bool equ(const HStr* var) const{
		likely_if(var->hash != hash) return false;
		if(var->len != len) return false;
		if(strncmp(str,var->str,len)) return false;
		return true;
	}
	bool equ(const HStr& var) const{
		likely_if(var.hash != hash) return false;
		if(var.len != len) return false;
		if(strncmp(str,var.str,len)) return false;
		return true;
	}
	void calcHash(){
		int h = 64613467;
		for(int i=0;i<len;i++) h = h * (15612357 + str[i]) + 178;
		hash = h;
	}
	bool hasChar(char c) const {
		for(int i=0;i<len;i++)
			unlikely_if(str[i]==c)return true;
		return false;
	}
	int toInt() const{
		return strtol(str,0,0);
	}
	const char* toStr(char* dest, int destSize) const;
	char* toStr() const;
	void initWith(const char* someStr){
		str = someStr;
		len = strlen(someStr);
		calcHash();
	}
	inline void initZero(){
		str = null;
		len = 0;
		hash = 0;
	}
	static HStr make(const char* someStr){
		HStr s;	s.initWith(someStr);
		return s;
	}

	static HStr getTok(const char** pstr, bool skipNewline=false, int* pkind=0);
};

//================================ fast vector templates =======================================================

template<typename T>
struct ARR{
	int num;
	T* items;
	ARR(){num=0;items=null;}
	~ARR(){free(items);}
	void resize(int nsize){
		num = nsize; items = (T*)realloc(items,num*sizeof(T));
	}
	void append(const T& val){
		resize(num+1);
		items[num-1] = val;
	}
	T* steal(){
		T* res = items; num=0; items=null;  return res;
	}
	void deleteAll(){
		loopi(num) delete[] items[i];
		resize(0);
	}
};

template<typename T>
struct PVEC{
	T** items;
	int num;

	PVEC(){
		num=0; items=(T**)malloc(sizeof(void*)); items[0]=null;
	}
	~PVEC(){free(items);}

	void add(T* data){
		if((num & (num-1))){
			items[num++] = data;
			items[num]= null;
		}else{
			int nsize = num ? num*2 : 1;
			items = (T**) realloc(items, (nsize+1)*sizeof(void*));
			items[num++] = data;
			items[num]= null;
		}
	}
	void remove(int idx){
		assert(num);
		num--;
		for(int i=idx;i<num;i++)items[i] = items[i+1];
		items[num]=null;
		unlikely_if((num & (num-1))==0){
			items = (T**) realloc(items, (num+1)*sizeof(void*));
		}
	}
	void fastRemove(int idx){
		assert(idx >= 0 && idx < num);
		num--;
		items[idx] = items[num];
		items[num]=null;

		unlikely_if((num & (num-1))==0){
			items = (T**) realloc(items, (num+1)*sizeof(void*));
		}
	}
	int find(T* data){
		loopi(num) if(items[i]==data) return i+1;
		return 0;
	}
	void fastRemove(T* data){
		int idx = find(data);
		if(idx) fastRemove(idx-1);
	}
	void deleteAll(){
		loopi(num) delete[] items[i];
		num = 0;
		items = (T**)realloc(items, sizeof(void*)); items[0] = null;
	}
};


class BootupCaller{
public:
	BootupCaller(void (*callback)()){ callback();}
};


//================================ IMPLEMENTATION ===========================================================================
#ifdef KEISTD_IMPL
void DebugPrint(const char* x){ printf("%s\n",x);}
void DebugPrint(const char* name, int x){	printf("%s = %d\n", name,x);}
void DebugPrint(const char* name, double x){	printf("%s = %f\n", name,x);}
void DebugPrint(const char* name, const char* x){	printf("%s = %s\n", name,x);}
void DebugPrintHex(const char* name, int x){	printf("%s = 0x%08X\n", name,x);}
void _onUAssertFail(){
	fprintf(stderr,"Assert hit\n"); fflush(stderr);
	BreakpointInt3;
}

void* memclone(const void* ptr,int size){
	void* data = malloc(size);
	memcpy(data, ptr, size);
	return data;
}
char* uffetch(const char* fname, int* len, int padEnd, int padStart){
	FILE* f1 = fopen(fname, "rb"); if(!f1)return null;
	fseek(f1,0, SEEK_END); int siz = ftell(f1); fseek(f1, 0, SEEK_SET);
	char* data = (char*)malloc(siz+padEnd+padStart); if(!data) { fclose(f1); return null; }
	if(padStart)memset(data, 0, padStart);
	if(padEnd)memset(data+(padStart+siz), 0, padEnd);
	fread(data + padStart, 1, siz, f1);
	fclose(f1);
	if(len) *len = siz;
	return data;
}

bool  ufdump(const char* fname, const void* data, int len){
	FILE* f1 = fopen(fname, "wb"); if(!f1)return false;
	bool result = (fwrite(data, 1, len, f1) == (size_t)len);
	fclose(f1);
	return result;
}

static FILE *_kei_fread = 0, *_kei_fwrite=0;

bool ufopenRead(const char* fname){
	FILE* f1 = fopen(fname,"rb"); if(!f1)return false;
	if(_kei_fread)fclose(_kei_fread);
	_kei_fread = f1;
	return true;
}
void  ufcloseRead(){ if(_kei_fread)fclose(_kei_fread); _kei_fread = null; }
int   ufread4(){	int x = 0; fread(&x,sizeof(x),1,_kei_fread); return x;}
short ufread2(){	short x = 0; fread(&x,sizeof(x),1,_kei_fread); return x;}
char  ufread1(){	char x = 0; fread(&x,sizeof(x),1,_kei_fread); return x;}
float ufreadF(){	float x = 0.0f; fread(&x,sizeof(x),1,_kei_fread); return x;}
bool  ufread(void* data, int len){ return (size_t)len == fread(data, 1, len, _kei_fread);}
void  ufreadSkip(int offs){	fseek(_kei_fread, offs, SEEK_CUR);}
void* ufreadAlloc(int len){
	char* p = (char*)malloc(len+1);
	if(p){ fread(p, 1, len, _kei_fread);  p[len]=0;}
	return p;
}
char* ufreadStr(){
	int len = ufread4();
	if(len)return (char*)ufreadAlloc(len);
	return null;
}

bool ufopenWrite(const char* fname){
	FILE* f1 = fopen(fname,"wb"); if(!f1)return false;
	if(_kei_fwrite)fclose(_kei_fwrite);
	_kei_fwrite = f1;
	return true;
}

void ufcloseWrite(){ if(_kei_fwrite)fclose(_kei_fwrite); _kei_fwrite = null; }
bool ufwrite4(int x){	return fwrite(&x, sizeof(x), 1, _kei_fwrite) == sizeof(x);}
bool ufwrite2(short x){	return fwrite(&x, sizeof(x), 1, _kei_fwrite) == sizeof(x);}
bool ufwrite1(char x){	return fwrite(&x, sizeof(x), 1, _kei_fwrite) == sizeof(x);}
bool ufwriteF(float x){ return fwrite(&x, sizeof(x), 1, _kei_fwrite) == sizeof(x);}
bool ufwrite(const void* data, int len){ return fwrite(data, 1, len, _kei_fwrite) == (size_t)len;}

bool ufwriteStr(const char* str){
	if(str){
		int len = 1 + strlen(str);
		if(!ufwrite4(len))return false;
		if(!ufwrite(str, len))return false;
	}else{
		if(!ufwrite4(0))return false;
	}
	return true;
}


char* strclone(const char* data){
	if(data){
		char* res = new char[strlen(data)+1];
		strcpy(res,data);
		return res;
	}
	return null;
}

void itoaComma(char* str, int x){
	if(x < 0){ *str++ ='-';x=-x;}
	int w=0,three=0;
	for(;;){
		three++;
		if(three==4){three=1; str[w++]=',';}
		int nx = x/10;
		str[w++]=(char)('0'+ x-nx*10);
		x=nx;
		if(x==0)break;
	}
	str[w]=0;
	// reverse string
	for(int i=0;i<w;i++){
		w--;
		char c=str[w];
		str[w]=str[i];
		str[i]=c;
	}
}

char* strfirst(char* str, char c){
	for(;;){
		char t = *str;
		if(t==c) return str;
		if(!t)return null;
		str++;
	}
}
char* strfirst(char* str, char c1, char c2){
	for(;;){
		char t = *str;
		if(t==c1 || t==c2) return str;
		if(!t)return null;
		str++;
	}
}
char* strlast(char* str, char c){
	char* res = null;
	for(;;){
		char t = *str;
		if(t==c) res = str;
		if(!t)break;
		str++;
	}
	return res;
}
char* strlast(char* str, char c1, char c2){
	char* res = null;
	for(;;){
		char t = *str;
		if(t==c1 || t==c2) res = str;
		if(!t)break;
		str++;
	}
	return res;
}

void strSkipWhitespace(char** str){
	char* ptr = *str;
	for(;;){
		char c = *ptr;
		if(c==9 || c==32 || c==10 || c==13)ptr++;
		else break;
	}
	*str = ptr;
}

int strRemoveChars(char* data,char c){
	if(!data)return 0;
	char *esi=data,*edi=data,*base=data,t;
	do{
		t = *esi++;
		if(t!=c) *edi++ = t;
	}while(t);
	return edi - base;
}

const char* HStr::toStr(char* dest, int destSize) const {
	destSize--;
	if(destSize > len) destSize = len;
	memcpy(dest, str, destSize);
	dest[destSize] = 0;
	return dest;
}
char* HStr::toStr() const{
	char* res = new char[len];
	memcpy(res, str, len);
	res[len] = 0;
	return res;
}

HStr HStr::getTok(const char** pstr, bool skipNewline, int* pkind){
	int kind;
	const char* str = *pstr;
	char c;
	c = *str++;

	while(c==32 || c==9 || c==13 || (c==10 && skipNewline)){
		c = *str++;
	}
	const char* base = str;

	if((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c=='_' || c=='@'){
		// identifier
		kind = 256+'i';
		c = *str++;
		while((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c=='_' || c=='@'){
			c = *str++;
		}
	}else if(c >= '0' && c <= '9'){
		// number
		kind = 256+'n';
		c = *str++;
		if(c!='x'){
			// decimal number
			while(c >= '0' && c <= '9'){
				c = *str++;
			}
		}else{
			// hexadecimal number
			c = *str++;
			while((c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F')){
				c = *str++;
			}
		}
	}else if(c=='"'){
		// quote
		kind = 256+'q';
		char prevC;
		for(;;){
			prevC = c;
			c = *str++;
			if(c=='"' && prevC!='\\'){ str++; break;}
			if(c==0)break;
			if(c==10 && !skipNewline)break;
		}
	}else{
		// others. Null and NewLine fall here
		kind = (int)c;
		str++;
	}

	// return results
	base--;	str--;
	if(pkind) *pkind = kind;
	*pstr = str;
	HStr res;
	res.str = base;
	res.len = str - base;
	res.calcHash();
	return res;
}



// ================= benchmarking ==========================


struct _kei_BenchResult{
	const char* name;
	uint minTime;
	uint lastTime;
	uint maxTime;
	double avgTime;
	double avgTime2;

	bool used;
	uint numTimesUsed;
};

static uint _kei_BenchStartTick[8],_kei_BenchStartTickIDX=0;
static uint _kei_BenchNumObjects=0;
static _kei_BenchResult _kei_BenchResults[16];

static uint _RDTSC(){
	uint x,upper;
	#ifdef __GNUC__
		asm volatile ("rdtsc": "=a" (x), "=d" (upper));
	#else
		__asm{
			RDTSC;
			mov x,eax;
		}
	#endif
	return x;
}


void BenchStart(){
	_kei_BenchStartTick[_kei_BenchStartTickIDX] = _RDTSC();
	_kei_BenchStartTickIDX++;
	_kei_BenchStartTickIDX&=7;
}
uint _BenchEndFunc(const char* name, int& index){
	uint time = _RDTSC();
	_kei_BenchStartTickIDX--;
	_kei_BenchStartTickIDX&=7;

	time = time-_kei_BenchStartTick[_kei_BenchStartTickIDX];
	unlikely_if(name==null)return time;

	unlikely_if(index==0){
		_kei_BenchNumObjects++; index = _kei_BenchNumObjects;
		_kei_BenchResults[index-1].used = false;
	}

	_kei_BenchResult* edx = &_kei_BenchResults[index-1];

	likely_if(edx->used) {
		edx->numTimesUsed++;
		edx->lastTime=time;
		if(edx->minTime>time)edx->minTime=time;
		if(edx->maxTime<time)edx->maxTime=time;
		edx->avgTime+= (double)time;
		edx->avgTime2 = (edx->avgTime2*0.9999) + (time*0.0001);
		return time;
	}else{
		edx->name = name;
		edx->minTime=time;
		edx->lastTime=time;
		edx->maxTime=time;
		edx->avgTime=(double)time;
		edx->avgTime2=(double)time;

		edx->used=true;
		edx->numTimesUsed=1;
		return time;
	}
}

static char* _itoaComma(char* dest, int x){ itoaComma(dest, x); return dest;}

void BenchPrint(){
	if(!_kei_BenchNumObjects)return;
	bool oki=false;


	loopui(_kei_BenchNumObjects){
		_kei_BenchResult* edx = &_kei_BenchResults[i];
		if(!edx->used)continue;
		if(!oki){
			prints("Bench results:");
			oki=true;
		}
		edx->avgTime/= (double)edx->numTimesUsed;

		char str[32];

		//printf("    %-30s:	avg1=%-10d  avg2=%-10d min=%-10d	last=%-10d	max=%-10d, count=%-10d\n",
		//	edx->name,(int)edx->avgTime,(int)edx->avgTime2,edx->minTime,edx->lastTime,edx->maxTime,edx->numTimesUsed);
		printf("    %-16s:	",edx->name);
		printf("avg1: %-14s  ",	_itoaComma(str, (int)edx->avgTime));
		printf("avg2: %-14s  ",	_itoaComma(str, (int)edx->avgTime2));
		printf("min: %-14s  ",	_itoaComma(str, edx->minTime));
		printf("last: %-14s  ",	_itoaComma(str, edx->lastTime));
		printf("max: %-14s  ",	_itoaComma(str, edx->maxTime));
		printf("count: %-14s  ",	_itoaComma(str, edx->numTimesUsed));
		printf("\n");



		edx->used=false;
	}
}

void SSE_DenormalsAreZero_FlushToZero(){
#ifndef __GNUC__
	int sse_cr;
	__asm{
		STMXCSR sse_cr
		or sse_cr,8040h
		LDMXCSR sse_cr
	};
#else
	unsigned int mxcsr;
	__asm__ __volatile__ ("stmxcsr (%0)" : : "r"(&mxcsr) : "memory");
	mxcsr = (mxcsr | (1<<15) | (1<<6));
	__asm__ __volatile__ ("ldmxcsr (%0)" : : "r"(&mxcsr));
#endif
}

#endif

#endif // _KEISTD_H_

