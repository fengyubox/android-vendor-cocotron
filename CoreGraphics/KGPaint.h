/*------------------------------------------------------------------------
 *
 * Derivative of the OpenVG 1.0.1 Reference Implementation
 * -------------------------------------
 *
 * Copyright (c) 2007 The Khronos Group Inc.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and /or associated documentation files
 * (the "Materials "), to deal in the Materials without restriction,
 * including without limitation the rights to use, copy, modify, merge,
 * publish, distribute, sublicense, and/or sell copies of the Materials,
 * and to permit persons to whom the Materials are furnished to do so,
 * subject to the following conditions: 
 *
 * The above copyright notice and this permission notice shall be included 
 * in all copies or substantial portions of the Materials. 
 *
 * THE MATERIALS ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE MATERIALS OR
 * THE USE OR OTHER DEALINGS IN THE MATERIALS.
 *
 *-------------------------------------------------------------------*/

#import "KGSurface.h"

@class O2Paint;
typedef O2Paint *O2PaintRef;

// this function returns the number of pixels read as a positive value or skipped as a negative value
typedef int (*O2PaintReadSpan_lRGBA8888_PRE_function)(O2Paint *self,int x,int y,KGRGBA8888 *span,int length);
typedef int (*O2PaintReadSpan_lRGBAffff_PRE_function)(O2Paint *self,int x,int y,KGRGBAffff *span,int length);

@interface O2Paint : NSObject {
@public
    O2PaintReadSpan_lRGBA8888_PRE_function _paint_lRGBA8888_PRE;
    O2PaintReadSpan_lRGBAffff_PRE_function _paint_lRGBAffff_PRE;
@protected
    CGAffineTransform               m_surfaceToPaintMatrix;
}

O2PaintRef O2PaintRetain(O2PaintRef self);
void O2PaintRelease(O2PaintRef self);

void O2PaintSetSurfaceToPaintMatrix(O2Paint *self,CGAffineTransform surfaceToPaintMatrix);


@end

static inline int O2PaintReadSpan_lRGBA8888_PRE(O2Paint *self,int x,int y,KGRGBA8888 *span,int length) {
   return self->_paint_lRGBA8888_PRE(self,x,y,span,length);
}

static inline int O2PaintReadSpan_lRGBAffff_PRE(O2Paint *self,int x,int y,KGRGBAffff *span,int length) {
   return self->_paint_lRGBAffff_PRE(self,x,y,span,length);
}
