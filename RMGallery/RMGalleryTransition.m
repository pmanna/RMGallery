//
//  RMGalleryTransition.m
//  RMGallery
//
//  Created by Hermés Piqué on 16/04/14.
//  Copyright (c) 2014 Robot Media. All rights reserved.
//

#import "RMGalleryTransition.h"
#import "RMGalleryViewController.h"

CGRect RMCGRectAspectFit(CGSize sourceSize, CGSize size)
{
    const CGFloat targetAspect = size.width / size.height;
    const CGFloat sourceAspect = sourceSize.width / sourceSize.height;
    CGRect rect = CGRectZero;
    
    if (targetAspect > sourceAspect)
    {
        rect.size.height = size.height;
        rect.size.width = rect.size.height * sourceAspect;
        rect.origin.x = (size.width - rect.size.width) * 0.5;
    }
    else
    {
        rect.size.width = size.width;
        rect.size.height = rect.size.width / sourceAspect;
        rect.origin.y = (size.height - rect.size.height) * 0.5;
    }
    return CGRectIntegral(rect);
}

@interface RMGalleryViewController(RMGalleryTransition)

@property (nonatomic, readonly) RMGalleryCell *transitionGalleryCell;

@end

@interface RMGalleryCell(RMGalleryTransition)

@property (nonatomic, readonly) UIImageView *imageView; // Implemented in RMGalleryCell.m

@end

@implementation RMGalleryTransition

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *viewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    return viewController.isBeingPresented ? 0.5 : 0.25;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *viewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    if (viewController.isBeingPresented)
    {
        [self animateZoomInTransition:transitionContext];
    }
    else
    {
        [self animateZoomOutTransition:transitionContext];
    }
}

- (void)animateZoomInTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *containerView = transitionContext.containerView;
    
    RMGalleryViewController *galleryViewController = [self galleryViewControllerFromViewController:toViewController];
    const NSUInteger galleryIndex = galleryViewController.galleryIndex;
    
    UIImage *transitionImage = [self transitionImageForIndex:galleryIndex];
    UIImageView *transitionView = [[UIImageView alloc] initWithImage:transitionImage];
    transitionView.contentMode = UIViewContentModeScaleAspectFill;
    transitionView.clipsToBounds = YES;
    
    UIView *fromView = fromViewController.view;
    const CGRect referenceRect = [self transitionRectForIndex:galleryIndex inView:fromView];
    transitionView.frame = [containerView convertRect:referenceRect fromView:fromView];
    
    UIView *coverView = [[UIView alloc] initWithFrame:transitionView.frame];
    coverView.backgroundColor = [self coverColorForIndex:galleryIndex inView:fromView];
    [containerView addSubview:coverView];

    UIView *backgroundView = [[UIView alloc] initWithFrame:containerView.bounds];
    backgroundView.backgroundColor = [UIColor blackColor];
    backgroundView.alpha = 0;
    [containerView addSubview:backgroundView];
    
    [containerView addSubview:transitionView];
    
    const NSTimeInterval duration = [self transitionDuration:transitionContext];
    [UIView animateWithDuration:duration
                          delay:0
         usingSpringWithDamping:0.7
          initialSpringVelocity:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         backgroundView.alpha = 1;
                         
                         const CGRect transitionViewFinalFrame = RMCGRectAspectFit(transitionImage.size, containerView.bounds.size);
                         transitionView.frame = transitionViewFinalFrame;
                     }
                     completion:^(BOOL finished) {
                         fromView.alpha = 1;
                         [backgroundView removeFromSuperview];
                         [coverView removeFromSuperview];
                         [transitionView removeFromSuperview];
                         
                         UIView *toView = toViewController.view;
                         [containerView addSubview:toView];
                         CGRect finalFrame = [transitionContext finalFrameForViewController:toViewController];
                         if (CGRectIsEmpty(finalFrame))
                         { // In case finalFrameForViewController returns CGRectZero
                             finalFrame = fromView.bounds;
                         }
                         toView.frame = finalFrame;
                         [toView layoutIfNeeded];
                         
                         RMGalleryCell *transitionGalleryCell = galleryViewController.transitionGalleryCell;
                         const CGSize imageSize = [self estimatedImageSizeForIndex:galleryIndex];
                         [transitionGalleryCell setImage:transitionImage inSize:imageSize];
                         
                         [transitionContext completeTransition:YES];
                     }];
}

