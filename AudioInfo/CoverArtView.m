//
//  CoverArtView.m
//  AudioInfo
//
//  Created by Rinat Abdrashitov on 12-05-25.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CoverArtView.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import "GTMBase64.h"
#import "TBXML.h"

#define REQUEST_XML 1
#define REQUEST_COVER 2

@interface CoverArtView()
- (NSString *) urlencode: (NSString *) url;
- (NSString *)hmacForString:(NSString *)signatureInput;
- (NSString *)utcTimestamp;
@end


@implementation CoverArtView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        imageView_ = [[UIImageView  alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:imageView_];
        [imageView_ release];
       
    }
    return self;
}

- (void) getCoverArtForArtist:(NSString*)artist album:(NSString*)album {
    NSString* baseurl = @"http://ecs.amazonaws.com/onca/xml?";
    
    NSString* AWSAccessKeyId = @"AWSAccessKeyId=AKIAJLDG2QYKMWC5QSGA";
    NSString* AssociateTag = @"AssociateTag=audioinfo";
    NSString* Keywords= [NSString stringWithFormat:@"%@ %@",artist, album];
    NSString* URLEncodedKeywords = [NSString stringWithFormat:@"Keywords=%@", [self urlencode:Keywords]];
    NSString* Operation = @"Operation=ItemSearch";
    NSString* ResponseGroup=@"ResponseGroup=Images";
    NSString* SearchIndex = @"SearchIndex=Music";
    NSString* Service = @"Service=AWSECommerceService";
    NSString* Timestamp = [self utcTimestamp];
    NSString* URLEncodedTimestamp = [NSString stringWithFormat:@"Timestamp=%@", [self urlencode:Timestamp]];
    
    
    NSString* Version=@"Version=2011-08-01";
    
    NSString* CanonicalizedQueryString = [NSString stringWithFormat:@"%@&%@&%@&%@&%@&%@&%@&%@&%@",AWSAccessKeyId,AssociateTag, 
                                                                                URLEncodedKeywords, Operation,
                                                                                ResponseGroup, SearchIndex,
                                                                                Service, URLEncodedTimestamp, Version];
    NSLog(@"%@", CanonicalizedQueryString);
    
    NSString* stringToSign = [NSString stringWithFormat:@"GET\necs.amazonaws.com\n/onca/xml\n%@", CanonicalizedQueryString];
    NSLog(@"%@", stringToSign);
    
    NSString* signedString = [self hmacForString:stringToSign];
    NSLog(@"%@", signedString);
    NSString* URLEncodedSignedString = [NSString stringWithFormat:@"Signature=%@", [self urlencode:signedString]];
    
    NSString* urlRequest = [NSString stringWithFormat:@"%@%@&%@", baseurl, CanonicalizedQueryString, URLEncodedSignedString];
    NSLog(@"%@", urlRequest);
    
    NSURL *url = [NSURL URLWithString:urlRequest];
    
    //Send http request to fethc lyrics
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    [request setTag:REQUEST_XML];
    [request setDelegate:self];
    [request startAsynchronous];


    
}

- (NSString *)utcTimestamp {
	NSDateFormatter *outputFormatter = [[[NSDateFormatter alloc] init] autorelease];
	outputFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
	outputFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
	return [outputFormatter stringFromDate:[NSDate date]];
}

//simple API that encodes reserved characters according to:
//RFC 3986
//http://tools.ietf.org/html/rfc3986
-(NSString *) urlencode: (NSString *) url {
    NSArray *escapeChars = [NSArray arrayWithObjects:@";" , @"/" , @"?" , @":" ,
							@"@", @"&", @"=", @"+",	@"$" , @"," , @"[" , @"]",
							@"#", @"!", @"'", @"(", @")", @"*", @" ", nil];
	
    NSArray *replaceChars = [NSArray arrayWithObjects:@"%3B" , @"%2F" , @"%3F" ,
							 @"%3A", @"%40", @"%26", @"%3D" , @"%2B" , @"%24" ,
							 @"%2C", @"%5B", @"%5D", @"%23", @"%21", @"%27",
							 @"%28", @"%29", @"%2A", @"%20", nil];
	
    int len = [escapeChars count];
	NSMutableString *temp = [url mutableCopy];
	
    int i;
    for(i = 0; i < len; i++) {
		[temp replaceOccurrencesOfString: [escapeChars objectAtIndex:i]
							  withString:[replaceChars objectAtIndex:i]
								 options:NSLiteralSearch
								   range:NSMakeRange(0, [temp length])];
    }
	
    NSString *out = [NSString stringWithString: temp];
	return out;
}

- (NSString *)hmacForString:(NSString *)signatureInput {
	
	unsigned char digest[CC_SHA256_DIGEST_LENGTH] = {0};
	NSString* key = @"OXa6CQ7zD6xuln7yWjdcm6WDR2m9FjVwwfbQegmt";
	char *keychar = strdup([key UTF8String]);
	char *datachar = strdup([signatureInput UTF8String]);
	
	CCHmacContext hctx;
	CCHmacInit(&hctx, kCCHmacAlgSHA256, keychar, strlen(keychar));
	CCHmacUpdate(&hctx, datachar, strlen(datachar));
	CCHmacFinal(&hctx, digest);
	
	free(keychar);
	free(datachar);
	return [GTMBase64 stringByEncodingBytes:digest length:CC_SHA256_DIGEST_LENGTH];
}


#pragma mark - ASIHTTPRequest delegate
- (void)requestFinished:(ASIHTTPRequest *)request {
    //NSString* stringData = [request responseString];
    //NSLog(@"%@", stringData);    
    //NSLog(@"%i", [request tag]);
    
    if ([request tag] == REQUEST_XML){
        TBXML * tbxml = [[TBXML tbxmlWithXMLData:[request responseData]] retain];
        TBXMLElement * root= tbxml.rootXMLElement;
        TBXMLElement* l1 = [TBXML childElementNamed:@"Items" parentElement:root];
        TBXMLElement* l2 = [TBXML childElementNamed:@"Item" parentElement:l1];
        TBXMLElement* l3 = [TBXML childElementNamed:@"LargeImage" parentElement:l2];
        TBXMLElement* l4 = [TBXML childElementNamed:@"URL" parentElement:l3];
        NSString* imageURL = [TBXML textForElement:l4];
        NSLog(@"%@", imageURL);
        ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:imageURL]];
        [request setTag:REQUEST_COVER];
        [request setDelegate:self];
        [request startAsynchronous];
            
    } else if ([request tag] == REQUEST_COVER) {
        imageView_.image = [[UIImage alloc] initWithData:[request responseData]];
  
    }
                     
    
}

- (void)requestFailed:(ASIHTTPRequest *)request {
    NSError *error = [request error];
    NSLog(@"ASI Error");
}

@end
