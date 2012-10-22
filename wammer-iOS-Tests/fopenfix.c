//
//  fopenfix.c
//  BrowseOverflow
//
//  Created by jamie on 8/12/12.
//
//  Source: http://stackoverflow.com/questions/8732393/code-coverage-with-xcode-4-2-missing-files/8733416#8733416

#include <stdio.h>

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wmissing-prototypes"

FILE *fopen$UNIX2003( const char *filename, const char *mode )
{
  return fopen(filename, mode);
}

size_t fwrite$UNIX2003( const void *a, size_t b, size_t c, FILE *d )
{
  return fwrite(a, b, c, d);
}

#pragma clang diagnostic pop