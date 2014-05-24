//
//  ViewController.m
//  Breakout
//
//  Created by Vik Denic on 5/22/14.
//  Copyright (c) 2014 Mobile Makers. All rights reserved.
//

#import "ViewController.h"
#import "PaddleView.h"
#import "BallView.h"
#import "BlockView.h"

#import <QuartzCore/QuartzCore.h> //for rounded view

@interface ViewController () <UICollisionBehaviorDelegate>

@property (weak, nonatomic) IBOutlet PaddleView *paddleView;
@property (weak, nonatomic) IBOutlet BallView *ballView;

@property UIDynamicAnimator *dynamicAnimator;

@property UIDynamicItemBehavior *paddleDynamicBehavior;
@property UIDynamicItemBehavior *ballDynamicBehavior;

@property UIPushBehavior *pushBehavior;

@property UICollisionBehavior *collisionBehavior;

@property UIGravityBehavior *gravityBehavior;

@property UISnapBehavior *snapBehavior;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Provides physics-related capabilities and animations for paddle and ball
    self.dynamicAnimator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];

    // Applies a continuous or instantaneous force to dynamic items
    self.pushBehavior = [[UIPushBehavior alloc] initWithItems:@[self.ballView] mode:UIPushBehaviorModeInstantaneous];

    // Sets up properties for the pushBehavior and add it to the dynamicAnimator
    self.pushBehavior.pushDirection = CGVectorMake(0.5, 1.0);
    self.pushBehavior.active = YES;
    self.pushBehavior.magnitude = 0.15;
    [self.dynamicAnimator addBehavior:self.pushBehavior];

    // Dynamic animation configuration for paddle
    self.paddleDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.paddleView]];
    self.paddleDynamicBehavior.density = INT_MAX;
    self.paddleDynamicBehavior.elasticity = 1.0;
    self.paddleDynamicBehavior.allowsRotation = NO;
    [self.dynamicAnimator addBehavior:self.paddleDynamicBehavior];

    // A dynamic item behavior represents a base dynamic animation configuration for one or more dynamic items.
    self.ballDynamicBehavior = [[UIDynamicItemBehavior alloc] initWithItems:@[self.ballView]];
    self.ballDynamicBehavior.allowsRotation = NO;
    self.ballDynamicBehavior.elasticity = 1.0;
    self.ballDynamicBehavior.friction = 0.0;
    self.ballDynamicBehavior.resistance = 0.0;

    [self.dynamicAnimator addBehavior:self.ballDynamicBehavior];

    self.gravityBehavior =[[UIGravityBehavior alloc] initWithItems:@[self.ballView]];
    self.gravityBehavior.magnitude = 0.0;
    [self.dynamicAnimator addBehavior:self.gravityBehavior];

    // Allows items to engage in collisions with each other and with the behavior’s specified boundaries
    self.collisionBehavior = [[UICollisionBehavior alloc] initWithItems:@[self.ballView, self.paddleView]];
    self.collisionBehavior.collisionMode = UICollisionBehaviorModeEverything;
    self.collisionBehavior.translatesReferenceBoundsIntoBoundary = YES;
    [self.dynamicAnimator addBehavior:self.collisionBehavior];

    // Sets collision delegate to ViewController
    self.collisionBehavior.collisionDelegate = self;

    // Call rounded circle method on ballView
    [self setRoundedView:self.ballView toDiameter:15.0];

    // Creates BlockView objects for Level 1
    [self createBlocksForLevel1];

}

