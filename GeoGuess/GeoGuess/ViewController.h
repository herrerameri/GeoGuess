//
//  ViewController.h
//  GeoGuess
//
//  Created by Nicolás Hechim on 16/1/17.
//  Copyright © 2017 Meri Herrera. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController

@property (strong, nonatomic) IBOutlet UILabel *labelDistanciaTotal;
@property (strong, nonatomic) IBOutlet MKMapView *mapaMonumento;
@property (strong, nonatomic) IBOutlet MKMapView *mapaResultado;
@property (strong, nonatomic) NSMutableArray* monumentos;
@property (nonatomic) CGFloat distanciaPartida;
@property (strong, nonatomic) IBOutlet UIView *viewInstrucciones;

- (IBAction)validarJuego:(id)sender;
- (IBAction)siguienteMonumento:(id)sender;
@end

