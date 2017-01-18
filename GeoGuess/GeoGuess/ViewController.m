//
//  ViewController.m
//  GeoGuess
//  Copyright (c) 2017 dedam. All rights reserved.
//

#import "ViewController.h"
#import "Monumento.h"
#import "SoundManager.h"
#include <stdlib.h>
#import <QuartzCore/QuartzCore.h>

@interface ViewController (){
    UILongPressGestureRecognizer* longPressGestureRecognizer;
    UISwipeGestureRecognizer* swipeGestureRecognizer;
    Monumento* monumentoEnJuego;
    CLLocationCoordinate2D eleccionUsuario;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Tipo de mapa
    [_mapaMonumento setMapType:MKMapTypeSatelliteFlyover];
    [_mapaMonumento setPitchEnabled:YES];
    
    // Borde curvo
    _viewInstrucciones.layer.cornerRadius = 5;
    _viewInstrucciones.layer.masksToBounds = YES;
    [_mapaResultado setDelegate:self];
    
    longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc]
                                  initWithTarget:self
                                  action:@selector(handleLongPressGesture:)];
    swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(siguienteMonumento:)];
    [swipeGestureRecognizer setDirection:UISwipeGestureRecognizerDirectionLeft];
    
    [self initJuego];
}

// Inicialización del juego y mostrar el primer mapa con el monumento.
- (void) initJuego {
    monumentoEnJuego = nil;
    [self initMonumentos];
    [self mostrarMonumento];
    _distanciaPartida = 0;
    [_labelDistanciaTotal setText: [NSString stringWithFormat:@"%dkm",_distanciaPartida]];
}

// Muestra un monumento al azar en el mapaMonumento.
// Llama a la función setRegion para centrar el mapa.
// Cambia la configuración de la cámara usando los parámetros del monumento que se va a mostrar.
// Si al ir a mostrar un nueva monumento vemos que nuestro array ya no tiene más elementos, daremos la
// opción de volver a empezar el juego.
-(void) mostrarMonumento {
    monumentoEnJuego = [self selectRandomMonumento];
    [self.view removeGestureRecognizer:swipeGestureRecognizer];
    
    [self deshabilitarAmbos];
    if(monumentoEnJuego != nil)
    {
        CLLocationCoordinate2D posicionMonumento = CLLocationCoordinate2DMake(monumentoEnJuego.lat, monumentoEnJuego.lng);
        [self setRegion:posicionMonumento distancia: monumentoEnJuego.distancia enMapa:_mapaMonumento];
    
        MKMapCamera* currentCamera  = _mapaMonumento.camera;
        [currentCamera setCenterCoordinate:CLLocationCoordinate2DMake(monumentoEnJuego.lat, monumentoEnJuego.lng)];
        [currentCamera setPitch:monumentoEnJuego.pitch];
        [currentCamera setHeading:monumentoEnJuego.heading];
        [_mapaMonumento setCamera:currentCamera animated:NO];
        
        [_mapaResultado addGestureRecognizer:longPressGestureRecognizer];
    }
    else
    {
        // Volver a comenzar?
        UIAlertController *alerta = [UIAlertController
                                     alertControllerWithTitle:@"¿Otra oportunidad?"
                                     message:@"El juego ha terminado. ¡Puedes volver a comenzar!"
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                     style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction * action){
                                                      [self initJuego];
                                                   }];
        
        [alerta addAction:ok];
        [self presentViewController:alerta animated:YES completion:nil];
    }
}

// Centra un mapa en una región (MKCoordinateRegion) con centro y tamaño indicado por los parámetros.
- (void) setRegion:(CLLocationCoordinate2D)centro distancia:(int)distancia enMapa:(MKMapView*)mapa {
    MKCoordinateRegion regionMonumento = MKCoordinateRegionMakeWithDistance(centro, distancia,distancia);
    [mapa setRegion:regionMonumento];
}

// Nos da un monumento aleatorio del array de monumentos y lo eliminará del array. Durante el juego
// deberemos pasar por todos los monumentos en orden aleatorio, pero sin repetir ninguno de ellos.
- (Monumento*) selectRandomMonumento {
    int cantidadMonumentos = (int)_monumentos.count;
    Monumento* retorno = nil;
    
    if(cantidadMonumentos != 0)
    {
        int posicionRandom = [self getRandomNumberBetween:0 to: cantidadMonumentos-1];
        retorno = _monumentos[posicionRandom];
        [_monumentos removeObjectAtIndex:posicionRandom];
    }
    return retorno;
}

