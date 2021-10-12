#include <stdio.h>
#include <unistd.h>
#include <omp.h>

#define SIZE 5
#define NUMITER 26

omp_lock_t my_lock;
omp_lock_t my_lock1;

char buffer[SIZE];
int nextin = 0;
int nextout = 0;
int count = 0;
int empty = 1;
int full = 0;
int i,j;

void put(char item)
{
    buffer[nextin] = item;

    #pragma omp atomic write 
    nextin = (nextin + 1) % SIZE;

    count++;
    if (count == SIZE)
        full = 1;
    if (count == 1) // buffer was empty
        empty = 0;
}


void producer(int tid)
{
    char item;
    while( i < NUMITER)
    {
        omp_set_lock(&my_lock);
            item = 'A' + (i % 26);
            put(item);
            i++;
            printf("%d Producing %c ...\n",tid, item);
        omp_unset_lock(&my_lock);
        sleep(1);
    }
}


char get()
{
    char item;

    #pragma omp atomic read
    item = buffer[nextout];

    nextout = (nextout + 1) % SIZE;
    count--;
    if (count == 0) // buffer is empty
        empty = 1;
    if (count == (SIZE-1))
        // buffer was full
        full = 0;
    return item;
}


void consumer(int tid)
{
    char item;
    while(j < NUMITER )
    {
        omp_set_lock(&my_lock);
            j++;
            item = get();
            printf("%d ...Consuming %c\n",tid, item);
        omp_unset_lock(&my_lock);
    sleep(1);
    }
}

int main()
{
    omp_init_lock(&my_lock);
    int tid;
    i=j=0;
    #pragma omp parallel firstprivate(i,j) private(tid) num_threads(4) 
    {
       tid=omp_get_thread_num();

       if(tid%2==1)
       {
           producer(tid);
       }
       else
       {
           consumer(tid);
       }
    }
    omp_destroy_lock(&my_lock);
    return 0;
}
