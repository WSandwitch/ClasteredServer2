#pragma once

#include <string.h>
#include <string>
#include <vector>
#include <map>

using namespace std;

#define OBJECT_QUAD 0
#define OBJECT_ELLIPSE 1
#define OBJECT_POLYGONE 2
#define OBJECT_POLYLINE 3

class NLTmxMapTileset {
public:
    int firstGid;
    string name;
    int tileWidth;
    int tileHeight;
    string filename;
};


class NLTmxMapLayer {
public:
    string name;
    int width;
    int height;
    int* data;
    
    ~NLTmxMapLayer() {
        delete [] data;
    }
};


struct NLTmxMapObjectProperty {
    string name;
    string value;
};

struct NLTmxMapPoint {
	NLTmxMapPoint(int x,int y):x(x),y(y){}
	int x,y;
};

class NLTmxMapObject {
public:
    string name;
	char type;
    int gid;
    int x;
    int y;
    int width;
    int height;
//    vector<NLTmxMapObjectProperty*> properties;
	vector<NLTmxMapPoint> points; //line from 0 to size()-1
	map<string, string> properties;
	
};


class NLTmxMapObjectGroup {
public:
    string name;
    int width;
    int height;
    bool visible;
    
    vector<NLTmxMapObject*> objects;
    
    ~NLTmxMapObjectGroup() {
        for ( auto o : objects ) {
            delete o;
        }
    }
};


class NLTmxMap {
public:
    
    int width;
    int height;
    int tileWidth;
    int tileHeight;
	map<string, string> properties;
    
    vector<NLTmxMapTileset*> tilesets;
    vector<NLTmxMapLayer*> layers;
    vector<NLTmxMapObjectGroup*> groups;
    
    ~NLTmxMap() {
        for ( auto g : groups ) {
            delete g;
        }
        
        for ( auto l : layers ) {
            delete l;
        }
        
        for ( auto ts : tilesets ) {
            delete ts;
        }
    }
    
    
};


NLTmxMap* NLLoadTmxMap( char *xml );