// Recoge las coordenadas del punto donde ha pulsado el jugador.
// Llama a la función para mostrar una anotación en ese punto.
-(IBAction)handleLongPressGesture:(UILongPressGestureRecognizer*)gestureRecognizer {
    if (gestureRecognizer.state != UIGestureRecognizerStateBegan)
        return;
    
    [self borrarAnotaciones];
    CGPoint puntoEnView = [gestureRecognizer locationInView:_mapaResultado];
    eleccionUsuario = [_mapaResultado convertPoint:puntoEnView
                                                        toCoordinateFromView:_mapaResultado];
    
    [self mostrarAnotacion:eleccionUsuario title:@"Tu respuesta" subtitle:@"¡Esta es tu elección!"];
    [self habilitarAccionValidar];
}

// Muestra una anotación (MKPointAnnotation) en el mapaMundo.
-(void) mostrarAnotacion:(CLLocationCoordinate2D)coordenadas title:(NSString*)titulo subtitle:(NSString*)subtitulo {
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    [annotation setCoordinate:coordenadas];
    [annotation setTitle:titulo];
    [annotation setSubtitle:subtitulo];
    
    [_mapaResultado addAnnotation:annotation];
}

// Borra las anotaciones y los overlays anteriores del mapaMundo.
-(void)borrarAnotaciones {
    [_mapaResultado removeAnnotations:_mapaResultado.annotations];
    [_mapaResultado removeOverlays:_mapaResultado.overlays];
}

// Nos devuelve un número aleatorio entre dos valores.
-(int)getRandomNumberBetween:(int)from to:(int)to {
    return (int)from + arc4random() % (to-from+1);
}

// Desactiva el longPress gesture.
// Llama a la función que calcula la distancia entre el lugar donde el jugador ha puesto la anotación y
// la ubicación del monumento.
// Centra el mapaMundo en las coordenadas del monumento.
// Llama a la función mostrarAnotacion para mostrar una anotación en las coordenadas del monumento, con
// su nombre, ciudad y distancia.
// Llama a la función de dibujar línea
- (IBAction)validarJuego:(id)sender {
    [_mapaResultado removeGestureRecognizer: longPressGestureRecognizer];
    [self.view addGestureRecognizer:swipeGestureRecognizer];
    
    CLLocation *hasta = [[CLLocation alloc] initWithLatitude:monumentoEnJuego.lat longitude:monumentoEnJuego.lng];
    CLLocation *desde = [[CLLocation alloc] initWithLatitude:eleccionUsuario.latitude longitude:eleccionUsuario.longitude];
    int distancia = [self distancia:desde hasta:hasta];
    
    CLLocationCoordinate2D coordMonumento = CLLocationCoordinate2DMake(monumentoEnJuego.lat, monumentoEnJuego.lng);
    CLLocationCoordinate2D coordUsuario = CLLocationCoordinate2DMake(eleccionUsuario.latitude, eleccionUsuario.longitude);
    
    [_mapaResultado showAnnotations:@[desde,hasta] animated:YES];
    NSString* subtitulo = [NSString stringWithFormat:@"%@(%d km)", monumentoEnJuego.ciudad, distancia];
    [self mostrarAnotacion:coordMonumento title:monumentoEnJuego.nombre subtitle:subtitulo];
    
    [self dibujarLineaDesde:coordUsuario hasta:coordMonumento];
    [self habilitarAccionSiguiente];
}

// Llama a la función de borrarAnotaciones.
// Llama a la función de mostrarMonumento.
// Vuelve a agregar el longPress gesture recognizer al mapa.
- (IBAction)siguienteMonumento:(id)sender {
    [self borrarAnotaciones];
    [self mostrarMonumento];
}

// Nos retorna la distancia en kilometros entre dos puntos.
// Además, iremos acumulando las distancias calculadas durante la partida en la etiquetaDistancia.
- (int) distancia:(CLLocation*)desde hasta:(CLLocation*)hasta {
    int distancia = [hasta distanceFromLocation:desde] / 1000;
    _distanciaPartida += distancia;
    [_labelDistanciaTotal setText: [NSString stringWithFormat:@"%dkm",_distanciaPartida]];
    
    if(distancia < 300)
    {
        [self playSound:@"applause-moderate-03.wav"];
    }
    else
    {
        if(distancia < 1000){
            [self playSound:@"applause-light-02.wav"];
        }
        else{
            [self playSound:@"boo-01.wav"];
        }
    }
    return distancia;
}

