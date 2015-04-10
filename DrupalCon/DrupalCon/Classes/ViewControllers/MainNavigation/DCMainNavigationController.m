//
//  DCMainNavigationController.m
//  DrupalCon
//
//  Created by Volodymyr Hyrka on 2/27/15.
//  Copyright (c) 2015 Lemberg Solution. All rights reserved.
//

#import "DCMainNavigationController.h"
#import "DCSideMenuViewController.h"
#import "MFSideMenuContainerViewController.h"
#import "DCAppFacade.h"
#import "DCLimitedNavigationController.h"

@interface DCMainNavigationController ()

@property (nonatomic, weak) DCSideMenuViewController* sideMenuController;

@end


@implementation DCMainNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [DCAppFacade shared].mainNavigationController = self;
    
    if ([DCMainProxy sharedProxy].state != DCMainProxyStateInitDataLoading)
    {
            // if it's not a first loading - go forward to Side menu; else FirstLaunchVC will be shown (root)
        [[DCAppFacade shared].mainNavigationController goToSideMenuContainer: nil];
    }
    return;
}

- (void)openEventFromFavoriteController:(DCEvent *)event
{
    [self goToSideMenuContainer:NO];
    [self.sideMenuController openEventFromFavorite:event];
}

- (void) goToSideMenuContainer:(BOOL)animated
{
    DCSideMenuViewController *sideMenuViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"SideMenuViewController"];
    
    self.sideMenuController = sideMenuViewController;
    
    MFSideMenuContainerViewController *container = [MFSideMenuContainerViewController containerWithCenterViewController: nil
                                                                                                 leftMenuViewController: self.sideMenuController
                                                                                                rightMenuViewController: nil];
    sideMenuViewController.sideMenuContainer = container;
    
    [self pushViewController:container animated: animated];
}

-(UIViewController *)childViewControllerForStatusBarStyle
{
    if ([self.visibleViewController isKindOfClass:[MFSideMenuContainerViewController class]])
    {
        MFSideMenuContainerViewController* topController = (MFSideMenuContainerViewController*)self.visibleViewController;
        
        UIViewController* menuController = topController.leftMenuViewController;
        UIViewController* sideController = topController.centerViewController;
        
            // asks for Statur Bar for SideMenuController
        if (menuController && [sideController isKindOfClass:[NSNull class]])
            return menuController;

        if (topController.menuState == MFSideMenuStateClosed)
        {
            if ([sideController isKindOfClass:[UINavigationController class]])
            {
                // asks for Statur Bar for SideMenu Item viewController
                return [(UINavigationController*)sideController visibleViewController];
            }
        }
        else
        {
            return menuController;
        }
    }
    else
    {
        return self.visibleViewController;
    }
    
    return self.visibleViewController;
}

@end
