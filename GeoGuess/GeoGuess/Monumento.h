//
//  Monumento.h
//  GeoGuess
//
//  Created by Nicolás Hechim on 16/1/17.
//  Copyright © 2017 Meri Herrera. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Monumento : NSObject
@property(nonatomic) NSString* nombre;
@property(nonatomic) NSString* ciudad;
@property(nonatomic) CGFloat lat;
@property(nonatomic) CGFloat lng;
@property(nonatomic) CGFloat distancia;
@property(nonatomic) CGFloat pitch;
@property(nonatomic) CGFloat heading;

@end
