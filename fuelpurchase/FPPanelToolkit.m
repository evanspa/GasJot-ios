//
//  FPPanelToolkit.m
//  fuelpurchase
//
//  Created by Evans, Paul on 10/1/14.
//  Copyright (c) 2014 Paul Evans. All rights reserved.
//

#import "FPPanelToolkit.h"
#import <PEObjc-Commons/PEUIUtils.h>
#import <PEObjc-Commons/PEUtils.h>
#import "FPFuelStationCoordinatesTableDataSource.h"
#import "FPFpLogVehicleFuelStationDateDataSourceAndDelegate.h"
#import "FPEnvLogVehicleAndDateDataSourceDelegate.h"
#import <BlocksKit/UIControl+BlocksKit.h>
#import "FPLogEnvLogComposite.h"
#import "FPNames.h"

NSString * const FPFpLogEntityMakerFpLogEntry = @"FPFpLogEntityMakerFpLogEntry";
NSString * const FPFpLogEntityMakerVehicleEntry = @"FPFpLogEntityMakerVehicleEntry";
NSString * const FPFpLogEntityMakerFuelStationEntry = @"FPFpLogEntityMakerFuelStationEntry";

@implementation FPPanelToolkit {
  FPCoordinatorDao *_coordDao;
  PEUIToolkit *_uitoolkit;
  FPScreenToolkit *_screenToolkit;
  NSMutableArray *_tableViewDataSources;
  PELMDaoErrorBlk _errorBlk;
}

#pragma mark - Initializers

- (id)initWithCoordinatorDao:(FPCoordinatorDao *)coordDao
               screenToolkit:(FPScreenToolkit *)screenToolkit
                   uitoolkit:(PEUIToolkit *)uitoolkit
                       error:(PELMDaoErrorBlk)errorBlk {
  self = [super init];
  if (self) {
    _coordDao = coordDao;
    _uitoolkit = uitoolkit;
    _screenToolkit = screenToolkit;
    _tableViewDataSources = [NSMutableArray array];
    _errorBlk = errorBlk;
  }
  return self;
}

#pragma mark - User Account Panel

