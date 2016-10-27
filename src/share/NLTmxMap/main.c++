#include <iostream>
#include <cstdio>
#include <cstdlib>

using namespace std;

#include "NLTmxMap.h"


static void* loadFile( const char * filename, bool appendNull ) {
    
    FILE* f = fopen( filename, "r" );
    if ( !f ) {
        return 0;
    }
    
    fseek( f, 0, SEEK_END );
    auto length = ftell( f ) + appendNull;
    fseek( f, 0, SEEK_SET );
    
    void* buffer = malloc( length );
    fread( buffer, length, 1, f );
    fclose( f );
    
    if ( appendNull ) {
        ((char*)buffer)[ length-1 ] = 0;
    }
    
    return buffer;
}


int main (int argc, const char * argv[])
{
    char * xml = (char*) loadFile( "map1.tmx", true );

    NLTmxMap* map = NLLoadTmxMap( xml );
    
    std::cout << "width " << map->width << ", height " << map->height << std::endl;
    
    delete map;
    
    
    return 0;
}

