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
        
        defaultImage_ = [UIImage imageNamed:@"no_image.gif"];
    }
    return self;
}



//Set the image for imageView
-(void) setCoverArtImage:(UIImage*)image {
    imageView_.image = image;    
}

//Fetch covert art from amazon
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
    //NSLog(@"%@", CanonicalizedQueryString);
    
    NSString* stringToSign = [NSString stringWithFormat:@"GET\necs.amazonaws.com\n/onca/xml\n%@", CanonicalizedQueryString];
    //NSLog(@"%@", stringToSign);
    
    NSString* signedString = [self hmacForString:stringToSign];
    //NSLog(@"%@", signedString);
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
    NSArray *escapeChars = [NSArray arrayWithObjects:@"`", @";" , @"/" , @"?" , @":" ,
							@"@", @"&", @"=", @"+",	@"$" , @"," , @"[" , @"]",
							@"#", @"!", @"'", @"(", @")", @"*", @" ", nil];
	
    NSArray *replaceChars = [NSArray arrayWithObjects:@"", @"%3B" , @"%2F" , @"%3F" ,
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

        //Check validity Case 1
        TBXMLElement* firstChild = root->firstChild;
        if( [[TBXML elementName:firstChild] isEqualToString:@"Error"]){
            NSLog(@"ERROR: Amazon XML contains error. Probably signature is not correct");
            return;
        }
        
        //Check validity Case 2
        TBXMLElement* l1 = [TBXML childElementNamed:@"Items" parentElement:root];
        TBXMLElement* l2 = [TBXML childElementNamed:@"Request" parentElement:l1];
        TBXMLElement* element = [TBXML childElementNamed:@"IsValid" parentElement:l2];
        
        while ((element = element->nextSibling)) {
            //Return if error was found
            NSLog(@"Cur Element: %@", [TBXML elementName:element]);
            if ([[TBXML elementName:element] isEqualToString:@"Errors"]) {
                NSLog(@"ERROR: Amazon XML contains an error.");
                imageView_.image = defaultImage_;
                return;
            }
            
        }
                
        TBXMLElement* l3 = [TBXML childElementNamed:@"Item" parentElement:l1];
        TBXMLElement* l4 = [TBXML childElementNamed:@"LargeImage" parentElement:l3];
        TBXMLElement* l5 = [TBXML childElementNamed:@"URL" parentElement:l4];
        NSString* imageURL = [TBXML textForElement:l5];
        NSLog(@"%@", imageURL);
        [tbxml release];
        
        
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
    imageView_.image = defaultImage_;
}





//- (void)loadUnknownXML {
//    // Load and parse the books.xml file
//    tbxml = [[TBXML tbxmlWithXMLFile:@"books.xml"] retain];
//    
//    // If TBXML found a root node, process element and iterate all children
//    if (tbxml.rootXMLElement)
//        [self traverseElement:tbxml.rootXMLElement];
//    
//    // release resources
//    [tbxml release];
//}
//
//- (void) traverseElement:(TBXMLElement *)element {
//    
//    do {
//        // Display the name of the element
//        NSLog(@"%@",[TBXML elementName:element]);
//        
//        // Obtain first attribute from element
//        TBXMLAttribute * attribute = element->firstAttribute;
//        
//        // if attribute is valid
//        while (attribute) {
//            // Display name and value of attribute to the log window
//            NSLog(@"%@->%@ = %@",
//                  [TBXML elementName:element],
//                  [TBXML attributeName:attribute],
//                  [TBXML attributeValue:attribute]);
//            
//            // Obtain the next attribute
//            attribute = attribute->next;
//        }
//        
//        // if the element has child elements, process them
//        if (element->firstChild) 
//            [self traverseElement:element->firstChild];
//        
//        // Obtain next sibling element
//    } while ((element = element->nextSibling));  
//}
//


@end
