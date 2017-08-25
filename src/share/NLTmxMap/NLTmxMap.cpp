#include "RapidXML/rapidxml.hpp"
#include <iostream>
#include <algorithm>
#include "NLTmxMap.h"



using namespace rapidxml;

std::vector<string> split(const string& str, int delimiter(int) = ::isspace){
  std::vector<string> result;
  auto e=str.end();
  auto i=str.begin();
  while(i!=e){
    i=find_if_not(i,e, delimiter);
    if(i==e) break;
    auto j=find_if(i,e, delimiter);
    result.push_back(string(i,j));
    i=j;
  }
  return result;
}


NLTmxMap* NLLoadTmxMap( char *xml )
{
    xml_document<> doc;
    doc.parse<0>( xml );
    
    xml_node<> *mapnode = doc.first_node("map");
    
    NLTmxMap* map = new NLTmxMap();
	map->width = atoi( mapnode->first_attribute( "width" )->value() );
    map->height = atoi( mapnode->first_attribute( "height" )->value() );
    map->tileWidth = atoi( mapnode->first_attribute( "tilewidth" )->value() );
    map->tileHeight = atoi( mapnode->first_attribute( "tileheight" )->value() );

	//get user defined properties
	auto props=mapnode->first_node( "properties" );
	if (props){
		auto prop=mapnode->first_node( "property" );
		while ( prop ) {
			map->properties[string(prop->first_attribute( "name" )->value())] = string(prop->first_attribute( "value" )->value());
			prop = prop->next_sibling( "property" );
		}
	}
	
/*
    xml_node<> *tilesetnode = mapnode->first_node( "tileset" );
    while ( tilesetnode ) {
        NLTmxMapTileset* tileset = new NLTmxMapTileset();
        
        tileset->firstGid = atoi( tilesetnode->first_attribute( "firstgid" )->value() );
        tileset->name = tilesetnode->first_attribute( "name" )->value();
        tileset->tileWidth =  atoi( tilesetnode->first_attribute( "tilewidth" )->value() );
        tileset->tileHeight = atoi( tilesetnode->first_attribute( "tileheight" )->value() );
        tileset->filename = tilesetnode->first_node( "image" )->first_attribute( "source" )->value();//check for tiset of images
        
        //cout << "Tileset " << tileset->name << " filename " << tileset->filename << endl;
        
        map->tilesets.push_back( tileset );
        
        tilesetnode = tilesetnode->next_sibling( "tileset" );
    }
*/    
    const char *separators = " \t,\n\r";
    
    xml_node<> *layernode = mapnode->first_node( "layer" );
    
    while ( layernode ) {
        NLTmxMapLayer* layer = new NLTmxMapLayer();
        
        layer->name = layernode->first_attribute( "name" )->value();
        layer->width = atoi( layernode->first_attribute( "width" )->value() );
        layer->height = atoi( layernode->first_attribute( "height" )->value() );
        
        // TODO assert that the "encoding" attribute is set to "CSV" here.
        
        const char* data = layernode->first_node( "data" )->value();
        
        layer->data = new int[ layer->width * layer->height ];
        
        char* copy = (char*) malloc( strlen( data ) + 1 );
        strcpy( copy, data );
        char* item = strtok( copy, separators );

        int index = 0;
        while ( item ) {
            layer->data[ index ] = atoi( item );
            index++;
            
            item = strtok( 0, separators );
        }

        free( copy );
        
        map->layers.push_back( layer );
        
        layernode = layernode->next_sibling( "layer" );
    }
    
    xml_node<> *objectgroupnode = mapnode->first_node( "objectgroup" );
    
    while ( objectgroupnode ) {
        NLTmxMapObjectGroup* group = new NLTmxMapObjectGroup();
        
        group->name = objectgroupnode->first_attribute( "name" )->value();

        xml_attribute<> *visibleattr = objectgroupnode->first_attribute( "visible" );
        if ( visibleattr ) {
            group->visible = atoi( visibleattr->value() );
        } else {
            group->visible = true;
        }
        
        //cout << "group " << group->name << endl;
        
        xml_node<> *objectnode = objectgroupnode->first_node( "object" );
        
        while ( objectnode ) {
            NLTmxMapObject* object = new NLTmxMapObject();
            
			//get user defined properties
			auto oprops=objectnode->first_node( "properties" );
			if (oprops){
				auto prop=oprops->first_node( "property" );
				while ( prop ) {
					object->properties[string(prop->first_attribute( "name" )->value())] = string(prop->first_attribute( "value" )->value());
					prop = prop->next_sibling( "property" );
				}
			}
			
            auto nameattr = objectnode->first_attribute( "name" );
            if ( nameattr ) {
                object->name = nameattr->value();
            }
            auto gidattr = objectnode->first_attribute( "gid" );
            if ( gidattr ) {
                object->gid = atoi( gidattr->value() );
            }
            object->x = atoi( objectnode->first_attribute( "x" )->value() );
            object->y = atoi( objectnode->first_attribute( "y" )->value() );
            
			object->type=OBJECT_QUAD;
			
            auto widthattr = objectnode->first_attribute( "width" );
            if ( widthattr ) {
                object->width = atoi( widthattr->value() );
            }
            
            auto heightattr = objectnode->first_attribute( "height" );
            if ( heightattr ) {
                object->height = atoi( heightattr->value() );
            }
            
            xml_node<> *ellipsenode = objectnode->first_node( "ellipse" );
            
            if ( ellipsenode ) {
				object->type=OBJECT_ELLIPSE;
			}
				
			xml_node<> *polygonnode = objectnode->first_node( "polygon" );
            
            if ( polygonnode ) {
				auto pointsattr = polygonnode->first_attribute( "points" );
				std::vector<string> points=split(pointsattr->value(), [](int i)->int{return i==' ';});
				for (auto point : points){
					std::vector<string> xy=split(point, [](int i)->int{return i==',';});
					if (xy.size()==2){
						NLTmxMapPoint p(atoi(xy[0].c_str()),atoi(xy[1].c_str()));
	//					std::cout << "x " << p.x << " y " << p.y <<"\n";
						object->points.push_back(p);
					}
				}
				object->points.push_back(object->points[0]);//create loop
				object->type=OBJECT_POLYGONE;
            }
			
            xml_node<> *polylinenode = objectnode->first_node( "polyline" );
            
            if ( polylinenode ) {
				auto pointsattr = polylinenode->first_attribute( "points" );
				std::vector<string> points=split(pointsattr->value(), [](int i)->int{return i==' ';});
				for (auto point : points){
					std::vector<string> xy=split(point, [](int i)->int{return i==',';});
					if (xy.size()==2){
						NLTmxMapPoint p(atoi(xy[0].c_str()),atoi(xy[1].c_str()));
	//					std::cout << "x " << p.x << " y " << p.y <<"\n";
						object->points.push_back(p);
					}
				}
				object->type=OBJECT_POLYLINE;
            }
			
            group->objects.push_back( object );
            
            objectnode = objectnode->next_sibling( "object" );
        }
        
        map->groups.push_back( group );
        
        objectgroupnode = objectgroupnode->next_sibling( "objectgroup" );
    }
    
//    free( (void*) xml );
    
    return map;
}