-(void)playSound:(NSString*) nombreSonido{
    [[SoundManager sharedManager] playSound:nombreSonido looping:NO];
}

// Dibuja una línea (MKPolyline) entre dos puntos.
- (void) dibujarLineaDesde:(CLLocationCoordinate2D)desde hasta:(CLLocationCoordinate2D)hasta {
    CLLocationCoordinate2D points[2];
    
    points[0] = desde;
    points[1] = hasta;
    MKPolyline *overlayPolyline = [MKPolyline polylineWithCoordinates:points count:2];
    MKGeodesicPolyline *geodesicPolyline = [MKGeodesicPolyline polylineWithCoordinates:points count:2];
    
    [_mapaResultado addOverlay:overlayPolyline];
    [_mapaResultado addOverlay:geodesicPolyline];
}


- (MKOverlayRenderer *) mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    
    MKPolylineRenderer *polylineRender  = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
    UIColor *lineColor = [UIColor redColor];
    [polylineRender setStrokeColor:lineColor];
    [polylineRender setLineWidth:3.0f];
    
    return polylineRender;
}

-(void) habilitarAccionSiguiente {
    [_buttonValida setEnabled:NO];
    [_buttonValida setBackgroundColor:[UIColor lightGrayColor]];
    [_buttonSiguiente setEnabled:YES];
    [_buttonSiguiente setBackgroundColor:[UIColor orangeColor]];
    [_labelEtiquetaTitulo setText: monumentoEnJuego.nombre];
    [_labelEtiquetaSubtitulo setText:monumentoEnJuego.ciudad.uppercaseString];
}

-(void) habilitarAccionValidar {
    [_buttonSiguiente setEnabled:NO];
    [_buttonSiguiente setBackgroundColor:[UIColor lightGrayColor]];
    [_buttonValida setEnabled:YES];
    [_buttonValida setBackgroundColor:[UIColor orangeColor]];
    [_labelEtiquetaTitulo setText:@"Sitúa el monumento en el mapa"];
    [_labelEtiquetaSubtitulo setText:@""];
}

-(void) deshabilitarAmbos {
    [_buttonSiguiente setEnabled:NO];
    [_buttonSiguiente setBackgroundColor:[UIColor lightGrayColor]];
    [_buttonValida setEnabled:NO];
    [_buttonValida setBackgroundColor:[UIColor lightGrayColor]];
    [_labelEtiquetaTitulo setText:@"Sitúa el monumento en el mapa"];
    [_labelEtiquetaSubtitulo setText:@""];
}

