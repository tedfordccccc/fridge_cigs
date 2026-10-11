import sys, uharfbuzz as hb
from fontTools.ttLib import TTFont
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
def paths(fontfile, text, track=0):
    blob=hb.Blob.from_file_path(fontfile); face=hb.Face(blob); font=hb.Font(face)
    buf=hb.Buffer(); buf.add_str(text); buf.guess_segment_properties(); hb.shape(font,buf,{"liga":True,"calt":True,"swsh":True})
    tt=TTFont(fontfile); gs=tt.getGlyphSet(); order=tt.getGlyphOrder()
    x=0; out=[]
    for info,pos in zip(buf.glyph_infos,buf.glyph_positions):
        name=order[info.codepoint]; pen=SVGPathPen(gs)
        tp=TransformPen(pen,(1,0,0,-1,x+pos.x_offset,-pos.y_offset))
        gs[name].draw(tp); d=pen.getCommands()
        if d: out.append(d)
        x+=pos.x_advance+track
    upm=tt['head'].unitsPerEm
    return out,x,upm
