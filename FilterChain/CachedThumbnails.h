//
//  CachedThumbnails.h
//  FilterChain
//
//  Created by Ryan Cumley on 9/20/13.
//  Copyright (c) 2013 Ryan Cumley. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CachedThumbnails : NSObject <NSFileManagerDelegate>
{
    NSFileManager* fileManager;
    NSMutableArray* fileUrlsForThumbnails;
    NSString* thumbnailsPath;
}

- (UIImage*)thumbnailForURL:(NSURL*)targetUrl;
- (void)deleteThumbnailForURL:(NSURL*)targetUrl;

- (BOOL)thumbnailAlreadyExistsForPath:(NSString*)targetPath;
- (UIImage*)generateNewThumbnailForURL:(NSURL*)targetUrl withPath:(NSString*)path;
- (NSString*)thumbnailPathFromVideoUrl:(NSURL*)videoUrl;
- (NSString*)thumbnailsPath;

@end