-(void) initMonumentos {
    Monumento *monumento1 = [[Monumento alloc] init];
    
    monumento1.nombre = @"La Sagrada Familia";
    monumento1.ciudad = @"BARCELONA";
    monumento1.lat = 41.4028931;
    monumento1.lng = 2.1719068;
    monumento1.distancia = 450;
    monumento1.pitch = 80;
    monumento1.heading = 70;
    
    Monumento *monumento2 = [[Monumento alloc] init];
    monumento2.nombre = @"La Puerta de Alcalá";
    monumento2.ciudad = @"MADRID";
    monumento2.lat = 40.420788;
    monumento2.lng = -3.688876;
    monumento2.distancia = 200;
    monumento2.pitch = 25;
    monumento2.heading = 230;
    
    Monumento *monumento3 = [[Monumento alloc] init];
    monumento3.nombre = @"Empire State";
    monumento3.ciudad = @"NEW YORK";
    monumento3.lat = 40.748327;
    monumento3.lng = -73.985471;
    monumento3.distancia = 925;
    monumento3.pitch = 45;
    monumento3.heading = 170;
    
    Monumento *monumento4 = [[Monumento alloc] init];
    monumento4.nombre = @"La Torre Eiffel";
    monumento4.ciudad = @"PARÍS";
    monumento4.lat = 48.8583701;
    monumento4.lng = 2.2922926;
    monumento4.distancia = 1200;
    monumento4.pitch = 60;
    monumento4.heading = 60;
    
    Monumento *monumento5 = [[Monumento alloc] init];
    monumento5.nombre = @"El Coliseo";
    monumento5.ciudad = @"ROMA";
    monumento5.lat = 41.8902102;
    monumento5.lng = 12.4900422;
    monumento5.distancia = 250;
    monumento5.pitch = 80;
    monumento5.heading = 75;
    
    Monumento *monumento6 = [[Monumento alloc] init];
    monumento6.nombre = @"La Casa Blanca";
    monumento6.ciudad = @"WASHINGTON";
    monumento6.lat = 38.8976815;
    monumento6.lng = -77.0368423;
    monumento6.distancia = 500;
    monumento6.pitch = 45;
    monumento6.heading = 0;
    
    Monumento *monumento7 = [[Monumento alloc] init];
    monumento7.nombre = @"El Big Ben";
    monumento7.ciudad = @"LONDRES";
    monumento7.lat = 51.5007292;
    monumento7.lng = -0.1268141;
    monumento7.distancia = 550;
    monumento7.pitch = 80;
    monumento7.heading = 260;
    
    Monumento *monumento8 = [[Monumento alloc] init];
    monumento8.nombre = @"El Kremlin";
    monumento8.ciudad = @"MOSCÚ";
    monumento8.lat = 55.751382;
    monumento8.lng = 37.618446;
    monumento8.distancia = 600;
    monumento8.pitch = 30;
    monumento8.heading = 280;
    
    Monumento *monumento9 = [[Monumento alloc] init];
    monumento9.nombre = @"Tokyo Tower";
    monumento9.ciudad = @"TOKYO";
    monumento9.lat = 35.6585805;
    monumento9.lng = 139.7448857;
    monumento9.distancia = 900;
    monumento9.pitch = 45;
    monumento9.heading = 0;
    
    Monumento *monumento10 = [[Monumento alloc] init];
    monumento10.nombre = @"La Opera";
    monumento10.ciudad = @"SIDNEY";
    monumento10.lat = -33.857033;
    monumento10.lng = 151.215191;
    monumento10.distancia = 500;
    monumento10.pitch = 45;
    monumento10.heading = 110;
    
    Monumento *monumento11 = [[Monumento alloc] init];
    monumento11.nombre = @"El Partenón";
    monumento11.ciudad = @"ATENES";
    monumento11.lat = 37.971402;
    monumento11.lng = 23.726591;
    monumento11.distancia = 500;
    monumento11.pitch = 65;
    monumento11.heading = 0;
    
    Monumento *monumento12 = [[Monumento alloc] init];
    monumento12.nombre = @"Plaza de la Constitución";
    monumento12.ciudad = @"MEXICO DF";
    monumento12.lat = 19.4319642;
    monumento12.lng = -99.1333981;
    monumento12.distancia = 500;
    monumento12.pitch = 45;
    monumento12.heading = 0;
    
    Monumento *monumento13 = [[Monumento alloc] init];
    monumento13.nombre = @"Santa Sofía";
    monumento13.ciudad = @"ISTANBUL";
    monumento13.lat = 41.005270;
    monumento13.lng = 28.976960;
    monumento13.distancia = 500;
    monumento13.pitch = 45;
    monumento13.heading = 0;
    
    Monumento *monumento14 = [[Monumento alloc] init];
    monumento14.nombre = @"La Puerta de Brandenburgo";
    monumento14.ciudad = @"BERLÍN";
    monumento14.lat = 52.5162746;
    monumento14.lng = 13.3755153;
    monumento14.distancia = 400;
    monumento14.pitch = 75;
    monumento14.heading = 260;
    
    Monumento *monumento15 = [[Monumento alloc] init];
    monumento15.nombre = @"La Plaza de Mayo";
    monumento15.ciudad = @"BUENOS AIRES";
    monumento15.lat = -34.6080556;
    monumento15.lng = -58.3724665;
    monumento15.distancia = 500;
    monumento15.pitch = 45;
    monumento15.heading = 75;
    
    _monumentos = [NSMutableArray arrayWithObjects:monumento1, monumento2, monumento3, monumento4, monumento5, monumento6, monumento7, monumento8, monumento9, monumento10, monumento11, monumento12, monumento13, monumento14, monumento15, nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
