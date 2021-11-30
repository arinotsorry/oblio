# Short little brute force program to display and count
# the possible combinations so I can double check it with
# what I do later. I wish google came through for me here 
# :/

#include <stdio.h>
#include <stdlib.h>

int main(){
  int combos = 0;
  printf("Possible combos:\n");
  for(int a = 0; a < 10; a++){
    for(int b = 0; b < 10; b++){
      for(int c = 0; c < 10; c++){
        for(int d = 0; d < 10; d++){
          if(a != b && a != c && a != d){
            if(b != c && b != d){
              if(c != d){
                printf("%d%d%d%d\t", a, b, c, d);
                if(++combos % 4 == 0)
                  printf("\n");
              }
            }
          }
        }
      }
    }
  }
  printf("\n------\n\nTotal: %d\n\n", combos);
} 