// New blocks for Level 1, with color, placement, and behaviors
-(void)createBlocksForLevel1
{
    BlockView *blockView1 = [[BlockView alloc]initWithFrame:CGRectMake(62, 172, 55, 20)];
    [self behaviorsForNewBlocks:blockView1 withColor:[UIColor purpleColor]];

    BlockView *blockView2 = [[BlockView alloc]initWithFrame:CGRectMake(134, 138, 55, 20)];
    [self behaviorsForNewBlocks:blockView2 withColor:[UIColor purpleColor]];

    BlockView *blockView3 = [[BlockView alloc]initWithFrame:CGRectMake(206, 172, 55, 20)];
    [self behaviorsForNewBlocks:blockView3 withColor:[UIColor purpleColor]];

    BlockView *blockView4 = [[BlockView alloc]initWithFrame:CGRectMake(134, 207, 55, 20)];
    [self behaviorsForNewBlocks:blockView4 withColor:[UIColor purpleColor]];

    BlockView *blockView5 = [[BlockView alloc]initWithFrame:CGRectMake(134, 172, 55, 20)];
    [self behaviorsForNewBlocks:blockView5 withColor:[UIColor orangeColor]];
}

// Necessary view-adding and behaviors for newly created blocks
-(void)behaviorsForNewBlocks:(BlockView *)newBlockView withColor:(UIColor *)color
{
    [self.view addSubview:newBlockView];
    newBlockView.backgroundColor = color;
    [self.collisionBehavior addItem:newBlockView];
    [self.paddleDynamicBehavior addItem:newBlockView];
}

# pragma mark - Actions

// Allows paddle to be dragged in place along y-axis
-(IBAction)dragPaddle:(UIPanGestureRecognizer *)gestureRecognizer
{
    self.paddleView.center = CGPointMake([gestureRecognizer locationInView:self.view].x, self.paddleView.center.y);
    [self.dynamicAnimator updateItemUsingCurrentState:self.paddleView];
}

// Drops ball from center upon tap
- (IBAction)tapGesture:(UITapGestureRecognizer *)sender;{
    [self.gravityBehavior addItem:self.ballView];
    self.gravityBehavior.magnitude = 0.3;
    self.gravityBehavior.gravityDirection = CGVectorMake(1.0, 1.0);
    [self.dynamicAnimator removeBehavior:self.snapBehavior];
}

# pragma mark - Delegates

// Detects collision at bottom of view and resets ball to center
-(void)collisionBehavior:(UICollisionBehavior *)behavior beganContactForItem:(id<UIDynamicItem>)item withBoundaryIdentifier:(id<NSCopying>)identifier atPoint:(CGPoint)p
{
    if (p.y > 560)
    {
        //returns the ball to the middle of screen
        CGPoint centerOfView = self.view.center;
        self.snapBehavior = [[UISnapBehavior alloc] initWithItem:self.ballView snapToPoint:centerOfView];
        [self.dynamicAnimator addBehavior:self.snapBehavior];
    }
}

// Detects collision between a ball and block
-(void)collisionBehavior:(UICollisionBehavior *)behavior endedContactForItem:(id<UIDynamicItem>)item1 withItem:(id<UIDynamicItem>)item2
{
    // When ball hits block
    if ([item1 isKindOfClass:[BallView class]] && [item2 isKindOfClass:[BlockView class]])
    {
        BlockView *blockCollided = (BlockView *)item2;
        [blockCollided removeFromSuperview];
        [self.collisionBehavior removeItem:item2];
        [self.paddleDynamicBehavior removeItem:item2];
    }

    // When ball hits paddle
    if ([item1 isKindOfClass:[BallView class]] && [item2 isKindOfClass:[PaddleView class]])
    {
        [self.gravityBehavior removeItem:self.ballView];
    }
}

# pragma mark - Quartz Framework

// Method for rounded BallView
-(void)setRoundedView:(BallView *)roundedView toDiameter:(float)newSize;
{
    CGPoint saveCenter = roundedView.center;
    CGRect newFrame = CGRectMake(roundedView.frame.origin.x, roundedView.frame.origin.y, newSize, newSize);
    roundedView.frame = newFrame;
    roundedView.layer.cornerRadius = newSize / 2.0;
    roundedView.center = saveCenter;
}

@end