- (PEEntityPanelMakerBlk)userAccountPanelMaker {
  return ^ UIView * (PEAddViewEditController *parentViewController) {
    UIView *parentView = [parentViewController view];
    UIView *userAccountPanel = [PEUIUtils panelWithWidthOf:1.0
                                               andHeightOf:1.0
                                            relativeToView:parentView];
    TaggedTextfieldMaker tfMaker =
    [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:userAccountPanel];
    UITextField *nameTf = tfMaker(@"Name", FPUserTagName);
    UITextField *usernameTf = tfMaker(@"Username", FPUserTagUsername);
    UITextField *emailTf = tfMaker(@"Email", FPUserTagEmail);
    [PEUIUtils placeView:nameTf
                 atTopOf:userAccountPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:15
                hpadding:0];
    [PEUIUtils placeView:usernameTf
                   below:nameTf
                    onto:userAccountPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:emailTf
                   below:usernameTf
                    onto:userAccountPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    return userAccountPanel;
  };
}

- (PEPanelToEntityBinderBlk)userAccountPanelToUserAccountBinder {
  return ^ void (UIView *panel, FPUser *userAccount) {
    [PEUIUtils bindToEntity:userAccount
           withStringSetter:@selector(setName:)
       fromTextfieldWithTag:FPUserTagName
                   fromView:panel];
    [PEUIUtils bindToEntity:userAccount
           withStringSetter:@selector(setUsername:)
       fromTextfieldWithTag:FPUserTagUsername
                   fromView:panel];
    [PEUIUtils bindToEntity:userAccount
           withStringSetter:@selector(setEmail:)
       fromTextfieldWithTag:FPUserTagEmail
                   fromView:panel];
  };
}

- (PEEntityToPanelBinderBlk)userAccountToUserAccountPanelBinder {
  return ^ void (FPUser *userAccount, UIView *panel) {
    [PEUIUtils bindToTextControlWithTag:FPUserTagName
                               fromView:panel
                             fromEntity:userAccount
                             withGetter:@selector(name)];
    [PEUIUtils bindToTextControlWithTag:FPUserTagUsername
                               fromView:panel
                             fromEntity:userAccount
                             withGetter:@selector(username)];
    [PEUIUtils bindToTextControlWithTag:FPUserTagEmail
                               fromView:panel
                             fromEntity:userAccount
                             withGetter:@selector(email)];
  };
}

- (PEEnableDisablePanelBlk)userAccountPanelEnablerDisabler {
  return ^ (UIView *panel, BOOL enable) {
    [PEUIUtils enableControlWithTag:FPUserTagName
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPUserTagUsername
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPUserTagEmail
                           fromView:panel
                             enable:enable];
  };
}

#pragma mark - Vehicle Panel

- (PEEntityPanelMakerBlk)vehiclePanelMaker {
  return ^ UIView * (PEAddViewEditController *parentViewController) {
    UIView *parentView = [parentViewController view];
    UIView *vehiclePanel = [PEUIUtils panelWithWidthOf:1.0
                                           andHeightOf:1.0
                                        relativeToView:parentView];
    TaggedTextfieldMaker tfMaker =
      [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:vehiclePanel];
    UITextField *vehicleNameTf = tfMaker(@"Vehicle name", FPVehicleTagName);
    UITextField *vehicleDefaultOctaneTf = tfMaker(@"Default octane", FPVehicleTagDefaultOctane);
    [vehicleDefaultOctaneTf setKeyboardType:UIKeyboardTypeNumberPad];
    UITextField *vehicleFuelCapacityTf = tfMaker(@"Fuel capacity", FPVehicleTagFuelCapacity);
    [vehicleFuelCapacityTf setKeyboardType:UIKeyboardTypeDecimalPad];
    [PEUIUtils placeView:vehicleNameTf
                 atTopOf:vehiclePanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:15
                hpadding:0];
    [PEUIUtils placeView:vehicleDefaultOctaneTf
                   below:vehicleNameTf
                    onto:vehiclePanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:vehicleFuelCapacityTf
                   below:vehicleDefaultOctaneTf
                    onto:vehiclePanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    // View Fuel Purchase Logs button
    UIButton *viewFpLogsBtn = [_uitoolkit systemButtonMaker](@"Fuel Purchase Logs", nil, nil);
    [PEUIUtils setFrameWidthOfView:viewFpLogsBtn ofWidth:1.0 relativeTo:vehiclePanel];
    [PEUIUtils addDisclosureIndicatorToButton:viewFpLogsBtn];
    [viewFpLogsBtn bk_addEventHandler:^(id sender) {
      FPVehicle *vehicle = (FPVehicle *)[parentViewController entity];
      FPAuthScreenMaker fpLogsScreenMaker =
        [_screenToolkit newViewFuelPurchaseLogsScreenMakerForVehicleInCtx];
      [PEUIUtils displayController:fpLogsScreenMaker(vehicle) fromController:parentViewController animated:YES];
    } forControlEvents:UIControlEventTouchUpInside];
    [PEUIUtils placeView:viewFpLogsBtn
                   below:vehicleFuelCapacityTf
                    onto:vehiclePanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:30
                hpadding:0];
    // View Environment Logs button
    UIButton *viewEnvLogsBtn = [_uitoolkit systemButtonMaker](@"Environment Logs", nil, nil);
    [PEUIUtils setFrameWidthOfView:viewEnvLogsBtn ofWidth:1.0 relativeTo:vehiclePanel];
    [PEUIUtils addDisclosureIndicatorToButton:viewEnvLogsBtn];
    [viewEnvLogsBtn bk_addEventHandler:^(id sender) {
      FPVehicle *vehicle = (FPVehicle *)[parentViewController entity];
      FPAuthScreenMaker envLogsScreenMaker =
        [_screenToolkit newViewEnvironmentLogsScreenMakerForVehicleInCtx];
      [PEUIUtils displayController:envLogsScreenMaker(vehicle) fromController:parentViewController animated:YES];
    } forControlEvents:UIControlEventTouchUpInside];
    [PEUIUtils placeView:viewEnvLogsBtn
                   below:viewFpLogsBtn
                    onto:vehiclePanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5
                hpadding:0];
    return vehiclePanel;
  };
}

- (PEPanelToEntityBinderBlk)vehiclePanelToVehicleBinder {
  return ^ void (UIView *panel, FPVehicle *vehicle) {
    [PEUIUtils bindToEntity:vehicle
           withStringSetter:@selector(setName:)
       fromTextfieldWithTag:FPVehicleTagName
                   fromView:panel];
    [PEUIUtils bindToEntity:vehicle
           withNumberSetter:@selector(setDefaultOctane:)
       fromTextfieldWithTag:FPVehicleTagDefaultOctane
                   fromView:panel];
    [PEUIUtils bindToEntity:vehicle
          withDecimalSetter:@selector(setFuelCapacity:)
       fromTextfieldWithTag:FPVehicleTagFuelCapacity
                   fromView:panel];
  };
}

- (PEEntityToPanelBinderBlk)vehicleToVehiclePanelBinder {
  return ^ void (FPVehicle *vehicle, UIView *panel) {
    [PEUIUtils bindToTextControlWithTag:FPVehicleTagName
                               fromView:panel
                             fromEntity:vehicle
                             withGetter:@selector(name)];
    [PEUIUtils bindToTextControlWithTag:FPVehicleTagDefaultOctane
                               fromView:panel
                             fromEntity:vehicle
                             withGetter:@selector(defaultOctane)];
    [PEUIUtils bindToTextControlWithTag:FPVehicleTagFuelCapacity
                               fromView:panel
                             fromEntity:vehicle
                             withGetter:@selector(fuelCapacity)];
  };
}

- (PEEnableDisablePanelBlk)vehiclePanelEnablerDisabler {
  return ^ (UIView *panel, BOOL enable) {
    [PEUIUtils enableControlWithTag:FPVehicleTagName
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPVehicleTagDefaultOctane
                           fromView:panel
                             enable:enable];
    [PEUIUtils enableControlWithTag:FPVehicleTagFuelCapacity
                           fromView:panel
                             enable:enable];
  };
}

- (PEEntityMakerBlk)vehicleMaker {
  return ^ PELMModelSupport * (UIView *panel) {
    FPVehicle *newVehicle =
      [_coordDao vehicleWithName:[PEUIUtils stringFromTextFieldWithTag:FPVehicleTagName fromView:panel]
                   defaultOctane:[PEUIUtils numberFromTextFieldWithTag:FPVehicleTagDefaultOctane fromView:panel]
                    fuelCapacity:[PEUIUtils decimalNumberFromTextFieldWithTag:FPVehicleTagFuelCapacity fromView:panel]];
    return newVehicle;
  };
}

#pragma mark - Fuel Station Panel

- (PEEntityPanelMakerBlk)fuelStationPanelMaker {
  return ^ UIView * (PEAddViewEditController *parentViewController) {
    UIView *parentView = [parentViewController view];
    UIView *fuelStationPanel = [PEUIUtils panelWithWidthOf:1.0
                                               andHeightOf:1.1
                                            relativeToView:parentView];
    //[PEUIUtils applyBorderToView:fuelStationPanel withColor:[UIColor greenColor]];
    TaggedTextfieldMaker tfMaker =
      [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:fuelStationPanel];
    UITextField *fuelStationNameTf = tfMaker(@"Fuel station name", FPFuelStationTagName);
    UITextField *fuelStationStreetTf = tfMaker(@"Street", FPFuelStationTagStreet);
    UITextField *fuelStationCityTf = tfMaker(@"City", FPFuelStationTagCity);
    UITextField *fuelStationStateTf = tfMaker(@"State", FPFuelStationTagState);
    UITextField *fuelStationZipTf = tfMaker(@"Zip", FPFuelStationTagZip);
    [fuelStationZipTf setKeyboardType:UIKeyboardTypeNumberPad];
    [PEUIUtils placeView:fuelStationNameTf
                 atTopOf:fuelStationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:15
                hpadding:0];
    [PEUIUtils placeView:fuelStationStreetTf
                   below:fuelStationNameTf
                    onto:fuelStationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:fuelStationCityTf
                   below:fuelStationStreetTf
                    onto:fuelStationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:fuelStationStateTf
                   below:fuelStationCityTf
                    onto:fuelStationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:fuelStationZipTf
                   below:fuelStationStateTf
                    onto:fuelStationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    UITableView *coordinatesTableView =
      [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)
                                   style:UITableViewStyleGrouped];
    FPFuelStationCoordinatesTableDataSource *ds =
      [[FPFuelStationCoordinatesTableDataSource alloc]
        initWithFuelStationLatitude:nil longitude:nil];
    [_tableViewDataSources addObject:ds];
    [coordinatesTableView setDataSource:ds];
    [coordinatesTableView setScrollEnabled:NO];
    [coordinatesTableView setTag:FPFuelStationTagLocationCoordinates];
    [PEUIUtils setFrameWidthOfView:coordinatesTableView ofWidth:1.0 relativeTo:parentView];
    [PEUIUtils setFrameHeightOfView:coordinatesTableView ofHeight:.25 relativeTo:parentView];
    [PEUIUtils placeView:coordinatesTableView
                   below:fuelStationZipTf
                    onto:fuelStationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    UIButton *useCurrentLocationBtn = [_uitoolkit systemButtonMaker](@"Use Current Location", nil, nil);
    [useCurrentLocationBtn setTag:FPFuelStationTagUseCurrentLocation];
    [useCurrentLocationBtn bk_addEventHandler:^(id sender) {
      CLLocation *currentLocation = [APP latestLocation];
      if (currentLocation) {
        [ds setLatitude:[PEUtils decimalNumberFromDouble:[currentLocation coordinate].latitude]];
        [ds setLongitude:[PEUtils decimalNumberFromDouble:[currentLocation coordinate].longitude]];
        [coordinatesTableView reloadData];
      }
    } forControlEvents:UIControlEventTouchUpInside];
    [PEUIUtils setFrameWidthOfView:useCurrentLocationBtn ofWidth:1.0 relativeTo:fuelStationPanel];
    [PEUIUtils placeView:useCurrentLocationBtn
                   below:coordinatesTableView
                    onto:fuelStationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:10.0
                hpadding:0];
    UIButton *recomputeCoordsBtn = [_uitoolkit systemButtonMaker](@"Compute Location from Address", nil, nil);
    [recomputeCoordsBtn setTag:FPFuelStationTagRecomputeCoordinates];
    [recomputeCoordsBtn bk_addEventHandler:^(id sender) {
      MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:parentView animated:YES];
      hud.delegate = parentViewController;
      hud.labelText = @"Computing Location Coordinates";
      CLGeocoder *geocoder = [[CLGeocoder alloc] init];
      [geocoder geocodeAddressString:[PEUtils addressStringFromStreet:[fuelStationStreetTf text]
                                                                 city:[fuelStationCityTf text]
                                                                state:[fuelStationStateTf text]
                                                                  zip:[fuelStationZipTf text]]
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                     if (placemarks && ([placemarks count] > 0)) {
                       CLPlacemark *placemark = placemarks[0];
                       CLLocation *location = [placemark location];
                       CLLocationCoordinate2D coordinate = [location coordinate];
                       [ds setLatitude:[PEUtils decimalNumberFromDouble:coordinate.latitude]];
                       [ds setLongitude:[PEUtils decimalNumberFromDouble:coordinate.longitude]];
                       [coordinatesTableView reloadData];
                       [hud hide:YES];
                     } else if (error) {
                       [hud hide:YES];
                       [PEUIUtils showErrorAlertWithMsgs:nil
                                                   title:@"Oops."
                                        alertDescription:[[NSAttributedString alloc] initWithString:@"There was a problem trying to compute the\n\
location from the given address above."]
                                             buttonTitle:@"Okay."
                                            buttonAction:nil
                                          relativeToView:parentView];
                     }
                   }];
    } forControlEvents:UIControlEventTouchUpInside];
    [PEUIUtils setFrameWidthOfView:recomputeCoordsBtn ofWidth:1.0 relativeTo:fuelStationPanel];
    [PEUIUtils placeView:recomputeCoordsBtn
                   below:useCurrentLocationBtn
                    onto:fuelStationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:10.0
                hpadding:0];
    UIButton *viewFpLogsBtn = [_uitoolkit systemButtonMaker](@"Fuel Purchase Logs", nil, nil);
    [PEUIUtils setFrameWidthOfView:viewFpLogsBtn ofWidth:1.0 relativeTo:fuelStationPanel];
    [PEUIUtils addDisclosureIndicatorToButton:viewFpLogsBtn];
    [viewFpLogsBtn bk_addEventHandler:^(id sender) {
      FPVehicle *vehicle = (FPVehicle *)[parentViewController entity];
      FPAuthScreenMaker fpLogsScreenMaker =
      [_screenToolkit newViewFuelPurchaseLogsScreenMakerForFuelStationInCtx];
      [PEUIUtils displayController:fpLogsScreenMaker(vehicle) fromController:parentViewController animated:YES];
    } forControlEvents:UIControlEventTouchUpInside];
    [PEUIUtils placeView:viewFpLogsBtn
                   below:recomputeCoordsBtn
                    onto:fuelStationPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:30
                hpadding:0];
    
    // wrap fuel station panel in scroll view (so everything can "fit")
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:[fuelStationPanel frame]];
    [scrollView setContentSize:CGSizeMake(fuelStationPanel.frame.size.width, 1.25 * fuelStationPanel.frame.size.height)];
    [scrollView addSubview:fuelStationPanel];
    [scrollView setBounces:NO];
    return scrollView;
  };
}

