#python

# Created and shared by YANAGIMURA at Modo User Group Osaka - ARIGATOU!!!!
# Source: http://modoosaka.blogspot.com/2017/10/align-y.html

# Included with ETEREA Aligners by Cristobal Vila

# Select a bunch of vertices in order (and with different Y coordinates)
# and use this script to get a falloff vertical progression between first and last one.

# Enabling 'Connection' will cause the falloff vertical progression
# to affect also to the "lateral" inmediate rings (only for vert selections at border)

import lx
import modo

mesh = lx.eval1('query layerservice layer.id ? fg')
mesh = modo.Mesh(mesh)
vert = mesh.geometry.vertices


# ---------------------------------------------------------
# ---------------------------------------------------------
def set_pair_verts(v):
    res = []

    for i in enumerate(v):
        polys = lx.evalN('query layerservice vert.polyList ? %s' % i[1])

        if len(polys) == 1:
            cv = lx.eval('query layerservice vert.vertList ? %s' % i[1])

            # ---------------------------------------
            for n in cv:
                if str(n) not in sel_verts:
                    res.append((int(i[1]), n))
            # ---------------------------------------
        else:
            polys = lx.eval('query layerservice vert.polyList ? %s' % i[1])
            poly_vert_list = []
            # ---------------------------------------
            for n in polys:
                pv = lx.eval('query layerservice poly.vertList ? %s' % n)
                # ---------------------------------------
                for j in pv:
                    poly_vert_list.append(j)
                # ---------------------------------------

            t = []
            s = set()

            # ---------------------------------------
            for k in poly_vert_list:
                if k in s:
                    t.append(k)
                s.add(k)
            # ---------------------------------------

            t.remove(int(i[1]))
            res.append((int(i[1]), t[0]))

    return res


# ---------------------------------------------------------
# ---------------------------------------------------------
def culc_length(v):
    section = []
    res = 0

    for i in enumerate(v):
        if i[0] != len(v) - 1:
            p1 = modo.Vector3(vert[int(v[i[0]])].position)
            p2 = modo.Vector3(vert[int(v[i[0] + 1])].position)

            dist = modo.Vector3.distanceBetweenPoints(p1, p2)

            res = res + dist
            section.append(res)

    return section, res


# ---------------------------------------------------------
# ---------------------------------------------------------

def align_y():
    for roop in range(1, 10):

        height = vert[pair_verts[-1][0]].y - vert[pair_verts[0][0]].y
        all_length = culc_length(sel_verts)

        for i in enumerate(sel_verts):
            if i[0] == 0:
                h = vert[int(sel_verts[0])].y
            else:
                st = vert[int(sel_verts[0])].y
                per = all_length[0][i[0] - 1] / all_length[1]

                args = lx.args()

                # -Linier----------------------------------------------------------
                if args[0] == '1':
                    h = per * height + st
                # -Ease Out--------------------------------------------------------
                elif args[0] == '2':
                    h = per * per * height + st
                # -Ease In---------------------------------------------------------
                elif args[0] == '3':
                    h = per * (2.0 - per) * height + st
                # -Smooth----------------------------------------------------------
                elif args[0] == '4':
                    h = per * per * (3 - 2 * per) * height + st
                # -----------------------------------------------------------------

            lx.eval('vertMap.setVertex position position 1 %s %s' % (i[1], h))


# -----------------------------------------------------------------
# -----------------------------------------------------------------
# -----------------------------------------------------------------

sel_verts = lx.evalN('query layerservice verts ? selected')
pair_verts = set_pair_verts(sel_verts)

align_y()

# -----------------------------------------------------------------

if lx.eval('user.value align_y.connect ?') == 1:
    for i in pair_verts:
        vert[i[1]].y = vert[i[0]].position[1]
    mesh.geometry.setMeshEdits()

# -----------------------------------------------------------------
