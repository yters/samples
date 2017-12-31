/*

  Overview
  ========
  
  The token counter creates a hash table, and adds the tokens one by
  one.  Each token slot in the table has a datastructure that keeps
  track of how many times the token has occurred.

  The hash table will dynamically size, up to preset limits.  It
  starts based on an initial load value.  The resizing criteria is
  based on number of collisions a token encounters while being placed.
  If the token encounters too many collisions, then the table is
  doubled in size.

  Once all the tokens are added, the hash table contents are printed.

*/

#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>

#define TRUE 0
#define FALSE -1

typedef struct {
  char* tkn;
  uint64_t cnt;
} item_t;

// Functions adapted from FNV hash function
#define hashA(x) (((uint64_t)(x) * 1111111111111111111ULL) >> (64 - h_bits))
#define hashB(x) (((uint64_t)(x) * 9999999997777777333ULL) >> (64 - h_bits))

int h_bits = 21;  // Initial hashtable size = 2 ^ h_bits.  If RAM is available and you have 64 bit architecture, set as high as possible, up to 64.
int h_limit = 22; // Limitation on hash table size
int p_limit = 10; // Limitation on number of probes for empty hash slot when collision occurs

uint64_t hash_string(char *tkn) {
  uint64_t value = 0;
  int curr = 0;
  for(curr = 0; curr < (int) strlen(tkn); curr++) {
    value = hashA(value) + tkn[curr];
  }

  return hashA(value);
}

int exist(item_t** tbl, uint64_t key) {
  if((*tbl)[key].tkn != NULL) {
    return TRUE;
  } else {
    return FALSE;
  }
}

int match(item_t** tbl, uint64_t key, item_t item) {
  if(strcmp((*tbl)[key].tkn, item.tkn) == TRUE) {
    return TRUE;
  } else {
    return FALSE;
  }
}

int add_item(item_t** tbl, item_t item) {
  uint64_t hA = hash_string(item.tkn);

  // Probe for empty spot or match in table
  int i = 0;
  uint64_t hB = hashB(hA + i);

  for(; exist(tbl, hB) == TRUE && match(tbl, hB, item) == FALSE;
      i++, hB = hashB(hA + i)) { // Generate next probe site
    if(i == p_limit) return FALSE; // Throw exception if probe limit reached
  }

  if(exist(tbl, hB) == FALSE) { // Add new item, or..
    (*tbl)[hB].tkn = malloc(strlen(item.tkn) + 1);
    memcpy((*tbl)[hB].tkn, item.tkn, strlen(item.tkn));
    (*tbl)[hB].tkn[strlen(item.tkn)] = '\0';
    
    (*tbl)[hB].cnt = item.cnt;
  } else { // increment item count
    (*tbl)[hB].cnt += item.cnt;
  }
  
  return TRUE;
}
 
int add_tkn(item_t** tbl, char* tkn) {
  item_t item;
  item.tkn = tkn;
  item.cnt = 1;

  return add_item(tbl, item);
}

void create_table(item_t** tbl, int sz) {
  *tbl = malloc(sizeof(item_t) * pow(2, sz));

  // Initialize all the items
  int i = 0;
  for(i = 0; i < pow(2, sz); i++) {
    (*tbl)[i].tkn = NULL;
    (*tbl)[i].cnt = 0;
  }
}

void destroy_table(item_t** tbl, int sz) {
  uint64_t i = 0;

  if(tbl == NULL) return;

  for(i = 0; i < pow(2, sz); i++) {
    if((*tbl)[i].tkn != NULL) {
      free((*tbl)[i].tkn);
    }
  }

  free(*tbl);
}

void print_counts(item_t** tbl, uint64_t sz) {
  uint64_t i = 0;
  uint64_t empty = 0;
  
  for(i = 0; i < pow(2, sz); i++) {
    if((*tbl)[i].tkn != NULL) {
      printf("%s ", (*tbl)[i].tkn);
      printf("%" PRIu64 "\n", (*tbl)[i].cnt);
    } else {
      empty++;
    }
  }
}

int resize_table(item_t** old_tbl, int old_sz, int new_sz) {
  item_t** new_tbl = malloc(sizeof(item_t*));
  create_table(new_tbl, new_sz);

  int i = 0;
  
  // Add items from old table
  for(i = 0; i < pow(2, old_sz); i++)
    if((*old_tbl)[i].tkn != NULL) // Make sure item isn't blank
      if(add_item(new_tbl, (*old_tbl)[i]) == FALSE)
	return FALSE;
  
  destroy_table(old_tbl, old_sz); 
  
  *old_tbl = *new_tbl;

  free(new_tbl);
  return TRUE;
}

int main (int argc, char **argv) {
  char* filename = NULL;

  if(argc == 1) {
    fprintf(stderr, "usage: token_counter filename\n");
    return FALSE;
  } else {
    filename = argv[1];
  }
  
  FILE* file = fopen(filename, "r");
  char* line = NULL;
  char* tkn = NULL;
  size_t len = 0;

  item_t** table = malloc(sizeof(item_t*));
  create_table(table, h_bits);

  while(getline(&line, &len, file) != FALSE) {
    tkn = malloc(strlen(line));
    memcpy(tkn, line, strlen(line) - 1); // Offset to remove \n at end of line
    tkn[strlen(line) - 1] = '\0';

    while(add_tkn(table, tkn) == FALSE) { // Try adding the token
      // If table doesn't have enough space, keep resizing 
      do {
	h_bits++;
	if(h_bits == h_limit) {
	  fprintf(stderr, "Table is too large %d\n", h_bits);
	  return FALSE;
	}
      } while(resize_table(table, h_bits - 1, h_bits) == FALSE);
    }
  }

  print_counts(table, h_bits);

  destroy_table(table, h_bits);
  free(table);

  return TRUE;
}