- (void)animateZoomOutTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    // Get the view controllers participating in the transition
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIView *containerView = transitionContext.containerView;
    
    UIView *toView = toViewController.view;
    [containerView addSubview:toView];
    [containerView sendSubviewToBack:toView];
    toView.frame = [transitionContext finalFrameForViewController:toViewController];
    toView.alpha = 0;
    [toView layoutIfNeeded];
    
    RMGalleryViewController *galleryViewController = [self galleryViewControllerFromViewController:fromViewController];
    RMGalleryCell *transitionGalleryCell = galleryViewController.transitionGalleryCell;
    UIImageView *fromImageView = transitionGalleryCell.imageView;
    CGRect transitionViewInitialFrame = RMCGRectAspectFit(fromImageView.image.size, fromImageView.bounds.size);
    transitionViewInitialFrame = [transitionContext.containerView convertRect:transitionViewInitialFrame fromView:fromImageView];
    
    const NSUInteger galleryIndex = galleryViewController.galleryIndex;
    const CGRect referenceRect = [self transitionRectForIndex:galleryIndex inView:toView];
    const CGRect transitionViewFinalFrame = [transitionContext.containerView convertRect:referenceRect fromView:toView];
    
    UIView *coverView = coverView = [[UIView alloc] initWithFrame:referenceRect];
    coverView.backgroundColor = [self coverColorForIndex:galleryIndex inView:toView];
    [toViewController.view addSubview:coverView];

    UIImageView *transitionView = [[UIImageView alloc] initWithImage:fromImageView.image];
    transitionView.contentMode = UIViewContentModeScaleAspectFill;
    transitionView.clipsToBounds = YES;
    transitionView.frame = transitionViewInitialFrame;
    [containerView addSubview:transitionView];
    [fromViewController.view removeFromSuperview];
    
    // Perform the transition
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         toViewController.view.alpha = 1;
                         transitionView.frame = transitionViewFinalFrame;
                     } completion:^(BOOL finished) {
                         [coverView removeFromSuperview];
                         [transitionView removeFromSuperview];
                         [transitionContext completeTransition:YES];
                     }];
}

#pragma mark Utils

- (UIColor*)coverColorForIndex:(NSUInteger)index inView:(UIView*)view
{
    UIImageView *imageView = [self transitionImageViewForIndex:index];
    if (imageView)
    {
        UIView *superview = imageView.superview;
        return superview.backgroundColor;
    }
    return view.backgroundColor;
}

- (CGSize)estimatedImageSizeForIndex:(NSUInteger)index
{
    if ([self.delegate respondsToSelector:@selector(galleryTransition:estimatedSizeForIndex:)])
    {
        return [self.delegate galleryTransition:self estimatedSizeForIndex:index];
    }
    UIImageView *imageView = [self transitionImageViewForIndex:index];
    UIImage *image = imageView.image;
    return image ? image.size : CGSizeZero;
}

- (UIImage*)transitionImageForIndex:(NSUInteger)index
{
    if ([self.delegate respondsToSelector:@selector(galleryTransition:transitionImageForIndex:)])
    {
        UIImage *image = [self.delegate galleryTransition:self transitionImageForIndex:index];
        if (image) return image;
    }
    UIImageView *imageView = [self transitionImageViewForIndex:index];
    return imageView.image;
}

- (UIImageView*)transitionImageViewForIndex:(NSUInteger)index
{
    if ([self.delegate respondsToSelector:@selector(galleryTransition:transitionImageViewForIndex:)])
    {
        return [self.delegate galleryTransition:self transitionImageViewForIndex:index];
    }
    return nil;
}

- (CGRect)transitionRectForIndex:(NSUInteger)index inView:(UIView*)view
{
    if ([self.delegate respondsToSelector:@selector(galleryTransition:transitionRectForIndex:inView:)])
    {
        return [self.delegate galleryTransition:self transitionRectForIndex:index inView:view];
    }
    UIImageView *imageView = [self transitionImageViewForIndex:index];
    return imageView ? imageView.frame : CGRectZero;
}

- (RMGalleryViewController*)galleryViewControllerFromViewController:(UIViewController*)viewController
{
    if ([viewController isKindOfClass:RMGalleryViewController.class]) return (RMGalleryViewController*) viewController;

    if ([viewController isKindOfClass:UINavigationController.class])
    {
        UINavigationController *navigationController = (UINavigationController*)viewController;
        UIViewController *topViewController = navigationController.topViewController;
        if ([topViewController isKindOfClass:RMGalleryViewController.class]) return (RMGalleryViewController*) topViewController;
    }
    
    return nil;
}

@end

@implementation RMGalleryViewController(RMGalleryTransition)

- (RMGalleryCell*)transitionGalleryCell
{
    RMGalleryView *galleryView = self.galleryView;
    const NSUInteger galleryIndex = self.galleryIndex;
    RMGalleryCell *cell = [galleryView galleryCellAtIndex:galleryIndex];
    return cell;
}

@end
