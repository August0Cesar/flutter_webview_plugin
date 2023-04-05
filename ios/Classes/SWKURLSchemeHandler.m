#import "SWKURLSchemeHandler.h"
#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <WebKit/WKURLSchemeHandler.h>


@implementation SWKURLSchemeHandler

# pragma mark - WKURLSchemeHandler callbacks

- (void)webView:(nonnull WKWebView *)webView startURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask {
    
    NSURL *fileURL = urlSchemeTask.request.URL;
    
    NSLog(@"SD/ url -> %@", fileURL.absoluteString);
    
    fileURL = [self changeURLScheme:urlSchemeTask.request.URL toScheme:@"https"];  
        
    NSURLRequest* fileUrlRequest = [[NSURLRequest alloc] initWithURL:fileURL];
//cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:360];
    
    //Aqui eu valido se ja existe um cache para essa requisicao
    NSURLCache *myNSURLCache = [NSURLCache sharedURLCache];
    if([urlSchemeTask.request.HTTPMethod isEqualToString:@"GET"] && myNSURLCache != nil){
        
        NSCachedURLResponse *cacheResponse = [myNSURLCache cachedResponseForRequest:fileUrlRequest];
        if(cacheResponse != nil && cacheResponse.response != nil && cacheResponse.data != nil){
            
           NSLog(@"SD/ cache existe para %@", fileURL.absoluteString);
            [urlSchemeTask didReceiveResponse:cacheResponse.response];
            [urlSchemeTask didReceiveData:cacheResponse.data];
            [urlSchemeTask didFinish];
            
            return;
        }
    }
        
    fileUrlRequest = [self addCustomHeadersInRequest:fileUrlRequest logHeaders:YES fromRequest:urlSchemeTask.request];
    NSLog(@"SD/ vai fazer a request para %@", fileURL.absoluteString);
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:fileUrlRequest 
        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if(error){
            NSLog(@"SD/ Erro ao tentar fazer a requisicao %@ ", error);
            // [urlSchemeTask didFailWithError:error];
        }
        
        [urlSchemeTask didReceiveResponse:response];
        [urlSchemeTask didReceiveData:data];
        [urlSchemeTask didFinish];
        
    }];
    
    [dataTask resume];
    
}

- (void)webView:(nonnull WKWebView *)webView stopURLSchemeTask:(nonnull id<WKURLSchemeTask>)urlSchemeTask {
    NSLog(@"SD/ stopURLScheme hhhhhh");
}

- (NSURL *)changeURLScheme:(NSURL *)url toScheme:(NSString *)newScheme {
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    components.scheme = newScheme;
    return components.URL;
}

-(NSURLRequest *)addCustomHeadersInRequest:(NSURLRequest *)request logHeaders:(BOOL)isAllowed fromRequest:(NSURLRequest *)fromRequest{

    // NSLog(@"fromRequest %@", fromRequest);

    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    if (mutableRequest != nil) {
        NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for(NSHTTPCookie *cookie in cookieStorage.cookies) {
            [mutableRequest setValue:cookie.value forHTTPHeaderField:cookie.name];
        }
        
        //problema com origem
        NSDictionary *allHeaders = fromRequest.allHTTPHeaderFields;
        NSMutableDictionary *dictHeaders = [[NSMutableDictionary alloc] init];
        for (NSString *key in [allHeaders allKeys]) {
            //  if(![key containsString:@"Origin"]){ 
            //     [dictHeaders setObject:[allHeaders valueForKey:key] forKey:key];
            //  }
            [dictHeaders setObject:[allHeaders valueForKey:key] forKey:key];

            // if([key containsString:@"Origin"]){
            //     NSString *urlOrigem = [dictHeaders valueForKey:key];
            //     urlOrigem = [urlOrigem stringByReplacingOccurrencesOfString:@"mycustomurl"
            //                                                         withString:@"https"];
            //     [dictHeaders setObject:urlOrigem forKey:@"Origin"];
                
            //     NSLog(@"My keyOrigem:%@ value:%@", key, [dictHeaders valueForKey:key]);
            // }
        }

        //Forcando a Origem certa
        if(![request.URL.absoluteString containsString:@"app.sults.com.br"]){
            NSString *origem = @"https://treinamento.sults.com.br";
            dictHeaders[@"Origin"] = origem;
        }
        //Forcando a Origem certa

        if (fromRequest) {
            [mutableRequest setHTTPBody:[fromRequest HTTPBody]];
            [mutableRequest setHTTPMethod:[fromRequest HTTPMethod]];
            [mutableRequest setAllHTTPHeaderFields:dictHeaders];
        }
    }
    
    return [mutableRequest copy];
}

//- (void) printAllCache {
//    WKWebsiteDataStore* dataStore = [WKWebsiteDataStore defaultDataStore];
//    NSMutableArray *wKWebsiteDataTypeCacheArray = [NSMutableArray arrayWithObjects:WKWebsiteDataTypeMemoryCache, WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeOfflineWebApplicationCache, nil];
//    NSSet<NSString *> *websiteDataTypes = [NSSet setWithArray:wKWebsiteDataTypeCacheArray];
//
//    void (^printValuesCahce)(NSArray<WKWebsiteDataRecord *> *) =
//        ^(NSArray<WKWebsiteDataRecord *> *currentCache) {
//
//            NSLog(@"SD/ Atual cache %@", currentCache);
//        };
//
//    [dataStore fetchDataRecordsOfTypes:websiteDataTypes completionHandler:printValuesCahce];
//}

@end
