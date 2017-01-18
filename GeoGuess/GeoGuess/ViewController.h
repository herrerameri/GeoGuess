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

@interface ViewController : UIViewController<MKMapViewDelegate>

@property (strong, nonatomic) IBOutlet UILabel *labelDistanciaTotal;
@property (strong, nonatomic) IBOutlet MKMapView *mapaMonumento;
@property (strong, nonatomic) IBOutlet MKMapView *mapaResultado;
@property (strong, nonatomic) NSMutableArray* monumentos;
@property (nonatomic) int distanciaPartida;
@property (strong, nonatomic) IBOutlet UIView *viewInstrucciones;
@property (strong, nonatomic) IBOutlet UILabel *labelEtiquetaSubtitulo;
@property (strong, nonatomic) IBOutlet UILabel *labelEtiquetaTitulo;
@property (strong, nonatomic) IBOutlet UIButton *buttonValida;
@property (strong, nonatomic) IBOutlet UIButton *buttonSiguiente;

- (IBAction)validarJuego:(id)sender;
- (IBAction)siguienteMonumento:(id)sender;
@end

