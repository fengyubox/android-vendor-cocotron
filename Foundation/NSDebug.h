/* Copyright (c) 2006-2007 Christopher J. W. Lloyd

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE. */

#import <Foundation/NSObject.h>

FOUNDATION_EXPORT BOOL NSZombieEnabled;
FOUNDATION_EXPORT BOOL NSDebugEnabled;
FOUNDATION_EXPORT BOOL NSCooperativeThreadsEnabled;

void NSCooperativeThreadBlocking();
void NSCooperativeThreadWaiting();

FOUNDATION_EXPORT void *NSFrameAddress(NSUInteger level);
FOUNDATION_EXPORT unsigned NSCountFrames(void);
FOUNDATION_EXPORT void *NSReturnAddress(int level);

#if defined(__WIN32__) || defined(SOLARIS) || defined(__ANDROID__)
int backtrace(void** array, int size);
char** backtrace_symbols(void* const* array, int size);
#endif
