/**
    This file is part of Adguard for iOS (https://github.com/AdguardTeam/AdguardForiOS).
    Copyright © 2015-2016 Performix LLC. All rights reserved.
 
    Adguard for iOS is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
 
    Adguard for iOS is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
 
    You should have received a copy of the GNU General Public License
    along with Adguard for iOS.  If not, see <http://www.gnu.org/licenses/>.
 */



#import "APDnsResponse.h"
#include <arpa/inet.h>

#define IPV4_FOR_BLOCKING       @"127.0.0.1"
#define IPV6_FOR_BLOCKING       @"::1"

@implementation APDnsResponse

- (id)initWithRR:(ns_rr)rr msg:(ns_msg)msg{
    
    self = [super initWithRR:rr];
    if (self) {
        
        _addressResponse = _blocked = NO;
        _rdata = [NSData dataWithBytes:ns_rr_rdata(rr)
                                length:ns_rr_rdlen(rr)];
        char *buffer = (char *) malloc(NS_MAXDNAME);
        if(buffer == NULL){
            
            return nil;
        }
        const char *str = NULL;
        
        switch (ns_rr_type(rr)) {
            case ns_t_cname:
            case ns_t_ns:
            case ns_t_md:
            case ns_t_mf:
            case ns_t_mg:
            case ns_t_mr:
            case ns_t_ptr:
                
                /* Expand the name server's domain name */
                if (ns_name_uncompress(ns_msg_base(msg), ns_msg_end(msg),
                                       ns_rr_rdata(rr), buffer, NS_MAXDNAME) == 0) {
                }
                
                _stringValue = [NSString stringWithUTF8String:buffer];
                break;
                
            case ns_t_hinfo:
            case ns_t_txt:
                [self parseChString];
                break;
                
            case ns_t_a:
                _addressResponse = YES;
                _stringValue = [NSString stringWithUTF8String:inet_ntoa(*((struct in_addr *)_rdata.bytes))];
                _blocked = [_stringValue isEqualToString:IPV4_FOR_BLOCKING];
                
                break;
                
            case ns_t_aaaa:
            case ns_t_a6:
                _addressResponse = YES;
                str = inet_ntop(AF_INET6, _rdata.bytes, buffer, NS_MAXDNAME);
                if (str) {
                    _stringValue = [NSString stringWithUTF8String:str];
                    _blocked = [_stringValue isEqualToString:IPV6_FOR_BLOCKING];
                }
                break;
                
            default:
                break;
        }
        
        free(buffer);
    }
    
    return self;
}

- (NSString *)description{
    
    return [NSString stringWithFormat:@"name: %@, type: %@, value: %@", self.name, self.type, self.stringValue];
}

- (NSString *)parseChString{
    
    u_int8_t *buf = (u_int8_t *)[_rdata bytes];
    NSUInteger dataLength = _rdata.length;
    NSUInteger i = 0;
    
    NSMutableString *sb = [NSMutableString new];
    
    int len = 1;
    while (i < dataLength && len){
        
        len = buf[i];
        i++;
        if (len) {
            [sb appendString:[[NSString alloc] initWithBytes:(buf + i)
                                                      length:len
                                                    encoding:NSUTF8StringEncoding]];
            i += len;
        }
    }
    
    return sb;
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        
        _rdata = [aDecoder decodeObjectForKey:@"rdata"];
        _stringValue = [aDecoder decodeObjectForKey:@"stringValue"];
        
        NSNumber *val = [aDecoder decodeObjectForKey:@"addressResponse"];
        _addressResponse = [val boolValue];

        val = [aDecoder decodeObjectForKey:@"blocked"];
        _blocked = [val boolValue];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder{

    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.rdata forKey:@"rdata"];
    [aCoder encodeObject:self.stringValue forKey:@"stringValue"];
    [aCoder encodeObject:@(self.addressResponse) forKey:@"addressResponse"];
    [aCoder encodeObject:@(self.blocked) forKey:@"blocked"];
}

@end
