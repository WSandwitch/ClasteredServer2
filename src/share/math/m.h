#ifndef CLASTERED_SERVER_SLAVE_M_HEADER
#define CLASTERED_SERVER_SLAVE_M_HEADER

#define sqr(x) ({typeof(x) _x=x; _x*_x;})

#define PPI 120
#define to_pdegrees(a) (PPI/3.14f*(a))
#define from_pdegrees(a) (3.14f/PPI*(a))

#endif