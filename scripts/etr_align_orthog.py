#python

# Created and shared by YANAGIMURA at Modo User Group Osaka - ARIGATOU!!!!
# Source: http://modoosaka.blogspot.com/2017/03/blog-post_27.html

# Included with ETEREA Aligners by Cristobal Vila

import lx

if lx.eval('select.typeFrom vertex;edge;polygon ?') == 1:
    sel_type = 'vertex'
elif lx.eval('select.typeFrom edge;polygon;vertex ?') == 1:
    sel_type = 'edge'
elif lx.eval('select.typeFrom polygon;edge;vertex ?') == 1:
    sel_type = 'polygon'

iLayer = lx.eval('query layerservice layers ? fg')
lx.eval('select.convert vertex')

argvs = lx.args()

try:
    iP = lx.eval('query layerservice verts ? selected')
    pos = lx.eval('query layerservice vert.pos ? %s' % iP[0])

    max_x = pos[0]
    max_y = pos[1]
    max_z = pos[2]
    min_x = pos[0]
    min_y = pos[1]
    min_z = pos[2]

    for i in iP:
        pos = lx.eval('query layerservice vert.pos ? %s' % i)

        if pos[0] > max_x:
            max_x = pos[0]
        if pos[1] > max_y:
            max_y = pos[1]
        if pos[2] > max_z:
            max_z = pos[2]
        if pos[0] < min_x:
            min_x = pos[0]
        if pos[1] < min_y:
            min_y = pos[1]
        if pos[2] < min_z:
            min_z = pos[2]

    if argvs[0] == '0':
        lx.eval('vert.set x %s' % min_x)
    elif argvs[0] == '1':
        lx.eval('vert.set x %s' % max_x)
    elif argvs[0] == '2':
        lx.eval('vert.set y %s' % min_y)
    elif argvs[0] == '3':
        lx.eval('vert.set y %s' % max_y)
    elif argvs[0] == '4':
        lx.eval('vert.set z %s' % min_z)
    elif argvs[0] == '5':
        lx.eval('vert.set z %s' % max_z)

except:

    print(False)

lx.eval('select.typeFrom %s' % sel_type)
