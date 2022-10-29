//
//  LinkRouteAnnotation.m
//  LinkRoute
//
//  Created by tanxl on 2022/10/27.
//

#import "LinkRouteAnnotation.h"
#include <mach-o/getsect.h>
#include <mach-o/ldsyms.h>
#include <mach-o/loader.h>
#import <objc/runtime.h>
#import <objc/message.h>
#include <mach-o/dyld.h>
#include <dlfcn.h>
#import "LinkRoute.h"

NSArray<NSString *>* lr_read_configuration(char *sectionName,const struct mach_header *mhp){
    NSMutableArray *configs = [NSMutableArray array];
    unsigned long size = 0;
#ifndef __LP64__
    uintptr_t *memory = (uintptr_t*)getsectiondata(mhp, SEG_DATA, sectionName, &size);
#else
    const struct mach_header_64 *mhp64 = (const struct mach_header_64 *)mhp;
    uintptr_t *memory = (uintptr_t*)getsectiondata(mhp64, SEG_DATA, sectionName, &size);
#endif
    unsigned long counter = size/sizeof(void*);
    for(int idx = 0; idx < counter; ++idx){
        char *string = (char*)memory[idx];
        NSString *str = [NSString stringWithUTF8String:string];
        if(!str)continue;
        if(str) [configs addObject:str];
    }
    return configs;
}

static void lr_dyld_callback_load(const struct mach_header *mhp, intptr_t vmaddr_slide)
{
    //register services
    NSArray<NSString *> *services = lr_read_configuration(LinkRouteSectName,mhp);
    for (NSString *map in services) {
        NSData *jsonData =  [map dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error = nil;
        id json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if (!error) {
            if ([json isKindOfClass:[NSDictionary class]] && [json allKeys].count) {
                NSString *clsName = [json allKeys][0];
                NSString *protocol  = [json allValues][0];
                if (protocol && clsName) {
                    [LinkRoute registerService:NSProtocolFromString(protocol) withModule:NSClassFromString(clsName)];
                }
            }
        }
    }
}

__attribute__((constructor))
void lr_initPropheter(void) {
    _dyld_register_func_for_add_image(lr_dyld_callback_load);
}

@implementation LinkRouteAnnotation

@end
