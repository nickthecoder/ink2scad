myshape_data = [
    [ [0,0], [100,0], [0,100],    [10,10], [70,10], [10,70]  , [40,40],[20,40], [40,20] ],
    [ [0,1,2], [3,4,5], [6,7,8] ]
];

module myshape()
{
    polygon( points=myshape_data[0], paths=myshape_data[1], convexity=10 );
}

myshape();