- (PEPanelToEntityBinderBlk)fuelStationPanelToFuelStationBinder {
  return ^ void (UIView *panel, FPFuelStation *fuelStation) {
    void (^bindte)(NSInteger, SEL) = ^(NSInteger tag, SEL sel) {
      [PEUIUtils bindToEntity:fuelStation
             withStringSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
    };
    bindte(FPFuelStationTagName, @selector(setName:));
    bindte(FPFuelStationTagStreet, @selector(setStreet:));
    bindte(FPFuelStationTagCity, @selector(setCity:));
    bindte(FPFuelStationTagState, @selector(setState:));
    bindte(FPFuelStationTagZip, @selector(setZip:));
    UITableView *coordinatesTableView =
      (UITableView *)[panel viewWithTag:FPFuelStationTagLocationCoordinates];
    FPFuelStationCoordinatesTableDataSource *ds =
      [coordinatesTableView dataSource];
    [fuelStation setLatitude:[ds latitude]];
    [fuelStation setLongitude:[ds longitude]];
  };
}

- (PEEntityToPanelBinderBlk)fuelStationToFuelStationPanelBinder {
  return ^ void (FPFuelStation *fuelStation, UIView *panel) {
    void (^bindtt)(NSInteger, SEL) = ^ (NSInteger tag, SEL sel) {
      [PEUIUtils bindToTextControlWithTag:tag
                                 fromView:panel
                               fromEntity:fuelStation
                               withGetter:sel];
    };
    bindtt(FPFuelStationTagName, @selector(name));
    bindtt(FPFuelStationTagStreet, @selector(street));
    bindtt(FPFuelStationTagCity, @selector(city));
    bindtt(FPFuelStationTagState, @selector(state));
    bindtt(FPFuelStationTagZip, @selector(zip));
    UITableView *coordinatesTableView =
      (UITableView *)[panel viewWithTag:FPFuelStationTagLocationCoordinates];
    FPFuelStationCoordinatesTableDataSource *dataSource =
      (FPFuelStationCoordinatesTableDataSource *)[coordinatesTableView dataSource];
    [dataSource setLatitude:[fuelStation latitude]];
    [dataSource setLongitude:[fuelStation longitude]];
    [coordinatesTableView reloadData];
  };
}

- (PEEnableDisablePanelBlk)fuelStationPanelEnablerDisabler {
  return ^ (UIView *panel, BOOL enable) {
    void (^enabDisab)(NSInteger) = ^(NSInteger tag) {
      [PEUIUtils enableControlWithTag:tag
                             fromView:panel
                               enable:enable];
    };
    enabDisab(FPFuelStationTagName);
    enabDisab(FPFuelStationTagStreet);
    enabDisab(FPFuelStationTagCity);
    enabDisab(FPFuelStationTagState);
    enabDisab(FPFuelStationTagZip);
    enabDisab(FPFuelStationTagUseCurrentLocation);
    enabDisab(FPFuelStationTagRecomputeCoordinates);
  };
}

- (PEEntityMakerBlk)fuelStationMaker {
  return ^ PELMModelSupport * (UIView *panel) {
    NSString *(^tfstr)(NSInteger) = ^ NSString * (NSInteger tag) {
      return [PEUIUtils stringFromTextFieldWithTag:tag fromView:panel];
    };
    UITableView *coordinatesTableView =
      (UITableView *)[panel viewWithTag:FPFuelStationTagLocationCoordinates];
    FPFuelStationCoordinatesTableDataSource *ds =
      [coordinatesTableView dataSource];
    
    FPFuelStation *newFuelstation = [_coordDao fuelStationWithName:tfstr(FPFuelStationTagName)
                                                            street:tfstr(FPFuelStationTagStreet)
                                                              city:tfstr(FPFuelStationTagCity)
                                                             state:tfstr(FPFuelStationTagState)
                                                               zip:tfstr(FPFuelStationTagZip)
                                                          latitude:[ds latitude]
                                                         longitude:[ds longitude]];
    return newFuelstation;
  };
}

#pragma mark - Fuel Purchase / Environment Log Composite Panel (Add only)

- (PEEntityPanelMakerBlk)fpEnvLogCompositePanelMakerWithUser:(FPUser *)user
                                      defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                  defaultSelectedFuelStation:(FPFuelStation *)defaultSelectedFuelStation
                                        defaultPickedLogDate:(NSDate *)defaultPickedLogDate {
  return ^ UIView * (UIViewController *parentViewController) {
    UIView *parentView = [parentViewController view];
    UIView *fpEnvCompPanel = [PEUIUtils panelWithWidthOf:1.0
                                             andHeightOf:1.12
                                          relativeToView:parentView];
    NSDictionary *envlogComponents = [self envlogComponentsWithUser:user
                                             defaultSelectedVehicle:defaultSelectedVehicle
                                               defaultPickedLogDate:defaultPickedLogDate](parentViewController);
    UITextField *odometerTf = envlogComponents[@(FPEnvLogTagOdometer)];
    UITextField *reportedAvgMpgTf = envlogComponents[@(FPEnvLogTagReportedAvgMpg)];
    UITextField *reportedAvgMphTf = envlogComponents[@(FPEnvLogTagReportedAvgMph)];
    UITextField *reportedOutsideTempTf = envlogComponents[@(FPEnvLogTagReportedOutsideTemp)];
    TaggedTextfieldMaker tfMaker =
      [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:fpEnvCompPanel];
    UITextField *preFillupReportedDteTf = tfMaker(@"Pre-fillup Reported DTE", FPFpEnvLogCompositeTagPreFillupReportedDte);
    [preFillupReportedDteTf setKeyboardType:UIKeyboardTypeNumberPad];
    UITextField *postFillupReportedDteTf = tfMaker(@"Post-fillup Reported DTE", FPFpEnvLogCompositeTagPostFillupReportedDte);
    [postFillupReportedDteTf setKeyboardType:UIKeyboardTypeNumberPad];
    NSDictionary *fplogComponents = [self fplogComponentsWithUser:user
                                           defaultSelectedVehicle:defaultSelectedVehicle
                                       defaultSelectedFuelStation:defaultSelectedFuelStation
                                             defaultPickedLogDate:defaultPickedLogDate](parentViewController);
    UITableView *vehicleFuelStationDateTableView = fplogComponents[@(FPFpLogTagVehicleFuelStationAndDate)];
    //[PEUIUtils applyBorderToView:vehicleFuelStationDateTableView withColor:[UIColor yellowColor]];
    UITextField *numGallonsTf = fplogComponents[@(FPFpLogTagNumGallons)];
    UITextField *pricePerGallonTf = fplogComponents[@(FPFpLogTagPricePerGallon)];
    UITextField *octaneTf = fplogComponents[@(FPFpLogTagOctane)];
    UITextField *carWashPerGallonDiscountTf = fplogComponents[@(FPFpLogTagCarWashPerGallonDiscount)];
    UIView *gotCarWashPanel = fplogComponents[@(FPFpLogTagCarWashPanel)];
    [PEUIUtils placeView:vehicleFuelStationDateTableView
                 atTopOf:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    [PEUIUtils placeView:octaneTf
                   below:vehicleFuelStationDateTableView
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:preFillupReportedDteTf
                   below:octaneTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:reportedAvgMpgTf
                   below:preFillupReportedDteTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:reportedAvgMphTf
                   below:reportedAvgMpgTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:odometerTf
                   below:reportedAvgMphTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:reportedOutsideTempTf
                   below:odometerTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:pricePerGallonTf
                   below:reportedOutsideTempTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:carWashPerGallonDiscountTf
                   below:pricePerGallonTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:gotCarWashPanel
                   below:carWashPerGallonDiscountTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:numGallonsTf
                   below:gotCarWashPanel
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:postFillupReportedDteTf
                   below:numGallonsTf
                    onto:fpEnvCompPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    
    NSNumber *defaultOctane = [defaultSelectedVehicle defaultOctane];
    if (defaultOctane) {
      [octaneTf setText:[defaultOctane description]];
    }
    
    // wrap fuel station panel in scroll view (so everything can "fit")
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:[fpEnvCompPanel frame]];
    [scrollView setContentSize:CGSizeMake(fpEnvCompPanel.frame.size.width, 1.25 * fpEnvCompPanel.frame.size.height)];
    [scrollView addSubview:fpEnvCompPanel];
    [scrollView setBounces:NO];
    return scrollView;
  };
}

- (PEPanelToEntityBinderBlk)fpEnvLogCompositePanelToFpEnvLogCompositeBinder {
  PEPanelToEntityBinderBlk fpLogPanelToEntityBinder =
    [self fuelPurchaseLogPanelToFuelPurchaseLogBinder];
  return ^ void (UIView *panel, FPLogEnvLogComposite *fpEnvLogComposite) {
    fpLogPanelToEntityBinder(panel, [fpEnvLogComposite fpLog]);
    void (^binddecToEnvLogs)(NSInteger, SEL) = ^(NSInteger tag, SEL sel) {
      [PEUIUtils bindToEntity:[fpEnvLogComposite preFillupEnvLog]
            withDecimalSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
      [PEUIUtils bindToEntity:[fpEnvLogComposite postFillupEnvLog]
            withDecimalSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
    };
    void (^bindnumToEnvLogs)(NSInteger, SEL) = ^(NSInteger tag, SEL sel) {
      [PEUIUtils bindToEntity:[fpEnvLogComposite preFillupEnvLog]
             withNumberSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
      [PEUIUtils bindToEntity:[fpEnvLogComposite postFillupEnvLog]
             withNumberSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
    };
    binddecToEnvLogs(FPEnvLogTagOdometer, @selector(setOdometer:));
    [PEUIUtils bindToEntity:[fpEnvLogComposite preFillupEnvLog]
          withDecimalSetter:@selector(setReportedDte:)
       fromTextfieldWithTag:FPFpEnvLogCompositeTagPreFillupReportedDte
                   fromView:panel];
    [PEUIUtils bindToEntity:[fpEnvLogComposite postFillupEnvLog]
          withDecimalSetter:@selector(setReportedDte:)
       fromTextfieldWithTag:FPFpEnvLogCompositeTagPostFillupReportedDte
                   fromView:panel];
    binddecToEnvLogs(FPEnvLogTagReportedAvgMpg, @selector(setReportedAvgMpg:));
    binddecToEnvLogs(FPEnvLogTagReportedAvgMph, @selector(setReportedAvgMph:));
    bindnumToEnvLogs(FPEnvLogTagReportedOutsideTemp, @selector(setReportedOutsideTemp:));
    [[fpEnvLogComposite preFillupEnvLog] setLogDate:[[fpEnvLogComposite fpLog] purchasedAt]];
    [[fpEnvLogComposite postFillupEnvLog] setLogDate:[[fpEnvLogComposite fpLog] purchasedAt]];
  };
}

- (PEEntityToPanelBinderBlk)fpEnvLogCompositeToFpEnvLogCompositePanelBinder {
  PEEntityToPanelBinderBlk fpLogToPanelBinder =
    [self fuelPurchaseLogToFuelPurchaseLogPanelBinder];
  return ^ void (FPLogEnvLogComposite *fpEnvLogComposite, UIView *panel) {
    fpLogToPanelBinder([fpEnvLogComposite fpLog], panel);
    void (^bindtt)(NSInteger, SEL) = ^ (NSInteger tag, SEL sel) {
     [PEUIUtils bindToTextControlWithTag:tag
                                fromView:panel
                              fromEntity:[fpEnvLogComposite preFillupEnvLog] // either envLog instance will do here
                              withGetter:sel];
    };
    bindtt(FPEnvLogTagOdometer, @selector(odometer));
    bindtt(FPEnvLogTagReportedAvgMpg, @selector(reportedAvgMpg));
    bindtt(FPEnvLogTagReportedAvgMph, @selector(reportedAvgMph));
    bindtt(FPEnvLogTagReportedOutsideTemp, @selector(reportedOutsideTemp));
    [PEUIUtils bindToTextControlWithTag:FPFpEnvLogCompositeTagPreFillupReportedDte
                               fromView:panel
                             fromEntity:[fpEnvLogComposite preFillupEnvLog]
                             withGetter:@selector(reportedDte)];
    [PEUIUtils bindToTextControlWithTag:FPFpEnvLogCompositeTagPostFillupReportedDte
                               fromView:panel
                             fromEntity:[fpEnvLogComposite postFillupEnvLog]
                             withGetter:@selector(reportedDte)];
  };
}

- (PEEntityMakerBlk)fpEnvLogCompositeMaker {
  return ^ FPLogEnvLogComposite * (UIView *panel) {
    NSNumber *(^tfnum)(NSInteger) = ^ NSNumber * (NSInteger tag) {
      return [PEUIUtils numberFromTextFieldWithTag:tag fromView:panel];
    };
    NSDecimalNumber *(^tfdec)(NSInteger) = ^ NSDecimalNumber * (NSInteger tag) {
      return [PEUIUtils decimalNumberFromTextFieldWithTag:tag fromView:panel];
    };
    UISwitch *gotCarWashSwitch = (UISwitch *)[panel viewWithTag:FPFpLogTagGotCarWash];
    UITableView *vehicleFuelStationDateTableView =
      (UITableView *)[panel viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
    FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
      (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)[vehicleFuelStationDateTableView dataSource];
    FPLogEnvLogComposite *composite = [[FPLogEnvLogComposite alloc] initWithNumGallons:tfdec(FPFpLogTagNumGallons)
                                                                                octane:tfnum(FPFpLogTagOctane)
                                                                           gallonPrice:tfdec(FPFpLogTagPricePerGallon)
                                                                            gotCarWash:[gotCarWashSwitch isOn]
                                                              carWashPerGallonDiscount:tfdec(FPFpLogTagCarWashPerGallonDiscount)
                                                                              odometer:tfdec(FPEnvLogTagOdometer)
                                                                        reportedAvgMpg:tfdec(FPEnvLogTagReportedAvgMpg)
                                                                        reportedAvgMph:tfdec(FPEnvLogTagReportedAvgMph)
                                                                   reportedOutsideTemp:tfnum(FPEnvLogTagReportedOutsideTemp)
                                                                  preFillupReportedDte:tfnum(FPFpEnvLogCompositeTagPreFillupReportedDte)
                                                                 postFillupReportedDte:tfnum(FPFpEnvLogCompositeTagPostFillupReportedDte)
                                                                               logDate:[ds pickedLogDate]
                                                                              coordDao:_coordDao];
    return composite;
  };
}

#pragma mark - Fuel Purchase Log

- (PEComponentsMakerBlk)fplogComponentsWithUser:(FPUser *)user
                         defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                     defaultSelectedFuelStation:(FPFuelStation *)defaultSelectedFuelStation
                           defaultPickedLogDate:(NSDate *)defaultPickedLogDate {
  return ^ NSDictionary * (UIViewController *parentViewController) {
    NSMutableDictionary *components = [NSMutableDictionary dictionary];
    UIView *parentView = [parentViewController view];
    UITableView *vehicleFuelStationDateTableView =
    [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)
                                 style:UITableViewStyleGrouped];
    [vehicleFuelStationDateTableView setScrollEnabled:NO];
    [vehicleFuelStationDateTableView setTag:FPFpLogTagVehicleFuelStationAndDate];
    [PEUIUtils setFrameWidthOfView:vehicleFuelStationDateTableView ofWidth:1.0 relativeTo:parentView];
    [PEUIUtils setFrameHeightOfView:vehicleFuelStationDateTableView ofHeight:.28 relativeTo:parentView];
    vehicleFuelStationDateTableView.sectionHeaderHeight = 2.0;
    vehicleFuelStationDateTableView.sectionFooterHeight = 2.0;
    components[@(FPFpLogTagVehicleFuelStationAndDate)] = vehicleFuelStationDateTableView;
    TaggedTextfieldMaker tfMaker =
    [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:parentView];
    UITextField *numGallonsTf = tfMaker(@"Num gallons", FPFpLogTagNumGallons);
    components[@(FPFpLogTagNumGallons)] = numGallonsTf;
    [numGallonsTf setKeyboardType:UIKeyboardTypeDecimalPad];
    UITextField *pricePerGallonTf =
      tfMaker(@"Price per gallon", FPFpLogTagPricePerGallon);
    components[@(FPFpLogTagPricePerGallon)] = pricePerGallonTf;
    [pricePerGallonTf setKeyboardType:UIKeyboardTypeDecimalPad];
    UITextField *octaneTf = tfMaker(@"Octane", FPFpLogTagOctane);
    if (defaultSelectedVehicle) {
      NSNumber *defaultOctane = [defaultSelectedVehicle defaultOctane];
      if (defaultOctane) {
        [octaneTf setText:[defaultOctane description]];
      }
    }
    [octaneTf setKeyboardType:UIKeyboardTypeNumberPad];
    components[@(FPFpLogTagOctane)] = octaneTf;
    UITextField *carWashPerGallonDiscountTf =
    tfMaker(@"Car was per-gallon discount", FPFpLogTagCarWashPerGallonDiscount);
    [carWashPerGallonDiscountTf setKeyboardType:UIKeyboardTypeDecimalPad];
    components[@(FPFpLogTagCarWashPerGallonDiscount)] = carWashPerGallonDiscountTf;
    UISwitch *gotCarWashSwitch =
    [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    [gotCarWashSwitch setTag:FPFpLogTagGotCarWash];
    components[@(FPFpLogTagGotCarWash)] = gotCarWashSwitch;
    UIView *gotCarWashPanel =
    [PEUIUtils panelWithWidthOf:1.0
                 relativeToView:parentView
                    fixedHeight:numGallonsTf.frame.size.height];
    [gotCarWashPanel setTag:FPFpLogTagCarWashPanel];
    [gotCarWashPanel setBackgroundColor:[UIColor whiteColor]];
    UILabel *gotCarWashLbl =
    [PEUIUtils labelWithKey:@"Got car wash?"
                       font:[numGallonsTf font]
            backgroundColor:[UIColor clearColor]
                  textColor:[_uitoolkit colorForTableCellTitles]
      horizontalTextPadding:3.0
        verticalTextPadding:3.0];
    [PEUIUtils placeView:gotCarWashLbl
              inMiddleOf:gotCarWashPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                hpadding:10.0];
    [PEUIUtils placeView:gotCarWashSwitch
            toTheRightOf:gotCarWashLbl
                    onto:gotCarWashPanel
           withAlignment:PEUIVerticalAlignmentTypeCenter
                hpadding:15.0];
    components[@(FPFpLogTagCarWashPanel)] = gotCarWashPanel;
    PEItemSelectedAction vehicleSelectedAction = ^(FPVehicle *vehicle, NSIndexPath *indexPath, UIViewController *vehicleSelectionController) {
      [[vehicleSelectionController navigationController] popViewControllerAnimated:YES];
      [vehicleFuelStationDateTableView
       reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] // 'Vehicle' is col-index 0
       withRowAnimation:UITableViewRowAnimationAutomatic];
      NSNumber *defaultOctane = [vehicle defaultOctane];
      if (defaultOctane) {
        [octaneTf setText:[defaultOctane description]];
      } else {
        [octaneTf setText:@""];
      }
    };
    PEItemSelectedAction fuelStationSelectedAction = ^(FPFuelStation *fuelStation, NSIndexPath *indexPath, UIViewController *fuelStationSelectionController) {
      [[fuelStationSelectionController navigationController] popViewControllerAnimated:YES];
      [vehicleFuelStationDateTableView
       reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] // 'Fuel Station' is col-index 1
       withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    void (^logDatePickedAction)(NSDate *) = ^(NSDate *logDate) {
      [vehicleFuelStationDateTableView
       reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:2]] // 'Log Date' is col-index 2
       withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
    [[FPFpLogVehicleFuelStationDateDataSourceAndDelegate alloc]
     initWithControllerCtx:parentViewController
     defaultSelectedVehicle:defaultSelectedVehicle
     defaultSelectedFuelStation:defaultSelectedFuelStation
     defaultLogDate:defaultPickedLogDate
     vehicleSelectedAction:vehicleSelectedAction
     fuelStationSelectedAction:fuelStationSelectedAction
     logDatePickedAction:logDatePickedAction
     coordinatorDao:_coordDao
     user:user
     screenToolkit:_screenToolkit
     error:_errorBlk];
    [_tableViewDataSources addObject:ds];
    [vehicleFuelStationDateTableView setDataSource:ds];
    [vehicleFuelStationDateTableView setDelegate:ds];
    return components;
  };
}

- (PEEntityPanelMakerBlk)fuelPurchaseLogPanelMakerWithUser:(FPUser *)user
                                    defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                defaultSelectedFuelStation:(FPFuelStation *)defaultSelectedFuelStation
                                      defaultPickedLogDate:(NSDate *)defaultPickedLogDate {
  return ^ UIView * (UIViewController *parentViewController) {
    UIView *parentView = [parentViewController view];
    UIView *fpLogPanel = [PEUIUtils panelWithWidthOf:1.0
                                         andHeightOf:1.0
                                      relativeToView:parentView];
    NSDictionary *components = [self fplogComponentsWithUser:user
                                      defaultSelectedVehicle:defaultSelectedVehicle
                                  defaultSelectedFuelStation:defaultSelectedFuelStation
                                        defaultPickedLogDate:defaultPickedLogDate](parentViewController);
    UITableView *vehicleFuelStationDateTableView = components[@(FPFpLogTagVehicleFuelStationAndDate)];
    UITextField *numGallonsTf = components[@(FPFpLogTagNumGallons)];
    UITextField *pricePerGallonTf = components[@(FPFpLogTagPricePerGallon)];
    UITextField *octaneTf = components[@(FPFpLogTagOctane)];
    UITextField *carWashPerGallonDiscountTf = components[@(FPFpLogTagCarWashPerGallonDiscount)];
    UIView *gotCarWashPanel = components[@(FPFpLogTagCarWashPanel)];
    [PEUIUtils placeView:vehicleFuelStationDateTableView
                 atTopOf:fpLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    [PEUIUtils placeView:octaneTf
                   below:vehicleFuelStationDateTableView
                    onto:fpLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:pricePerGallonTf
                   below:octaneTf
                    onto:fpLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:carWashPerGallonDiscountTf
                   below:pricePerGallonTf
                    onto:fpLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:gotCarWashPanel
                   below:carWashPerGallonDiscountTf
                    onto:fpLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:numGallonsTf
                   below:gotCarWashPanel
                    onto:fpLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    
//    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:[fpLogPanel frame]];
//    [scrollView setContentSize:CGSizeMake(fpLogPanel.frame.size.width, 1.3 * fpLogPanel.frame.size.height)];
//    [scrollView addSubview:fpLogPanel];
//    [scrollView setBounces:NO];
//    return scrollView;
    return fpLogPanel;
  };
}

- (PEPanelToEntityBinderBlk)fuelPurchaseLogPanelToFuelPurchaseLogBinder {
  return ^ void (UIView *panel, FPFuelPurchaseLog *fpLog) {
    void (^binddec)(NSInteger, SEL) = ^(NSInteger tag, SEL sel) {
      [PEUIUtils bindToEntity:fpLog
            withDecimalSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
    };
    void (^bindnum)(NSInteger, SEL) = ^(NSInteger tag, SEL sel) {
      [PEUIUtils bindToEntity:fpLog
             withNumberSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
    };
    binddec(FPFpLogTagNumGallons, @selector(setNumGallons:));
    binddec(FPFpLogTagPricePerGallon, @selector(setGallonPrice:));
    bindnum(FPFpLogTagOctane, @selector(setOctane:));
    binddec(FPFpLogTagCarWashPerGallonDiscount, @selector(setCarWashPerGallonDiscount:));
    UISwitch *gotCarWasSwitch = (UISwitch *)[panel viewWithTag:FPFpLogTagGotCarWash];
    [fpLog setGotCarWash:[gotCarWasSwitch isOn]];
    
    UITableView *vehicleFuelStationDateTableView =
      (UITableView *)[panel viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
    FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
      (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)[vehicleFuelStationDateTableView dataSource];
    [fpLog setPurchasedAt:[ds pickedLogDate]];
  };
}

- (PEEntityToPanelBinderBlk)fuelPurchaseLogToFuelPurchaseLogPanelBinder {
  return ^ void (FPFuelPurchaseLog *fpLog, UIView *panel) {
    if (fpLog) {
      void (^bindtt)(NSInteger, SEL) = ^ (NSInteger tag, SEL sel) {
        [PEUIUtils bindToTextControlWithTag:tag
                                   fromView:panel
                                 fromEntity:fpLog
                                 withGetter:sel];
      };
      bindtt(FPFpLogTagNumGallons, @selector(numGallons));
      bindtt(FPFpLogTagPricePerGallon, @selector(gallonPrice));
      bindtt(FPFpLogTagOctane, @selector(octane));
      bindtt(FPFpLogTagCarWashPerGallonDiscount, @selector(carWashPerGallonDiscount));
      UISwitch *gotCarWasSwitch = (UISwitch *)[panel viewWithTag:FPFpLogTagGotCarWash];
      [gotCarWasSwitch setOn:[fpLog gotCarWash] animated:YES];
      
      if ([fpLog purchasedAt]) {
        UITableView *vehicleFuelStationDateTableView =
        (UITableView *)[panel viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
        FPFpLogVehicleFuelStationDateDataSourceAndDelegate *ds =
        (FPFpLogVehicleFuelStationDateDataSourceAndDelegate *)[vehicleFuelStationDateTableView dataSource];
        [ds setPickedLogDate:[fpLog purchasedAt]];
        [vehicleFuelStationDateTableView reloadData];
      }
    }
  };
}

- (PEEnableDisablePanelBlk)fuelPurchaseLogPanelEnablerDisabler {
  return ^ (UIView *panel, BOOL enable) {
    void (^enabDisab)(NSInteger) = ^(NSInteger tag) {
      [PEUIUtils enableControlWithTag:tag
                             fromView:panel
                               enable:enable];
    };
    enabDisab(FPFpLogTagVehicleFuelStationAndDate);
    enabDisab(FPFpLogTagNumGallons);
    enabDisab(FPFpLogTagPricePerGallon);
    enabDisab(FPFpLogTagOctane);
    enabDisab(FPFpLogTagCarWashPerGallonDiscount);
    enabDisab(FPFpLogTagGotCarWash);
    UITableView *vehicleFuelStationDateTableView =
      (UITableView *)[panel viewWithTag:FPFpLogTagVehicleFuelStationAndDate];
    [vehicleFuelStationDateTableView setUserInteractionEnabled:enable];
  };
}

#pragma mark - Environment Log

- (PEComponentsMakerBlk)envlogComponentsWithUser:(FPUser *)user
                          defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                            defaultPickedLogDate:(NSDate *)defaultPickedLogDate {
  return ^ NSDictionary * (UIViewController *parentViewController) {
    NSMutableDictionary *components = [NSMutableDictionary dictionary];
    UIView *parentView = [parentViewController view];
    UITableView *vehicleAndLogDateTableView =
    [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)
                                 style:UITableViewStyleGrouped];
    [vehicleAndLogDateTableView setScrollEnabled:NO];
    [vehicleAndLogDateTableView setTag:FPEnvLogTagVehicleAndDate];
    [PEUIUtils setFrameWidthOfView:vehicleAndLogDateTableView ofWidth:1.0 relativeTo:parentView];
    [PEUIUtils setFrameHeightOfView:vehicleAndLogDateTableView ofHeight:.22 relativeTo:parentView];
    PEItemSelectedAction vehicleSelectedAction = ^(FPVehicle *vehicle, NSIndexPath *indexPath, UIViewController *vehicleSelectionController) {
      [[vehicleSelectionController navigationController] popViewControllerAnimated:YES];
      [vehicleAndLogDateTableView
       reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] // 'Vehicle' is col-index 0
       withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    void (^logDatePickedAction)(NSDate *) = ^(NSDate *logDate) {
      [vehicleAndLogDateTableView
       reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] // 'Log Date' is col-index 1
       withRowAnimation:UITableViewRowAnimationAutomatic];
    };
    FPEnvLogVehicleAndDateDataSourceDelegate *ds =
    [[FPEnvLogVehicleAndDateDataSourceDelegate alloc]
     initWithControllerCtx:parentViewController
     defaultSelectedVehicle:defaultSelectedVehicle
     defaultLogDate:defaultPickedLogDate
     vehicleSelectedAction:vehicleSelectedAction
     logDatePickedAction:logDatePickedAction
     coordinatorDao:_coordDao
     user:user
     screenToolkit:_screenToolkit
     error:_errorBlk];
    [_tableViewDataSources addObject:ds];
    vehicleAndLogDateTableView.sectionHeaderHeight = 2.0;
    vehicleAndLogDateTableView.sectionFooterHeight = 2.0;
    [vehicleAndLogDateTableView setDataSource:ds];
    [vehicleAndLogDateTableView setDelegate:ds];
    components[@(FPEnvLogTagVehicleAndDate)] = vehicleAndLogDateTableView;
    TaggedTextfieldMaker tfMaker =
      [_uitoolkit taggedTextfieldMakerForWidthOf:1.0 relativeTo:parentView];
    UITextField *odometerTf = tfMaker(@"Odometer", FPEnvLogTagOdometer);
    [odometerTf setKeyboardType:UIKeyboardTypeDecimalPad];
    components[@(FPEnvLogTagOdometer)] = odometerTf;
    UITextField *reportedDteTf = tfMaker(@"Reported DTE", FPEnvLogTagReportedDte);
    [reportedDteTf setKeyboardType:UIKeyboardTypeNumberPad];
    components[@(FPEnvLogTagReportedDte)] = reportedDteTf;
    UITextField *reportedAvgMpgTf =
    tfMaker(@"Reported avg mpg", FPEnvLogTagReportedAvgMpg);
    [reportedAvgMpgTf setKeyboardType:UIKeyboardTypeDecimalPad];
    components[@(FPEnvLogTagReportedAvgMpg)] = reportedAvgMpgTf;
    UITextField *reportedAvgMphTf = tfMaker(@"Reported avg mph", FPEnvLogTagReportedAvgMph);
    [reportedAvgMphTf setKeyboardType:UIKeyboardTypeDecimalPad];
    components[@(FPEnvLogTagReportedAvgMph)] = reportedAvgMphTf;
    UITextField *reportedOutsideTempTf =
    tfMaker(@"Reported outside temperature", FPEnvLogTagReportedOutsideTemp);
    [reportedOutsideTempTf setKeyboardType:UIKeyboardTypeNumberPad];
    components[@(FPEnvLogTagReportedOutsideTemp)] = reportedOutsideTempTf;
    return components;
  };
}

- (PEEntityPanelMakerBlk)environmentLogPanelMakerWithUser:(FPUser *)user
                                   defaultSelectedVehicle:(FPVehicle *)defaultSelectedVehicle
                                     defaultPickedLogDate:(NSDate *)defaultPickedLogDate {
  return ^ UIView * (UIViewController *parentViewController) {
    UIView *parentView = [parentViewController view];
    UIView *envLogPanel = [PEUIUtils panelWithWidthOf:1.0
                                          andHeightOf:1.0
                                       relativeToView:parentView];
    NSDictionary *components = [self envlogComponentsWithUser:user
                                       defaultSelectedVehicle:defaultSelectedVehicle
                                         defaultPickedLogDate:defaultPickedLogDate](parentViewController);
    UITableView *vehicleAndLogDateTableView = components[@(FPEnvLogTagVehicleAndDate)];
    UITextField *odometerTf = components[@(FPEnvLogTagOdometer)];
    UITextField *reportedDteTf = components[@(FPEnvLogTagReportedDte)];
    UITextField *reportedAvgMpgTf = components[@(FPEnvLogTagReportedAvgMpg)];
    UITextField *reportedAvgMphTf = components[@(FPEnvLogTagReportedAvgMph)];
    UITextField *reportedOutsideTempTf = components[@(FPEnvLogTagReportedOutsideTemp)];
    [PEUIUtils placeView:vehicleAndLogDateTableView
                 atTopOf:envLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    [PEUIUtils placeView:odometerTf
                   below:vehicleAndLogDateTableView
                    onto:envLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:0.0
                hpadding:0.0];
    [PEUIUtils placeView:reportedAvgMpgTf
                   below:odometerTf
                    onto:envLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:reportedDteTf
                   below:reportedAvgMpgTf
                    onto:envLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:reportedAvgMphTf
                   below:reportedDteTf
                    onto:envLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    [PEUIUtils placeView:reportedOutsideTempTf
                   below:reportedAvgMphTf
                    onto:envLogPanel
           withAlignment:PEUIHorizontalAlignmentTypeLeft
                vpadding:5.0
                hpadding:0.0];
    return envLogPanel;
  };
}

- (PEPanelToEntityBinderBlk)environmentLogPanelToEnvironmentLogBinder {
  return ^ void (UIView *panel, FPEnvironmentLog *envLog) {
    void (^binddec)(NSInteger, SEL) = ^(NSInteger tag, SEL sel) {
      [PEUIUtils bindToEntity:envLog
            withDecimalSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
    };
    void (^bindnum)(NSInteger, SEL) = ^(NSInteger tag, SEL sel) {
      [PEUIUtils bindToEntity:envLog
             withNumberSetter:sel
         fromTextfieldWithTag:tag
                     fromView:panel];
    };
    binddec(FPEnvLogTagOdometer, @selector(setOdometer:));
    binddec(FPEnvLogTagReportedDte, @selector(setReportedDte:));
    binddec(FPEnvLogTagReportedAvgMpg, @selector(setReportedAvgMpg:));
    binddec(FPEnvLogTagReportedAvgMph, @selector(setReportedAvgMph:));
    bindnum(FPEnvLogTagReportedOutsideTemp, @selector(setReportedOutsideTemp:));
    
    UITableView *vehicleAndDateTableView =
      (UITableView *)[panel viewWithTag:FPEnvLogTagVehicleAndDate];
    FPEnvLogVehicleAndDateDataSourceDelegate *ds =
      (FPEnvLogVehicleAndDateDataSourceDelegate *)[vehicleAndDateTableView dataSource];
    [envLog setLogDate:[ds pickedLogDate]];
  };
}

- (PEEntityToPanelBinderBlk)environmentLogToEnvironmentLogPanelBinder {
  return ^ void (FPEnvironmentLog *envLog, UIView *panel) {
    void (^bindtt)(NSInteger, SEL) = ^ (NSInteger tag, SEL sel) {
      [PEUIUtils bindToTextControlWithTag:tag
                                 fromView:panel
                               fromEntity:envLog
                               withGetter:sel];
    };
    bindtt(FPEnvLogTagOdometer, @selector(odometer));
    bindtt(FPEnvLogTagReportedDte, @selector(reportedDte));
    bindtt(FPEnvLogTagReportedAvgMpg, @selector(reportedAvgMpg));
    bindtt(FPEnvLogTagReportedAvgMph, @selector(reportedAvgMph));
    bindtt(FPEnvLogTagReportedOutsideTemp, @selector(reportedOutsideTemp));
    if ([envLog logDate]) {
      UITableView *vehicleAndDateTableView =
        (UITableView *)[panel viewWithTag:FPEnvLogTagVehicleAndDate];
      FPEnvLogVehicleAndDateDataSourceDelegate *ds =
        (FPEnvLogVehicleAndDateDataSourceDelegate *)[vehicleAndDateTableView dataSource];
      [ds setPickedLogDate:[envLog logDate]];
      [vehicleAndDateTableView reloadData];
    }
    // FYI, we have to do the binding back up the screen toolkit method because
    // we simply don't have access to envlog's associated vehicle; we only have
    // access to the vehicle back in the screnn toolkit context.
  };
}

- (PEEnableDisablePanelBlk)environmentLogPanelEnablerDisabler {
  return ^ (UIView *panel, BOOL enable) {
    void (^enabDisab)(NSInteger) = ^(NSInteger tag) {
      [PEUIUtils enableControlWithTag:tag
                             fromView:panel
                               enable:enable];
    };
    enabDisab(FPEnvLogTagOdometer);
    enabDisab(FPEnvLogTagReportedDte);
    enabDisab(FPEnvLogTagReportedAvgMpg);
    enabDisab(FPEnvLogTagReportedAvgMph);
    enabDisab(FPEnvLogTagReportedOutsideTemp);
    UITableView *vehicleAndDateTableView =
      (UITableView *)[panel viewWithTag:FPEnvLogTagVehicleAndDate];
    [vehicleAndDateTableView setUserInteractionEnabled:enable];
  };
}

- (PEEntityMakerBlk)environmentLogMaker {
  return ^ PELMModelSupport * (UIView *panel) {
    NSNumber *(^tfnum)(NSInteger) = ^ NSNumber * (NSInteger tag) {
      return [PEUIUtils numberFromTextFieldWithTag:tag fromView:panel];
    };
    NSDecimalNumber *(^tfdec)(NSInteger) = ^ NSDecimalNumber * (NSInteger tag) {
      return [PEUIUtils decimalNumberFromTextFieldWithTag:tag fromView:panel];
    };
    UITableView *vehicleAndDateTableView =
      (UITableView *)[panel viewWithTag:FPEnvLogTagVehicleAndDate];
    FPEnvLogVehicleAndDateDataSourceDelegate *ds =
      (FPEnvLogVehicleAndDateDataSourceDelegate *)[vehicleAndDateTableView dataSource];
    
    FPEnvironmentLog *envlog = [_coordDao environmentLogWithOdometer:tfdec(FPEnvLogTagOdometer)
                                                      reportedAvgMpg:tfdec(FPEnvLogTagReportedAvgMpg)
                                                      reportedAvgMph:tfdec(FPEnvLogTagReportedAvgMph)
                                                 reportedOutsideTemp:tfnum(FPEnvLogTagReportedOutsideTemp)
                                                             logDate:[ds pickedLogDate]
                                                         reportedDte:tfnum(FPEnvLogTagReportedDte)];
    return envlog;
  };
}

@end
